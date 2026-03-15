import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

void main() => runApp(
      MaterialApp(
        home: RockyTransformApp(),
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF050814),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            elevation: 4,
            centerTitle: true,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFC400), // Vibrant gold
            secondary: Color(0xFF00E5FF), // Neon cyan
            surface: Color(0xFF101624),
            onPrimary: Colors.black,
            onSecondary: Colors.black,
          ),
        ),
      ),
    );

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

  Future<void> _saveBhaiImage() async {
    if (_base64Result == null) return;

    try {
      // 1. Decode your existing base64 variable
      Uint8List bytes = base64Decode(_base64Result!);

      // 2. Create a temporary file path
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/rocky_bhai_${DateTime.now().millisecondsSinceEpoch}.png');
      
      // 3. Write bytes to the file
      await file.writeAsBytes(bytes);

      // 4. Save to actual Gallery
      await Gal.putImage(file.path);

      // 5. Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Gallery, Bhai!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
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
          if (_base64Result != null && !_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                onPressed: _saveBhaiImage, // Your save function
                icon: const Icon(Icons.download),
                label: const Text("SAVE TO GALLERY"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC400),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
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
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 6,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _transformToRocky,
                  child: const Text(
                    "ENTER KGF (Rocky Style)",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3D00),
                      disabledBackgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
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