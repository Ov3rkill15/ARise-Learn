import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class ARViewerScreen extends StatefulWidget {
  const ARViewerScreen({super.key});

  @override
  State<ARViewerScreen> createState() => _ARViewerScreenState();
}

class _ARViewerScreenState extends State<ARViewerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _rx = -0.5; // X rotation
  double _ry = 0.5;  // Y rotation
  double _scale = 1.0;
  double _baseScale = 1.0;
  bool _autoRotate = true;
  bool _showGrid = true;
  double _pulse = 1.0; // Heart beat pulse

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetId = (ModalRoute.of(context)?.settings.arguments as String?) ?? 'atom';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black, // Dark space for AR immersion
      body: Stack(
        children: [
          // 1. Mock Camera Background Feed (Gradient grid)
          Positioned.fill(
            child: _buildCameraOverlay(),
          ),

          // 2. Interactive 3D Render Area
          Positioned.fill(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  setState(() {
                    _scale = (_scale - pointerSignal.scrollDelta.dy * 0.0015).clamp(0.4, 2.5);
                  });
                }
              },
              child: GestureDetector(
                onScaleStart: (details) {
                  _baseScale = _scale;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    if (details.pointerCount >= 2) {
                      // Two or more fingers: zoom
                      _scale = (_baseScale * details.scale).clamp(0.4, 2.5);
                    } else if (details.pointerCount == 1) {
                      // One finger: rotate
                      _ry += details.focalPointDelta.dx * 0.007;
                      _rx -= details.focalPointDelta.dy * 0.007;
                    }
                  });
                },
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final baseAngle = _autoRotate ? _animationController.value * 2 * math.pi : 0.0;
                    return CustomPaint(
                      painter: Model3DPainter(
                        rx: _rx,
                        ry: _ry,
                        baseAngle: baseAngle,
                        scale: _scale * 1.5,
                        pulse: _pulse,
                        assetId: assetId,
                        showGrid: _showGrid,
                        primaryColor: Theme.of(context).colorScheme.primary,
                        secondaryColor: Theme.of(context).colorScheme.secondary,
                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
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
                  'Seret untuk memutar objek • Cubit untuk memperbesar',
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
                  heroTag: 'zoom_in',
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${(_scale * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
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
                ),
              ],
            ),
          ),
        ],
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
    if (assetId == 'heart') return 'Menampilkan denyut pemompaan miokardium melintang.';
    if (assetId == 'dna_helix') return 'Menampilkan kode ikatan basa nitrogen A-T / C-G.';
    if (assetId == 'water_molecule') return 'Menampilkan sudut kovalen molekul air sebesar 104.5°.';
    return 'Menampilkan orbit elektron dengan tingkat energi Bohr.';
  }

  Widget _buildToggleBtn({
    required String label,
    required bool active,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? Theme.of(context).colorScheme.primary : Colors.black54,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
          top: top ? const BorderSide(color: Colors.white54, width: thickness) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Colors.white54, width: thickness) : BorderSide.none,
          left: left ? const BorderSide(color: Colors.white54, width: thickness) : BorderSide.none,
          right: !left ? const BorderSide(color: Colors.white54, width: thickness) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return CustomPaint(
      painter: GridBackgroundPainter(),
    );
  }
}

// Draw a futuristic grid backdrop simulating an AR tracking plane
class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.08)
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
  }

  void _drawARFloorGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2 + 100);
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
        final phi = 2 * math.pi * j / ptCount;
        
        // Stylize horizontal cross section to have a heart indent in front/back
        final double indent = 1.0 - 0.25 * math.cos(phi).abs();
        final x = r * math.cos(phi) * indent;
        final z = r * math.sin(phi) * indent;

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
          canvas.drawLine(prevOffset, currentOffset, linePaint..color = Colors.redAccent.withOpacity(0.35));
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
    final paintA = Paint()..color = Colors.greenAccent..strokeWidth = 3.0;
    final paintT = Paint()..color = Colors.redAccent..strokeWidth = 3.0;
    final paintC = Paint()..color = Colors.blueAccent..strokeWidth = 3.0;
    final paintG = Paint()..color = Colors.orangeAccent..strokeWidth = 3.0;

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
    final nodePaint = Paint()..color = primaryColor..style = PaintingStyle.fill;
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

    // Draw Oxygen Atom (Big Red/Blue)
    final oPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(oxygenPos, 22, oPaint);
    canvas.drawCircle(oxygenPos, 22, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 2);

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
    _drawText(canvas, oxygenPos - const Offset(0, 32), 'δ-', Colors.redAccent, 12, bold: true);
    _drawText(canvas, h1Pos + const Offset(0, 22), 'δ+', Colors.white70, 11, bold: true);
    _drawText(canvas, h2Pos + const Offset(0, 22), 'δ+', Colors.white70, 11, bold: true);
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
      canvas.drawCircle(pPos, 6, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1);
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
    final electronPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill;

    // Animate angle over time
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
      size
    );
    _drawGlowingDot(canvas, e2Pos, 5, Colors.yellowAccent);

    // Electron 3
    final e3x = radiusX * math.cos(electronAngle + 4 * math.pi / 3);
    final e3Pos = _project(
      e3x * math.cos(-math.pi / 3),
      e3x * math.sin(-math.pi / 3),
      radiusZ * math.sin(electronAngle + 4 * math.pi / 3),
      size
    );
    _drawGlowingDot(canvas, e3Pos, 5, Colors.yellowAccent);
  }

  void _drawGlowingDot(Canvas canvas, Offset pos, double radius, Color color) {
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(pos, radius * 2.2, glowPaint);
    canvas.drawCircle(pos, radius, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawText(Canvas canvas, Offset pos, String text, Color color, double size, {bool bold = false}) {
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
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
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
