class Service {
  final int id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int durationMinutes;
  final bool isAvailable;
  final int professionalId;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'DT',
    required this.durationMinutes,
    this.isAvailable = true,
    required this.professionalId,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      currency: json['currency'] ?? 'DT',
      durationMinutes: json['duration_minutes'] ?? 60,
      isAvailable: json['is_available'] ?? true,
      professionalId: json['professional_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'duration_minutes': durationMinutes,
      'is_available': isAvailable,
      'professional_id': professionalId,
    };
  }

  String get formattedPrice => '$price $currency';
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '${durationMinutes}min';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h${minutes}min';
      }
    }
  }
}
