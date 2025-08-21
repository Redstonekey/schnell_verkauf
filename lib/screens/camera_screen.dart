import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
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
    _configureOrientations();
    _initializeCamera();
  }

  void _configureOrientations() {
    // Allow key orientations (portrait + both landscapes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
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
  // Restore all orientations when leaving this screen
  SystemChrome.setPreferredOrientations(DeviceOrientation.values);
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Material(
            elevation: 4,
            color: Colors.black45,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ),
        actions: [
          if (_capturedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Material(
                elevation: 4,
                color: Colors.black45,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _proceedToAnalysis,
                  child: Badge(
                    label: Text('${_capturedImages.length}'),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.photo_library, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildFullScreenPreview(orientation),
              _buildSideControls(orientation),
              if (_capturedImages.isNotEmpty) _buildThumbnailsOverlay(orientation),
            ],
          );
        },
      ),
    );
  }
  Widget _buildFullScreenPreview(Orientation orientation) {
    final controller = _controller!;
    // Use OverflowBox + FittedBox to cover without distorting aspect ratio.
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewAspect = controller.value.aspectRatio; // width / height
        final screenAspect = constraints.maxWidth / constraints.maxHeight;

        // For portrait orientation the preview is rotated by the system; we still rely on aspect as given.
        double scale;
        if (screenAspect > previewAspect) {
          // Screen wider than preview -> scale by width ratio
          scale = screenAspect / previewAspect;
        } else {
          // Screen narrower -> scale by height ratio (invert aspects)
          scale = previewAspect / screenAspect;
        }

        return Center(
          child: Transform.scale(
            scale: scale,
            child: AspectRatio(
              aspectRatio: previewAspect,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback? onTap, Color bg = Colors.white, Color fg = Colors.black, double size = 72, double iconSize = 36, String? tooltip}) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg.withOpacity(onTap == null ? 0.4 : 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: fg.withOpacity(onTap == null ? 0.5 : 1.0)),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }

  Widget _buildSideControls(Orientation orientation) {
    final bool portrait = orientation == Orientation.portrait;
    final spacing = portrait ? 22.0 : 28.0;
    if (!portrait) {
      return Positioned(
        right: 16,
        top: 24,
        bottom: 24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleButton(
              icon: Icons.photo_library,
              onTap: _pickFromGallery,
              bg: Colors.white70,
              fg: Colors.black87,
              size: 56,
              iconSize: 28,
              tooltip: 'Galerie',
            ),
            SizedBox(height: spacing),
            _circleButton(
              icon: Icons.camera_alt,
              onTap: _takePicture,
              size: 78,
              iconSize: 38,
              tooltip: 'Foto',
            ),
            SizedBox(height: spacing),
            _circleButton(
              icon: Icons.arrow_forward,
              onTap: _capturedImages.isNotEmpty ? _proceedToAnalysis : null,
              bg: Colors.white70,
              fg: Colors.black,
              size: 56,
              iconSize: 28,
              tooltip: 'Weiter',
            ),
          ],
        ),
      );
    }

    // Portrait: place buttons centered at bottom over preview (floating)
    return Positioned(
      bottom: 28,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleButton(
            icon: Icons.photo_library,
            onTap: _pickFromGallery,
            bg: Colors.black54,
            fg: Colors.white,
            size: 60,
            iconSize: 28,
            tooltip: 'Galerie',
          ),
          SizedBox(width: spacing),
          _circleButton(
            icon: Icons.camera_alt,
            onTap: _takePicture,
            size: 84,
            iconSize: 40,
            tooltip: 'Foto',
          ),
          SizedBox(width: spacing),
          _circleButton(
            icon: Icons.arrow_forward,
            onTap: _capturedImages.isNotEmpty ? _proceedToAnalysis : null,
            bg: Colors.black54,
            fg: Colors.white,
            size: 60,
            iconSize: 28,
            tooltip: 'Weiter',
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailsOverlay(Orientation orientation) {
    final bool portrait = orientation == Orientation.portrait;
    if (portrait) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 120, // keep clear of bottom buttons
        child: SizedBox(
          height: 80,
          child: _horizontalThumbs(),
        ),
      );
    }
    // Landscape: keep vertical list on left
    return Positioned(
      left: 12,
      top: 16,
      bottom: 16,
      child: SizedBox(
        width: 120,
        child: _verticalThumbs(),
      ),
    );
  }

  Widget _horizontalThumbs() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _capturedImages.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) => _thumb(index),
    );
  }

  Widget _verticalThumbs() {
    return ListView.separated(
      scrollDirection: Axis.vertical,
      itemCount: _capturedImages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _thumb(index, vertical: true),
    );
  }

  Widget _thumb(int index, {bool vertical = false}) {
    return GestureDetector(
      onTap: () => _showImagePreview(_capturedImages[index]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white54, width: 1),
          ),
          child: Image.file(
            File(_capturedImages[index]),
            width: vertical ? 100 : 70,
            height: vertical ? 70 : 100,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
