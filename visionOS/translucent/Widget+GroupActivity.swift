import GroupActivities
import Foundation
import SwiftUI


func startSession(widget: Widget) async throws {
  let activity = WidgetActivity(widget:widget)
    let activationSuccess = try await activity.activate()
    print("Group Activities session activation: ", activationSuccess)
}

struct WidgetActivity: GroupActivity {
  
  var widget: Widget
  
  init(widget: Widget) {
    self.widget = widget
  }

  // Provide information about the activity.
  var metadata: GroupActivityMetadata {
    var metadata = GroupActivityMetadata()
    metadata.type = .exploreTogether
    metadata.title = "\(widget.displayName)"
    metadata.subtitle = "Browse together."
    metadata.previewImage = widget.thumbnailUIImage?.cgImage
    metadata.fallbackURL = widget.shareURL
    metadata.sceneAssociationBehavior = .content(WidgetActivity.activityIdentifier)
    return metadata
  }
}


struct LocationMessage: Codable {
    let location: String
}

struct ScrollMessage: Codable {
    let position: UnitPoint3D
}

struct EventMessage: Codable {
    let event: String
}


/// State information about the current group activity.
var sessionInfo: ProjectionSessionInfo? = nil

/// A container for group activity session information.
class ProjectionSessionInfo: ObservableObject {
    @Published var session: GroupSession<WidgetActivity>?
    var messenger: GroupSessionMessenger?
    var reliableMessenger: GroupSessionMessenger?
}
