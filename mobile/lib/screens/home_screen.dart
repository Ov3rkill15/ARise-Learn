import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/live_camera_dialog.dart';
import 'scan_result_screen.dart';
import 'ar_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _urlController = TextEditingController();
  late AnimationController _breathController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _breathController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _handleScan([String? explicitUrl]) async {
    final url = explicitUrl ?? _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Masukkan URL gambar atau gunakan contoh preset'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (explicitUrl != null) {
      _urlController.text = explicitUrl;
    }

    final apiService = context.read<ApiService>();
    final result = await apiService.submitScan(url);

    if (!mounted) return;

    if (result != null) {
      Navigator.pushNamed(context, '/result');
    } else if (apiService.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiService.error!),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleCameraScan() async {
    final apiService = context.read<ApiService>();

    try {
      final XFile? photo = await showDialog<XFile>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LiveCameraDialog(),
      );

      if (photo != null) {
        apiService.setCapturedImage(photo);

        if (!mounted) return;

        final String? contextText = await showDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            final textController = TextEditingController();
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return StatefulBuilder(builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                backgroundColor:
                    isDark ? const Color(0xFF1A1F35) : Colors.white,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.psychology,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Analisis AI Multimodal',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Gambar berhasil diambil!',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Masukkan petunjuk materi halaman yang Anda foto atau pilih topik di bawah ini:',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          labelText: 'Konteks/Kata Kunci Materi (Opsional)',
                          hintText: 'Misal: jantung, dna, h2o, atom...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onChanged: (val) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'REKOMENDASI TOPIK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildDialogChip(context, '❤️ Jantung', () {
                            textController.text = 'jantung';
                            setDialogState(() {});
                          }, textController.text == 'jantung'),
                          _buildDialogChip(context, '🧬 DNA Helix', () {
                            textController.text = 'dna helix';
                            setDialogState(() {});
                          }, textController.text == 'dna helix'),
                          _buildDialogChip(context, '💧 Molekul H2O', () {
                            textController.text = 'molekul h2o';
                            setDialogState(() {});
                          }, textController.text == 'molekul h2o'),
                          _buildDialogChip(context, '⚛️ Atom Bohr', () {
                            textController.text = 'atom bohr';
                            setDialogState(() {});
                          }, textController.text == 'atom bohr'),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text('Batal',
                        style: TextStyle(color: Colors.grey[500])),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: () =>
                        Navigator.pop(context, textController.text.trim()),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Mulai Analisis',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            });
          },
        );

        if (contextText != null) {
          final result =
              await apiService.uploadScan(photo, context: contextText);

          if (!mounted) return;

          if (result != null) {
            Navigator.pushNamed(context, '/result');
          } else if (apiService.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(apiService.error!),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        } else {
          apiService.setCapturedImage(null);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengakses kamera atau mengunggah: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDialogChip(
      BuildContext context, String label, VoidCallback onTap, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiService = context.watch<ApiService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 720;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background orbs
          ..._buildBackgroundOrbs(isDark, scheme),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? screenWidth * 0.08 : 20.0,
                vertical: 16.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ──
                      _buildHeader(context, apiService, isDark, scheme),
                      const SizedBox(height: 20),

                      // ── Stats Row ──
                      _buildStatsPanel(context, isDark, scheme),
                      const SizedBox(height: 28),

                      // ── Scanner Hero Card ──
                      _buildScannerHeroCard(context, apiService, isDark, scheme),
                      const SizedBox(height: 32),

                      // ── Scan History ──
                      if (apiService.history.isNotEmpty) ...[
                        _buildSectionHeader(context, 'Riwayat Pemindaian',
                            Icons.history_rounded, isDark),
                        const SizedBox(height: 12),
                        _buildHistoryList(context, apiService, isDark, scheme),
                        const SizedBox(height: 32),
                      ],

                      // ── 3D Catalog ──
                      _buildSectionHeader(context, 'Eksplorasi Model 3D AR',
                          Icons.view_in_ar_rounded, isDark),
                      const SizedBox(height: 14),
                      _buildCatalogGrid(context, isDark, scheme),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ BACKGROUND ORBS ═══════════════════
  List<Widget> _buildBackgroundOrbs(bool isDark, ColorScheme scheme) {
    if (!isDark) return [];
    return [
      AnimatedBuilder(
        animation: _breathController,
        builder: (_, __) {
          final t = _breathController.value;
          return Positioned(
            top: -80 + t * 20,
            right: -60 + t * 10,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.primary.withOpacity(0.08 + t * 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _breathController,
        builder: (_, __) {
          final t = _breathController.value;
          return Positioned(
            bottom: -100 + t * 15,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.secondary.withOpacity(0.06 + t * 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  // ═══════════════════ HEADER ═══════════════════
  Widget _buildHeader(
      BuildContext context, ApiService apiService, bool isDark, ColorScheme scheme) {
    return Row(
      children: [
        // Logo & Title
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [scheme.primary, scheme.secondary],
                    ).createShader(bounds),
                    child: Text(
                      'ARise Learn',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  Text(
                    'Belajar Interaktif dengan AR & AI',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 11.5,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Theme toggle
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  RotationTransition(turns: anim, child: child),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                size: 20,
              ),
            ),
            color: isDark ? Colors.amber : scheme.primary,
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => apiService.toggleTheme(),
          ),
        ),
        const SizedBox(width: 10),
        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2.5),
          child: const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=150',
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════ STATS PANEL ═══════════════════
  Widget _buildStatsPanel(BuildContext context, bool isDark, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.12),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(context, '4', 'Kelas Aktif', Icons.school_rounded,
              const Color(0xFF60A5FA), isDark),
          _buildStatDivider(isDark),
          _buildStatItem(context, '12', 'Model 3D', Icons.view_in_ar_rounded,
              const Color(0xFFA78BFA), isDark),
          _buildStatDivider(isDark),
          _buildStatItem(context, '94%', 'RAG Score', Icons.verified_rounded,
              const Color(0xFF34D399), isDark),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.grey.withOpacity(0.15),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label,
      IconData icon, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════ SCANNER HERO CARD ═══════════════════
  Widget _buildScannerHeroCard(
      BuildContext context, ApiService apiService, bool isDark, ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (_, __) {
        final t = _breathController.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, scheme.secondary, 0.3 + t * 0.15)!,
                scheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.25 + t * 0.1),
                blurRadius: 24 + t * 8,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: scheme.secondary.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Decorative pattern
                Positioned(
                  top: -40,
                  right: -40,
                  child: Opacity(
                    opacity: 0.08,
                    child: Icon(Icons.camera_enhance_rounded,
                        size: 200, color: Colors.white),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -20,
                  child: Opacity(
                    opacity: 0.05,
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 150, color: Colors.white),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.document_scanner_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pindai Buku Cetak',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'AI akan menganalisis & membuat model 3D',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Camera Button — BIG & prominent
                      _buildCameraButton(apiService),
                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Colors.white.withOpacity(0.15),
                                  height: 1)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'ATAU TEMPEL TAUTAN',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Colors.white.withOpacity(0.15),
                                  height: 1)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // URL Input
                      _buildUrlInput(apiService),
                      const SizedBox(height: 16),

                      // Quick presets
                      Text(
                        'COBA CONTOH CEPAT',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPresetChip(context, '❤️ Jantung',
                              'https://images.unsplash.com/photo-1530026405186-ed1ea0ac7a63'),
                          _buildPresetChip(context, '🧬 DNA',
                              'https://images.unsplash.com/photo-1507679799987-c73779587ccf'),
                          _buildPresetChip(context, '💧 H2O',
                              'https://images.unsplash.com/photo-1544383835-bda2bc66a55d'),
                          _buildPresetChip(context, '⚛️ Atom',
                              'https://images.unsplash.com/photo-1635070041078-e363dbe005cb'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraButton(ApiService apiService) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.5),
          ),
        ),
        onPressed: apiService.isLoading ? null : _handleCameraScan,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 20),
            ),
            const SizedBox(width: 14),
            const Text(
              'BUKA KAMERA SCANNER',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput(ApiService apiService) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://example.com/halaman-buku.jpg',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 12.5),
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.link_rounded,
                    color: Colors.white.withOpacity(0.5), size: 20),
              ),
              onChanged: (text) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: SizedBox(
              height: 40,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                onPressed: apiService.isLoading
                    ? null
                    : () {
                        apiService.setCapturedImage(null);
                        _handleScan();
                      },
                child: apiService.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        children: [
                          Icon(Icons.psychology_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Analisis',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ SECTION HEADER ═══════════════════
  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 16, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Lihat Semua',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ═══════════════════ HISTORY LIST ═══════════════════
  Widget _buildHistoryList(
      BuildContext context, ApiService apiService, bool isDark, ColorScheme scheme) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: apiService.history.length,
        itemBuilder: (context, index) {
          final item = apiService.history[index];
          final cardColors = [
            [const Color(0xFFEF4444), const Color(0xFFF97316)],
            [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
            [const Color(0xFF14B8A6), const Color(0xFF06B6D4)],
            [const Color(0xFFF59E0B), const Color(0xFFF97316)],
          ];
          final colors = cardColors[index % cardColors.length];

          return GestureDetector(
            onTap: () {
              apiService.setCapturedImage(null);
              apiService.selectResult(item);
              Navigator.pushNamed(context, '/result');
            },
            child: Container(
              width: 230,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.02),
                        ]
                      : [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(isDark ? 0.08 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Gradient accent bar at top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colors),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: colors),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  item.asset3dUrl == 'heart'
                                      ? Icons.favorite_rounded
                                      : item.asset3dUrl == 'dna_helix'
                                          ? Icons.bubble_chart_rounded
                                          : item.asset3dUrl == 'water_molecule'
                                              ? Icons.water_drop_rounded
                                              : Icons.science_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.subjectTopic,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.explanation
                                .replaceAll(RegExp(r'[#\*]'), ''),
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 11,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: Colors.green[400], size: 11),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(item.confidence * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: Colors.green[400],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════ CATALOG GRID ═══════════════════
  Widget _buildCatalogGrid(BuildContext context, bool isDark, ColorScheme scheme) {
    final items = [
      _CatalogItem('Jantung Manusia', 'Kardiologi & Aliran Darah',
          Icons.favorite_rounded, 'heart', const Color(0xFFEF4444), const Color(0xFFF97316)),
      _CatalogItem('Heliks DNA', 'Genetika & Kromosom',
          Icons.bubble_chart_rounded, 'dna_helix', const Color(0xFF3B82F6), const Color(0xFF8B5CF6)),
      _CatalogItem('Molekul H₂O', 'Kepolaran & Ikatan Kovalen',
          Icons.water_drop_rounded, 'water_molecule', const Color(0xFF14B8A6), const Color(0xFF06B6D4)),
      _CatalogItem('Model Bohr', 'Fisika Kuantum & Orbit',
          Icons.wb_sunny_rounded, 'atom', const Color(0xFFF59E0B), const Color(0xFFF97316)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCatalogCard(context, item, isDark, index);
      },
    );
  }

  Widget _buildCatalogCard(
      BuildContext context, _CatalogItem item, bool isDark, int index) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (_, __) {
        final offset = math.sin(_floatController.value * math.pi + index * 0.8) * 3;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.05),
                        item.color1.withOpacity(0.06),
                      ]
                    : [
                        Colors.white,
                        item.color1.withOpacity(0.04),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isDark
                    ? item.color1.withOpacity(0.15)
                    : item.color1.withOpacity(0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.color1.withOpacity(isDark ? 0.1 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  context.read<ApiService>().setCapturedImage(null);
                  Navigator.pushNamed(context, '/ar', arguments: item.assetId);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [item.color1, item.color2],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: item.color1.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(item.icon,
                                color: Colors.white, size: 22),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.grey.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.view_in_ar_rounded,
                              size: 14,
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetChip(BuildContext context, String label, String url) {
    return GestureDetector(
      onTap: () {
        context.read<ApiService>().setCapturedImage(null);
        _handleScan(url);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CatalogItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String assetId;
  final Color color1;
  final Color color2;

  _CatalogItem(
      this.title, this.subtitle, this.icon, this.assetId, this.color1, this.color2);
}
