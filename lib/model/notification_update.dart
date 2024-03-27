class NotificationUpdateModel {
  String notificationId;
  String notificationStatus;
  String userIdentifier;

  NotificationUpdateModel({
    required this.notificationId,
    required this.notificationStatus,
    required this.userIdentifier
  });


  Map<String, dynamic> toJson() {
    return {
      "notificationId": notificationId,
      "notificationStatus": notificationStatus,
      "userIdentifier" : userIdentifier,
    };
  }
}
