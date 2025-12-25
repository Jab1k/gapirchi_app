class CarModel {
  final String id;
  final String name;

  CarModel({required this.id, required this.name});

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['_id'],
      name: json['name'],
    );
  }
}