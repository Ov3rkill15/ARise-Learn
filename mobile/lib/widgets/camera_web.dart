import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Widget buildWebcamPreview({
  required BuildContext context,
  required Function(XFile) onCaptured,
  required Function(String) onError,
}) {
  return WebcamPreviewWidget(onCaptured: onCaptured, onError: onError);
}

class WebcamPreviewWidget extends StatefulWidget {
  final Function(XFile) onCaptured;
  final Function(String) onError;
  
  const WebcamPreviewWidget({
    super.key,
    required this.onCaptured,
    required this.onError,
  });

  @override
  State<WebcamPreviewWidget> createState() => _WebcamPreviewWidgetState();
}

class _WebcamPreviewWidgetState extends State<WebcamPreviewWidget> {
  html.VideoElement? _videoElement;
  html.MediaStream? _localStream;
  String _viewId = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'webcam-view-${DateTime.now().millisecondsSinceEpoch}';
    _initWebcam();
  }

  Future<void> _initWebcam() async {
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    // Register View Factory
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) => _videoElement!);

    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({'video': true});
      if (stream == null) {
        throw Exception("Kamera tidak dapat diakses.");
      }
      _localStream = stream;
      _videoElement!.srcObject = stream;
      
      // Explicitly trigger video element playback
      _videoElement!.play().catchError((err) {
        print("Webcam play error: $err");
      });

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      widget.onError("Izin kamera ditolak atau tidak ada kamera terhubung. Silakan aktifkan izin kamera di browser Anda atau gunakan tombol unggah berkas.");
    }
  }

  @override
  void dispose() {
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _videoElement?.srcObject = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
    }
    
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: HtmlElementView(
                key: ValueKey(_viewId),
                viewType: _viewId,
              ),
            ),
          ),
          
          // Target Reticle Box overlay
          IgnorePointer(
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Scan line effect
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.only(top: value * 198),
                          child: Container(
                            width: 200,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.8),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
  
          // Shutter Button Panel
          Positioned(
            bottom: 20,
            child: GestureDetector(
              onTap: _takePicture,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  html.Blob _dataURItoBlob(String dataURI) {
    // dataURI format: "data:image/jpeg;base64,..."
    final parts = dataURI.split(',');
    final mime = parts[0].split(':')[1].split(';')[0];
    final byteString = base64.decode(parts[1]);
    return html.Blob([byteString], mime);
  }

  void _takePicture() {
    if (_videoElement == null || _videoElement!.videoWidth == 0) return;
    
    final canvas = html.CanvasElement(
      width: _videoElement!.videoWidth,
      height: _videoElement!.videoHeight,
    );
    canvas.context2D.drawImage(_videoElement!, 0, 0);
    final dataUrl = canvas.toDataUrl('image/jpeg');
    
    try {
      final blob = _dataURItoBlob(dataUrl);
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      widget.onCaptured(XFile(blobUrl, name: 'webcam_capture.jpg'));
    } catch (e) {
      widget.onError("Gagal mengambil gambar: $e");
    }
  }
}
