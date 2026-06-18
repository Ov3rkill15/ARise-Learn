import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_stub.dart' if (dart.library.html) 'camera_web.dart';

class LiveCameraDialog extends StatefulWidget {
  const LiveCameraDialog({super.key});

  @override
  State<LiveCameraDialog> createState() => _LiveCameraDialogState();
}

class _LiveCameraDialogState extends State<LiveCameraDialog> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  String? _error;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      setState(() {
        _isInitializing = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception("Kamera tidak ditemukan di perangkat Anda.");
      }

      _controller = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;
      
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      String friendlyMsg = e.toString().replaceAll("Exception: ", "");
      if (friendlyMsg.contains("Null") || friendlyMsg.contains("JSArray") || friendlyMsg.contains("mediaDevices")) {
        friendlyMsg = "Kamera tidak terdeteksi atau izin kamera diblokir oleh browser. Silakan aktifkan izin kamera di bilah alamat browser Anda atau gunakan tombol unggah berkas di bawah ini.";
      }
      setState(() {
        _error = friendlyMsg;
        _isInitializing = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile photo = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pop(context, photo);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    _controller?.dispose();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.videocam, color: Colors.blueAccent, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Live Camera Scanner',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Viewfinder Panel
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isInitializing)
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blueAccent),
                          SizedBox(height: 12),
                          Text(
                            'Menghubungkan kamera...',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Akses Kamera Gagal',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else if (kIsWeb)
                      buildWebcamPreview(
                        context: context,
                        onCaptured: (photo) => Navigator.pop(context, photo),
                        onError: (err) {
                          if (mounted) {
                            setState(() {
                              _error = err;
                              _isInitializing = false;
                            });
                          }
                        },
                      )
                    else if (_controller != null && _controller!.value.isInitialized)
                      // Camera Stream
                      Center(
                        child: CameraPreview(_controller!),
                      ),

                    // Target Reticle Box overlay (HUD)
                    if (!kIsWeb && !_isInitializing && _error == null)
                      IgnorePointer(
                        child: Stack(
                          children: [
                            // Outer dim overlay
                            Container(
                              color: Colors.black.withOpacity(0.3),
                            ),
                            // Scanning Frame
                            Center(
                              child: Container(
                                width: 250,
                                height: 250,
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
                                final topOffset = 150 + value * 230; // boundaries of 250 height box
                                return Positioned(
                                  top: topOffset,
                                  left: MediaQuery.of(context).size.width / 2 - 125,
                                  width: 250,
                                  height: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blueAccent.withOpacity(0.8),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Shutter Button Panel
            if (!kIsWeb && !_isInitializing && _error == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Spacer
                  const SizedBox(width: 48),
                  
                  // Main Capture Button
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Switch Camera (Front/Rear)
                  if (_cameras != null && _cameras!.length >= 2)
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios, color: Colors.white70, size: 28),
                      onPressed: _switchCamera,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              )
            else if (_error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      try {
                        final picker = ImagePicker();
                        final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
                        if (photo != null && mounted) {
                          Navigator.pop(context, photo);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal memilih berkas: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pilih Berkas dari Galeri/OS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    onPressed: () => Navigator.pop(context, null),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kembali ke Dashboard'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
