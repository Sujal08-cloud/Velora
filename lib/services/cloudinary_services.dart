import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
 
  static const _cloudName = 'deqod2qje';   
  static const _uploadPreset = 'Shopping App';   

  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,  
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  
  Future<String> uploadImage(File imageFile, String fileName) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['public_id'] = fileName  
      ..files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

    final response = await request.send();
    final body = jsonDecode(await response.stream.bytesToString());

    if (response.statusCode == 200) {
      return body['secure_url'] as String;  
    }

    throw Exception('Upload failed: ${body['error']['message']}');
  }
}