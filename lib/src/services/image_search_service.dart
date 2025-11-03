import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class ImageSearchService {
  static const _baseUrl = 'https://www.googleapis.com/customsearch/v1';
  static String? _apiKey;
  static String? _engineId;

  // Call this method once, perhaps in your main.dart, to load the keys.
  static Future<void> loadApiKeys() async {
    if (_apiKey != null && _engineId != null) return;

    try {
      // This is not a foolproof way to get the local.properties file,
      // but it will work for this specific use case.
      // A more robust solution would be to use a proper secrets management solution.
      final properties = await rootBundle.loadString('assets/secrets.properties');
      final lines = properties.split('\n');
      for (final line in lines) {
        if (line.startsWith('google.custom_search.api_key=')) {
          _apiKey = line.substring('google.custom_search.api_key='.length).trim();
        } else if (line.startsWith('google.custom_search.engine_id=')) {
          _engineId = line.substring('google.custom_search.engine_id='.length).trim();
        }
      }
    } catch (e) {
      print('Error loading secrets.properties: $e');
    }
  }

  Future<String?> searchImage(String query) async {
    if (_apiKey == null || _engineId == null) {
      print('API key or engine ID is not available. Have you called loadApiKeys()?');
      return null;
    }

    final url = Uri.parse(
      '$_baseUrl?key=$_apiKey&cx=$_engineId&q=$query&searchType=image&num=1',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data['items'][0]['link'];
        }
      } else {
        print('Image search failed with status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error searching for image: $e');
    }

    return null;
  }

  /// Search for multiple images at once
  /// Returns a map of query -> image URL (null if not found)
  Future<Map<String, String?>> searchImages(List<String> queries) async {
    final results = <String, String?>{};
    
    for (final query in queries) {
      // Add delay between requests to avoid rate limiting
      if (results.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      results[query] = await searchImage(query);
    }
    
    return results;
  }
}
