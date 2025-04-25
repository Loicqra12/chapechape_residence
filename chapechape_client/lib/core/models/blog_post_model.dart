class BlogPost {
  final String id;
  final String title;
  final String? summary;
  final String? content;
  final String? imageUrl;
  final DateTime? publishedDate;
  final String? authorName;
  final String? authorImageUrl;
  final String? category;
  final int? readTimeMinutes;
  final List<String>? tags;
  final bool isFeatured;

  BlogPost({
    required this.id,
    required this.title,
    this.summary,
    this.content,
    this.imageUrl,
    this.publishedDate,
    this.authorName,
    this.authorImageUrl,
    this.category,
    this.readTimeMinutes,
    this.tags,
    this.isFeatured = false,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'],
      title: json['title'],
      summary: json['summary'],
      content: json['content'],
      imageUrl: json['imageUrl'],
      publishedDate: json['publishedDate'] != null 
        ? DateTime.parse(json['publishedDate']) 
        : null,
      authorName: json['authorName'],
      authorImageUrl: json['authorImageUrl'],
      category: json['category'],
      readTimeMinutes: json['readTimeMinutes'],
      tags: json['tags'] != null 
        ? List<String>.from(json['tags']) 
        : null,
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'imageUrl': imageUrl,
      'publishedDate': publishedDate?.toIso8601String(),
      'authorName': authorName,
      'authorImageUrl': authorImageUrl,
      'category': category,
      'readTimeMinutes': readTimeMinutes,
      'tags': tags,
      'isFeatured': isFeatured,
    };
  }
} 