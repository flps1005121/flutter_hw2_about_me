import 'package:flutter/material.dart';
import 'game.dart';
import 'steam_scraper.dart';
import 'steam_service.dart';

class GameDetailPage extends StatefulWidget {
  final Game game;

  const GameDetailPage({super.key, required this.game});

  @override
  _GameDetailPageState createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  late Future<Map<String, dynamic>> futureDetails;
  late SteamService steamService;

  @override
  void initState() {
    super.initState();
    steamService = SteamService(
      apiKey: '5925A11126363F4F3647388FED60807D',
      steamId: '76561198249575264',
    );
    futureDetails = SteamScraper().fetchGameDetails(widget.game.appId);
  }

  String formatPlayTime(double playTime) {
    if (playTime < 1) {
      return '${(playTime * 60).round()} 分鐘';
    } else if (playTime < 24) {
      return '${playTime.round()} 小時';
    } else {
      return '${(playTime / 24).round()} 天';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 將成就列表按名稱排序
    final sortedAchievements =
        List<Map<String, String>>.from(widget.game.achievements)
          ..sort((a, b) => a['name']!.compareTo(b['name']!));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // 設置箭頭圖標為白色
        title:
            Text(widget.game.name, style: const TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(widget.game.imageUrl,
                    width: double.infinity, height: 200, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error);
                }),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      '已遊玩 ${formatPlayTime(widget.game.playTime)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('遊戲詳情',
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(widget.game.description,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('遊戲圖片',
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: futureDetails,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData ||
                    snapshot.data!['images'].isEmpty) {
                  return const Center(child: Text('No images found'));
                } else {
                  final images = snapshot.data!['images'] as List<String>;
                  return SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: images
                          .map((imageUrl) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.network(imageUrl,
                                    width: 300, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error);
                                }),
                              ))
                          .toList(),
                    ),
                  );
                }
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('好友遊玩紀錄',
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            FutureBuilder<List<Map<String, String>>>(
              future: steamService
                  .fetchFriendsWhoPlayedGame(widget.game.appId.toString()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('沒有好友玩過這款遊戲'));
                } else {
                  return SizedBox(
                    height: 200,
                    child: ListView(
                      children: snapshot.data!
                          .map((friend) => ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(friend['avatar']!),
                                ),
                                title: Text(friend['name']!),
                                subtitle: Text('已遊玩 ${friend['playtime']}'),
                              ))
                          .toList(),
                    ),
                  );
                }
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  Text('成就', style: Theme.of(context).textTheme.headlineMedium),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('已解鎖 ${widget.game.achievements.length} 個成就',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0), // 增加底部間距
              child: SizedBox(
                height: 350,
                child: GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: sortedAchievements.length,
                  itemBuilder: (context, index) {
                    final achievement = sortedAchievements[index];
                    return Column(
                      children: [
                        Image.network(achievement['icon']!,
                            width: 75, height: 75,
                            errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error);
                        }),
                        Text(
                          achievement['name']!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
