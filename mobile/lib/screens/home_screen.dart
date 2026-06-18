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

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleScan([String? explicitUrl]) async {
    final url = explicitUrl ?? _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan URL gambar atau gunakan contoh preset'),
          behavior: SnackBarBehavior.floating,
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
        // Save captured image to show preview
        apiService.setCapturedImage(photo);
        
        if (!mounted) return;
        
        // Show dialog to let user choose/type context of the scanned page
        final String? contextText = await showDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            final textController = TextEditingController();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  title: Row(
                    children: [
                      Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        'Analisis AI Multimodal',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gambar berhasil diambil!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan petunjuk materi halaman yang Anda foto atau pilih topik di bawah ini untuk RAG:',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            labelText: 'Konteks/Kata Kunci Materi (Opsional)',
                            hintText: 'Misal: jantung, dna, h2o, atom...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (val) {
                            setDialogState(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Rekomendasi Topik:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
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
                      onPressed: () {
                        Navigator.pop(context, null);
                      },
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context, textController.text.trim());
                      },
                      child: const Text('Mulai Analisis', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              }
            );
          },
        );
        
        if (contextText != null) {
          // Trigger file upload and analysis
          final result = await apiService.uploadScan(photo, context: contextText);
          
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

  Widget _buildDialogChip(BuildContext context, String label, VoidCallback onTap, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.25)
              : (isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hai, Pelajar! 👋',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mau belajar apa hari ini?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                        color: isDark ? Colors.yellowAccent : Theme.of(context).colorScheme.primary,
                        tooltip: isDark ? 'Aktifkan Mode Terang' : 'Aktifkan Mode Gelap',
                        onPressed: () {
                          apiService.toggleTheme();
                        },
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=150',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Student statistics panel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(context, '4', 'Kelas Aktif', Icons.menu_book, Colors.blueAccent),
                    _buildStatItem(context, '12', 'Model 3D', Icons.view_in_ar, Colors.purpleAccent),
                    _buildStatItem(context, '94%', 'Grounded RAG', Icons.verified_user, Colors.greenAccent),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Scanner / Input Panel Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_enhance,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Pindai Buku Cetak',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Masukkan URL gambar halaman buku Anda atau ketuk ikon kamera untuk mengambil foto.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Large, Prominent Camera Scanner Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.white30, width: 1.5),
                          ),
                        ),
                        onPressed: _handleCameraScan,
                        icon: const Icon(Icons.camera_alt, size: 24),
                        label: const Text(
                          'BUKA KAMERA SCANNER (AMBIL FOTO)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 18),
                    
                    // Visual separator
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white24, height: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ATAU GUNAKAN TAUTAN GAMBAR',
                            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white24, height: 1)),
                      ],
                    ),
                    
                    const SizedBox(height: 18),

                    TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'https://example.com/halaman-buku.jpg',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.link, color: Colors.white70),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white70),
                              tooltip: 'Ambil Foto Buku',
                              onPressed: _handleCameraScan,
                            ),
                            if (_urlController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white70),
                                onPressed: () {
                                  setState(() {
                                    _urlController.clear();
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      onChanged: (text) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 14),
                    
                    // Quick Presets
                    const Text(
                      'Coba Contoh Cepat:',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip(context, '❤️ Jantung', 'https://images.unsplash.com/photo-1530026405186-ed1ea0ac7a63'),
                        _buildPresetChip(context, '🧬 DNA Helix', 'https://images.unsplash.com/photo-1507679799987-c73779587ccf'),
                        _buildPresetChip(context, '💧 Molekul H2O', 'https://images.unsplash.com/photo-1544383835-bda2bc66a55d'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: apiService.isLoading ? null : () {
                          apiService.setCapturedImage(null);
                          _handleScan();
                        },
                        icon: apiService.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const Icon(Icons.psychology),
                        label: Text(
                          apiService.isLoading ? 'Menganalisis...' : 'Analisis & Jelaskan',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Scan History Section
              if (apiService.history.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Pemindaian',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () {}, 
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: apiService.history.length,
                    itemBuilder: (context, index) {
                      final item = apiService.history[index];
                      return GestureDetector(
                        onTap: () {
                          apiService.setCapturedImage(null);
                          apiService.selectResult(item);
                          Navigator.pushNamed(context, '/result');
                        },
                        child: Container(
                          width: 210,
                          margin: const EdgeInsets.only(right: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    item.asset3dUrl == 'heart'
                                        ? Icons.favorite
                                        : item.asset3dUrl == 'dna_helix'
                                            ? Icons.bubble_chart
                                            : Icons.science,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.subjectTopic,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.explanation.replaceAll(RegExp(r'[#\*]'), ''),
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.green[400], size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Kecocokan ${(item.confidence * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: Colors.green[400],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
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
                ),
                const SizedBox(height: 28),
              ],

              // Explore 3D Catalog Grid
              Text(
                'Eksplorasi Model 3D AR',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
                children: [
                  _buildCatalogCard(
                    context,
                    title: 'Jantung Manusia',
                    subtitle: 'Kardiologi & Aliran Darah',
                    icon: Icons.favorite,
                    assetId: 'heart',
                    color: Colors.redAccent,
                  ),
                  _buildCatalogCard(
                    context,
                    title: 'Heliks DNA',
                    subtitle: 'Genetika & Struktur Kromosom',
                    icon: Icons.bubble_chart,
                    assetId: 'dna_helix',
                    color: Colors.blueAccent,
                  ),
                  _buildCatalogCard(
                    context,
                    title: 'Molekul Air H2O',
                    subtitle: 'Kepolaran & Sudut Kovalen',
                    icon: Icons.science,
                    assetId: 'water_molecule',
                    color: Colors.teal,
                  ),
                  _buildCatalogCard(
                    context,
                    title: 'Model Bohr Atom',
                    subtitle: 'Fisika Kuantum & Orbit Elektron',
                    icon: Icons.wb_sunny,
                    assetId: 'atom',
                    color: Colors.orangeAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetChip(BuildContext context, String label, String url) {
    return GestureDetector(
      onTap: () {
        context.read<ApiService>().setCapturedImage(null);
        _handleScan(url);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String assetId,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  color.withOpacity(0.04),
                ]
              : [
                  Colors.white,
                  color.withOpacity(0.03),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark
              ? color.withOpacity(0.2)
              : color.withOpacity(0.15),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.read<ApiService>().setCapturedImage(null);
            Navigator.pushNamed(context, '/ar', arguments: assetId);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 10,
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
    );
  }
}
