import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/camera_service.dart';
import 'image_review_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  List<String> _capturedImages = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _isInitializing = false;
      });
      return;
    }

    try {
      _controller = await CameraService.initializeCamera();
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _takePicture() async {
    final imagePath = await CameraService.takePicture();
    if (imagePath != null) {
      setState(() {
        _capturedImages.add(imagePath);
      });
      
      // Show preview
      _showImagePreview(imagePath);
    }
  }

  void _showImagePreview(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 3/4,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('Vorschau konnte nicht geladen werden'),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _capturedImages.removeLast();
                    });
                  },
                  child: const Text('Löschen'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Behalten'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final images = await CameraService.pickImagesFromGallery();
    setState(() {
      _capturedImages.addAll(images);
    });
  }

  void _proceedToAnalysis() {
    if (_capturedImages.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageReviewScreen(imagePaths: _capturedImages),
        ),
      );
    }
  }

  @override
  void dispose() {
    CameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Schnell Verkaufen'),
          backgroundColor: Colors.orange,
        ),
        body: const Center(
          child: Text(
            'Kamera konnte nicht initialisiert werden.\nBitte überprüfen Sie die Berechtigungen.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos aufnehmen'),
        backgroundColor: Colors.orange,
        actions: [
          if (_capturedImages.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_capturedImages.length}'),
                child: const Icon(Icons.photo_library),
              ),
              onPressed: _proceedToAnalysis,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_controller!),
          ),
          Container(
            color: Colors.black,
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 40),
                  onPressed: _pickFromGallery,
                ),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 40),
                  onPressed: _capturedImages.isNotEmpty ? _proceedToAnalysis : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
