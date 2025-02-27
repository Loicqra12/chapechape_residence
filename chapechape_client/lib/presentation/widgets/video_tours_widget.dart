import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_assets.dart';

class VideoToursWidget extends StatelessWidget {
  const VideoToursWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<VideoTour> videoTours = [
      VideoTour(
        title: 'Villa Santorini - Visite Guidée',
        thumbnail: ResidenceAssets.villa1,
        videoUrl: 'https://youtu.be/example1',
        duration: '5:30',
        location: '',
        price: '',
      ),
      VideoTour(
        title: 'Appartement Moderne au Plateau',
        thumbnail: ResidenceAssets.apartment4,
        videoUrl: 'https://youtu.be/example2',
        duration: '4:15',
        location: '',
        price: '',
      ),
      VideoTour(
        title: 'Studio de Luxe au Quai d\'Orsay',
        thumbnail: ResidenceAssets.luxury1,
        videoUrl: 'https://youtu.be/example3',
        duration: '3:45',
        location: '',
        price: '',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visites Virtuelles',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explorez nos propriétés en vidéo',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: videoTours.length,
              itemBuilder: (context, index) {
                final tour = videoTours[index];
                return Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              tour.thumbnail,
                              height: 200,
                              width: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tour.duration,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tour.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tour.location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tour.price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VideoTour {
  final String title;
  final String thumbnail;
  final String videoUrl;
  final String duration;
  final String location;
  final String price;

  VideoTour({
    required this.title,
    required this.thumbnail,
    required this.videoUrl,
    required this.duration,
    required this.location,
    required this.price,
  });
}
