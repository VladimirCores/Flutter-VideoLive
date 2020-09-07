import 'package:agora_rtc_engine/rtc_engine.dart';

class RoomVO {
  // TODO: Temporary solution, remove when real user data will be available
  static final String CURRENT_USER_ID = DateTime.now().toUtc().microsecondsSinceEpoch.toString();

  String id;
  String appId;
  String title;
  bool isCurrent;
  ClientRole role;

  RoomVO(this.id, this.appId, this.title, this.role, {this.isCurrent = false});
}