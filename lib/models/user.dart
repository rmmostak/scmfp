class User {
  int? id;
  String? name;
  String? phone;
  String? password;
  String? father_name;
  String? address;
  String? gher_size;
  String? location;
  String? nid;
  String? picture;
  String? api_token;

  User(
      {this.id,
      this.name,
      this.phone,
      this.password,
      this.father_name,
      this.address,
      this.gher_size,
      this.location,
      this.nid,
      this.picture,
      this.api_token});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        id: json['user']['id'],
        name: json['user']['name'],
        phone: json['user']['phone'],
        password: json['user']['password'],
        father_name: json['user']['father_name'],
        address: json['user']['address'],
        gher_size: json['user']['gher_size'],
        location: json['user']['location'],
        nid: json['user']['nid'],
        picture: json['user']['picture'],
        api_token: json['token']);
  }
}
