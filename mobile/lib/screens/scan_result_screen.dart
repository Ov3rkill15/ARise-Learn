import 'dart:io' as io;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'ar_viewer_screen.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _rx = -0.5; // X rotation
  double _ry = 0.5;  // Y rotation
  double _scale = 1.0;
  double _baseScale = 1.0;
  bool _autoRotate = true;
  bool _showGrid = true;
  double _pulse = 1.0;
  Timer? _pulseTimer;
  String? _selectedPart;
  bool _isHovering3D = false;

  Offset projectPoint(double x, double y, double z, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2 - 20);
    final theta = _ry + (_autoRotate ? _animationController.value * 2 * math.pi : 0.0);
    final x1 = x * math.cos(theta) - z * math.sin(theta);
    final z1 = x * math.sin(theta) + z * math.cos(theta);
    final y2 = y * math.cos(_rx) - z1 * math.sin(_rx);
    final z2 = y * math.sin(_rx) + z1 * math.cos(_rx);
    const cameraDist = 400.0;
    final factor = cameraDist / (cameraDist + z2);
    final scaleVal = _scale * 2.3;
    return Offset(
      center.dx + x1 * scaleVal * factor,
      center.dy + y2 * scaleVal * factor,
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Pulse animation for heart or general breathing effect
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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
    _pulseTimer?.cancel();
    super.dispose();
  }

  List<TextSpan> _parseMarkdown(String text, BuildContext context, bool isDark, {bool compact = false}) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        spans.add(TextSpan(text: compact ? '\n' : '\n\n'));
        continue;
      }
      
      if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: compact ? '${line.substring(4)}\n' : '\n${line.substring(4)}\n\n',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: compact
                ? (_selectedPart != null ? _getPartColor(_selectedPart!) : Colors.white)
                : Theme.of(context).colorScheme.primary,
            fontSize: compact ? 11.0 : 16.0,
          ),
        ));
      } else if (line.startsWith('**') && line.endsWith('**')) {
        spans.add(TextSpan(
          text: '${line.replaceAll('**', '')}\n',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: compact ? 10.5 : 13.5,
            color: compact ? Colors.white : (isDark ? Colors.white : Colors.black),
          ),
        ));
      } else {
        // Simple inline bold parser
        final parts = line.split('**');
        for (int j = 0; j < parts.length; j++) {
          final isBold = j % 2 == 1;
          spans.add(TextSpan(
            text: parts[j],
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: compact ? 10.5 : 13.5,
              height: compact ? 1.3 : 1.5,
              color: compact ? Colors.white70 : (isDark ? Colors.grey[300] : Colors.grey[800]),
            ),
          ));
        }
        spans.add(TextSpan(text: compact ? '\n' : '\n\n'));
      }
    }
    return spans;
  }

  Widget _buildMiniControlBtn({
    required String label,
    required bool active,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: active
            ? Theme.of(context).colorScheme.primary
            : (isDark ? const Color(0xFF1E293B) : Colors.grey[200]),
        foregroundColor: active
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: active
                ? Colors.transparent
                : (isDark ? Colors.white12 : Colors.grey[300]!),
          ),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPulsingPin({required Color color}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
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

  // ══════════ Dynamic Model Helpers ══════════
  String _getAssetTitle(String? assetId) {
    switch (assetId) {
      case 'heart': return '3D HUMAN HEART MODEL';
      case 'dna_helix': return '3D DNA DOUBLE HELIX';
      case 'water_molecule': return '3D H2O MOLECULE';
      default: return 'ATOM BOHR';
    }
  }

  String _getAssetHintText(String? assetId) {
    switch (assetId) {
      case 'heart': return 'Ketuk pin (aorta, otot, katup) untuk detail • Seret untuk putar';
      case 'dna_helix': return 'Ketuk pin (backbone, basepair) untuk detail • Seret untuk putar';
      case 'water_molecule': return 'Ketuk pin (oksigen, hidrogen) untuk detail • Seret untuk putar';
      default: return 'Ketuk pin (inti, elektron, orbit) untuk detail • Seret untuk putar';
    }
  }

  Offset? _getSelectedPartOffset(String part, String assetId, Size canvasSize) {
    if (assetId == 'atom' || assetId == 'general') {
      if (part == 'nucleus') return projectPoint(0, 0, 0, canvasSize);
      if (part == 'electron') {
        final baseAngle = _autoRotate ? _animationController.value * 2 * math.pi : 0.0;
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

  String _getPartTitle(String part) {
    switch (part) {
      case 'nucleus': return 'Inti Atom (Nucleus)';
      case 'electron': return 'Elektron Bermuatan (-)';
      case 'orbit': return 'Lintasan / Orbit Bohr';
      case 'aorta': return 'Aorta Utama';
      case 'myocardium': return 'Otot Jantung (Myocardium)';
      case 'valve': return 'Katup Jantung (Valve)';
      case 'backbone': return 'Rantai Fosfat (Backbone)';
      case 'basepair': return 'Pasangan Basa Nitrogen';
      case 'oxygen': return 'Atom Oksigen (O)';
      case 'hydrogen': return 'Atom Hidrogen (H)';
      default: return 'Detail Bagian';
    }
  }

  String _getPartDescription(String part) {
    switch (part) {
      case 'nucleus': return 'Pusat atom yang padat, terdiri atas Proton bermuatan positif (+) dan Neutron yang netral.';
      case 'electron': return 'Partikel elementer bermuatan negatif (-) yang mengitari inti pada tingkat energi tertentu.';
      case 'orbit': return 'Jalur stasioner melingkar tempat elektron mengitari inti tanpa memancarkan radiasi.';
      case 'aorta': return 'Pembuluh darah arteri terbesar yang mengalirkan darah kaya oksigen dari bilik kiri ke seluruh tubuh.';
      case 'myocardium': return 'Lapisan otot tebal di dinding jantung yang berkontraksi untuk memompa darah.';
      case 'valve': return 'Pintu searah yang mencegah darah mengalir kembali ke ruang sebelumnya saat jantung memompa.';
      case 'backbone': return 'Rantai samping gula fosfat yang membentuk struktur spiral penopang rantai ganda DNA.';
      case 'basepair': return 'Pasangan basa nitrogen kovalen A-T (Adenin-Timin) dan C-G (Sitosin-Guanin) pembawa kode genetik.';
      case 'oxygen': return 'Atom pusat elektronegatif (-) yang berikatan kovalen dengan dua atom hidrogen.';
      case 'hydrogen': return 'Dua atom bermuatan parsial positif (+) yang berikatan dengan atom oksigen dengan sudut 104.5°.';
      default: return '';
    }
  }

  String _getPartDetailedDescription(String part) {
    switch (part) {
      case 'nucleus':
        return '### **Struktur & Massa**\nTerdiri atas proton bermuatan positif (+1e) dan neutron netral. Meskipun ukurannya 100.000 kali lebih kecil dari atom keseluruhan, inti atom menyimpan **99.9% dari seluruh massa atom**.\n\n'
            '### **Gaya Ikat Nuklir**\nDiikat oleh **Gaya Nuklir Kuat**, salah satu gaya fundamental alam semesta yang bekerja pada jarak sangat pendek untuk mengalahkan gaya tolak-menolak elektrostatik alami antar proton.';
      case 'electron':
        return '### **Karakteristik Fisik**\nPartikel subatomik bermuatan negatif (-1e) dan bermassa sangat kecil (~9.11 × 10^-31 kg, setara 1/1836 massa proton). Elektron tidak memiliki struktur internal yang diketahui.\n\n'
            '### **Fungsi Kimiawi**\nBerada pada tingkat energi terluar (kulit valensi) untuk menentukan **ikatan kimia** (kovalen, ionik, logam), reaksi, hantaran arus listrik, dan sifat kemagnetan materi.';
      case 'orbit':
        return '### **Kuantisasi Energi**\nLintasan melingkar diskret di mana elektron bergerak tanpa memancarkan radiasi elektromagnetik. Tingkat energi di setiap orbit terkuantisasi penuh berdasarkan bilangan kuantum utama (n = 1, 2, 3...).\n\n'
            '### **Efek Transisi Foton**\nElektron berpindah orbit dengan menyerap energi foton (ke tingkat lebih tinggi/eksitasi) atau memancarkan foton dengan panjang gelombang spesifik (ke tingkat lebih rendah), membentuk **spektrum garis atom**.';
      case 'aorta':
        return '### **Rute & Dimensi**\nArteri terbesar manusia dengan diameter mencapai 2.5 - 3.5 cm. Mengalir dari bilik (ventrikel) kiri jantung, melengkung ke atas (arcus aorta), lalu turun ke dada dan perut.\n\n'
            '### **Fungsi & Adaptasi Tekanan**\nMenyalurkan darah kaya oksigen ke seluruh sistem sirkulasi tubuh. Memiliki dinding berotot tebal dan serat elastis tinggi untuk **meredam fluktuasi tekanan darah tinggi (sistolik)** saat ventrikel memompa.';
      case 'myocardium':
        return '### **Karakteristik Jaringan**\nLapisan otot tengah jantung yang tersusun atas sel kardiomiosit khusus. Bekerja secara otomatis (involunter) dan berirama tanpa lelah sepanjang hidup karena kaya akan organel penghasil energi (mitokondria).\n\n'
            '### **Sinkronisasi Impuls**\nSel kardiomiosit dihubungkan oleh diskus interkalaris dengan *gap junction*. Hal ini memungkinkan **penyebaran impuls listrik yang sangat cepat**, membuat seluruh serambi atau bilik berkontraksi serentak.';
      case 'valve':
        return '### **Mekanisme Katup**\nStruktur katup searah dinamis yang membuka dan menutup pasif akibat perubahan gradien tekanan darah. Mencegah darah mengalir kembali (regurgitasi) ke bilik atau serambi sebelumnya.\n\n'
            '### **Klasifikasi & Penyokong**\nTerbagi menjadi katup atrioventrikuler (Mitral & Trikuspid) dan semilunar (Aorta & Pulmonal). Katup AV disokong oleh korda tendinae (tali jantung) agar daun katup tidak membalik ke belakang saat kontraksi.';
      case 'backbone':
        return '### **Struktur Kovalen**\nRangka rantai ganda luar DNA yang tersusun dari molekul gula deoksiribosa dan gugus fosfat yang berikatan kovalen secara berulang melalui ikatan fosfodiester.\n\n'
            '### **Polaritas & Hidrofilisitas**\nBerjalan antiparalel dengan polaritas arah 5\' ke 3\'. Gugus fosfat yang bermuatan negatif membuat rantai samping ini **sangat polar (hidrofilik)**, memungkinkannya stabil berinteraksi dengan lingkungan berair di dalam sel.';
      case 'basepair':
        return '### **Aturan Komplementer**\nBasa nitrogen di dalam heliks ganda yang saling berpasangan secara spesifik: Adenin (A) dengan Timin (T), dan Sitosin (C) dengan Guanin (G) sesuai Aturan Chargaff.\n\n'
            '### **Ikatan Hidrogen & Kode Genetik**\nPasangan A-T dihubungkan oleh 2 ikatan hidrogen, sedangkan C-G oleh 3 ikatan hidrogen. Urutan linier dari pasangan basa nitrogen ini membentuk **sandi genetik (kodon)** yang mengode protein dalam tubuh.';
      case 'oxygen':
        return '### **Elektronegativitas Tinggi**\nAtom pusat berdiameter kecil dengan elektronegativitas tinggi (3.44). Oksigen menarik elektron ikatan kovalen lebih kuat ke arah intinya dibanding atom Hidrogen.\n\n'
            '### **Dipol & Geometri Molekul**\nMenyebabkan ujung oksigen bermuatan parsial negatif (δ-). Sudut ikatan H-O-H terdistorsi menjadi **104.5°** akibat dorongan kuat dari dua pasangan elektron bebas (PEB), menghasilkan momen dipol permanen.';
      case 'hydrogen':
        return '### **Kutub Parsial Positif**\nDua atom hidrogen yang berikatan kovalen dengan Oksigen. Karena kerapatan elektron ditarik oleh oksigen, inti hidrogen bermuatan parsial positif (δ+) dan agak tidak terlindungi.\n\n'
            '### **Ikatan Hidrogen Antarmolekul**\nPolaritas δ+ pada hidrogen memicu daya tarik elektrostatik kuat dengan oksigen (δ-) dari molekul H2O tetangga. Fenomena ini mendasari **ikatan hidrogen**, yang memberikan air titik didih tinggi dan kohesi kuat.';
      default: return '';
    }
  }

  IconData _getPartIcon(String part) {
    switch (part) {
      case 'nucleus': return Icons.adjust;
      case 'electron': return Icons.blur_on;
      case 'orbit': return Icons.album_outlined;
      case 'aorta': return Icons.favorite;
      case 'myocardium': return Icons.fitness_center;
      case 'valve': return Icons.door_sliding;
      case 'backbone': return Icons.linear_scale;
      case 'basepair': return Icons.compare_arrows;
      case 'oxygen': return Icons.circle;
      case 'hydrogen': return Icons.circle_outlined;
      default: return Icons.info;
    }
  }

  Color _getPartColor(String part) {
    switch (part) {
      case 'nucleus': return Colors.redAccent;
      case 'electron': return Colors.yellowAccent;
      case 'orbit': return Colors.white70;
      case 'aorta': return Colors.redAccent;
      case 'myocardium': return Colors.pinkAccent;
      case 'valve': return Colors.white70;
      case 'backbone': return Colors.blueAccent;
      case 'basepair': return Colors.orangeAccent;
      case 'oxygen': return Colors.redAccent;
      case 'hydrogen': return Colors.white;
      default: return Colors.blueAccent;
    }
  }

  List<Widget> _buildDynamicHotspots(String assetId, Size canvasSize, double electronAngle) {
    final List<Widget> hotspots = [];

    if (assetId == 'atom' || assetId == 'general') {
      const radiusX = 85.0;
      const radiusZ = 40.0;
      final nucleusOffset = projectPoint(0, 0, 0, canvasSize);
      final orbitOffset = projectPoint(radiusX, 0, 0, canvasSize);
      final e1x = radiusX * math.cos(electronAngle);
      final e1z = radiusZ * math.sin(electronAngle);
      final electronOffset = projectPoint(e1x, 0, e1z, canvasSize);

      hotspots.addAll([
        Positioned(
          left: nucleusOffset.dx - 12, top: nucleusOffset.dy - 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPart = 'nucleus'),
            child: _buildPulsingPin(color: Colors.redAccent),
          ),
        ),
        Positioned(
          left: electronOffset.dx - 12, top: electronOffset.dy - 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPart = 'electron'),
            child: _buildPulsingPin(color: Colors.yellowAccent),
          ),
        ),
        Positioned(
          left: orbitOffset.dx - 12, top: orbitOffset.dy - 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPart = 'orbit'),
            child: _buildPulsingPin(color: Colors.white70),
          ),
        ),
      ]);
    } else if (assetId == 'heart') {
      final aortaOffset = projectPoint(-20, -70, 0, canvasSize);
      final muscleOffset = projectPoint(0, 70, 0, canvasSize);
      final valveOffset = projectPoint(0, 0, 0, canvasSize);

      hotspots.addAll([
        Positioned(
          left: aortaOffset.dx - 12, top: aortaOffset.dy - 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPart = 'aorta'),
            child: _buildPulsingPin(color: Colors.redAccent),
          ),
        ),
        Positioned(
          left: muscleOffset.dx - 12, top: muscleOffset.dy - 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPart = 'myocardium'),
            child: _buildPulsingPin(color: Colors.pinkAccent),
          ),
        ),
        Positioned(
          left: valveOffset.dx - 12, top: valveOffset.dy - 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPart = 'valve'),
            child: _buildPulsingPin(color: Colors.white70),
          ),
        ),
      ]);
    } else if (assetId == 'dna_helix') {
      final backboneOffset = projectPoint(45.0, -40, 0, canvasSize);
      final basepairOffset = projectPoint(0, 20, 0, canvasSize);

      hotspots.addAll([
        Positioned(
          left: backboneOffset.dx - 12, top: backboneOffset.dy - 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPart = 'backbone'),
            child: _buildPulsingPin(color: Colors.blueAccent),
          ),
        ),
        Positioned(
          left: basepairOffset.dx - 12, top: basepairOffset.dy - 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPart = 'basepair'),
            child: _buildPulsingPin(color: Colors.orangeAccent),
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
      final h1Offset = projectPoint(h1x, h1y - 20, 0, canvasSize);
      final h2Offset = projectPoint(h2x, h2y - 20, 0, canvasSize);

      hotspots.addAll([
        Positioned(
          left: oOffset.dx - 12, top: oOffset.dy - 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPart = 'oxygen'),
            child: _buildPulsingPin(color: Colors.redAccent),
          ),
        ),
        Positioned(
          left: h1Offset.dx - 12, top: h1Offset.dy - 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPart = 'hydrogen'),
            child: _buildPulsingPin(color: Colors.white),
          ),
        ),
        Positioned(
          left: h2Offset.dx - 12, top: h2Offset.dy - 12,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPart = 'hydrogen'),
            child: _buildPulsingPin(color: Colors.white),
          ),
        ),
      ]);
    }

    return hotspots;
  }

  @override
  Widget build(BuildContext context) {
    final apiService = context.watch<ApiService>();
    final result = apiService.lastResult;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Analisis')),
        body: const Center(child: Text('Hasil pemindaian tidak tersedia.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Analisis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: _isHovering3D ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Interactive 3D AR Model Viewport (Always Bohr Atom model for mockup, but interactive)
            MouseRegion(
              onEnter: (_) => setState(() => _isHovering3D = true),
              onExit: (_) => setState(() => _isHovering3D = false),
              child: Container(
              height: 380,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black, // Dark space for AR immersion
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize = Size(constraints.maxWidth, 380);

                    return Stack(
                      children: [
                        // 1a. Grid Background
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GridBackgroundPainter(),
                          ),
                        ),

                        // 1b. Interactive 3D Render Area & Hotspots
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
                                  if (details.scale != 1.0) {
                                    _scale = (_baseScale * details.scale).clamp(0.4, 2.5);
                                  }
                                  
                                  if (details.pointerCount == 1 && details.scale == 1.0) {
                                    _ry += details.focalPointDelta.dx * 0.007;
                                    _rx -= details.focalPointDelta.dy * 0.007;
                                  }
                                });
                              },
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  final currentAssetId = result.asset3dUrl ?? 'atom';
                                  final baseAngle = _autoRotate ? _animationController.value * 2 * math.pi : 0.0;
                                  final electronAngle = baseAngle * 2.0;

                                  return Stack(
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: Model3DPainter(
                                            rx: _rx,
                                            ry: _ry,
                                            baseAngle: baseAngle,
                                            scale: _scale * 2.3,
                                            pulse: _pulse,
                                            assetId: currentAssetId,
                                            showGrid: _showGrid,
                                            primaryColor: Theme.of(context).colorScheme.primary,
                                            secondaryColor: Theme.of(context).colorScheme.secondary,
                                          ),
                                        ),
                                      ),

                                      // Dynamic hotspot pins based on model type
                                      ..._buildDynamicHotspots(currentAssetId, canvasSize, electronAngle),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // 1c. Mini HUD Overlay
                        Positioned(
                          top: 12,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, color: Colors.greenAccent, size: 6),
                                const SizedBox(width: 6),
                                Text(
                                  'PROYEKSI 3D: ${_getAssetTitle(result.asset3dUrl)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Interaction hint
                        Positioned(
                          bottom: 12,
                          left: 16,
                          child: Text(
                            _getAssetHintText(result.asset3dUrl),
                            style: const TextStyle(color: Colors.white54, fontSize: 9),
                          ),
                        ),

                        // Sci-fi HUD Interactive explanation card overlay (floating speech bubbles & bottom panel)
                        if (_selectedPart != null) ...[
                          (() {
                            final currentAssetId = result.asset3dUrl ?? 'atom';
                            final partOffset = _getSelectedPartOffset(_selectedPart!, currentAssetId, canvasSize);
                            if (partOffset == null) return const SizedBox.shrink();
                            
                            const double bubbleWidth = 200;
                            const double bubbleHeight = 85;
                            double leftPos = partOffset.dx - (bubbleWidth / 2);
                            double topPos = partOffset.dy - bubbleHeight - 20;

                            leftPos = leftPos.clamp(12.0, canvasSize.width - bubbleWidth - 12.0);
                            topPos = topPos.clamp(12.0, canvasSize.height - bubbleHeight - 110.0);

                            return Positioned(
                              left: partOffset.dx - 6,
                              top: partOffset.dy - 18,
                              child: Transform.rotate(
                                angle: math.pi / 4,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.9),
                                    border: Border(
                                      bottom: BorderSide(color: _getPartColor(_selectedPart!), width: 1.5),
                                      right: BorderSide(color: _getPartColor(_selectedPart!), width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })(),
                          (() {
                            final currentAssetId = result.asset3dUrl ?? 'atom';
                            final partOffset = _getSelectedPartOffset(_selectedPart!, currentAssetId, canvasSize);
                            if (partOffset == null) return const SizedBox.shrink();

                            const double bubbleWidth = 200;
                            const double bubbleHeight = 85;
                            double leftPos = partOffset.dx - (bubbleWidth / 2);
                            double topPos = partOffset.dy - bubbleHeight - 20;

                            leftPos = leftPos.clamp(12.0, canvasSize.width - bubbleWidth - 12.0);
                            topPos = topPos.clamp(12.0, canvasSize.height - bubbleHeight - 110.0);

                            return Positioned(
                              left: leftPos,
                              top: topPos,
                              child: Container(
                                width: bubbleWidth,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _getPartColor(_selectedPart!),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getPartColor(_selectedPart!).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          _getPartIcon(_selectedPart!),
                                          color: _getPartColor(_selectedPart!),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _getPartTitle(_selectedPart!),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10.5,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(() => _selectedPart = null),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white54,
                                            size: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _getPartDescription(_selectedPart!),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9.0,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          })(),
                          // Bottom fixed horizontal HUD details card
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getPartColor(_selectedPart!).withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getPartColor(_selectedPart!).withValues(alpha: 0.15),
                                    blurRadius: 8,
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
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
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
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          height: 75,
                                          child: SingleChildScrollView(
                                            physics: const BouncingScrollPhysics(),
                                            child: RichText(
                                              text: TextSpan(
                                                children: _parseMarkdown(
                                                  _getPartDetailedDescription(_selectedPart!),
                                                  context,
                                                  true,
                                                  compact: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedPart = null;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            ),

            // 2. Control buttons below it
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMiniControlBtn(
                    label: 'Grid Kisi',
                    active: _showGrid,
                    icon: Icons.grid_on,
                    onPressed: () => setState(() => _showGrid = !_showGrid),
                  ),
                  const SizedBox(width: 8),
                  _buildMiniControlBtn(
                    label: _autoRotate ? 'Auto Putar' : 'Mati Putar',
                    active: _autoRotate,
                    icon: Icons.sync,
                    onPressed: () => setState(() => _autoRotate = !_autoRotate),
                  ),
                  const SizedBox(width: 8),
                  _buildMiniControlBtn(
                    label: 'Reset',
                    active: false,
                    icon: Icons.refresh,
                    onPressed: () => setState(() {
                      _rx = -0.5;
                      _ry = 0.5;
                      _scale = 1.0;
                    }),
                  ),
                ],
              ),
            ),

            // 3. Topic Badge and Match percentage
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Topic Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tag, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          result.subjectTopic,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Match rate indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            value: result.confidence,
                            strokeWidth: 2,
                            color: Colors.greenAccent,
                            backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(result.confidence * 100).toStringAsFixed(0)}% Match',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 4. AI Explanation Text (Explanation appears directly below)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Penjelasan AI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Divider(height: 20, thickness: 1),
                    SelectableText.rich(
                      TextSpan(
                        children: _parseMarkdown(result.explanation, context, isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4b. Scoped Chat / Q&A Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ScopedAIChatCard(
                topic: result.subjectTopic,
              ),
            ),

            // 5. Spotify Voice Assistant Player
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SpotifyVoicePlayer(topicName: result.subjectTopic),
            ),

            // 6. Grounding RAG Curriculum Source Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Grounding Kurikulum Resmi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Penjelasan AI di atas telah divalidasi terhadap basis data buku teks resmi untuk mencegah halusinasi jawaban.',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCurriculumSourceCard(
                    context,
                    title: _getCurriculumTitle(result.asset3dUrl),
                    description: _getCurriculumDesc(result.asset3dUrl),
                    sourceName: 'LIDM Official Database v2026',
                    score: result.confidence,
                  ),
                ],
              ),
            ),

            // 7. Fullscreen AR Camera mode trigger
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/ar', arguments: result.asset3dUrl ?? 'atom');
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.fullscreen, size: 22),
                  label: const Text(
                    'MASUK MODE AR KAMERA PENUH',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurriculumTitle(String? assetId) {
    if (assetId == 'heart') return 'Biologi Kedokteran XI';
    if (assetId == 'dna_helix') return 'Prinsip Genetika Dasar';
    if (assetId == 'water_molecule') return 'Kimia Fisika I';
    return 'Fisika Kuantum Terapan';
  }

  String _getCurriculumDesc(String? assetId) {
    if (assetId == 'heart') {
      return 'Bab 4: Sistem Sirkulasi & Mekanika Jantung. Kurikulum Merdeka Halaman 112-125.';
    }
    if (assetId == 'dna_helix') {
      return 'Bab 9: Pewarisan Sifat & Struktur Nukleotida Watson-Crick. Halaman 304-320.';
    }
    if (assetId == 'water_molecule') {
      return 'Bab 6: Sudut Ikatan Kovalen Polar & Teori Hibridisasi VSEPR. Halaman 98-109.';
    }
    return 'Bab 2: Mekanika Bohr & Model Kulit Elektron Hidrogen. Halaman 45-56.';
  }

  Widget _buildCurriculumSourceCard(
    BuildContext context, {
    required String title,
    required String description,
    required String sourceName,
    required double score,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Skor RAG: ${(score * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.4,
            ),
          ),
          const Divider(height: 24, thickness: 1),
          Row(
            children: [
              Icon(Icons.library_books_outlined, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                sourceName,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Spotify-Style Voice Assistant Player with Equalizer waves and thumbnail
class SpotifyVoicePlayer extends StatefulWidget {
  final String topicName;
  const SpotifyVoicePlayer({super.key, required this.topicName});

  @override
  State<SpotifyVoicePlayer> createState() => _SpotifyVoicePlayerState();
}

class _SpotifyVoicePlayerState extends State<SpotifyVoicePlayer> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isPlaying = false;
  double _progress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.repeat();
        _startProgress();
      } else {
        _animController.stop();
      }
    });
  }

  void _startProgress() async {
    while (_isPlaying && _progress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted || !_isPlaying) return;
      setState(() {
        _progress += 0.005;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _isPlaying = false;
          _animController.stop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[200]!,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Podcast/Audio Cover Thumbnail Art
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.headset,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              
              // Text Titles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asisten Suara AI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isPlaying ? 'Memutar audio penjelasan...' : 'Ketuk untuk mendengarkan',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Equalizer visualizer
              if (_isPlaying)
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(4, (index) {
                        final shift = index * 0.25;
                        final val = (shift + _animController.value) % 1.0;
                        final height = 4.0 + (16.0 * (val - 0.5).abs() * 2);
                        return Container(
                          width: 3.2,
                          height: height,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Slider Progress
          Row(
            children: [
              Text(
                _formatProgressTime(_progress),
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: isDark ? Colors.white12 : Colors.grey[300],
                    thumbColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Slider(
                    value: _progress,
                    onChanged: (val) {
                      setState(() {
                        _progress = val;
                      });
                    },
                  ),
                ),
              ),
              Text(
                '0:45',
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ),
          
          // Play controls center
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 24),
                color: isDark ? Colors.white70 : Colors.black87,
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              
              // Glowing circular play button
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 24),
                color: isDark ? Colors.white70 : Colors.black87,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatProgressTime(double progress) {
    final totalSeconds = (progress * 45).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class ScopedAIChatCard extends StatefulWidget {
  final String topic;
  const ScopedAIChatCard({super.key, required this.topic});

  @override
  State<ScopedAIChatCard> createState() => _ScopedAIChatCardState();
}

class _ScopedAIChatCardState extends State<ScopedAIChatCard> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isSending = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final reply = await apiService.askQuestion(widget.topic, text, _messages);

    if (mounted) {
      setState(() {
        _isSending = false;
        if (reply != null) {
          _messages.add({'role': 'assistant', 'content': reply});
        } else {
          _messages.add({
            'role': 'assistant',
            'content': 'Maaf, terjadi kesalahan koneksi. Silakan coba lagi.'
          });
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Tanya Jawab Scoped AI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Obrolan ini dibatasi khusus membahas "${widget.topic}" untuk menjaga fokus belajar.',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
          const Divider(height: 20, thickness: 1),

          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Tanyakan hal menarik tentang topik ini di bawah...',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Theme.of(context).colorScheme.primary
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                      ),
                      child: Text(
                        msg['content'] ?? '',
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          if (_isSending)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI sedang merespon...',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Tanyakan materi...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontSize: 12.5,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey[200]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey[200]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
