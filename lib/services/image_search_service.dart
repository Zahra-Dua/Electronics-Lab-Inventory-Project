// lib/services/image_search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageSearchService {
  static const String baseUrl = 'https://zahradua-lab-inventory-ai.hf.space';

  Future<List<Map<String, dynamic>>> searchByImage(XFile imageFile) async {
    // Step 1: Image upload karo Gradio ke upload endpoint pe
    final uploadUri = Uri.parse('$baseUrl/gradio_api/upload');
    final uploadRequest = http.MultipartRequest('POST', uploadUri);

    final bytes = await imageFile.readAsBytes();
    uploadRequest.files.add(
      http.MultipartFile.fromBytes('files', bytes, filename: imageFile.name),
    );

    final uploadResponse = await uploadRequest.send();
    final uploadBody = await uploadResponse.stream.bytesToString();

    if (uploadResponse.statusCode != 200) {
      throw Exception('Image upload failed: $uploadBody');
    }

    final uploadedPaths = jsonDecode(uploadBody) as List;
    final uploadedPath = uploadedPaths.first as String;

    // Step 2: Search call trigger karo
    final callUri = Uri.parse('$baseUrl/gradio_api/call/search_component');
    final callResponse = await http.post(
      callUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'data': [
          {
            'path': uploadedPath,
            'meta': {'_type': 'gradio.FileData'},
          },
        ],
      }),
    );

    if (callResponse.statusCode != 200) {
      throw Exception('Search call failed: ${callResponse.body}');
    }

    final eventId = jsonDecode(callResponse.body)['event_id'] as String;

    // Step 3: Result stream se padho (Server-Sent Events)
    final resultUri = Uri.parse(
      '$baseUrl/gradio_api/call/search_component/$eventId',
    );
    final client = http.Client();
    final request = http.Request('GET', resultUri);
    final streamedResponse = await client.send(request);

    final responseBody = await streamedResponse.stream.bytesToString();
    client.close();

    // SSE format: lines starting with "data: "
    String? resultLine;
    for (var line in responseBody.split('\n')) {
      if (line.startsWith('data: ')) {
        resultLine = line.substring(6);
      }
    }

    if (resultLine == null) {
      throw Exception('No result received from search API');
    }

    final resultData = jsonDecode(resultLine) as List;
    final matchesJsonString = resultData.first as String;
    final matchesData = jsonDecode(matchesJsonString);

    return List<Map<String, dynamic>>.from(matchesData['matches']);
  }
}
