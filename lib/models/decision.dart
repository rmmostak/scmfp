class DecisionModel {
  String?  trx_id;
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
      trx_id: json['decisions']['id'],
      user_id: json['decisions']['user_id'],
      ph: json['decisions']['ph'],
      d0: json['decisions']['d0'],
      ammonia: json['decisions']['ammonia'],
      temp: json['decisions']['temp'],
      salinity: json['decisions']['salinity'],
      decision: json['decisions']['result'],
      dateTime: json['decisions']['created_at']
    );
  }
}