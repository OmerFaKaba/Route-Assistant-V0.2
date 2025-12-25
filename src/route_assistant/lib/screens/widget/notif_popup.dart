import 'package:flutter/material.dart';
import '../../models/notif_item.dart';

class NotifPopup extends StatelessWidget {
  final int unreadCount;
  final List<NotifItem> items;

  final VoidCallback onTapHeader;
  final void Function(int notifId, String routeId) onTapItem;
  final VoidCallback onClose;

  const NotifPopup({
    super.key,
    required this.unreadCount,
    required this.items,
    required this.onTapHeader,
    required this.onTapItem,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(blurRadius: 18, spreadRadius: 2, color: Color(0x22000000)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onTapHeader,
                  child: Text(
                    unreadCount > 0
                        ? '$unreadCount bildirim var — tıkla temizle'
                        : 'Bildirimler',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, i) {
                final n = items[i];
                final text = n.type == 'comment'
                    ? '@${n.actorUsername} yorum attı · ${n.routeName}'
                    : '@${n.actorUsername} like attı · ${n.routeName}';

                return InkWell(
                  onTap: () => onTapItem(n.id, n.routeId),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: n.actorAvatarUrl.isNotEmpty
                            ? NetworkImage(n.actorAvatarUrl)
                            : null,
                        child: n.actorAvatarUrl.isEmpty
                            ? const Icon(Icons.person, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.grey,
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
