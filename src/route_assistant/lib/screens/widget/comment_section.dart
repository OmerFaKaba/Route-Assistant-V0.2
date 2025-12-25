import 'package:flutter/material.dart';
import 'package:route_assistant/services/trail_service.dart';
import 'package:route_assistant/screens/in_app/profile_screen.dart'; // ✅ profil ekranın

class CommentsSection extends StatefulWidget {
  final String routeId;
  const CommentsSection({super.key, required this.routeId});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _ctrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeId != widget.routeId) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _comments = await TrailService.fetchComments(routeId: widget.routeId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Yorumlar alınamadı: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await TrailService.addComment(routeId: widget.routeId, content: text);
      _ctrl.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Yorum eklenemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _prettyTime(dynamic createdAt) {
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final y = dt.year.toString().padLeft(4, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$y-$mo-$d $h:$mi';
    } catch (_) {
      return createdAt?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Yorumlar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Yenile',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Yorum yaz...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Henüz yorum yok.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, i) {
                  final c = _comments[i];

                  // ✅ join ile gelmesi beklenen profiles alanı
                  final profile = c['profile'] as Map<String, dynamic>?;
                  final username = (profile?['username'] ?? 'user').toString();
                  final avatarUrl = profile?['avatar_url']?.toString();
                  final userId = c['user_id']?.toString();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,

                    // ✅ Avatar'a tıklayınca o kullanıcının profiline git
                    leading: GestureDetector(
                      onTap: (userId == null)
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileScreen(userId: userId),
                                ),
                              );
                            },
                      child: CircleAvatar(
                        backgroundImage:
                            (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                    ),

                    // ✅ isim + yorum
                    title: Text(
                      '@$username',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text((c['content'] ?? '').toString()),
                        const SizedBox(height: 4),
                        Text(_prettyTime(c['created_at'])),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
