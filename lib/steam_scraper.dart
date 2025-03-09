import 'package:http/http.dart' as http;
import 'dart:convert';

class SteamScraper {
  // 解析遊戲圖片
  List<String> _extractImages(dynamic screenshotData) {
    if (screenshotData is List) {
      return screenshotData
          .whereType<Map<String, dynamic>>()
          .map((screenshot) => screenshot['path_full']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return [];
  }

  // 獲取 Steam 遊戲數據
  Future<Map<String, dynamic>> fetchGameDetails(int appId) async {
    final url =
        'https://store.steampowered.com/api/appdetails?appids=$appId&l=tchinese';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('無法獲取遊戲頁面');
    }

    final data = json.decode(response.body);
    final gameData = data['$appId']?['data'];

    if (gameData == null) {
      throw Exception('無法解析遊戲數據');
    }

    // 解析遊戲圖片
    List<String> images = _extractImages(gameData['screenshots']);

    return {
      'images': images,
    };
  }
}
