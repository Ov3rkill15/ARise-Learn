import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:camera/camera.dart';
import '../widgets/camera_stub.dart'
    if (dart.library.html) '../widgets/camera_web.dart';

class ARViewerScreen extends StatefulWidget {
  const ARViewerScreen({super.key});

  @override
  State<ARViewerScreen> createState() => _ARViewerScreenState();
}

class _ARViewerScreenState extends State<ARViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _rx = -0.5; // X rotation
  double _ry = 0.5; // Y rotation
  double _scale = 1.0;
  double _baseScale = 1.0;
  bool _autoRotate = true;
  bool _showGrid = true;
  double _pulse = 1.0; // Heart beat pulse

  // Camera variables
  bool _enableCamera = false; // Default: Virtual Mode (no camera open)
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _cameraInitialized = false;
  String? _cameraError;
  String? _selectedPart;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    if (_enableCamera) {
      _initCamera();
    } else {
      _cameraInitialized = true;
    }

    // Pulse animation for heart or general breathing effect
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Simulate heartbeat double pulse: lub-dub
      setState(() {
        _pulse = 1.15;
      });
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        setState(() {
          _pulse = 0.95;
        });
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _pulse = 1.08;
        });
      });
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        setState(() {
          _pulse = 1.0;
        });
      });
    });
  }

  Future<void> _toggleCamera() async {
    if (_enableCamera) {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
      setState(() {
        _enableCamera = false;
        _cameraError = null;
        _cameraInitialized = true;
      });
    } else {
      setState(() {
        _enableCamera = true;
        _cameraInitialized = false;
        _cameraError = null;
      });
      await _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (!_enableCamera) {
      setState(() {
        _cameraInitialized = true;
      });
      return;
    }
    if (kIsWeb) {
      setState(() {
        _cameraInitialized = true;
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _cameraInitialized = true;
          });
        }
      } else {
        throw Exception("Kamera tidak ditemukan di perangkat.");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = e.toString().replaceAll("Exception: ", "");
          _cameraInitialized = true; // stop loading
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Project a 3D point (x, y, z) into 2D canvas coordinates
  Offset projectPoint(double x, double y, double z, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2 - 20);

    // Total rotation angle around Y
    final theta =
        _ry + (_autoRotate ? _animationController.value * 2 * math.pi : 0.0);
    // Rotation around Y
    final x1 = x * math.cos(theta) - z * math.sin(theta);
    final z1 = x * math.sin(theta) + z * math.cos(theta);

    // Rotation around X
    final phi = _rx;
    final y2 = y * math.cos(phi) - z1 * math.sin(phi);
    final z2 = y * math.sin(phi) + z1 * math.cos(phi);

    // Perspective factor
    const cameraDist = 400.0;
    final factor = cameraDist / (cameraDist + z2);
    final scaleVal = _scale * 2.1;

    return Offset(
      center.dx + x1 * scaleVal * factor,
      center.dy + y2 * scaleVal * factor,
    );
  }

  Offset? _getSelectedPartOffset(String part, String assetId, Size canvasSize) {
    if (assetId == 'atom' || assetId == 'general') {
      if (part == 'nucleus') return projectPoint(0, 0, 0, canvasSize);
      if (part == 'electron') {
        final baseAngle =
            _autoRotate ? _animationController.value * 2 * math.pi : 0.0;
        final electronAngle = baseAngle * 2.0;
        const radiusX = 85.0;
        const radiusZ = 40.0;
        final e1x = radiusX * math.cos(electronAngle);
        final e1z = radiusZ * math.sin(electronAngle);
        return projectPoint(e1x, 0, e1z, canvasSize);
      }
      if (part == 'orbit') {
        const radiusX = 85.0;
        return projectPoint(radiusX, 0, 0, canvasSize);
      }
    } else if (assetId == 'heart') {
      if (part == 'aorta') return projectPoint(-20, -70, 0, canvasSize);
      if (part == 'myocardium') return projectPoint(0, 70, 0, canvasSize);
      if (part == 'valve') return projectPoint(0, 0, 0, canvasSize);
    } else if (assetId == 'dna_helix') {
      if (part == 'backbone') return projectPoint(45.0, -40, 0, canvasSize);
      if (part == 'basepair') return projectPoint(0, 20, 0, canvasSize);
    } else if (assetId == 'water_molecule') {
      const bondLen = 65.0;
      const bondAngle = 104.5 * math.pi / 180.0;
      if (part == 'oxygen') return projectPoint(0, -20, 0, canvasSize);
      if (part == 'hydrogen') {
        final h1x = bondLen * math.cos(bondAngle / 2);
        final h1y = bondLen * math.sin(bondAngle / 2);
        return projectPoint(h1x, h1y - 20, 0, canvasSize);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final assetId =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? 'atom';

    return Scaffold(
      backgroundColor: Colors.black, // Dark space for AR immersion
      body: Stack(
        children: [
          // 1. Live Camera Background Feed (Webcam on Web, CameraPreview on Mobile)
          Positioned.fill(
            child: _buildCameraOverlay(),
          ),

          // 2. Interactive 3D Render Area and Hotspots
          Positioned.fill(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  setState(() {
                    _scale = (_scale - pointerSignal.scrollDelta.dy * 0.0015)
                        .clamp(0.4, 2.5);
                  });
                }
              },
              child: GestureDetector(
                onScaleStart: (details) {
                  _baseScale = _scale;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    if (details.scale != 1.0) {
                      _scale = (_baseScale * details.scale).clamp(0.4, 2.5);
                    }
                    if (details.pointerCount == 1 && details.scale == 1.0) {
                      _ry += details.focalPointDelta.dx * 0.007;
                      _rx -= details.focalPointDelta.dy * 0.007;
                    }
                  });
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize =
                        Size(constraints.maxWidth, constraints.maxHeight);

                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final baseAngle = _autoRotate
                            ? _animationController.value * 2 * math.pi
                            : 0.0;
                        final electronAngle = baseAngle * 2.0;

                        // Calculate projected positions in real time based on active assetId
                        final List<Widget> hotspots = [];

                        if (assetId == 'atom' || assetId == 'general') {
                          const radiusX = 85.0;
                          const radiusZ = 40.0;
                          final nucleusOffset =
                              projectPoint(0, 0, 0, canvasSize);
                          final orbitOffset =
                              projectPoint(radiusX, 0, 0, canvasSize);
                          final e1x = radiusX * math.cos(electronAngle);
                          final e1z = radiusZ * math.sin(electronAngle);
                          final electronOffset =
                              projectPoint(e1x, 0, e1z, canvasSize);

                          hotspots.addAll([
                            Positioned(
                              left: nucleusOffset.dx - 12,
                              top: nucleusOffset.dy - 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPart = 'nucleus'),
                                child:
                                    _buildPulsingPin(color: Colors.redAccent),
                              ),
                            ),
                            Positioned(
                              left: electronOffset.dx - 12,
                              top: electronOffset.dy - 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPart = 'electron'),
                                child: _buildPulsingPin(
                                    color: Colors.yellowAccent),
                              ),
                            ),
                            Positioned(
                              left: orbitOffset.dx - 12,
                              top: orbitOffset.dy - 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPart = 'orbit'),
                                child: _buildPulsingPin(color: Colors.white70),
                              ),
                            ),
                          ]);
                        } else if (assetId == 'heart') {
                          final aortaOffset =
                              projectPoint(-20, -70, 0, canvasSize);
                          final muscleOffset =
                              projectPoint(0, 70, 0, canvasSize);
                          final valveOffset = projectPoint(0, 0, 0, canvasSize);

                          hotspots.addAll([
                            Positioned(
                              left: aortaOffset.dx - 12,
                              top: aortaOffset.dy - 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPart = 'aorta'),
                                child:
                                    _buildPulsingPin(color: Colors.redAccent),
                              ),
                            ),
                            Positioned(
                              left: muscleOffset.dx - 12,
                              top: muscleOffset.dy - 12,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedPart = 'myocardium'),
                                child:
                                    _buildPulsingPin(color: Colors.pinkAccent),
                              ),
                            ),
                            Positioned(
                              left: valveOffset.dx - 12,
                              top: valveOffset.dy - 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPart = 'valve'),
                                child: _buildPulsingPin(color: Colors.white70),
                              ),
                            ),
                          ]);
                        } else if (assetId == 'dna_helix') {
                          final backboneOffset =
                              projectPoint(45.0, -40, 0, canvasSize);
                          final basepairOffset =
                              projectPoint(0, 20, 0, canvasSize);

                          hotspots.addAll([
                            Positioned(
                              left: backboneOffset.dx - 12,
                              top: backboneOffset.dy - 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPart = 'backbone'),
                                child:
                                    _buildPulsingPin(color: Colors.blueAccent),
                              ),
                            ),
                            Positioned(
                              left: basepairOffset.dx - 12,
                              top: basepairOffset.dy - 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPart = 'basepair'),
                                child: _buildPulsingPin(
                                    color: Colors.orangeAccent),
                              ),
                            ),
                          ]);
                        } else if (assetId == 'water_molecule') {
                          const bondLen = 65.0;
                          const bondAngle = 104.5 * math.pi / 180.0;
                          final h1x = bondLen * math.cos(bondAngle / 2);
                          final h1y = bondLen * math.sin(bondAngle / 2);
                          final h2x = -bondLen * math.cos(bondAngle / 2);
                          final h2y = bondLen * math.sin(bondAngle / 2);

                          final oOffset = projectPoint(0, -20, 0, canvasSize);
                          final h1Offset =
                              projectPoint(h1x, h1y - 20, 0, canvasSize);
                          final h2Offset =
                              projectPoint(h2x, h2y - 20, 0, canvasSize);

                          hotspots.addAll([
                            Positioned(
                              left: oOffset.dx - 12,
                              top: oOffset.dy - 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPart = 'oxygen'),
                                child:
                                    _buildPulsingPin(color: Colors.redAccent),
                              ),
                            ),
                            Positioned(
                              left: h1Offset.dx - 12,
                              top: h1Offset.dy - 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPart = 'hydrogen'),
                                child: _buildPulsingPin(color: Colors.white),
                              ),
                            ),
                            Positioned(
                              left: h2Offset.dx - 12,
                              top: h2Offset.dy - 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPart = 'hydrogen'),
                                child: _buildPulsingPin(color: Colors.white),
                              ),
                            ),
                          ]);
                        }

                        if (_selectedPart != null) {
                          final partOffset = _getSelectedPartOffset(
                              _selectedPart!, assetId, canvasSize);
                          if (partOffset != null) {
                            const double bubbleWidth = 220;
                            const double bubbleHeight = 90;
                            double leftPos = partOffset.dx - (bubbleWidth / 2);
                            double topPos = partOffset.dy - bubbleHeight - 20;

                            leftPos = leftPos.clamp(
                                16.0, canvasSize.width - bubbleWidth - 16.0);
                            topPos = topPos.clamp(
                                80.0, canvasSize.height - bubbleHeight - 180.0);

                            hotspots.addAll([
                              Positioned(
                                left: partOffset.dx - 6,
                                top: partOffset.dy - 18,
                                child: Transform.rotate(
                                  angle: math.pi / 4,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.9),
                                      border: Border(
                                        bottom: BorderSide(
                                            color:
                                                _getPartColor(_selectedPart!),
                                            width: 1.5),
                                        right: BorderSide(
                                            color:
                                                _getPartColor(_selectedPart!),
                                            width: 1.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: leftPos,
                                top: topPos,
                                child: Container(
                                  width: bubbleWidth,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _getPartColor(_selectedPart!),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getPartColor(_selectedPart!)
                                            .withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            _getPartIcon(_selectedPart!),
                                            color:
                                                _getPartColor(_selectedPart!),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _getPartTitle(_selectedPart!),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.5,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => setState(
                                                () => _selectedPart = null),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white54,
                                              size: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _getPartDescription(_selectedPart!),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9.5,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]);
                          }
                        }

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: Model3DPainter(
                                  rx: _rx,
                                  ry: _ry,
                                  baseAngle: baseAngle,
                                  scale: _scale * 2.1,
                                  pulse: _pulse,
                                  assetId: assetId,
                                  showGrid: _showGrid,
                                  primaryColor:
                                      Theme.of(context).colorScheme.primary,
                                  secondaryColor:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                            ...hotspots,
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // 3. AR HUD Overlays (Corner Viewfinders)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHUDCorner(top: true, left: true),
                        _buildHUDCorner(top: true, left: false),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHUDCorner(top: false, left: true),
                        _buildHUDCorner(top: false, left: false),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Upper Header Controls
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF0056D2).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle,
                          color: Color(0xFF1FA15F), size: 8),
                      const SizedBox(width: 8),
                      Text(
                        'AR MODE: ${assetId.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(_autoRotate ? Icons.sync : Icons.sync_disabled),
                  onPressed: () {
                    setState(() {
                      _autoRotate = !_autoRotate;
                    });
                  },
                ),
              ],
            ),
          ),

          // 5. Instruction Toast
          Positioned(
            top: 100,
            left: 50,
            right: 50,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Ketuk pin untuk detail • Seret untuk memutar • Cubit untuk memperbesar',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // 5b. Floating Zoom controls (vertical bar on the right side)
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height / 2 - 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in_ar',
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onPressed: () {
                    setState(() {
                      _scale = (_scale + 0.15).clamp(0.4, 2.5);
                    });
                  },
                  child: const Icon(Icons.add, size: 20),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF0056D2).withOpacity(0.4)),
                  ),
                  child: Text(
                    '${(_scale * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'zoom_out_ar',
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onPressed: () {
                    setState(() {
                      _scale = (_scale - 0.15).clamp(0.4, 2.5);
                    });
                  },
                  child: const Icon(Icons.remove, size: 20),
                ),
              ],
            ),
          ),

          // 6. Bottom Controls Panel
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildToggleBtn(
                        label: _enableCamera ? 'Kamera Off' : 'Kamera AR',
                        active: _enableCamera,
                        icon:
                            _enableCamera ? Icons.videocam_off : Icons.videocam,
                        onPressed: _toggleCamera,
                      ),
                      const SizedBox(width: 8),
                      _buildToggleBtn(
                        label: 'Kisi Grid',
                        active: _showGrid,
                        icon: Icons.grid_on,
                        onPressed: () {
                          setState(() {
                            _showGrid = !_showGrid;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildToggleBtn(
                        label: _autoRotate ? 'Auto Putar' : 'Putar Mati',
                        active: _autoRotate,
                        icon: _autoRotate ? Icons.sync : Icons.sync_disabled,
                        onPressed: () {
                          setState(() {
                            _autoRotate = !_autoRotate;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildToggleBtn(
                        label: 'Reset Sudut',
                        active: false,
                        icon: Icons.refresh,
                        onPressed: () {
                          setState(() {
                            _rx = -0.5;
                            _ry = 0.5;
                            _scale = 1.0;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Switch dynamically between default overview card and the active pin description card!
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedPart == null
                      ? Container(
                          key: const ValueKey('general_card'),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    const Color(0xFF0056D2).withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                assetId == 'heart'
                                    ? Icons.favorite
                                    : assetId == 'dna_helix'
                                        ? Icons.bubble_chart
                                        : Icons.science,
                                color: Theme.of(context).colorScheme.primary,
                                size: 32,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getAssetTitle(assetId),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      _getAssetSub(assetId),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          key: ValueKey(_selectedPart),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getPartColor(_selectedPart!),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getPartColor(_selectedPart!)
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _getPartIcon(_selectedPart!),
                                color: _getPartColor(_selectedPart!),
                                size: 28,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getPartTitle(_selectedPart!),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _getPartDescription(_selectedPart!),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPart = null),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraOverlay() {
    if (!_enableCamera) {
      return Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F0E1A),
                    Color(0xFF0A0918),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: GridBackgroundPainter(),
            ),
          ),
        ],
      );
    }

    if (!_cameraInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (_cameraError != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Akses kamera gagal: $_cameraError\nSilakan aktifkan izin kamera atau jalankan pada HTTPS/localhost.',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: kIsWeb
              ? buildWebcamPreview(
                  context: context,
                  onCaptured: (_) {},
                  onError: (err) {
                    if (mounted) {
                      setState(() {
                        _cameraError = err;
                      });
                    }
                  },
                  scanMode: false,
                )
              : (_cameraController != null &&
                      _cameraController!.value.isInitialized)
                  ? CameraPreview(_cameraController!)
                  : Container(color: Colors.black),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.45),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: GridBackgroundPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildPulsingPin({required Color color}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color,
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAssetTitle(String assetId) {
    if (assetId == 'heart') return '3D Human Heart Model';
    if (assetId == 'dna_helix') return '3D DNA Double Helix';
    if (assetId == 'water_molecule') return '3D H2O Molecule';
    return '3D Bohr Atom Model';
  }

  String _getAssetSub(String assetId) {
    if (assetId == 'heart')
      return 'Menampilkan denyut pemompaan miokardium melintang.';
    if (assetId == 'dna_helix')
      return 'Menampilkan kode ikatan basa nitrogen A-T / C-G.';
    if (assetId == 'water_molecule')
      return 'Menampilkan sudut kovalen molekul air sebesar 104.5°.';
    return 'Menampilkan orbit elektron dengan tingkat energi Bohr.';
  }

  String _getPartTitle(String part) {
    switch (part) {
      case 'nucleus':
        return 'Inti Atom (Nucleus)';
      case 'electron':
        return 'Elektron Bermuatan (-)';
      case 'orbit':
        return 'Lintasan / Orbit Bohr';
      case 'aorta':
        return 'Aorta Utama';
      case 'myocardium':
        return 'Otot Jantung (Myocardium)';
      case 'valve':
        return 'Katup Jantung (Valve)';
      case 'backbone':
        return 'Rantai Fosfat (Backbone)';
      case 'basepair':
        return 'Pasangan Basa Nitrogen';
      case 'oxygen':
        return 'Atom Oksigen (O)';
      case 'hydrogen':
        return 'Atom Hidrogen (H)';
      default:
        return 'Detail Bagian';
    }
  }

  String _getPartDescription(String part) {
    switch (part) {
      case 'nucleus':
        return 'Pusat atom yang padat, terdiri atas Proton bermuatan positif (+) dan Neutron yang netral.';
      case 'electron':
        return 'Partikel elementer bermuatan negatif (-) yang mengitari inti pada tingkat energi tertentu.';
      case 'orbit':
        return 'Jalur stasioner melingkar tempat elektron mengitari inti tanpa memancarkan radiasi.';
      case 'aorta':
        return 'Pembuluh darah arteri terbesar yang mengalirkan darah kaya oksigen dari bilik kiri ke seluruh tubuh.';
      case 'myocardium':
        return 'Lapisan otot tebal di dinding jantung yang berkontraksi untuk memompa darah.';
      case 'valve':
        return 'Pintu searah yang mencegah darah mengalir kembali ke ruang sebelumnya saat jantung memompa.';
      case 'backbone':
        return 'Rantai samping gula fosfat yang membentuk struktur spiral penopang rantai ganda DNA.';
      case 'basepair':
        return 'Pasangan basa nitrogen kovalen A-T (Adenin-Timin) dan C-G (Sitosin-Guanin) pembawa kode genetik.';
      case 'oxygen':
        return 'Atom pusat elektronegatif (-) yang berikatan kovalen dengan dua atom hidrogen.';
      case 'hydrogen':
        return 'Dua atom bermuatan parsial positif (+) yang berikatan dengan atom oksigen dengan sudut 104.5°.';
      default:
        return '';
    }
  }

  IconData _getPartIcon(String part) {
    switch (part) {
      case 'nucleus':
        return Icons.adjust;
      case 'electron':
        return Icons.blur_on;
      case 'orbit':
        return Icons.album_outlined;
      case 'aorta':
        return Icons.favorite;
      case 'myocardium':
        return Icons.fitness_center;
      case 'valve':
        return Icons.door_sliding;
      case 'backbone':
        return Icons.linear_scale;
      case 'basepair':
        return Icons.compare_arrows;
      case 'oxygen':
        return Icons.circle;
      case 'hydrogen':
        return Icons.circle_outlined;
      default:
        return Icons.info;
    }
  }

  Color _getPartColor(String part) {
    switch (part) {
      case 'nucleus':
        return Colors.redAccent;
      case 'electron':
        return Colors.yellowAccent;
      case 'orbit':
        return Colors.white70;
      case 'aorta':
        return Colors.redAccent;
      case 'myocardium':
        return Colors.pinkAccent;
      case 'valve':
        return Colors.white70;
      case 'backbone':
        return Colors.blueAccent;
      case 'basepair':
        return Colors.orangeAccent;
      case 'oxygen':
        return Colors.redAccent;
      case 'hydrogen':
        return Colors.white;
      default:
        return Colors.blueAccent;
    }
  }

  Widget _buildToggleBtn({
    required String label,
    required bool active,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: active
            ? Theme.of(context).colorScheme.primary
            : Colors.black.withOpacity(0.7),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white24),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHUDCorner({required bool top, required bool left}) {
    const size = 20.0;
    const thickness = 2.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? BorderSide(
                  color: const Color(0xFF0056D2).withOpacity(0.5),
                  width: thickness)
              : BorderSide.none,
          bottom: !top
              ? BorderSide(
                  color: const Color(0xFF0056D2).withOpacity(0.5),
                  width: thickness)
              : BorderSide.none,
          left: left
              ? BorderSide(
                  color: const Color(0xFF0056D2).withOpacity(0.5),
                  width: thickness)
              : BorderSide.none,
          right: !left
              ? BorderSide(
                  color: const Color(0xFF0056D2).withOpacity(0.5),
                  width: thickness)
              : BorderSide.none,
        ),
      ),
    );
  }
}

// Draw a futuristic grid backdrop simulating an AR tracking plane
class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0056D2).withOpacity(0.08)
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Vignette glow from borders
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final radial = RadialGradient(
      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
      stops: const [0.7, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = radial.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Mathematics-driven 3D Wireframe Projector
class Model3DPainter extends CustomPainter {
  final double rx;
  final double ry;
  final double baseAngle;
  final double scale;
  final double pulse;
  final String assetId;
  final bool showGrid;
  final Color primaryColor;
  final Color secondaryColor;

  Model3DPainter({
    required this.rx,
    required this.ry,
    required this.baseAngle,
    required this.scale,
    required this.pulse,
    required this.assetId,
    required this.showGrid,
    required this.primaryColor,
    required this.secondaryColor,
  });

  // Project a 3D point (x, y, z) into 2D canvas coordinates
  Offset _project(double x, double y, double z, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2 - 20);

    // Total rotation angle around Y
    final theta = ry + baseAngle;
    // Rotation around Y
    final x1 = x * math.cos(theta) - z * math.sin(theta);
    final z1 = x * math.sin(theta) + z * math.cos(theta);

    // Rotation around X
    final phi = rx;
    final y2 = y * math.cos(phi) - z1 * math.sin(phi);
    final z2 = y * math.sin(phi) + z1 * math.cos(phi);

    // Perspective factor
    const cameraDist = 400.0;
    final factor = cameraDist / (cameraDist + z2);

    return Offset(
      center.dx + x1 * scale * factor,
      center.dy + y2 * scale * factor,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      _drawARFloorGrid(canvas, size);
    }

    if (assetId == 'heart') {
      _paintHeart(canvas, size);
    } else if (assetId == 'dna_helix') {
      _paintDNA(canvas, size);
    } else if (assetId == 'water_molecule') {
      _paintWater(canvas, size);
    } else {
      _paintAtom(canvas, size);
    }

    // Draw CAD coordinate axes in the bottom-left corner
    _drawCoordinateGizmo(canvas, size);
  }

  void _drawCoordinateGizmo(Canvas canvas, Size size) {
    final center = Offset(50.0, size.height - 180.0);
    final theta = ry + baseAngle;

    Offset rotateVector(double x, double y, double z) {
      final x1 = x * math.cos(theta) - z * math.sin(theta);
      final z1 = x * math.sin(theta) + z * math.cos(theta);

      final y2 = y * math.cos(rx) - z1 * math.sin(rx);
      return Offset(center.dx + x1, center.dy + y2);
    }

    final origin = center;
    final xEnd = rotateVector(35, 0, 0);
    final yEnd = rotateVector(0, -35, 0); // Y points up in CAD local space
    final zEnd = rotateVector(0, 0, 35);

    // Draw Axes lines
    canvas.drawLine(
        origin,
        xEnd,
        Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 2.5);
    canvas.drawLine(
        origin,
        yEnd,
        Paint()
          ..color = Colors.greenAccent
          ..strokeWidth = 2.5);
    canvas.drawLine(
        origin,
        zEnd,
        Paint()
          ..color = Colors.blueAccent
          ..strokeWidth = 2.5);

    // Draw Origin sphere
    canvas.drawCircle(
        origin,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);

    // Draw Labels 'X', 'Y', 'Z'
    _drawText(canvas, xEnd + const Offset(4, 0), 'X', Colors.redAccent, 10,
        bold: true);
    _drawText(canvas, yEnd - const Offset(0, 6), 'Y', Colors.greenAccent, 10,
        bold: true);
    _drawText(canvas, zEnd + const Offset(0, 4), 'Z', Colors.blueAccent, 10,
        bold: true);

    // Circle boundary guide
    canvas.drawCircle(
        origin,
        42,
        Paint()
          ..color = Colors.white10
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  void _drawARFloorGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..strokeWidth = 1.0;

    const gridCount = 5;
    const step = 40.0;

    // Draw horizontal/vertical lines in pseudo 3D floor
    for (int i = -gridCount; i <= gridCount; i++) {
      final p1 = _project(i * step, 120, -gridCount * step, size);
      final p2 = _project(i * step, 120, gridCount * step, size);
      canvas.drawLine(p1, p2, paint);

      final p3 = _project(-gridCount * step, 120, i * step, size);
      final p4 = _project(gridCount * step, 120, i * step, size);
      canvas.drawLine(p3, p4, paint);
    }
  }

  // 1. Draw 3D pumping heart wireframe
  void _paintHeart(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    // Generate concentric vertical cross sections of the heart
    final currentScale = pulse; // Pulse changes scale dynamically

    const sliceCount = 8;
    for (int i = 0; i < sliceCount; i++) {
      // t ranges from -pi/2 to pi/2 representing vertical height layers
      final t = -math.pi / 2 + (math.pi * i / (sliceCount - 1));
      final h = 90 * math.sin(t); // height coordinate

      // Horizontal radius factor based on heart outer shape
      final rFactor = math.cos(t) * (1.2 - math.sin(t));
      final r = 60 * rFactor * currentScale;

      final layerPoints = <Offset>[];
      const ptCount = 16;

      for (int j = 0; j < ptCount; j++) {
        final jAngle = 2 * math.pi * j / ptCount;

        // Stylize horizontal cross section to have a heart indent in front/back
        final double indent = 1.0 - 0.25 * math.cos(jAngle).abs();
        final x = r * math.cos(jAngle) * indent;
        final z = r * math.sin(jAngle) * indent;

        // Apply slight offset to make Y axis match medical heart slant
        final double xOffset = -h * 0.15;

        layerPoints.add(_project(x + xOffset, h, z, size));
      }

      // Draw the rings
      for (int j = 0; j < ptCount; j++) {
        final next = (j + 1) % ptCount;
        canvas.drawLine(layerPoints[j], layerPoints[next], linePaint);
        canvas.drawCircle(layerPoints[j], 2.5, nodePaint);
      }
    }

    // Draw vertical connection lines to complete mesh
    const verticalLinesCount = 8;
    for (int i = 0; i < verticalLinesCount; i++) {
      final double phi = 2 * math.pi * i / verticalLinesCount;
      final double indent = 1.0 - 0.25 * math.cos(phi).abs();

      Offset? prevOffset;
      for (int slice = 0; slice < sliceCount; slice++) {
        final t = -math.pi / 2 + (math.pi * slice / (sliceCount - 1));
        final h = 90 * math.sin(t);
        final rFactor = math.cos(t) * (1.2 - math.sin(t));
        final r = 60 * rFactor * currentScale;

        final x = r * math.cos(phi) * indent;
        final z = r * math.sin(phi) * indent;
        final double xOffset = -h * 0.15;

        final currentOffset = _project(x + xOffset, h, z, size);
        if (prevOffset != null) {
          canvas.drawLine(prevOffset, currentOffset,
              linePaint..color = Colors.redAccent.withOpacity(0.35));
        }
        prevOffset = currentOffset;
      }
    }
  }

  // 2. Draw 3D DNA Double Helix
  void _paintDNA(Canvas canvas, Size size) {
    const double helixRadius = 45.0;
    const double heightLength = 160.0;
    const int stepsCount = 28;

    final List<Offset> strand1 = [];
    final List<Offset> strand2 = [];

    // Colors for base pair rungs
    final paintA = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3.0;
    final paintT = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3.0;
    final paintC = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3.0;
    final paintG = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3.0;

    for (int i = 0; i < stepsCount; i++) {
      final double t = (i / (stepsCount - 1));
      // DNA winds 2.5 complete turns
      final double angle = t * 2.5 * 2 * math.pi;
      final double y = -heightLength / 2 + t * heightLength;

      final double x1 = helixRadius * math.cos(angle);
      final double z1 = helixRadius * math.sin(angle);

      final double x2 = helixRadius * math.cos(angle + math.pi);
      final double z2 = helixRadius * math.sin(angle + math.pi);

      final p1 = _project(x1, y, z1, size);
      final p2 = _project(x2, y, z2, size);

      strand1.add(p1);
      strand2.add(p2);

      // Draw base pairs rungs every step
      if (i % 2 == 0) {
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        // Alternate base pairings
        if ((i ~/ 2) % 2 == 0) {
          canvas.drawLine(p1, mid, paintA);
          canvas.drawLine(mid, p2, paintT);
        } else {
          canvas.drawLine(p1, mid, paintC);
          canvas.drawLine(mid, p2, paintG);
        }
      }
    }

    // Draw main backbone strands
    final backbonePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < stepsCount - 1; i++) {
      canvas.drawLine(strand1[i], strand1[i + 1], backbonePaint);
      canvas.drawLine(strand2[i], strand2[i + 1], backbonePaint);
    }

    // Draw nodes on strands
    final nodePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < stepsCount; i++) {
      canvas.drawCircle(strand1[i], 4, nodePaint..color = primaryColor);
      canvas.drawCircle(strand2[i], 4, nodePaint..color = secondaryColor);
    }
  }

  // 3. Draw 3D H2O Molecule
  void _paintWater(Canvas canvas, Size size) {
    // Oxygen is central (0, 0, 0)
    // Hydrogens are bonded at 104.5 degrees
    const bondLen = 65.0;
    const bondAngle = 104.5 * math.pi / 180.0;

    final h1x = bondLen * math.cos(bondAngle / 2);
    final h1y = bondLen * math.sin(bondAngle / 2);

    final h2x = -bondLen * math.cos(bondAngle / 2);
    final h2y = bondLen * math.sin(bondAngle / 2);

    final oxygenPos = _project(0, -20, 0, size);
    final h1Pos = _project(h1x, h1y - 20, 0, size);
    final h2Pos = _project(h2x, h2y - 20, 0, size);

    // Draw Bonds
    final bondPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 6.0;
    canvas.drawLine(oxygenPos, h1Pos, bondPaint);
    canvas.drawLine(oxygenPos, h2Pos, bondPaint);

    // Draw Oxygen Atom (Big Red)
    final oPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(oxygenPos, 22, oPaint);
    canvas.drawCircle(
        oxygenPos,
        22,
        Paint()
          ..color = Colors.black26
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Draw Hydrogen Atoms (Small White)
    final hPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(h1Pos, 14, hPaint);
    canvas.drawCircle(h2Pos, 14, hPaint);

    // Outline for H
    final outlinePaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(h1Pos, 14, outlinePaint);
    canvas.drawCircle(h2Pos, 14, outlinePaint);

    // Text Labels
    _drawText(canvas, oxygenPos, 'O', Colors.white, 14);
    _drawText(canvas, h1Pos, 'H', Colors.black, 10);
    _drawText(canvas, h2Pos, 'H', Colors.black, 10);

    // Label delta charges
    _drawText(
        canvas, oxygenPos - const Offset(0, 32), 'δ-', Colors.redAccent, 12,
        bold: true);
    _drawText(canvas, h1Pos + const Offset(0, 22), 'δ+', Colors.white70, 11,
        bold: true);
    _drawText(canvas, h2Pos + const Offset(0, 22), 'δ+', Colors.white70, 11,
        bold: true);
  }

  // 4. Draw 3D Bohr Atom Model
  void _paintAtom(Canvas canvas, Size size) {
    // 1. Draw central Nucleus Protons/Neutrons
    final random = math.Random(42);
    final nucleusPaint = Paint()..style = PaintingStyle.fill;

    // Draw a small 3D cluster of Protons (+) and Neutrons (n)
    for (int i = 0; i < 9; i++) {
      // Random coordinates in small spherical radius
      final nx = 18 * (random.nextDouble() - 0.5);
      final ny = 18 * (random.nextDouble() - 0.5);
      final nz = 18 * (random.nextDouble() - 0.5);
      final pPos = _project(nx, ny, nz, size);

      final isProton = random.nextBool();
      nucleusPaint.color = isProton ? Colors.redAccent : Colors.blueAccent;
      canvas.drawCircle(pPos, 6, nucleusPaint);
      canvas.drawCircle(
          pPos,
          6,
          Paint()
            ..color = Colors.black26
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }

    // 2. Draw 3 Elliptical Electron Orbits
    final orbitPaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const radiusX = 85.0;
    const radiusZ = 40.0;
    const stepCount = 50;

    // Orbit 1 (flat XZ)
    final List<Offset> orbit1 = [];
    // Orbit 2 (rotated 45 deg)
    final List<Offset> orbit2 = [];
    // Orbit 3 (rotated -45 deg)
    final List<Offset> orbit3 = [];

    for (int i = 0; i <= stepCount; i++) {
      final double angle = i * 2 * math.pi / stepCount;
      final x = radiusX * math.cos(angle);
      final z = radiusZ * math.sin(angle);

      orbit1.add(_project(x, 0, z, size));

      // Rotate around Z axis by 60deg
      final double xRot2 = x * math.cos(math.pi / 3);
      final double yRot2 = x * math.sin(math.pi / 3);
      orbit2.add(_project(xRot2, yRot2, z, size));

      // Rotate around Z axis by -60deg
      final double xRot3 = x * math.cos(-math.pi / 3);
      final double yRot3 = x * math.sin(-math.pi / 3);
      orbit3.add(_project(xRot3, yRot3, z, size));
    }

    // Draw Orbit lines
    for (int i = 0; i < stepCount; i++) {
      canvas.drawLine(orbit1[i], orbit1[i + 1], orbitPaint);
      canvas.drawLine(orbit2[i], orbit2[i + 1], orbitPaint);
      canvas.drawLine(orbit3[i], orbit3[i + 1], orbitPaint);
    }

    // 3. Draw moving Electrons as glowing dots
    final electronAngle = baseAngle * 2.0; // Rotate electrons twice as fast

    // Electron 1
    final e1x = radiusX * math.cos(electronAngle);
    final e1z = radiusZ * math.sin(electronAngle);
    final e1Pos = _project(e1x, 0, e1z, size);
    _drawGlowingDot(canvas, e1Pos, 5, Colors.yellowAccent);

    // Electron 2
    final e2x = radiusX * math.cos(electronAngle + 2 * math.pi / 3);
    final e2Pos = _project(
        e2x * math.cos(math.pi / 3),
        e2x * math.sin(math.pi / 3),
        radiusZ * math.sin(electronAngle + 2 * math.pi / 3),
        size);
    _drawGlowingDot(canvas, e2Pos, 5, Colors.yellowAccent);

    // Electron 3
    final e3x = radiusX * math.cos(electronAngle + 4 * math.pi / 3);
    final e3Pos = _project(
        e3x * math.cos(-math.pi / 3),
        e3x * math.sin(-math.pi / 3),
        radiusZ * math.sin(electronAngle + 4 * math.pi / 3),
        size);
    _drawGlowingDot(canvas, e3Pos, 5, Colors.yellowAccent);
  }

  void _drawGlowingDot(Canvas canvas, Offset pos, double radius, Color color) {
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pos, radius * 2.2, glowPaint);
    canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
  }

  void _drawText(
      Canvas canvas, Offset pos, String text, Color color, double size,
      {bool bold = false}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant Model3DPainter oldDelegate) {
    return oldDelegate.rx != rx ||
        oldDelegate.ry != ry ||
        oldDelegate.baseAngle != baseAngle ||
        oldDelegate.scale != scale ||
        oldDelegate.pulse != pulse ||
        oldDelegate.assetId != assetId ||
        oldDelegate.showGrid != showGrid;
  }
}
