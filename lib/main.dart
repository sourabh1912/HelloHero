import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() => runApp(MaterialApp(home: RockyTransformApp(), theme: ThemeData.dark()));

class RockyTransformApp extends StatefulWidget {
  @override
  _RockyTransformAppState createState() => _RockyTransformAppState();
}

class _RockyTransformAppState extends State<RockyTransformApp> {
  File? _selectedImage;
  String? _base64Result;
  bool _isLoading = false;

  // 1. Pick Image from Gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _base64Result = null; // Reset result when new image is picked
      });
    }
  }

  // 2. Call your Backend API
  Future<void> _transformToRocky() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64String = base64Encode(bytes);

      // Replace with your actual backend URL (Firebase or FastAPI)
      final response = await http.post(
        Uri.parse('https://unfibered-lacy-nonobservantly.ngrok-free.dev/transform'),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true"
        },
        body: jsonEncode({
          "base64Image": base64String,
          "style": "rocky_bhai"
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _base64Result = jsonDecode(response.body)['image'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to connect to backend")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bhai-AI Transform"), centerTitle: true),
      body: Column(
        children: [
          // Image Preview Area
          Expanded(
            child: Container(
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border.all(color: Colors.amber, width: 2), borderRadius: BorderRadius.circular(15)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: _isLoading
                    ? Center(child: SpinKitDoubleBounce(color: Colors.amber, size: 50.0))
                    : _base64Result != null
                    ? Image.memory(base64Decode(_base64Result!), fit: BoxFit.cover)
                    : _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : Center(child: Text("Pick an images to start")),
              ),
            ),
          ),

          // Control Buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo_library),
                  label: Text("Gallery"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _transformToRocky,
                  child: Text("ENTER KGF (Rocky Style)", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}