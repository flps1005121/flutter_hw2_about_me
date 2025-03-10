import 'dart:convert';
import 'package:http/http.dart' as http;
import 'game.dart';

class SteamService {
  final String apiKey;
  final String steamId;

  SteamService({required this.apiKey, required this.steamId});

  Future<Map<String, String>> fetchUserProfile() async {
    final response = await http.get(Uri.parse(
        'http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=$apiKey&steamids=$steamId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final player = data['response']['players'][0];
      return {
        'name': player['personaname'],
        'avatar': player['avatarfull'],
      };
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  Future<List<Game>> fetchGames() async {
    final response = await http.get(Uri.parse(
        'https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=$apiKey&steamid=$steamId&include_appinfo=true&include_played_free_games=true'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final games = data['response']['games'] as List;
      List<Game> gameList = await Future.wait(games.map((game) async {
        final details = await fetchGameDetails(game['appid']);
        final achievements = await fetchGameAchievements(game['appid']);
        return Game(
          appId: game['appid'],
          name: game['name'] ?? details['name'] ?? 'Unknown', // 確保名稱正確顯示
          imageUrl:
              'https://steamcdn-a.akamaihd.net/steam/apps/${game['appid']}/header.jpg',
          genre: details['genre'] ?? 'Unknown',
          playTime: game['playtime_forever'] != null
              ? game['playtime_forever'] / 60
              : 0,
          achievements: achievements,
          totalAchievements: achievements.length,
          description: details['description'] ?? 'No description available',
        );
      }).toList());

      // Sort by playTime and take the top 10
      gameList.sort((a, b) => b.playTime.compareTo(a.playTime));
      return gameList.take(10).toList();
    } else {
      throw Exception('Failed to load games');
    }
  }

  Future<List<Game>> fetchRecentlyPlayedGames() async {
    final response = await http.get(Uri.parse(
        'http://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v1/?key=$apiKey&steamid=$steamId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final games = data['response']['games'] as List;
      return await Future.wait(games.map((game) async {
        final details = await fetchGameDetails(game['appid']);
        final achievements = await fetchGameAchievements(game['appid']);
        return Game(
          appId: game['appid'],
          name: game['name'] ?? details['name'] ?? 'Unknown', // 確保名稱正確顯示
          imageUrl:
              'https://steamcdn-a.akamaihd.net/steam/apps/${game['appid']}/header.jpg',
          genre: details['genre'] ?? 'Unknown',
          playTime: game['playtime_2weeks'] != null
              ? game['playtime_2weeks'] / 60
              : 0,
          achievements: achievements,
          totalAchievements: achievements.length,
          description: details['description'] ?? 'No description available',
        );
      }).toList());
    } else {
      throw Exception('Failed to load recently played games');
    }
  }

  Future<Map<String, dynamic>> fetchGameDetails(int appId) async {
    final response = await http.get(Uri.parse(
        'https://store.steampowered.com/api/appdetails?appids=$appId&l=tchinese'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final gameData = data['$appId']['data'];
      if (gameData == null) {
        return {
          'name': 'Unknown',
          'genre': 'Unknown',
          'description': 'No description available',
          'tags': [],
        };
      }
      return {
        'name': gameData['name'],
        'genre': gameData['genres'] != null && gameData['genres'].isNotEmpty
            ? gameData['genres'][0]['description']
            : 'Unknown',
        'description': gameData['short_description'],
        'tags': gameData['categories'] != null
            ? gameData['categories']
                .map<String>((category) => category['description'].toString())
                .toList()
            : <String>[], // 確保回傳的是 List<String>
      };
    } else {
      return {
        'name': 'Unknown',
        'genre': 'Unknown',
        'description': 'No description available',
        'tags': [],
      };
    }
  }

  Future<List<Map<String, String>>> fetchGameAchievements(int appId) async {
    final response = await http.get(Uri.parse(
        'http://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v1/?key=$apiKey&steamid=$steamId&appid=$appId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final achievements = data['playerstats']['achievements'] as List?;
      if (achievements == null || data['playerstats']['success'] == false) {
        return [];
      }

      final achievementDetailsResponse = await http.get(Uri.parse(
          'https://api.steampowered.com/ISteamUserStats/GetSchemaForGame/v2/?key=$apiKey&appid=$appId&l=tchinese'));
      if (achievementDetailsResponse.statusCode == 200) {
        final achievementDetailsData =
            json.decode(achievementDetailsResponse.body);
        final achievementDetails = achievementDetailsData['game']
            ['availableGameStats']['achievements'] as List?;
        if (achievementDetails != null) {
          return achievements
              .where((achievement) => achievement['achieved'] == 1)
              .map<Map<String, String>>((achievement) {
            final detail = achievementDetails.firstWhere(
                (detail) => detail['name'] == achievement['apiname'],
                orElse: () => null);
            return {
              'name': detail != null
                  ? detail['displayName']
                  : achievement['apiname'],
              'icon': detail != null ? detail['icon'] : '',
            };
          }).toList();
        }
      }

      return achievements
          .where((achievement) => achievement['achieved'] == 1)
          .map<Map<String, String>>((achievement) => {
                'name': achievement['apiname'],
                'icon':
                    'https://steamcdn-a.akamaihd.net/steamcommunity/public/images/apps/$appId/${achievement['icon']}.jpg',
              })
          .toList();
    } else {
      return [];
    }
  }

  Future<List<Map<String, String>>> fetchFriendsList() async {
    final response = await http.get(Uri.parse(
        'https://api.steampowered.com/ISteamUser/GetFriendList/v1/?key=$apiKey&steamid=$steamId&relationship=friend'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final friends = data['friendslist']['friends'] as List?;
      if (friends == null) {
        return [];
      }

      // 獲取朋友的詳細信息
      final friendIds = friends.map((friend) => friend['steamid']).join(',');
      final friendDetailsResponse = await http.get(Uri.parse(
          'http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=$apiKey&steamids=$friendIds'));

      if (friendDetailsResponse.statusCode == 200) {
        final friendDetailsData = json.decode(friendDetailsResponse.body);
        final friendDetails = friendDetailsData['response']['players'] as List?;

        if (friendDetails != null) {
          return await Future.wait(
              friendDetails.map<Future<Map<String, String>>>((friend) async {
            final recentGamesResponse = await http.get(Uri.parse(
                'http://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v1/?key=$apiKey&steamid=${friend['steamid']}'));

            String recentGame = 'No recent games';
            if (recentGamesResponse.statusCode == 200) {
              final recentGamesData = json.decode(recentGamesResponse.body);
              final recentGames = recentGamesData['response']['games'] as List?;
              if (recentGames != null && recentGames.isNotEmpty) {
                recentGame = recentGames[0]['name'] ?? 'Unknown';
              }
            }

            return {
              'steamid': friend['steamid'] ?? '',
              'name': friend['personaname'] ?? 'Unknown',
              'avatar': friend['avatarfull'] ?? '',
              'friend_since': friends
                  .firstWhere(
                      (f) => f['steamid'] == friend['steamid'])['friend_since']
                  .toString(),
              'recent_game': recentGame,
            };
          }).toList());
        }
      }

      return [];
    } else {
      throw Exception('Failed to load friends list');
    }
  }

  Future<Map<String, dynamic>> fetchPreferredGenres() async {
    final games = await fetchGames();
    final genreCount = <String, int>{};

    for (var game in games) {
      if (game.genre != 'Unknown') {
        genreCount[game.genre] = (genreCount[game.genre] ?? 0) + 1;
      }
    }

    // 取得最受歡迎的遊戲類型（可選擇按次數排序）
    final sortedGenres = genreCount.keys.toList()
      ..sort((a, b) => genreCount[b]!.compareTo(genreCount[a]!));

    return {'genres': sortedGenres};
  }

  Future<List<Map<String, String>>> fetchFriendsWhoPlayedGame(
      String appId) async {
    List<Map<String, String>> friendsWhoPlayed = [];
    List<Map<String, String>> friendsList = await fetchFriendsList(); // 取得好友清單

    for (var friend in friendsList) {
      String friendSteamId =
          friend['steamid']!; // 需要確保 fetchFriendsList 也回傳 steamid

      final response = await http.get(Uri.parse(
          'https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=$apiKey&steamid=$friendSteamId&include_played_free_games=true&format=json'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final games = data['response']['games'] as List<dynamic>?;

        if (games != null) {
          for (var game in games) {
            if (game['appid'].toString() == appId &&
                game['playtime_forever'] > 0) {
              friendsWhoPlayed.add({
                'name': friend['name']!,
                'avatar': friend['avatar']!,
                'playtime': game['playtime_forever'] / 60 < 1
                    ? '${game['playtime_forever']} 分鐘'
                    : '${(game['playtime_forever'] / 60).round()} 小時',
              });
              break; // 找到這個好友有玩該遊戲後就不用繼續查詢他的遊戲列表
            }
          }
        }
      }
    }
    return friendsWhoPlayed;
  }
}
