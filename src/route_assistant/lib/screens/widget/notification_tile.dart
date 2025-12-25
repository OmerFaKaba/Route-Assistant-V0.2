import 'package:flutter/material.dart';
import '../../models/notif_item.dart';

class NotificationTile extends StatelessWidget {
  final NotifItem item;
  final String timeText;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.item,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = item.readAt == null;

    final text = item.type == 'comment'
        ? '@${item.actorUsername} yorum attı · ${item.routeName}'
        : '@${item.actorUsername} like attı · ${item.routeName}';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
          color: isUnread ? Colors.black.withOpacity(0.04) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: item.actorAvatarUrl.isNotEmpty
                  ? NetworkImage(item.actorAvatarUrl)
                  : null,
              child: item.actorAvatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
