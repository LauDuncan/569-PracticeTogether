/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A coordinator that manages transitions between immersive spaces.
*/

import SwiftUI
import Observation
import Foundation

/// A coordinator that manages opening and closing of immersive spaces in the app.
/// It ensures proper sequencing of transitions and prevents race conditions.
@Observable @MainActor
final class ImmersiveSpaceCoordinator {
    // Reference to the app model to track space states
    private var appModel: AppModel
    
    // Tracks the currently active space ID, if any
    private var currentSpaceID: String?
    
    // A UUID for the current transition to prevent duplicate transitions
    private var currentTransitionID: UUID?
    
    // A queue of transition requests to prevent race conditions
    private var pendingTransitions: [(id: UUID, fromStage: GameModel.ActivityStage?, toStage: GameModel.ActivityStage?)] = []
    
    // Flag to indicate if a transition is in progress
    private var isTransitioning = false
    
    // Keep track of the last handled stage transition to prevent duplicate processing
    private var lastHandledStages: (oldStage: GameModel.ActivityStage?, newStage: GameModel.ActivityStage?)?
    
    init(appModel: AppModel) {
        self.appModel = appModel
    }
    
    /// Handles a game stage change by requesting appropriate immersive space transition.
    /// This is the main method that should be called from GameSpace and DebriefSpace.
    ///
    /// - Parameters:
    ///   - oldStage: The previous game stage
    ///   - newStage: The new game stage
    ///   - openSpace: A closure that opens an immersive space
    ///   - dismissSpace: A closure that dismisses the current immersive space
    func handleStageChange(
        from oldStage: GameModel.ActivityStage?,
        to newStage: GameModel.ActivityStage?,
        openSpace: @escaping (String) async throws -> Void,
        dismissSpace: @escaping () async throws -> Void
    ) async {
        // Generate a unique ID for this transition request
        let transitionID = UUID()
        
        // Check if we've already handled this exact stage transition
        if let lastHandled = lastHandledStages,
           lastHandled.oldStage == oldStage && lastHandled.newStage == newStage {
            print("Skipping duplicate stage transition: \(oldStage.debugDescription) → \(newStage.debugDescription)")
            return
        }
        
        // Determine appropriate space IDs for both stages
        let oldSpaceID = spaceIDForGameStage(oldStage)
        let newSpaceID = spaceIDForGameStage(newStage)
        
        // Skip if no change in space is needed
        if oldSpaceID == newSpaceID {
            return
        }
        
        // If a transition is already in progress, add this one to the queue
        if isTransitioning {
            print("Transition already in progress, queueing: \(oldStage.debugDescription) → \(newStage.debugDescription)")
            pendingTransitions.append((id: transitionID, fromStage: oldStage, toStage: newStage))
            return
        }
        
        // Mark as transitioning and store this transition ID
        isTransitioning = true
        currentTransitionID = transitionID
        
        // Record this transition as the last handled one
        lastHandledStages = (oldStage, newStage)
        
        print("Starting transition: \(oldStage.debugDescription) → \(newStage.debugDescription) (ID: \(transitionID))")
        
        // Perform the transition
        do {
            // First dismiss the old space if needed
            if let oldSpaceID = oldSpaceID {
                // Update tracking flags first
                updateTrackingFlags(for: oldSpaceID, isOpen: false)
                
                // Then dismiss the space
                try await dismissSpace()
                print("Successfully dismissed space: \(oldSpaceID)")
            }
            
            // Update the current space ID
            currentSpaceID = newSpaceID
            
            // Then open the new space if needed
            if let newSpaceID = newSpaceID {
                try await openSpace(newSpaceID)
                print("Successfully opened space: \(newSpaceID)")
                
                // Update tracking flags after successful open
                updateTrackingFlags(for: newSpaceID, isOpen: true)
            }
            
            print("Completed transition: \(oldStage.debugDescription) → \(newStage.debugDescription) (ID: \(transitionID))")
        } catch {
            print("Transition failed: \(error.localizedDescription)")
        }
        
        // Reset transition state
        isTransitioning = false
        currentTransitionID = nil
        
        // Process any pending transitions
        processPendingTransitions(openSpace: openSpace, dismissSpace: dismissSpace)
    }
    
    /// Process any pending transitions in the queue
    private func processPendingTransitions(
        openSpace: @escaping (String) async throws -> Void,
        dismissSpace: @escaping () async throws -> Void
    ) {
        // If there are pending transitions, process the next one
        guard !pendingTransitions.isEmpty else { return }
        
        // Get the next transition and remove it from the queue
        let nextTransition = pendingTransitions.removeFirst()
        
        // Process it asynchronously
        Task {
            await handleStageChange(
                from: nextTransition.fromStage,
                to: nextTransition.toStage,
                openSpace: openSpace,
                dismissSpace: dismissSpace
            )
        }
    }
    
    /// Updates the tracking flags in the app model based on which space was opened/closed
    private func updateTrackingFlags(for spaceID: String, isOpen: Bool) {
        if spaceID == GameSpace.spaceID {
            appModel.isImmersiveSpaceOpen = isOpen
        } else if spaceID == DebriefSpace.spaceID {
            appModel.isDebriefSpaceOpen = isOpen
        }
    }
    
    /// Determines the appropriate space ID based on the game stage.
    /// 
    /// - Parameter stage: The current game stage
    /// - Returns: The ID of the immersive space to open, or nil if no space should be open
    func spaceIDForGameStage(_ stage: GameModel.ActivityStage?) -> String? {
        guard let stage = stage else { return nil }
        
        switch stage {
        case .inGame:
            return GameSpace.spaceID
        case .debrief:
            return DebriefSpace.spaceID
        case .scenarioSelection, .roleSelection:
            return nil
        }
    }
} 