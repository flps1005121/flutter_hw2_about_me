import 'package:flutter/material.dart';
import 'game.dart';
import 'game_card.dart';
import 'steam_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的遊戲庫',
      theme: ThemeData(
        fontFamily: 'Cubic',
        colorScheme: ColorScheme(
          primary: const Color(0xFF1B2838), // Steam 主色
          primaryContainer: const Color(0xFF2A475E), // Steam 次色
          secondary: const Color(0xFF66C0F4), // Steam 輔助色
          secondaryContainer: const Color(0xFF66C0F4), // Steam 輔助色
          surface: const Color(0xFF1B2838), // Steam 主色
          background: const Color(0xFF171A21), // Steam 背景色
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onError: Colors.white,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '我的遊戲庫'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Game>> futureRecentlyPlayedGames;
  late Future<Map<String, String>> futureUserProfile;
  late Future<List<Map<String, String>>> futureFriendsList;
  late Future<Map<String, dynamic>> futurePreferredGenres;
  late SteamService steamService;

  @override
  void initState() {
    super.initState();
    steamService = SteamService(
      apiKey: '5925A11126363F4F3647388FED60807D',
      steamId: '76561198249575264',
    );
    futureRecentlyPlayedGames = _fetchRecentlyPlayedGamesWithRetry();
    futureUserProfile = steamService.fetchUserProfile();
    futureFriendsList = steamService.fetchFriendsList();
    futurePreferredGenres = _fetchPreferredGenresWithRetry();
  }

  Future<List<Game>> _fetchRecentlyPlayedGamesWithRetry(
      {int retries = 3}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        return await steamService.fetchRecentlyPlayedGames();
      } catch (e) {
        if (attempt == retries - 1) {
          rethrow;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> _fetchPreferredGenresWithRetry(
      {int retries = 3}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        return await steamService.fetchPreferredGenres();
      } catch (e) {
        if (attempt == retries - 1) {
          rethrow;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return {};
  }

  void _navigateToGameLibrary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GameLibraryPage(steamService: steamService)),
    );
  }

  String formatFriendSince(String timestamp) {
    final friendSince =
        DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
    final now = DateTime.now();
    final difference = now.difference(friendSince).inDays;
    return '已成為朋友 $difference 天';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: FutureBuilder<Map<String, String>>(
          future: futureUserProfile,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white));
            } else if (!snapshot.hasData) {
              return const Text('No user data found',
                  style: TextStyle(color: Colors.white));
            } else {
              final userProfile = snapshot.data!;
              return Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(userProfile['avatar']!),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    userProfile['name']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              );
            }
          },
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background, // 設置背景顏色
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  elevation: 4,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('這是我的 Steam 遊戲庫應用程式，展示了我的遊戲和成就。',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('偏好的遊戲類型',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF66C0F4))),
                const SizedBox(height: 10),
                FutureBuilder<Map<String, dynamic>>(
                  future: futurePreferredGenres,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No preferred genres found'));
                    } else {
                      final genres = snapshot.data!['genres'] as List<String>;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('${genres.join(', ')}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text('最近遊玩',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF66C0F4))),
                const SizedBox(height: 10),
                FutureBuilder<List<Game>>(
                  future: futureRecentlyPlayedGames,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No recently played games found'));
                    } else {
                      return Column(
                        children: [
                          for (var game in snapshot.data!) GameCard(game: game)
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text('朋友列表',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF66C0F4))),
                const SizedBox(height: 10),
                FutureBuilder<List<Map<String, String>>>(
                  future: futureFriendsList,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No friends found'));
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
                                    subtitle: Text(formatFriendSince(
                                        friend['friend_since']!)),
                                  ))
                              .toList(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _navigateToGameLibrary(context),
                    child: const Text('瀏覽我的遊戲庫',
                        style: TextStyle(color: Colors.white)),
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

class GameLibraryPage extends StatelessWidget {
  final SteamService steamService;

  const GameLibraryPage({super.key, required this.steamService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white), // 設置箭頭圖標為白色
        title: const Text('我的遊戲庫', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<Game>>(
        future: steamService.fetchGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No games found'));
          } else {
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [for (var game in snapshot.data!) GameCard(game: game)],
            );
          }
        },
      ),
    );
  }
}
