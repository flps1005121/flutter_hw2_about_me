class Game {
  final String name;
  final String imageUrl;
  final String genre;
  final double playTime;
  final List<Map<String, String>> achievements; // Update achievements type
  final String description;
  final int appId; // Add this line
  final int totalAchievements; // Add this line

  Game({
    required this.name,
    required this.imageUrl,
    required this.genre,
    required this.playTime,
    required this.achievements,
    required this.description,
    required this.appId, // Add this line
    required this.totalAchievements, // Add this line
  });
}
