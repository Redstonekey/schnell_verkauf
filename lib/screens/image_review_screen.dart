import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../services/ai_service.dart';
import 'edit_product_screen.dart';

class ImageReviewScreen extends StatefulWidget {
  final List<String> imagePaths;
  
  const ImageReviewScreen({
    super.key,
    required this.imagePaths,
  });

  @override
  State<ImageReviewScreen> createState() => _ImageReviewScreenState();
}

class _ImageReviewScreenState extends State<ImageReviewScreen> {
  bool _isAnalyzing = false;
  bool _isTextFieldFocused = false;
  final TextEditingController _additionalInfoController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  
  // Preset phrases for common product conditions
  final List<String> _presets = [
    'Neuwertig',
    'Sehr guter Zustand',
    'Guter Zustand',
    'Gebraucht',
    'Defekt',
    'Für Bastler',
    'Gebrauchsspuren',
    'Originalverpackung',
    'Ohne Zubehör',
    'Vintage',
    'Sammlerstück',
    'Funktionsfähig',
  ];
  
  @override
  void initState() {
    super.initState();
    _textFieldFocusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _textFieldFocusNode.hasFocus;
      });
    });
  }
  
  void _removeImage(int index) {
    setState(() {
      widget.imagePaths.removeAt(index);
    });
  }
  
  void _addPresetText(String preset) {
    final currentText = _additionalInfoController.text;
    if (currentText.isEmpty) {
      _additionalInfoController.text = preset;
    } else {
      _additionalInfoController.text = '$currentText, $preset';
    }
  }
  
  Future<void> _cropImage(int index) async {
    final imagePath = widget.imagePaths[index];
    
    try {
      // Read the image file
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      
      if (!mounted) return;
      
      // Show crop screen
      final result = await Navigator.push<Uint8List?>(
        context,
        MaterialPageRoute(
          builder: (context) => _CropScreen(
            imageBytes: imageBytes,
            imageName: path.basename(imagePath),
          ),
        ),
      );
      
      if (result != null && mounted) {
        // Save the cropped image
        final directory = await getTemporaryDirectory();
        final fileName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final newPath = path.join(directory.path, fileName);
        final newFile = File(newPath);
        await newFile.writeAsBytes(result);
        
        // Update the image path
        setState(() {
          widget.imagePaths[index] = newPath;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bild erfolgreich zugeschnitten'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Zuschneiden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _additionalInfoController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _analyzeWithAI() async {
    if (widget.imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens ein Foto hinzufügen')),
      );
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final additionalInfo = _additionalInfoController.text.trim();
      final productData = await AIService.analyzeImages(widget.imagePaths, additionalInfo: additionalInfo);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EditProductScreen(productData: productData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Fehler bei der Analyse: $e';
        
        // Check if it's an API key error
        if (e.toString().contains('API-Schlüssel')) {
          errorMessage = 'API-Schlüssel nicht konfiguriert. Bitte gehen Sie zu den Einstellungen.';
          
          // Show settings dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('API-Schlüssel erforderlich'),
              content: const Text(
                'Um die KI-Analyse zu nutzen, müssen Sie einen Gemini API-Schlüssel in den Einstellungen konfigurieren.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos überprüfen'),
        backgroundColor: Colors.orange,
      ),
      body: Stack(
        children: [
          Column(
        children: [
          if (widget.imagePaths.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Keine Fotos ausgewählt.\nGehen Sie zurück, um Fotos aufzunehmen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            )
          else ...[
            // Images section - less space when text field is focused
            Expanded(
              flex: _isTextFieldFocused ? 1 : 3,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.imagePaths.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(widget.imagePaths[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Close button (top right)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () => _removeImage(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ),
                      ),
                      // Edit/Crop button (top left)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () => _cropImage(index),
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.crop, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Bearbeiten',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // Additional information section - more space when text field is focused
            Expanded(
              flex: _isTextFieldFocused ? 3 : 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zusätzliche Informationen für die KI:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Text input field - expands when focused
                    TextField(
                      controller: _additionalInfoController,
                      focusNode: _textFieldFocusNode,
                      maxLines: _isTextFieldFocused ? 4 : 2,
                      decoration: const InputDecoration(
                        hintText: 'Beschreiben Sie den Zustand oder besondere Eigenschaften...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Preset buttons - less space when text field is focused
                    if (!_isTextFieldFocused) ...[
                      const Text(
                        'Schnellauswahl:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _presets.map((preset) {
                              return ActionChip(
                                label: Text(preset),
                                onPressed: () => _addPresetText(preset),
                                backgroundColor: Colors.orange[100],
                                labelStyle: const TextStyle(fontSize: 12),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Show compact preset buttons when focused
                      const Text(
                        'Schnellauswahl:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _presets.map((preset) {
                              return ActionChip(
                                label: Text(preset),
                                onPressed: () => _addPresetText(preset),
                                backgroundColor: Colors.orange[100],
                                labelStyle: const TextStyle(fontSize: 11),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeWithAI,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isAnalyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('KI analysiert...'),
                      ],
                    )
                  : const Text('Mit KI analysieren'),
            ),
          ),
        ],
      ),
      ],
    ));
  }
}

class _CropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String imageName;

  const _CropScreen({
    required this.imageBytes,
    required this.imageName,
  });

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final _cropController = CropController();
  late Uint8List _currentImageBytes;
  int _rotationCount = 0; // Track 90-degree rotations
  bool _isRotating = false;

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.imageBytes;
  }

  Future<void> _rotateImage(int quarterTurns) async {
    setState(() {
      _isRotating = true;
    });
    
    try {
      // Decode the image
      final image = img.decodeImage(_currentImageBytes);
      if (image == null) return;

      // Rotate the image
      final rotatedImage = img.copyRotate(image, angle: quarterTurns * 90);
      
      // Encode back to bytes
      final rotatedBytes = Uint8List.fromList(img.encodeJpg(rotatedImage));
      
      setState(() {
        _currentImageBytes = rotatedBytes;
        _rotationCount = (_rotationCount + quarterTurns) % 4;
      });
    } catch (e) {
      print('Error rotating image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Drehen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRotating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.imageName} bearbeiten'),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isRotating 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.rotate_left),
            onPressed: _isRotating ? null : () => _rotateImage(-1),
            tooltip: 'Links drehen',
          ),
          IconButton(
            icon: _isRotating 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.rotate_right),
            onPressed: _isRotating ? null : () => _rotateImage(1),
            tooltip: 'Rechts drehen',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isRotating ? null : () {
              _cropController.crop();
            },
            tooltip: 'Zuschneiden',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: _currentImageBytes,
              controller: _cropController,
              onCropped: (cropResult) {
                // Extract the actual image bytes from CropResult
                Uint8List? croppedBytes;
                
                if (cropResult is CropSuccess) {
                  croppedBytes = cropResult.croppedImage;
                } else if (cropResult is CropFailure) {
                  // Handle crop failure
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Zuschneiden fehlgeschlagen'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  });
                  return;
                }
                
                // Navigate back with the result
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.of(context).pop(croppedBytes);
                  }
                });
              },
              aspectRatio: null, // Allow free cropping
              withCircleUi: false,
              baseColor: Colors.black,
              maskColor: Colors.black.withOpacity(0.3),
              radius: 0,
              cornerDotBuilder: (size, edgeAlignment) => const DotControl(color: Colors.orange),
              interactive: true,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AspectRatioButton(
                  label: 'Frei',
                  aspectRatio: null,
                  controller: _cropController,
                ),
                _AspectRatioButton(
                  label: '1:1',
                  aspectRatio: 1.0,
                  controller: _cropController,
                ),
                _AspectRatioButton(
                  label: '3:2',
                  aspectRatio: 3.0 / 2.0,
                  controller: _cropController,
                ),
                _AspectRatioButton(
                  label: '4:3',
                  aspectRatio: 4.0 / 3.0,
                  controller: _cropController,
                ),
                _AspectRatioButton(
                  label: '16:9',
                  aspectRatio: 16.0 / 9.0,
                  controller: _cropController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AspectRatioButton extends StatelessWidget {
  final String label;
  final double? aspectRatio;
  final CropController controller;

  const _AspectRatioButton({
    required this.label,
    required this.aspectRatio,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        controller.aspectRatio = aspectRatio;
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[100],
        foregroundColor: Colors.orange[800],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
