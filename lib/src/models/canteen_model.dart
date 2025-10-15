// lib/models/canteen_model.dart
class Canteen {
  final String id;
  final String name;
  final String ownerId;
  final bool approved;
  final String? imageUrl;

  Canteen({
    required this.id,
    required this.name,
    required this.ownerId,
    this.approved = false,
    this.imageUrl,
  });

  factory Canteen.fromMap(String id, Map<String, dynamic> m) {
    return Canteen(
      id: id,
      name: m['name'] ?? '',
      ownerId: m['ownerId'] ?? '',
      approved: m['approved'] ?? false,
      imageUrl: m['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'ownerId': ownerId,
    'approved': approved,
    'imageUrl': imageUrl,
  };
}