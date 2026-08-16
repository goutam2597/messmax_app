import 'package:equatable/equatable.dart';
import '../../../../core/config/app_config.dart';

class AdModel extends Equatable {
  final int id;
  final String title;
  final String slug;
  final String? city;
  final String? area;
  final String? areaLabel;
  final String? location;
  final bool hideAddress;
  final bool hasVisibleAddress;
  final int seatsAvailable;
  final double rentPerSeat;
  final double? rentTotal;
  final String roomType;
  final int? roomCapacity;
  final List<String> amenities;
  final String? description;
  final String? contactPhone;
  final String? contactEmail;
  final String? contactWhatsapp;
  final bool isFeatured;
  final String? publishedAt;
  final String? coverImageUrl;
  final List<String> imageUrls;
  final String? messName;
  final String? posterName;
  final String? posterAvatarUrl;

  const AdModel({
    required this.id,
    required this.title,
    required this.slug,
    this.city,
    this.area,
    this.areaLabel,
    this.location,
    required this.hideAddress,
    required this.hasVisibleAddress,
    required this.seatsAvailable,
    required this.rentPerSeat,
    this.rentTotal,
    required this.roomType,
    this.roomCapacity,
    required this.amenities,
    this.description,
    this.contactPhone,
    this.contactEmail,
    this.contactWhatsapp,
    required this.isFeatured,
    this.publishedAt,
    this.coverImageUrl,
    required this.imageUrls,
    this.messName,
    this.posterName,
    this.posterAvatarUrl,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    final mess = json['mess'] as Map<String, dynamic>?;
    final poster = json['poster'] as Map<String, dynamic>?;

    return AdModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      city: json['city'] as String?,
      area: json['area'] as String?,
      areaLabel: json['area_label'] as String?,
      location: json['location'] as String?,
      hideAddress: json['hide_address'] as bool? ?? false,
      hasVisibleAddress: json['has_visible_address'] as bool? ?? false,
      seatsAvailable: json['seats_available'] as int? ?? 1,
      rentPerSeat: (json['rent_per_seat'] as num?)?.toDouble() ?? 0.0,
      rentTotal: (json['rent_total'] as num?)?.toDouble(),
      roomType: json['room_type'] as String? ?? 'shared',
      roomCapacity: json['room_capacity'] as int?,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      description: json['description'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactWhatsapp: json['contact_whatsapp'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      publishedAt: json['published_at'] as String?,
      coverImageUrl: AppConfig.sanitizeImageUrl(json['cover_image_url'] as String?),
      imageUrls: (json['image_urls'] as List<dynamic>?)
              ?.map((e) => AppConfig.sanitizeImageUrl(e.toString())!)
              .toList() ??
          const [],
      messName: mess?['name'] as String?,
      posterName: poster?['name'] as String?,
      posterAvatarUrl: AppConfig.sanitizeImageUrl(poster?['avatar_url'] as String?),
    );
  }

  @override
  List<Object?> get props => [
        id,
        slug,
        title,
        city,
        area,
        seatsAvailable,
        rentPerSeat,
        roomType,
        coverImageUrl,
      ];
}
