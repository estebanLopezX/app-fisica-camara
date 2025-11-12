import 'package:http/http.dart' as http;
import 'dart:io';

class VideoUploader {
  final String serverUrl;

  VideoUploader({required this.serverUrl});

  Future<void> sendVideo(File videoFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverUrl/analyze_video/'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', videoFile.path));

      print('📤 Enviando video al servidor: ${videoFile.path}');

      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        print('✅ Resultados del servidor: $respStr');
      } else {
        print('❌ Error al enviar video: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error al conectar con el servidor: $e');
    }
  }
}
