import 'package:flutter/material.dart';
import 'game.dart';
import 'game_detail.dart';

class GameCard extends StatelessWidget {
  final Game game;

  const GameCard({super.key, required this.game});

  String formatPlayTime(double playTime) {
    if (playTime < 1) {
      return '${(playTime * 60).round()} 分鐘';
    } else {
      return '${playTime.round()} 小時';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[800], // 使用深色背景
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GameDetailPage(game: game)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Image.network(game.imageUrl, width: 100, height: 100,
                  errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error);
              }),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.category,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(game.genre,
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text('已遊玩 ${formatPlayTime(game.playTime)}',
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
