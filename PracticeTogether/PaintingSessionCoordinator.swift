import Foundation
import GroupActivities
import Combine
import SwiftUI // For @Published and ObservableObject
import simd // For SIMD3

// Handles the SharePlay session and synchronizes stroke data.
@MainActor
class PaintingSessionCoordinator: ObservableObject {
    // MARK: - Published Properties
    @Published var session: GroupSession<PaintingActivity>?
    @Published var messenger: GroupSessionMessenger?
    @Published var activeParticipants: [Participant] = []
    @Published var strokes: [UUID: ShareableStroke] = [:] // Holds all strokes (local and remote)
    @Published var isSharing = false

    // MARK: - Private Properties
    private var subscriptions = Set<AnyCancellable>()
    private var tasks = Set<Task<Void, Never>>()
    private var currentActivity: PaintingActivity? // Keep track of the activity

    // MARK: - Initialization
    init() {
        // Observe sessions for the PaintingActivity.
        Task {
            for await session in PaintingActivity.sessions() {
                handleSession(session)
            }
        }
    }

    // MARK: - Public Control Methods

    /// Starts a new SharePlay activity or prepares to join an existing one.
    func startSharing() async {
        print("Attempting to start SharePlay sharing...")
        // Ensure we don't try to start if already in a session
        guard session == nil else {
            print("Already in a session. Cannot start another.")
            return
        }
        
        currentActivity = PaintingActivity()
        do {
            // Activate the activity
            _ = try await currentActivity?.activate()
            print("PaintingActivity activated successfully. Waiting for session...")
            // Session handling logic is now fully within handleSession observed via PaintingActivity.sessions()
        } catch {
            print("Failed to activate PaintingActivity: \(error)")
            currentActivity = nil // Reset activity if activation failed
        }
    }

    /// Ends the current SharePlay session.
    func endSharing() {
        print("Attempting to end SharePlay sharing...")
        if let session = session {
            session.end()
            resetSession() // Ensure state is fully reset
            currentActivity = nil // Clear the activity
            print("SharePlay session ended.")
        } else {
            print("No active session to end.")
        }
        // Explicitly set isSharing to false as resetSession might not be called if session was already nil
        isSharing = false 
    }

    // MARK: - Session Handling
    func handleSession(_ session: GroupSession<PaintingActivity>) {
        self.session = session
        let messenger = GroupSessionMessenger(session: session)
        self.messenger = messenger
        
        print("Joined SharePlay session: \(session.id)")

        // Cancel ALL existing tasks before setting up new ones for this session
        print("Cancelling existing coordinator tasks before handling new session.")
        tasks.forEach { $0.cancel() }
        tasks.removeAll()

        // Initial setup
        self.activeParticipants = Array(session.activeParticipants)
        self.isSharing = true
        let initialParticipantCount = self.activeParticipants.count // Use count after setting self.activeParticipants

        // Configure SystemCoordinator for Immersive Space
        Task { // Use Task to access async property
            do {
                if let systemCoordinator = await session.systemCoordinator {
                    print("Successfully obtained SystemCoordinator for session \(session.id)")
                    
                    var configuration = SystemCoordinator.Configuration()
                    
                    // CRITICAL: Enable group immersive space for SharePlay
                    configuration.supportsGroupImmersiveSpace = true
                    
                    // Side-by-side is a good default for drawing activity
                    configuration.spatialTemplatePreference = .sideBySide
                    
                    // Apply the configuration
                    systemCoordinator.configuration = configuration
                    
                    print("SystemCoordinator fully configured for immersive space SharePlay with Personas enabled.")
                } else {
                    print("WARNING: Failed to get SystemCoordinator for session \(session.id)")
                    print("SharePlay may not work correctly in immersive space. Personas may not appear.")
                    print("This could be due to OS version incompatibility or missing entitlements.")
                }
            } catch {
                print("ERROR configuring SystemCoordinator: \(error)")
            }
        }

        // Listen for session state changes.
        session.$state.sink { [weak self] state in
            if case .invalidated = state {
                self?.resetSession()
                print("SharePlay session invalidated.")
            }
        }.store(in: &subscriptions)

        // --- Participant Change Listener --- 
        let participantTask = Task(priority: .userInitiated, operation: { [weak self] in
            print("Starting participant listener task.")
            guard let session = self?.session else {
                print("Participant listener task: Session is nil.")
                return
            }
            
            let stream = session.$activeParticipants.values
            
            do {
                for await participants in stream {
                    // Check for cancellation at the start of each iteration
                    try Task.checkCancellation()
                    
                    guard let self = self else { break } // Ensure self is still valid
                    
                    let newParticipants = Array(participants)
                    let previousCount = self.activeParticipants.count // Read current count directly
                    
                    // Update published property on main actor
                    await MainActor.run { 
                        self.activeParticipants = newParticipants
                        print("Participants updated via stream: \(newParticipants.count)")
                    }

                    // Send state if new participants joined
                    if newParticipants.count > previousCount && previousCount >= 1 {
                        print("New participant(s) joined. Sending full state.")
                        self.sendFullStateToAll()
                    }
                }
            } catch is CancellationError {
                print("Participant listener task cancelled.")
            } catch {
                print("Participant listener stream encountered error: \(error)")
            }
             print("Participant listener task finished.")
        })
        tasks.insert(participantTask)
        // ---------------------------------

        // Start listening for messages.
        listenForMessages() // Call this *after* clearing old tasks

        // Join the session.
        session.join()

        // If joining an *existing* session, send our initial state.
        if initialParticipantCount > 1 {
            print("Joined existing session with \(initialParticipantCount) participants. Sending initial state.")
            sendFullStateToAll() // Send our state to others
        }
    }

    private func resetSession() {
        print("Resetting SharePlay session and cancelling tasks.")
        self.session = nil
        self.messenger = nil
        self.activeParticipants = []
        self.strokes = [:] // Clear strokes on session invalidation
        self.isSharing = false // Reset sharing state
        subscriptions.removeAll()
        // Cancel all tasks on reset
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }

    // MARK: - Messaging
    private func listenForMessages() {
        guard let messenger = messenger else { return }

        let messageTask = Task {
            for await (message, context) in messenger.messages(of: StrokeMessage.self) {
                handle(message, from: context.source)
            }
        }
        tasks.insert(messageTask)
        
        let stateRequestTask = Task {
            for await (message, context) in messenger.messages(of: StateRequestMessage.self) {
                handle(message, from: context.source)
            }
        }
        tasks.insert(stateRequestTask)
        print("Message listener tasks started and added to managed set.")
    }

    private func handle(_ message: StrokeMessage, from participant: Participant) {
        switch message {
        case .addPoint(let strokeID, let point):
            if strokes[strokeID] != nil {
                strokes[strokeID]?.points.append(point)
            } else {
                // If we receive a point for a stroke we don't know, create it.
                // This might happen if messages arrive out of order.
                let newStroke = ShareableStroke(id: strokeID, points: [point], participantID: participant.id)
                strokes[strokeID] = newStroke
                print("Received point for unknown stroke \(strokeID), created it.")
            }
        case .startStroke(let stroke):
             // Ensure we don't overwrite an existing stroke unless timestamp is newer?
             // Also ensure the incoming stroke has a participantID (it should if coming via message)
            if stroke.participantID != nil && (strokes[stroke.id] == nil || (strokes[stroke.id]?.timestamp ?? .distantPast) < stroke.timestamp) {
                 strokes[stroke.id] = stroke
                 print("Received startStroke for \(stroke.id) from \(stroke.participantID?.debugDescription ?? "unknown")")
            } else if stroke.participantID == nil {
                 print("Ignoring startStroke message with nil participantID for \(stroke.id)")
            } else {
                 print("Ignoring older startStroke for \(stroke.id)")
            }
           
        case .finishStroke(let strokeID):
            if strokes[strokeID] != nil {
                strokes[strokeID]?.isFinished = true
                 print("Received finishStroke for \(strokeID)")
            } else {
                 print("Received finishStroke for unknown stroke \(strokeID)")
            }

        case .deleteStroke(let strokeID):
            if strokes.removeValue(forKey: strokeID) != nil {
                print("Removed stroke \(strokeID) based on message.")
            }
        }
    }
    
    private func handle(_ message: StateRequestMessage, from participant: Participant) {
        switch message {
        case .sendCurrentState(let allStrokes):
             print("Received current state with \(allStrokes.count) strokes from \(participant.id).")
             // Basic merge: Replace local strokes only if the incoming state has a participantID
             // Keep local-only strokes (participantID == nil)
             let localOnlyStrokes = self.strokes.filter { $1.participantID == nil }
             // Filter incoming strokes to ensure they have a participant ID
             let validRemoteStrokes = allStrokes.filter { $1.participantID != nil }
             
             // Combine local-only with valid remote strokes
             self.strokes = localOnlyStrokes.merging(validRemoteStrokes) { (local, remote) -> ShareableStroke in
                 // Basic conflict resolution: keep the newest based on timestamp
                 return local.timestamp >= remote.timestamp ? local : remote
             }
             print("Merged state: Now have \(self.strokes.count) strokes (\(localOnlyStrokes.count) local-only preserved).")
        }
    }

    // MARK: - Sending Messages
    func send(_ message: StrokeMessage) {
        guard let messenger = messenger else { return }
        Task {
            do {
                // Send to all participants (default behavior)
                try await messenger.send(message)
            } catch {
                print("Error sending StrokeMessage: \(error)")
            }
        }
    }

    // NOTE: This method is no longer used for targeted sending.
    // State updates are now sent to .all when participants change.
    // Keeping the signature for potential future use or refactoring.
    func send(_ message: StateRequestMessage, to participant: Participant) {
         print("Warning: send(_:to:) called but sending to .all by default.")
         sendStateUpdateMessage(message)
     }

    // Helper to send state messages to .all
    private func sendStateUpdateMessage(_ message: StateRequestMessage) {
        guard let messenger = messenger else { return }
         Task {
             do {
                 // Send to all participants (default behavior)
                 try await messenger.send(message)
                 if case .sendCurrentState(let strokes) = message {
                     print("Sent full state (\(strokes.count) strokes) to all participants.")
                 }
             } catch {
                 print("Error sending StateRequestMessage: \(error)")
             }
         }
    }

    // MARK: - Local Actions Triggering Network Updates
    func startStroke(participantID: Participant.ID?) -> ShareableStroke {
        let newStroke = ShareableStroke(participantID: participantID)
        strokes[newStroke.id] = newStroke
        print("Locally started stroke \(newStroke.id) - Participant: \(participantID?.debugDescription ?? "Local")")
        
        // Only send if we have a valid participant ID (i.e., in a session)
        if participantID != nil {
             send(.startStroke(stroke: newStroke))
        }
        return newStroke
    }

    func addPoint(_ point: SIMD3<Float>, to strokeID: UUID) {
        guard strokes[strokeID] != nil else { 
            print("Warning: Tried to add point to non-existent local stroke \(strokeID)."); 
            return 
        }
        // Update local state first
        strokes[strokeID]?.points.append(point)
        
        // Only send if the stroke belongs to a session participant
        if strokes[strokeID]?.participantID != nil {
            send(.addPoint(strokeID: strokeID, point: point))
        }
    }

    func finishStroke(strokeID: UUID) {
        guard strokes[strokeID] != nil else { 
            print("Warning: Tried to finish non-existent local stroke \(strokeID)."); 
            return 
        }
        // Update local state first
        strokes[strokeID]?.isFinished = true
        print("Locally finished stroke \(strokeID)")
        
        // Only send if the stroke belongs to a session participant
        if strokes[strokeID]?.participantID != nil {
            send(.finishStroke(strokeID: strokeID))
        }
        // Potentially send the full stroke data via Task for reliability later if needed
    }
    
    // Renamed/Refactored: Sends the *entire* current state to *all* participants.
    private func sendFullStateToAll() {
        print("Sending full current state (\(strokes.count) strokes) to all.")
        // Use the helper to send the state message to .all
        sendStateUpdateMessage(.sendCurrentState(strokes: self.strokes))
    }
}

// MARK: - Message Types

enum StrokeMessage: Codable {
    case startStroke(stroke: ShareableStroke) // Send when a new stroke begins
    case addPoint(strokeID: UUID, point: SIMD3<Float>) // Send frequently during drawing
    case finishStroke(strokeID: UUID) // Send when drawing ends
    case deleteStroke(strokeID: UUID) // Optional: For deleting strokes
}

enum StateRequestMessage: Codable {
    case sendCurrentState(strokes: [UUID: ShareableStroke])
} 