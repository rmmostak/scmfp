class DecisionModel {
  int?  trx_id;
  String?  user_id;
  String?  ph;
  String?  d0;
  String?  ammonia;
  String?  temp;
  String?  salinity;
  String?  decision;
  String?  dateTime;

  DecisionModel({
    this.trx_id,
    this.user_id,
    this.ph,
    this.d0,
    this.ammonia,
    this.temp,
    this.salinity,
    this.decision,
    this.dateTime
  });

  factory DecisionModel.fromJson(Map<String, dynamic> json) {
    return DecisionModel(
      trx_id: json['id'],
      user_id: json['user_id'],
      ph: json['ph'],
      d0: json['do'],
      ammonia: json['ammonia'],
      temp: json['temp'],
      salinity: json['salinity'],
      decision: json['result'],
      dateTime: json['created']
    );
  }
}