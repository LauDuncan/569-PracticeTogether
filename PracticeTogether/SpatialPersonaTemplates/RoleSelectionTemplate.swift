/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom spatial template used to arrange spatial Personas
  during Guess Together's team-selection stage.
*/

import GroupActivities

/// The team selection template contains three sets of seats:
///
/// 1. Five audience seats that participants are initially placed in.
/// 2. One seat for Charge Nurse
/// 3. One seat for Airway Nurse
/// 4. One seat for Defibrillator Nurse
///
/// ```
///                ┌────────────────────┐
///                │  Practice Together │
///                │     app window     │
///                └────────────────────┘
///
///
///
///        (Defib) %                   $ (Airway)
///
///                          X (Charge)
///
///                    *  *  *  *  *
///                       Audience
/// ```
struct RoleSelectionTemplate: SpatialTemplate {
    enum Role: String, SpatialTemplateRole {
        case blueTeam
        case redTeam
        case yellowTeam
    }
    
    /// An array of seating positions the game uses to position spatial Personas during the team-selection stage.
    ///
    /// The game fills the seats with participants based on the order of the array's elements.
    let elements: [any SpatialTemplateElement] = [
        // Red team (Defib):
//        .seat(position: .app.offsetBy(x: -2.5, z: 3.5), role: Role.redTeam),
        .seat(position: .app.offsetBy(x: -3.0, z: 3.0), role: Role.redTeam),
//        .seat(position: .app.offsetBy(x: -3.5, z: 2.5), role: Role.redTeam),
        
        // Starting positions:
        .seat(position: .app.offsetBy(x: 0, z: 5)),
        .seat(position: .app.offsetBy(x: 1, z: 5)),
        .seat(position: .app.offsetBy(x: -1, z: 5)),
        .seat(position: .app.offsetBy(x: 2, z: 5)),
        .seat(position: .app.offsetBy(x: -2, z: 5)),
        
        // Yellow team (Charge)
        .seat(position: .app.offsetBy(x: 0, z: 4), role: Role.yellowTeam),
        
        // Blue team (Airway):
//        .seat(position: .app.offsetBy(x: 2.5, z: 3.5), role: Role.blueTeam),
        .seat(position: .app.offsetBy(x: 3.0, z: 3.0), role: Role.blueTeam),
//        .seat(position: .app.offsetBy(x: 3.5, z: 2.5), role: Role.blueTeam)
    ]
}
