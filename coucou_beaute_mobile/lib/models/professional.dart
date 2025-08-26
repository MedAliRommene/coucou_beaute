import 'user.dart';

enum ServiceType {
  mobile,    // Je me déplace
  home,      // Je reçois chez moi
  salon      // J'ai un salon
}

enum ActivityCategory {
  hairdressing,    // Coiffure
  makeup,          // Maquillage
  manicure,        // Manucure
  esthetics,       // Esthétique
  massage,         // Massage
  other            // Autre
}

enum Language {
  french,    // Français
  arabic,    // Arabe
  english    // Anglais
}

class Professional {
  final int id;
  final User user;
  final String? businessName;
  final bool isVerified;
  final DateTime createdAt;
  
  // Informations professionnelles
  final ActivityCategory activityCategory;
  final ServiceType serviceType;
  final List<Language> spokenLanguages;
  final String? address;
  final double? latitude;
  final double? longitude;
  
  // Profil
  final String? profilePhoto;
  final String? idDocument;
  final String? description;
  final String? presentation;
  
  // Statistiques
  final int profileViews;
  final int reservations;
  final double rating;
  final int reviewCount;

  Professional({
    required this.id,
    required this.user,
    this.businessName,
    required this.isVerified,
    required this.createdAt,
    required this.activityCategory,
    required this.serviceType,
    required this.spokenLanguages,
    this.address,
    this.latitude,
    this.longitude,
    this.profilePhoto,
    this.idDocument,
    this.description,
    this.presentation,
    this.profileViews = 0,
    this.reservations = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    return Professional(
      id: json['id'],
      user: User.fromJson(json['user']),
      businessName: json['business_name'],
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      activityCategory: ActivityCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['activity_category'],
        orElse: () => ActivityCategory.hairdressing,
      ),
      serviceType: ServiceType.values.firstWhere(
        (e) => e.toString().split('.').last == json['service_type'],
        orElse: () => ServiceType.salon,
      ),
      spokenLanguages: (json['spoken_languages'] as List<dynamic>?)
          ?.map((lang) => Language.values.firstWhere(
                (e) => e.toString().split('.').last == lang,
                orElse: () => Language.french,
              ))
          .toList() ?? [Language.french],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      profilePhoto: json['profile_photo'],
      idDocument: json['id_document'],
      description: json['description'],
      presentation: json['presentation'],
      profileViews: json['profile_views'] ?? 0,
      reservations: json['reservations'] ?? 0,
      rating: json['rating']?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'business_name': businessName,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'activity_category': activityCategory.toString().split('.').last,
      'service_type': serviceType.toString().split('.').last,
      'spoken_languages': spokenLanguages
          .map((lang) => lang.toString().split('.').last)
          .toList(),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'profile_photo': profilePhoto,
      'id_document': idDocument,
      'description': description,
      'presentation': presentation,
      'profile_views': profileViews,
      'reservations': reservations,
      'rating': rating,
      'review_count': reviewCount,
    };
  }

  String get activityCategoryLabel {
    switch (activityCategory) {
      case ActivityCategory.hairdressing:
        return 'Coiffure';
      case ActivityCategory.makeup:
        return 'Maquillage';
      case ActivityCategory.manicure:
        return 'Manicure';
      case ActivityCategory.esthetics:
        return 'Esthétique';
      case ActivityCategory.massage:
        return 'Massage';
      case ActivityCategory.other:
        return 'Autre';
    }
  }

  String get serviceTypeLabel {
    switch (serviceType) {
      case ServiceType.mobile:
        return 'Je me déplace';
      case ServiceType.home:
        return 'Je reçois chez moi';
      case ServiceType.salon:
        return 'J\'ai un salon';
    }
  }
}
