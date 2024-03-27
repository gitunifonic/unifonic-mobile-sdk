class NotificationInfoDTO {
  late String notificationId;
  late String latitude;
  late String longitude;
  late String idAddress;
  late String deviceId;
  late String userId;
  late String status;
  late String deviceOs;
  late String accountId;

  NotificationInfoDTO({
    required this.notificationId,
    required this.latitude,
    required this.longitude,
    required this.idAddress,
    required this.deviceId,
    required this.userId,
    required this.status,
    required this.deviceOs,
    required this.accountId,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'latitude': latitude,
      'longitude': longitude,
      'idAddress': idAddress,
      'deviceId': deviceId,
      'userId': userId,
      'status': status,
      'deviceOs': deviceOs,
      'accountId': accountId,
    };
  }
}