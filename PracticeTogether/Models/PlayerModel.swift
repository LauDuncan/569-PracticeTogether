/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents each player's state in the SharePlay group session.
*/

import Spatial
import SwiftUI

struct PlayerModel: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var name: String
    
    var score: Int = 0
    var isPlaying: Bool = false
    
    var role: Role? = nil
    var seatPose: Pose3D?
    
    enum Role: String, Codable, Hashable, Sendable {
        case blue
        case red
        case yellow
    }
}

extension PlayerModel.Role {
    var name: String {
        switch self {
            case .blue: "Airway Nurse"
            case .red: "Defibrillator Nurse"
            case .yellow: "Charge Nurse"
        }
    }
    
    var color: Color {
        switch self {
            case .red: .red
            case .blue: .blue
            case .yellow: .yellow
        }
    }
}
