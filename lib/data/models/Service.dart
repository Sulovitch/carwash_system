class Service {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['ServiceID'] as int,
      name: json['Name'] as String,
      description: json['Description'] as String,
      price: double.tryParse(json['Price'].toString()) ??
          0.0, // Safely parse price
      imageUrl: json['image_url'] as String?,
    );
  }
}
