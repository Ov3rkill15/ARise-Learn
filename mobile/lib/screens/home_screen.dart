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
  int _currentNav = 0;
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                backgroundColor: isDark ? const Color(0xFF1C1B2E) : Colors.white,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.tertiary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Analisis AI Multimodal',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.green[400], size: 18),
                            const SizedBox(width: 10),
                            Text('Gambar berhasil diambil!',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green[400])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Masukkan petunjuk materi atau pilih topik:',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[600], height: 1.5)),
                      const SizedBox(height: 14),
                      TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          labelText: 'Konteks Materi (Opsional)',
                          hintText: 'jantung, dna, h2o, atom...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onChanged: (val) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Text('TOPIK CEPAT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: isDark ? Colors.grey[500] : Colors.grey[400])),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDialogChip(context, '❤️ Jantung', () { textController.text = 'jantung'; setDialogState(() {}); }, textController.text == 'jantung'),
                          _buildDialogChip(context, '🧬 DNA Helix', () { textController.text = 'dna helix'; setDialogState(() {}); }, textController.text == 'dna helix'),
                          _buildDialogChip(context, '💧 Molekul H2O', () { textController.text = 'molekul h2o'; setDialogState(() {}); }, textController.text == 'molekul h2o'),
                          _buildDialogChip(context, '⚛️ Atom Bohr', () { textController.text = 'atom bohr'; setDialogState(() {}); }, textController.text == 'atom bohr'),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text('Batal', style: TextStyle(color: Colors.grey[500])),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, textController.text.trim()),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Mulai Analisis', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            });
          },
        );
        if (contextText != null) {
          final result = await apiService.uploadScan(photo, context: contextText);
          if (!mounted) return;
          if (result != null) {
            Navigator.pushNamed(context, '/result');
          } else if (apiService.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(apiService.error!), behavior: SnackBarBehavior.floating, backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        } else {
          apiService.setCapturedImage(null);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengakses kamera: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Widget _buildDialogChip(BuildContext context, String label, VoidCallback onTap, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Theme.of(context).colorScheme.primary : (isDark ? Colors.white70 : Colors.black87),
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiService = context.watch<ApiService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    Widget bodyWidget;
    switch (_currentNav) {
      case 1:
        bodyWidget = _buildPindaiTab(context, apiService, isDark, scheme);
        break;
      case 2:
        bodyWidget = _buildModel3DTab(context, apiService, isDark, scheme);
        break;
      case 3:
        bodyWidget = _buildProfilTab(context, apiService, isDark, scheme);
        break;
      case 0:
      default:
        bodyWidget = _buildBerandaTab(context, apiService, isDark, scheme);
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: bodyWidget,
      ),
      bottomNavigationBar: _buildBottomNav(isDark, scheme),
    );
  }

  Widget _buildBerandaTab(BuildContext context, ApiService apiService, bool isDark, ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, apiService, isDark, scheme),
              const SizedBox(height: 24),
              _buildDashboardCard(context, isDark, scheme),
              const SizedBox(height: 24),
              _buildQuickActions(context, isDark, scheme),
              const SizedBox(height: 28),
              _buildStatsRow(context, isDark, scheme),
              const SizedBox(height: 28),
              if (apiService.history.isNotEmpty) ...[
                _buildSectionTitle(context, 'Riwayat Pemindaian', Icons.history_rounded, isDark),
                const SizedBox(height: 14),
                _buildHistoryList(context, apiService, isDark, scheme),
                const SizedBox(height: 28),
              ],
              _buildSectionTitle(context, 'Eksplorasi Model 3D', Icons.view_in_ar_rounded, isDark),
              const SizedBox(height: 14),
              _buildCatalogGrid(context, isDark, scheme),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPindaiTab(BuildContext context, ApiService apiService, bool isDark, ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, apiService, isDark, scheme),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.04),
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary.withOpacity(0.15), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(70),
                    child: AnimatedBuilder(
                      animation: _breathController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: RadarScannerPainter(_breathController.value, scheme.primary),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildWelcomeBanner(context, apiService, isDark, scheme),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModel3DTab(BuildContext context, ApiService apiService, bool isDark, ColorScheme scheme) {
    final searchController = TextEditingController(text: _searchQuery);
    searchController.selection = TextSelection.fromPosition(TextPosition(offset: searchController.text.length));

    final items = [
      _CatalogItem('Jantung Manusia', 'Kardiologi & Aliran Darah', Icons.favorite_rounded, 'heart', const Color(0xFFEF4444), const Color(0xFFF97316), 'Biologi'),
      _CatalogItem('Heliks DNA', 'Genetika & Kromosom', Icons.bubble_chart_rounded, 'dna_helix', const Color(0xFF3B82F6), const Color(0xFF8B5CF6), 'Biologi'),
      _CatalogItem('Molekul H₂O', 'Kepolaran & Ikatan Kovalen', Icons.water_drop_rounded, 'water_molecule', const Color(0xFF14B8A6), const Color(0xFF06B6D4), 'Kimia'),
      _CatalogItem('Model Bohr', 'Fisika Kuantum & Orbit', Icons.wb_sunny_rounded, 'atom', const Color(0xFFF59E0B), const Color(0xFFF97316), 'Fisika'),
    ];

    final filteredItems = items.where((item) {
      final matchesCategory = _selectedCategory == 'Semua' || item.category == _selectedCategory;
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, apiService, isDark, scheme),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15)),
                  boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  controller: searchController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari model 3D (jantung, dna, dll)...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: scheme.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['Semua', 'Biologi', 'Kimia', 'Fisika'].map((cat) {
                    final isCatSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isCatSelected ? LinearGradient(colors: [scheme.primary, scheme.tertiary]) : null,
                          color: isCatSelected ? null : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCatSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.grey[300]!),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCatSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              if (filteredItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[500]),
                        const SizedBox(height: 12),
                        Text(
                          'Model tidak ditemukan',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildCatalogCard(context, item, isDark, index);
                  },
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilTab(BuildContext context, ApiService apiService, bool isDark, ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, apiService, isDark, scheme),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15)),
                  boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=150',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'ARise Explorer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pangkat: Penjelajah Sains',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Level 4 (Orde Atom)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('1.450 / 2.000 XP', style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.725,
                        minHeight: 6,
                        color: scheme.primary,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildProfileStatCard('14', 'Scan Sukses', Icons.qr_code_scanner_rounded, const Color(0xFF60A5FA), isDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProfileStatCard('8', 'Pencapaian', Icons.emoji_events_rounded, const Color(0xFFFBBF24), isDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProfileStatCard('94%', 'Akurasi RAG', Icons.verified_user_rounded, const Color(0xFF34D399), isDark),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.emoji_events_outlined, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  const Text('Pencapaian Unlocked', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildBadgeCard('Pakar Atom', '⚛️', 'Pindai model Atom Bohr', true, isDark),
                    _buildBadgeCard('Peneliti DNA', '🧬', 'Pindai model Helix DNA', true, isDark),
                    _buildBadgeCard('Pencari Air', '💧', 'Pindai model Molekul H2O', true, isDark),
                    _buildBadgeCard('Ahli Jantung', '❤️', 'Pindai model Jantung', false, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: scheme.primary),
                      title: const Text('Mode Gelap / Terang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) => apiService.toggleTheme(),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.cloud_done_rounded, color: Colors.green[400]),
                      title: const Text('Grounding Kurikulum Resmi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Validasi RAG aktif & tersertifikasi', style: TextStyle(fontSize: 10)),
                      trailing: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      title: const Text('Hapus Riwayat Belajar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Hapus Riwayat'),
                            content: const Text('Apakah Anda yakin ingin menghapus semua riwayat pemindaian?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  apiService.clearHistory();
                                  Navigator.pop(context);
                                },
                                child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStatCard(String value, String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(String title, String emoji, String desc, bool unlocked, bool isDark) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? const Color(0xFFFBBF24).withOpacity(0.2)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(fontSize: 8, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, bool isDark, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E38), const Color(0xFF131224)]
              : [scheme.primary.withOpacity(0.06), scheme.tertiary.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: scheme.primary.withOpacity(isDark ? 0.2 : 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.insights_rounded, color: scheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progres Pembelajaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tingkat pemahaman materi sains',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Topik Terkuasai',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                '3 / 4 Topik (75%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => setState(() => _currentNav = 1),
              icon: const Icon(Icons.document_scanner_rounded, size: 18),
              label: const Text(
                'MULAI SCAN BUKU CETAK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1B2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Beranda', 0, isDark, scheme),
              _buildNavItem(Icons.search_rounded, 'Pindai', 1, isDark, scheme),
              _buildNavItem(Icons.view_in_ar_rounded, 'Model 3D', 2, isDark, scheme),
              _buildNavItem(Icons.person_rounded, 'Profil', 3, isDark, scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark, ColorScheme scheme) {
    final isActive = _currentNav == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNav = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? LinearGradient(colors: [scheme.primary, scheme.tertiary]) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? Colors.white : (isDark ? Colors.grey[500] : Colors.grey[500])),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ApiService apiService, bool isDark, ColorScheme scheme) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary.withOpacity(0.3), width: 2),
          ),
          padding: const EdgeInsets.all(2),
          child: const CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=150',
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selamat Datang 👋', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[500], fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('ARise Learn', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => apiService.toggleTheme(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : scheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20, color: isDark ? Colors.amber[300] : scheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, ApiService apiService, bool isDark, ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (_, __) {
        final t = _breathController.value;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, scheme.tertiary, 0.4 + t * 0.2)!,
                scheme.tertiary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.3 + t * 0.1),
                blurRadius: 28 + t * 12,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pindai Buku Cetak', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Text('AI menganalisis & membuat model 3D interaktif', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: apiService.isLoading ? null : _handleCameraScan,
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: const Text('BUKA KAMERA SCANNER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2), height: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('ATAU TEMPEL URL', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2), height: 1)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'https://example.com/halaman-buku.jpg',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.link_rounded, color: Colors.white.withOpacity(0.5), size: 20),
                        ),
                        onChanged: (text) => setState(() {}),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: scheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          onPressed: apiService.isLoading ? null : () { apiService.setCapturedImage(null); _handleScan(); },
                          child: apiService.isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Row(children: [Icon(Icons.send_rounded, size: 18), SizedBox(width: 6), Text('Kirim', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('COBA CONTOH CEPAT', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetChip(context, '❤️ Jantung', 'https://images.unsplash.com/photo-1530026405186-ed1ea0ac7a63'),
                  _buildPresetChip(context, '🧬 DNA', 'https://images.unsplash.com/photo-1507679799987-c73779587ccf'),
                  _buildPresetChip(context, '💧 H2O', 'https://images.unsplash.com/photo-1544383835-bda2bc66a55d'),
                  _buildPresetChip(context, '⚛️ Atom', 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark, ColorScheme scheme) {
    final actions = [
      _QuickAction('Scan Buku', 'Analisis AI', Icons.auto_stories_rounded, const Color(0xFF6366F1), const Color(0xFF8B5CF6)),
      _QuickAction('Model 3D', 'Lihat Katalog', Icons.view_in_ar_rounded, const Color(0xFF06B6D4), const Color(0xFF14B8A6)),
      _QuickAction('AR Mode', 'Augmented Reality', Icons.camera_rounded, const Color(0xFFF59E0B), const Color(0xFFF97316)),
    ];
    return SizedBox(
      height: 125,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: () {
              if (index == 0) {
                setState(() => _currentNav = 1);
              } else if (index == 1) {
                setState(() => _currentNav = 2);
              } else if (index == 2) {
                Navigator.pushNamed(context, '/ar', arguments: 'atom');
              }
            },
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [action.color1.withOpacity(0.15), action.color2.withOpacity(0.08)]
                      : [action.color1.withOpacity(0.08), action.color2.withOpacity(0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: action.color1.withOpacity(isDark ? 0.2 : 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [action.color1, action.color2]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action.icon, color: Colors.white, size: 18),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        action.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isDark, ColorScheme scheme) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('4', 'Kelas Aktif', Icons.school_rounded, const Color(0xFF60A5FA), isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('12', 'Model 3D', Icons.view_in_ar_rounded, const Color(0xFFA78BFA), isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('94%', 'RAG Score', Icons.verified_rounded, const Color(0xFF34D399), isDark)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() => _currentNav = 2),
          child: Text('Lihat Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
        ),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context, ApiService apiService, bool isDark, ColorScheme scheme) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: apiService.history.length,
        itemBuilder: (context, index) {
          final item = apiService.history[index];
          final colorPairs = [
            [const Color(0xFFEF4444), const Color(0xFFF97316)],
            [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
            [const Color(0xFF14B8A6), const Color(0xFF06B6D4)],
            [const Color(0xFFF59E0B), const Color(0xFFF97316)],
          ];
          final colors = colorPairs[index % colorPairs.length];
          return GestureDetector(
            onTap: () {
              apiService.setCapturedImage(null);
              apiService.selectResult(item);
              Navigator.pushNamed(context, '/result');
            },
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
                boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  children: [
                    Container(height: 3, decoration: BoxDecoration(gradient: LinearGradient(colors: colors))),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(
                                    item.asset3dUrl == 'heart' ? Icons.favorite_rounded
                                        : item.asset3dUrl == 'dna_helix' ? Icons.bubble_chart_rounded
                                        : item.asset3dUrl == 'water_molecule' ? Icons.water_drop_rounded
                                        : Icons.science_rounded,
                                    color: Colors.white, size: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(item.subjectTopic, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item.explanation.replaceAll(RegExp(r'[#\*]'), ''),
                                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Colors.green[400], size: 11),
                                      const SizedBox(width: 4),
                                      Text('${(item.confidence * 100).toStringAsFixed(0)}%', style: TextStyle(color: Colors.green[400], fontSize: 10, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                              ],
                            ),
                          ],
                        ),
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

  Widget _buildCatalogGrid(BuildContext context, bool isDark, ColorScheme scheme) {
    final items = [
      _CatalogItem('Jantung Manusia', 'Kardiologi & Aliran Darah', Icons.favorite_rounded, 'heart', const Color(0xFFEF4444), const Color(0xFFF97316), 'Biologi'),
      _CatalogItem('Heliks DNA', 'Genetika & Kromosom', Icons.bubble_chart_rounded, 'dna_helix', const Color(0xFF3B82F6), const Color(0xFF8B5CF6), 'Biologi'),
      _CatalogItem('Molekul H₂O', 'Kepolaran & Ikatan Kovalen', Icons.water_drop_rounded, 'water_molecule', const Color(0xFF14B8A6), const Color(0xFF06B6D4), 'Kimia'),
      _CatalogItem('Model Bohr', 'Fisika Kuantum & Orbit', Icons.wb_sunny_rounded, 'atom', const Color(0xFFF59E0B), const Color(0xFFF97316), 'Fisika'),
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

  Widget _buildCatalogCard(BuildContext context, _CatalogItem item, bool isDark, int index) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (_, __) {
        final offset = math.sin(_floatController.value * math.pi + index * 0.8) * 3;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.white.withOpacity(0.06), item.color1.withOpacity(0.08)]
                    : [Colors.white, item.color1.withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: item.color1.withOpacity(isDark ? 0.15 : 0.12), width: 1.2),
              boxShadow: [BoxShadow(color: item.color1.withOpacity(isDark ? 0.1 : 0.06), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  context.read<ApiService>().setCapturedImage(null);
                  Navigator.pushNamed(context, '/ar', arguments: item.assetId);
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [item.color1, item.color2]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: item.color1.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Icon(item.icon, color: Colors.white, size: 24),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.arrow_outward_rounded, size: 14, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2)),
                          const SizedBox(height: 4),
                          Text(item.subtitle, style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class RadarScannerPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  RadarScannerPainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Draw grid rings
    final paintRing = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * (i / 3), paintRing);
    }

    // Draw sweep lines
    final paintSweep = Paint()
      ..style = PaintingStyle.fill
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.0), color.withOpacity(0.2), color.withOpacity(0.0)],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(animationValue * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    
    canvas.drawCircle(center, maxRadius, paintSweep);

    // Draw active scanning ray
    final rayPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2.0;
    final angle = animationValue * 2 * math.pi;
    canvas.drawLine(
      center,
      Offset(center.dx + maxRadius * math.cos(angle), center.dy + maxRadius * math.sin(angle)),
      rayPaint,
    );

    // Draw center dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant RadarScannerPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue || oldDelegate.color != color;
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color1;
  final Color color2;
  _QuickAction(this.title, this.subtitle, this.icon, this.color1, this.color2);
}

class _CatalogItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String assetId;
  final Color color1;
  final Color color2;
  final String category;
  _CatalogItem(this.title, this.subtitle, this.icon, this.assetId, this.color1, this.color2, this.category);
}
