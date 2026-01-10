import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader pour l'écran de profil
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header section avec photo de profil
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Photo de profil
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  
                  // Nom
                  Container(
                    height: 24,
                    width: 180,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  
                  // Email
                  Container(
                    height: 16,
                    width: 200,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  
                  // Badge de statut
                  Container(
                    height: 32,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Section des statistiques
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildStatCardSkeleton()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCardSkeleton()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCardSkeleton()),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Options du profil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ...List.generate(
                    6,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 16,
                                    width: 120,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 12,
                                    width: 80,
                                    color: Colors.grey[300],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 20,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
            height: 12,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}

