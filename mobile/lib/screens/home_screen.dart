import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                      'Masukkan URL gambar halaman buku Anda untuk mendapatkan penjelasan AI dan objek AR.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                      ),
                    ),
                    const SizedBox(height: 12),
                    
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
                        _buildPresetChip('❤️ Jantung', 'https://images.unsplash.com/photo-1530026405186-ed1ea0ac7a63'),
                        _buildPresetChip('🧬 DNA Helix', 'https://images.unsplash.com/photo-1507679799987-c73779587ccf'),
                        _buildPresetChip('💧 Molekul H2O', 'https://images.unsplash.com/photo-1544383835-bda2bc66a55d'),
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
                        onPressed: apiService.isLoading ? null : () => _handleScan(),
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
                      onPressed: () {}, // Clear history / View all
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
                          apiService.selectResult(item);
                          Navigator.pushNamed(context, '/result');
                        },
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                            ),
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
                                item.explanation,
                                style: TextStyle(
                                  color: Colors.grey[500],
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
                    color: Colors.tealAccent,
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

  Widget _buildPresetChip(String label, String url) {
    return GestureDetector(
      onTap: () => _handleScan(url),
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

    return Card(
      elevation: isDark ? 4 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
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
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
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
    );
  }
}
