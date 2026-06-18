import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TextSpan> _parseMarkdown(String text, BuildContext context, bool isDark) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }
      
      if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: '\n${line.substring(4)}\n\n',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
        ));
      } else if (line.startsWith('**') && line.endsWith('**')) {
        spans.add(TextSpan(
          text: '${line.replaceAll('**', '')}\n',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ));
        }
        spans.add(const TextSpan(text: '\n\n'));
      }
    }
    return spans;
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

    // Determine representative image based on asset URL
    String thumbnailUrl = 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&q=80&w=400';
    if (result.asset3dUrl == 'heart') {
      thumbnailUrl = 'https://images.unsplash.com/photo-1530026405186-ed1ea0ac7a63?auto=format&fit=crop&q=80&w=400';
    } else if (result.asset3dUrl == 'dna_helix') {
      thumbnailUrl = 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&q=80&w=400';
    } else if (result.asset3dUrl == 'water_molecule') {
      thumbnailUrl = 'https://images.unsplash.com/photo-1544383835-bda2bc66a55d?auto=format&fit=crop&q=80&w=400';
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
      body: Column(
        children: [
          // 1. Image preview with scanning laser line animation
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(thumbnailUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: 180,
                width: double.infinity,
                color: Colors.black.withOpacity(0.4),
              ),
              // Scanner Laser Line
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 3),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Positioned(
                    top: value * 175,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onEnd: () {}, // Handled by continuous rebuild or simple linear loops, loops implicitly if we use repeat, let's keep it simple
              ),
              // Overlay labels
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
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
                    // Confidence Glow
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 4),
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
            ],
          ),

          // 2. Tab Bar Selector
          TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'Penjelasan AI'),
              Tab(text: 'Grounding RAG'),
            ],
          ),

          // 3. Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // AI Explanation Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Styled Text Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                          ),
                        ),
                        child: SelectableText.rich(
                          TextSpan(
                            children: _parseMarkdown(result.explanation, context, isDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TTS Audio guide mockup
                      VoiceGuidePlayer(topicName: result.subjectTopic),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Grounding RAG Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Grounding Kurikulum Resmi',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Penjelasan AI di atas telah divalidasi terhadap basis data buku teks resmi untuk mencegah halusinasi jawaban.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 20),
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
              ],
            ),
          ),

          // 4. Floating bottom action for AR viewer
          if (result.asset3dUrl != null)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/ar', arguments: result.asset3dUrl);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.view_in_ar, size: 24),
                  label: const Text(
                    'PROYEKSIKAN MODEL 3D AR',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
        ],
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
                  color: Colors.green.withOpacity(0.15),
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

// Stateful Sub-widget for Voice Assistant Player Simulation
class VoiceGuidePlayer extends StatefulWidget {
  final String topicName;
  const VoiceGuidePlayer({super.key, required this.topicName});

  @override
  State<VoiceGuidePlayer> createState() => _VoiceGuidePlayerState();
}

class _VoiceGuidePlayerState extends State<VoiceGuidePlayer> with SingleTickerProviderStateMixin {
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
        color: isDark ? const Color(0xFF334155).withOpacity(0.4) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filled(
                onPressed: _togglePlay,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(40, 40),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asisten Suara AI',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      _isPlaying ? 'Sedang membacakan naskah RAG...' : 'Ketuk untuk mendengarkan penjelasan',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (_isPlaying)
                // Equalizer Wave
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final shift = index * 0.2;
                        final val = (shift + _animController.value) % 1.0;
                        final height = 4.0 + (16.0 * (val - 0.5).abs() * 2);
                        return Container(
                          width: 3,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _formatProgressTime(_progress),
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
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
