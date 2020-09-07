class TokenVO {
  int uid;
  String value;
  int expire;

  TokenVO(this.uid, this.value, this.expire);

  TokenVO.fromJSON(Map<dynamic, dynamic> json)
      : uid = json['uid'],
        value = json['token'],
        expire = json['expire'];

  Map<String, dynamic> toJSON() => {
    'uid': uid,
    'token': value,
    'expire': expire,
  };
}