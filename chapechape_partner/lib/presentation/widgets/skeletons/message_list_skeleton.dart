import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader pour la liste des messages
class MessageListSkeleton extends StatelessWidget {
  final int itemCount;

  const MessageListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 12),
                
                // Message info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 16,
                            width: 120,
                            color: Colors.grey[300],
                          ),
                          Container(
                            height: 12,
                            width: 60,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: double.infinity,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: 150,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Unread badge
                if (index % 3 == 0)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

