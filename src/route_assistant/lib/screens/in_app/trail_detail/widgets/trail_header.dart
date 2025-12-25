import 'package:flutter/material.dart';
import 'package:route_assistant/screens/in_app/profile_screen.dart';

class TrailHeader extends StatelessWidget {
  final String title;
  final String? ownerId;
  final String? ownerUsername;
  final String? ownerAvatarUrl;

  final int likeCount;
  final bool likedByMe;
  final bool likeBusy;
  final VoidCallback onToggleLike;

  const TrailHeader({
    super.key,
    required this.title,
    required this.ownerId,
    required this.ownerUsername,
    required this.ownerAvatarUrl,
    required this.likeCount,
    required this.likedByMe,
    required this.likeBusy,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    final username = (ownerUsername != null && ownerUsername!.isNotEmpty)
        ? '@$ownerUsername'
        : '@user';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (ownerId != null && ownerId!.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: ownerId!),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage:
                      (ownerAvatarUrl != null && ownerAvatarUrl!.isNotEmpty)
                      ? NetworkImage(ownerAvatarUrl!)
                      : null,
                  child: (ownerAvatarUrl == null || ownerAvatarUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                const Text('· oluşturdu', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              onPressed: likeBusy ? null : onToggleLike,
              icon: Icon(likedByMe ? Icons.favorite : Icons.favorite_border),
            ),
            Text(
              '$likeCount',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
