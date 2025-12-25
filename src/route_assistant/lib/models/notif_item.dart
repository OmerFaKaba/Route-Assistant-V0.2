class NotifItem {
  final int id;
  final String type; // like/comment
  final String createdAt;
  final dynamic readAt;
  final String routeId;

  final String actorUsername;
  final String actorAvatarUrl;
  final String routeName;

  const NotifItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.readAt,
    required this.routeId,
    required this.actorUsername,
    required this.actorAvatarUrl,
    required this.routeName,
  });
}
