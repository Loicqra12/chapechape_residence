class Listing {
  final String id;
  final String title;
  final double? price;
  final String? description;
  final String? location;
  final List<String>? images;
  final String? category;
  final String? status;
  final int? bedrooms;
  final int? bathrooms;
  final double? area;
  final bool isPromoted;
  final DateTime? createdAt;
  final String? ownerId;
  final Map<String, dynamic>? additionalFeatures;

  Listing({
    required this.id,
    required this.title,
    this.price,
    this.description,
    this.location,
    this.images,
    this.category,
    this.status,
    this.bedrooms,
    this.bathrooms,
    this.area,
    this.isPromoted = false,
    this.createdAt,
    this.ownerId,
    this.additionalFeatures,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'],
      title: json['title'],
      price: json['price'] != null ? double.parse(json['price'].toString()) : null,
      description: json['description'],
      location: json['location'],
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : null,
      category: json['category'],
      status: json['status'],
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      area: json['area'] != null ? double.parse(json['area'].toString()) : null,
      isPromoted: json['isPromoted'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      ownerId: json['ownerId'],
      additionalFeatures: json['additionalFeatures'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'location': location,
      'images': images,
      'category': category,
      'status': status,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'isPromoted': isPromoted,
      'createdAt': createdAt?.toIso8601String(),
      'ownerId': ownerId,
      'additionalFeatures': additionalFeatures,
    };
  }
} 