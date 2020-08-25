class RoomVO {
  // TODO: Temporary solution, remove when real user data will be available
  static final String CURRENT_USER_ID = DateTime.now().toUtc().microsecondsSinceEpoch.toString();

  String id;
  String title;
  bool isCurrent;

  RoomVO(this.id, this.title, {this.isCurrent = false});
}