import GroupActivities

struct WidgetActivity: GroupActivity {
  static let activityIdentifier = "com.blacktree.vision.widget"
  
  // The movie to watch together.
  var widget: Widget
  
  init(widget: Widget) {
    self.widget = widget
  }
}

extension WidgetActivity {
  // Provide information about the activity.
  var metadata: GroupActivityMetadata {
    var metadata = GroupActivityMetadata()
    metadata.type = .watchTogether
    metadata.title = "\(widget.displayName)"
    metadata.fallbackURL = widget.shareURL
    metadata.supportsContinuationOnTV = true
    return metadata
  }
}
