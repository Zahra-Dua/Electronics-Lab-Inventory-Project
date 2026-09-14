// lib/services/image_search_service.dart
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ImageSearchService {
  // ⚠️ Apna laptop IP yahan daalo
  static const String baseUrl = 'http://192.168.18.70:8000';

  Future<List<Map<String, dynamic>>> searchByImage(XFile imageFile) async {
    final uri = Uri.parse('$baseUrl/search');
    final request = http.MultipartRequest('POST', uri);

    final bytes = await imageFile.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: imageFile.name),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Search failed: $responseBody');
    }

    final data = jsonDecode(responseBody);
    final matches = List<Map<String, dynamic>>.from(data['matches']);
    return matches;
  }
}
