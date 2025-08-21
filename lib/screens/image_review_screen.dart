import 'dart:io';
import 'package:flutter/material.dart';
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
  
  void _removeImage(int index) {
    setState(() {
      widget.imagePaths.removeAt(index);
    });
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
      final productData = await AIService.analyzeImages(widget.imagePaths);
      
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
      body: Column(
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
          else
            Expanded(
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
                    ],
                  );
                },
              ),
            ),
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
    );
  }
}
