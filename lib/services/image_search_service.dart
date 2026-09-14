// lib/services/image_search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageSearchService {
  static const String baseUrl = 'https://zahradua-lab-inventory-ai.hf.space';
  static const String hfToken = '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';

  Future<List<Map<String, dynamic>>> searchByImage(XFile imageFile) async {
    final headers = {'Authorization': 'Bearer $hfToken'};

    // Step 1: Image upload karo
    final uploadUri = Uri.parse('$baseUrl/gradio_api/upload');
    final uploadRequest = http.MultipartRequest('POST', uploadUri);
    uploadRequest.headers.addAll(headers); // 👈 naya

    final bytes = await imageFile.readAsBytes();
    uploadRequest.files.add(
      http.MultipartFile.fromBytes('files', bytes, filename: imageFile.name),
    );

    final uploadResponse = await uploadRequest.send();
    final uploadBody = await uploadResponse.stream.bytesToString();

    if (uploadResponse.statusCode != 200) {
      throw Exception('Image upload failed: $uploadBody');
    }

    final decodedUpload = jsonDecode(uploadBody);
    if (decodedUpload is! List) {
      throw Exception('Upload failed: $decodedUpload');
    }
    final uploadedPath = decodedUpload.first as String;

    // Step 2: Search call trigger karo
    final callUri = Uri.parse('$baseUrl/gradio_api/call/search_component');
    final callResponse = await http.post(
      callUri,
      headers: {
        'Content-Type': 'application/json',
        ...headers, // 👈 naya
      },
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

    // Step 3: Result stream se padho
    final resultUri = Uri.parse(
      '$baseUrl/gradio_api/call/search_component/$eventId',
    );
    final client = http.Client();
    final request = http.Request('GET', resultUri);
    request.headers.addAll(headers); // 👈 naya
    final streamedResponse = await client.send(request);
    final responseBody = await streamedResponse.stream.bytesToString();
    client.close();

    String? currentEvent;
    String? completeData;
    String? errorData;

    for (var line in responseBody.split('\n')) {
      if (line.startsWith('event: ')) {
        currentEvent = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        final dataStr = line.substring(6);
        if (currentEvent == 'complete') {
          completeData = dataStr;
        } else if (currentEvent == 'error') {
          errorData = dataStr;
        }
      }
    }

    if (errorData != null) {
      throw Exception('Backend error: $errorData');
    }

    if (completeData == null) {
      throw Exception(
        'No result received from search API. Raw response: $responseBody',
      );
    }

    final resultData = jsonDecode(completeData) as List;
    final matchesJsonString = resultData.first as String;
    final matchesData = jsonDecode(matchesJsonString);

    return List<Map<String, dynamic>>.from(matchesData['matches']);
  }
}
