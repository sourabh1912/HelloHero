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
  // Template styles for different prompts
  TemplateStyle _selectedStyle = TemplateStyle.rockyBhai;
  File? _selectedImage;
  String? _base64Result;
  bool _isLoading = false;

  String get _selectedStyleKey {
    switch (_selectedStyle) {
      case TemplateStyle.rockyBhai:
        return "rocky_bhai";
      case TemplateStyle.halogenSample:
        return "halogen_sample";
      case TemplateStyle.retroStyle:
        return "retro_style";
      case TemplateStyle.gymSample:
        return "gym_sample";
      case TemplateStyle.mafiaBoss:
        return "mafia_boss";
      case TemplateStyle.rainyWindow:
        return "rainy_window";
    }
  }

  // 1. Pick Image from Gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _base64Result = null; // Reset result when new image is picked
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image selected successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
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
          "style": _selectedStyleKey,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final imageData = body['image'];
        if (imageData != null && imageData is String && imageData.isNotEmpty) {
          setState(() {
            _base64Result = imageData;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No image in response')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to connect to backend")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildResultImage() {
    if (_base64Result == null || _base64Result!.isEmpty) {
      return const SizedBox.shrink();
    }
    try {
      final bytes = base64Decode(_base64Result!);
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      );
    } catch (_) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('Could not display image'),
      );
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
          // Scrollable area with templates (and optional save button)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Transformed result preview (shown when we have a result)
                  if (_base64Result != null && !_isLoading) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Your result',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildResultImage(),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _saveBhaiImage,
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
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose a style',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3 / 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _TemplateCard(
                          label: "Rocky Bhai",
                          assetPath: "resources/Real_rocky_bhai.jpg",
                          isSelected: _selectedStyle == TemplateStyle.rockyBhai,
                          onTap: () {
                            setState(() {
                              _selectedStyle = TemplateStyle.rockyBhai;
                            });
                          },
                        ),
                        _TemplateCard(
                          label: "Halogen Style",
                          assetPath: "resources/Halogen_sample.jpg",
                          isSelected: _selectedStyle == TemplateStyle.halogenSample,
                          onTap: () {
                            setState(() {
                              _selectedStyle = TemplateStyle.halogenSample;
                            });
                          },
                        ),
                        _TemplateCard(
                          label: "Retro",
                          assetPath: "resources/Retro_style_sample.jpg",
                          isSelected: _selectedStyle == TemplateStyle.retroStyle,
                          onTap: () {
                            setState(() {
                              _selectedStyle = TemplateStyle.retroStyle;
                            });
                          },
                        ),
                        _TemplateCard(
                          label: "Gym Beast",
                          assetPath: "resources/gym_sample.jpg",
                          isSelected: _selectedStyle == TemplateStyle.gymSample,
                          onTap: () {
                            setState(() {
                              _selectedStyle = TemplateStyle.gymSample;
                            });
                          },
                        ),
                        _TemplateCard(
                          label: "Mafia Boss",
                          assetPath: "resources/Mafia_boss_sample.jpg",
                          isSelected: _selectedStyle == TemplateStyle.mafiaBoss,
                          onTap: () {
                            setState(() {
                              _selectedStyle = TemplateStyle.mafiaBoss;
                            });
                          },
                        ),
                        _TemplateCard(
                          label: "Rainy Window",
                          assetPath: "resources/Rainy_window_sample.jpg",
                          isSelected: _selectedStyle == TemplateStyle.rainyWindow,
                          onTap: () {
                            setState(() {
                              _selectedStyle = TemplateStyle.rainyWindow;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fixed bottom control buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
          ),
        ],
      ),
    );
  }
}

enum TemplateStyle {
  rockyBhai,
  halogenSample,
  retroStyle,
  gymSample,
  mafiaBoss,
  rainyWindow,
}

class _TemplateCard extends StatelessWidget {
  final String label;
  final String assetPath;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.label,
    required this.assetPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? const Color(0xFFFFC400) : Colors.white24;
    final overlayColor = isSelected ? Colors.amber.withOpacity(0.15) : Colors.white10;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          color: overlayColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}