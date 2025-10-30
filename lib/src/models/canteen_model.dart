// lib/models/canteen_model.dart
class Canteen {
  final String id;
  final String name;
  final String ownerId;
  final bool approved;
  final String? openingTime;
  final String? closingTime;

  Canteen({
    required this.id,
    required this.name,
    required this.ownerId,
    this.approved = false,
    this.openingTime,
    this.closingTime,
  });

  factory Canteen.fromMap(String id, Map<String, dynamic> m) {
    return Canteen(
      id: id,
      name: m['name'] ?? '',
      ownerId: m['ownerId'] ?? '',
      approved: m['approved'] ?? false,
      openingTime: m['opening_time'],
      closingTime: m['closing_time'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'ownerId': ownerId,
    'approved': approved,
    'opening_time': openingTime,
    'closing_time': closingTime,
  };
}
