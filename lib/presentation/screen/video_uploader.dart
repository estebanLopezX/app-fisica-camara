import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideoUploader {
  final String serverUrl;

  VideoUploader({required this.serverUrl});

  Future<Map<String, dynamic>?> sendVideo(File videoFile) async {
    try {
      final uri = Uri.parse("$serverUrl/analyze_video/");
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath('file', videoFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📩 Respuesta del servidor: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Error del servidor: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error enviando video: $e");
      return null;
    }
  }
}
