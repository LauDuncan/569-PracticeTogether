/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An observable object class that enables hand tracking and tracks the motion of the anchors.
*/

import RealityKit
import ARKit
import simd // Needed for SIMD3
import Combine // Needed for Timer
import SwiftUI // Needed for @MainActor

/// The class starts the `ARKitSession` and the `HandTrackingProvider`,
/// then updates the latest left and right hand anchors.
@MainActor class PaintingHandTracking: ObservableObject {
    /// The `ARKitSession` for hand tracking.
    let arSession = ARKitSession()
    
    /// The `HandTrackingProvider` for hand tracking.
    let handTracking = HandTrackingProvider()
    
    /// The current left hand anchor the app detects.
    @Published var latestLeftHand: HandAnchor?
    
    /// The current right hand anchor the app detects.
    @Published var latestRightHand: HandAnchor?
    
    // Derived pinch state (using left hand for simplicity)
    @Published var isPinching: Bool = false
    @Published var pinchLocation: SIMD3<Float>? // World coordinates of index finger tip during pinch
    
    // Pinch detection parameters
    private let pinchThreshold: Float = 0.04 // Adjust as needed
    private var pinchCheckTimer: Timer? // Use a timer for periodic checks
    
    /// Check whether the device supports hand tracking, and start the ARKit session.
    func startTracking() async {
        // Check if the device supports hand tracking.
        guard HandTrackingProvider.isSupported else {
            print("HandTrackingProvider is not supported on this device.")
            return
        }

        do {
            // Start the ARKit session with the `HandTrackingProvider`.
            try await arSession.run([handTracking])
            // Start timer for pinch checks AFTER session is running
            startPinchCheckTimer()
        } catch let error as ARKitSession.Error {
            // Handle any ARKit errors.
            print("Encountered an error while running providers: \(error.localizedDescription)")
        } catch let error {
            // Handle any other unexpected errors.
            print("Encountered an unexpected error: \(error.localizedDescription)")
        }
        
        // Task to process anchor updates
        Task {
            for await anchorUpdate in handTracking.anchorUpdates {
                // Update published anchors on main actor
                 await MainActor.run { 
                     switch anchorUpdate.anchor.chirality {
                     case .left:
                         self.latestLeftHand = anchorUpdate.anchor
                     case .right:
                         self.latestRightHand = anchorUpdate.anchor
                     }
                 }
            }
            print("Hand anchor update stream finished.")
        }
    }
    
    func stopTracking() {
        print("Stopping hand tracking and pinch timer.")
        arSession.stop()
        pinchCheckTimer?.invalidate()
        pinchCheckTimer = nil
         // Reset state
         latestLeftHand = nil
         latestRightHand = nil
         isPinching = false
         pinchLocation = nil
    }
    
    // --- Pinch Detection Logic ---
    
    private func startPinchCheckTimer() {
        // Invalidate existing timer if any
        pinchCheckTimer?.invalidate()
        // Schedule a timer to call checkPinchState periodically (e.g., 30 times per second)
        pinchCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            // Run pinch check logic on main actor
            Task { @MainActor in
                 self?.checkPinchState()
            }
        }
         print("Pinch check timer started.")
    }

    /// Checks the pinch state for a given hand anchor.
    /// - Parameter handAnchor: The HandAnchor to check (optional).
    /// - Returns: A tuple containing a boolean indicating if the hand is pinching and the optional location of the index finger tip if pinching.
    private func checkPinch(for handAnchor: HandAnchor?) -> (isPinching: Bool, location: SIMD3<Float>?) {
        guard let hand = handAnchor, let handSkeleton = hand.handSkeleton else {
            return (false, nil)
        }

        // Get world transforms for thumb and index finger tips
        let thumbTipTransform = hand.originFromAnchorTransform * handSkeleton.joint(.thumbTip).anchorFromJointTransform
        let indexTipTransform = hand.originFromAnchorTransform * handSkeleton.joint(.indexFingerTip).anchorFromJointTransform

        // Get world positions
        let thumbPos = thumbTipTransform.translation()
        let indexPos = indexTipTransform.translation()
        
        // Calculate distance
        let distance = length(thumbPos - indexPos)

        // Check against threshold
        let currentlyPinching = distance < pinchThreshold

        if currentlyPinching {
            return (true, indexPos)
        } else {
            return (false, nil)
        }
    }
    
    /// Checks pinch state for both hands and updates published properties.
    /// Prioritizes right hand if both are pinching.
    private func checkPinchState() {
        // Check both hands
        let rightPinch = checkPinch(for: latestRightHand)
        let leftPinch = checkPinch(for: latestLeftHand)

        // Update published properties based on checks
        if rightPinch.isPinching {
            // Prioritize right hand
            self.pinchLocation = rightPinch.location
            if !self.isPinching { self.isPinching = true }
        } else if leftPinch.isPinching {
            // Use left hand if right isn't pinching
            self.pinchLocation = leftPinch.location
            if !self.isPinching { self.isPinching = true }
        } else {
            // Neither hand is pinching
            if self.isPinching { self.isPinching = false }
            self.pinchLocation = nil
        }
    }
    
    // Ensure timer is invalidated on deinit
    deinit {
         pinchCheckTimer?.invalidate()
         print("PaintingHandTracking deinitialized, timer invalidated.")
    }
}
