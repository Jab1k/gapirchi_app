class CarBrand {
  final String id;
  final String name;
  final String icon;

  CarBrand({required this.id, required this.name, required this.icon});

  factory CarBrand.fromJson(Map<String, dynamic> json) {
    return CarBrand(
      id: json['_id'],
      name: json['name'],
      icon: json['icon'] ?? '',
    );
  }
}