import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Yahan apni ImgBB se mili hui API Key daalein
  static const String apiKey = "e14d98ae5e9873d619be4e5f3f269340";

  static Future<String?> uploadImage(File imageFile) async {
    try {
      // ImgBB API endpoint
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
      );

      // Image file ko request mein add karna
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      // Request bhejna
      var response = await request.send();

      // Agar upload successful raha (Status 200)
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);

        // Image ka direct URL return karna
        return jsonResponse['data']['url'];
      } else {
        print("Upload failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
    return null;
  }
}
