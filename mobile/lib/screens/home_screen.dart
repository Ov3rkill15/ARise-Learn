import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/live_camera_dialog.dart';

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
    final apiService = context.read<ApiService>();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('input_error_url', apiService.language)),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }
    if (explicitUrl != null) {
      _urlController.text = explicitUrl;
    }
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  Future<void> _handleCameraScan() async {
    final apiService = context.read<ApiService>();
    final lang = apiService.language;
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
                    borderRadius: BorderRadius.circular(16)),
                backgroundColor:
                    isDark ? const Color(0xFF1F2937) : Colors.white,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0056D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Color(0xFF0056D2), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_t('multimodal_title', lang),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
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
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1FA15F).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF1FA15F).withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Color(0xFF1FA15F), size: 18),
                            SizedBox(width: 10),
                            Text('Gambar berhasil diambil!',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF1FA15F))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_t('input_context_label', lang),
                          style: TextStyle(
                              fontSize: 13,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[600],
                              height: 1.5)),
                      const SizedBox(height: 14),
                      TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          labelText: _t('context_label_optional', lang),
                          hintText: _t('hint_text_context', lang),
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Text(_t('quick_topic_title', lang),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400])),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDialogChip(context, _t('jantung_chip', lang),
                              () {
                            textController.text = 'jantung';
                            setDialogState(() {});
                          }, textController.text == 'jantung'),
                          _buildDialogChip(context, _t('dna_helix_chip', lang),
                              () {
                            textController.text = 'dna helix';
                            setDialogState(() {});
                          }, textController.text == 'dna helix'),
                          _buildDialogChip(
                              context, _t('water_molecule_chip', lang), () {
                            textController.text = 'molekul h2o';
                            setDialogState(() {});
                          }, textController.text == 'molekul h2o'),
                          _buildDialogChip(context, _t('atom_bohr_chip', lang),
                              () {
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
                    child: Text(_t('cancel', lang),
                        style: TextStyle(color: Colors.grey[500])),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0056D2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                    ),
                    onPressed: () =>
                        Navigator.pop(context, textController.text.trim()),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_t('start_analysis_btn', lang),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        } else {
          apiService.setCapturedImage(null);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${_t('camera_error_access', lang)} $e'),
            behavior: SnackBarBehavior.floating),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? Colors.white70 : Colors.black87),
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
      extendBody: true,
      body: Stack(
        children: [
          _buildBackgroundGradient(isDark),
          SafeArea(
            bottom: false,
            child: bodyWidget,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark, scheme),
    );
  }

  Widget _buildBackgroundGradient(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF5F7F9),
      ),
    );
  }

  Widget _buildBerandaTab(BuildContext context, ApiService apiService,
      bool isDark, ColorScheme scheme) {
    final lang = apiService.language;
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
              _buildDashboardCard(context, isDark, scheme, lang),
              const SizedBox(height: 24),
              _buildQuickActions(context, isDark, scheme, lang),
              const SizedBox(height: 28),
              _buildStatsRow(context, isDark, scheme, lang),
              const SizedBox(height: 28),
              if (apiService.history.isNotEmpty) ...[
                _buildSectionTitle(context, _t('history_title', lang),
                    Icons.history_rounded, isDark, lang),
                const SizedBox(height: 14),
                _buildHistoryList(context, apiService, isDark, scheme),
                const SizedBox(height: 28),
              ],
              _buildSectionTitle(context, _t('explore_3d_title', lang),
                  Icons.view_in_ar_rounded, isDark, lang),
              const SizedBox(height: 14),
              _buildCatalogGrid(context, isDark, scheme, lang),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPindaiTab(BuildContext context, ApiService apiService,
      bool isDark, ColorScheme scheme) {
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
                  width: 150,
                  height: 150,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(isDark ? 0.05 : 0.03),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 64,
                          color:
                              scheme.primary.withOpacity(isDark ? 0.35 : 0.25),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _breathController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size.infinite,
                            painter: BookScannerPainter(
                                _breathController.value, scheme.primary),
                          );
                        },
                      ),
                    ],
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

  Widget _buildModel3DTab(BuildContext context, ApiService apiService,
      bool isDark, ColorScheme scheme) {
    final lang = apiService.language;
    final searchController = TextEditingController(text: _searchQuery);
    searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: searchController.text.length));

    final items = [
      _CatalogItem(
          _t('catalog_heart', lang),
          _t('catalog_heart_sub', lang),
          Icons.favorite_rounded,
          'heart',
          const Color(0xFFEF4444),
          const Color(0xFFF97316),
          _t('biologi', lang)),
      _CatalogItem(
          _t('catalog_dna', lang),
          _t('catalog_dna_sub', lang),
          Icons.bubble_chart_rounded,
          'dna_helix',
          const Color(0xFF3B82F6),
          const Color(0xFF8B5CF6),
          _t('biologi', lang)),
      _CatalogItem(
          _t('catalog_water', lang),
          _t('catalog_water_sub', lang),
          Icons.water_drop_rounded,
          'water_molecule',
          const Color(0xFF14B8A6),
          const Color(0xFF06B6D4),
          _t('kimia', lang)),
      _CatalogItem(
          _t('catalog_bohr', lang),
          _t('catalog_bohr_sub', lang),
          Icons.wb_sunny_rounded,
          'atom',
          const Color(0xFFF59E0B),
          const Color(0xFFF97316),
          _t('fisika', lang)),
    ];

    final filteredItems = items.where((item) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          item.category == _t(_selectedCategory.toLowerCase(), lang);
      final matchesSearch =
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
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
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.withOpacity(0.15)),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                ),
                child: TextField(
                  controller: searchController,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _t('search_hint', lang),
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: scheme.primary, size: 20),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isCatSelected
                              ? LinearGradient(
                                  colors: [scheme.primary, scheme.tertiary])
                              : null,
                          color: isCatSelected
                              ? null
                              : (isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCatSelected
                                ? Colors.transparent
                                : (isDark ? Colors.white12 : Colors.grey[300]!),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _t(cat.toLowerCase(), lang),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCatSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
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
                        Icon(Icons.search_off_rounded,
                            size: 48, color: Colors.grey[500]),
                        const SizedBox(height: 12),
                        Text(
                          _t('not_found', lang),
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
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

  Widget _buildProfilTab(BuildContext context, ApiService apiService,
      bool isDark, ColorScheme scheme) {
    final lang = apiService.language;
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
                  color: (isDark ? Colors.white : Colors.white)
                      .withOpacity(isDark ? 0.04 : 0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.04)),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: AssetImage('assets/images/pp.jpg'),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Defender',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _t('pangkat', lang),
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
                        Text(_t('level_rank', lang),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('1.450 / 2.000 XP',
                            style: TextStyle(
                                fontSize: 11,
                                color: scheme.primary,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.725,
                        minHeight: 6,
                        color: scheme.primary,
                        backgroundColor:
                            isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildProfileStatCard(
                        '14',
                        _t('scan_success', lang),
                        Icons.qr_code_scanner_rounded,
                        const Color(0xFF60A5FA),
                        isDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProfileStatCard(
                        '8',
                        _t('achievements', lang),
                        Icons.emoji_events_rounded,
                        const Color(0xFFFBBF24),
                        isDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProfileStatCard(
                        '94%',
                        _t('rag_accuracy', lang),
                        Icons.verified_user_rounded,
                        const Color(0xFF34D399),
                        isDark),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('unlocked_achievements', lang),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildBadgeCard(_t('badge_atom_title', lang), '⚛️',
                        _t('badge_atom_desc', lang), true, isDark),
                    _buildBadgeCard(_t('badge_dna_title', lang), '🧬',
                        _t('badge_dna_desc', lang), true, isDark),
                    _buildBadgeCard(_t('badge_water_title', lang), '💧',
                        _t('badge_water_desc', lang), true, isDark),
                    _buildBadgeCard(_t('badge_heart_title', lang), '❤️',
                        _t('badge_heart_desc', lang), false, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.white)
                      .withOpacity(isDark ? 0.04 : 0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.04)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: scheme.primary),
                      title: Text(_t('dark_light', lang),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) => apiService.toggleTheme(),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          Icon(Icons.language_rounded, color: scheme.primary),
                      title: Text(_t('pilih_bahasa', lang),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: lang,
                          items: [
                            DropdownMenuItem(
                              value: 'id',
                              child: Text(_t('bahasa_indonesia', lang),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87)),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(_t('bahasa_inggris', lang),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87)),
                            ),
                          ],
                          onChanged: (String? newLang) {
                            if (newLang != null) {
                              apiService.setLanguage(newLang);
                            }
                          },
                          dropdownColor:
                              isDark ? const Color(0xFF1F2937) : Colors.white,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.cloud_done_rounded,
                          color: Colors.green[400]),
                      title: Text(_t('curriculum', lang),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(_t('validation', lang),
                          style: const TextStyle(fontSize: 10)),
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
                      leading: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent),
                      title: Text(_t('delete_history', lang),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(_t('delete_history', lang)),
                            content: Text(_t('delete_history_confirm', lang)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(_t('cancel', lang)),
                              ),
                              TextButton(
                                onPressed: () {
                                  apiService.clearHistory();
                                  Navigator.pop(context);
                                },
                                child: Text(_t('delete', lang),
                                    style: const TextStyle(
                                        color: Colors.redAccent)),
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

  Widget _buildProfileStatCard(
      String value, String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.white)
            .withOpacity(isDark ? 0.04 : 0.3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF1F1F1F))),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(
      String title, String emoji, String desc, bool unlocked, bool isDark) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked
            ? (isDark
                ? const Color(0xFF2D2A1E)
                : const Color(0xFFFFFDF5).withOpacity(0.35))
            : (isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.white.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? const Color(0xFFFBBF24).withOpacity(0.4)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04)),
          width: unlocked ? 1.5 : 1.0,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color:
                      const Color(0xFFFBBF24).withOpacity(isDark ? 0.15 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
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
              style: TextStyle(
                  fontSize: 8,
                  color: isDark ? Colors.grey[400] : const Color(0xFF475569)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
      BuildContext context, bool isDark, ColorScheme scheme, String lang) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFEEF0F2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: const Color(0xFF0056D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights_rounded,
                    color: Color(0xFF0056D2), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('progress', lang),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t('understanding_level', lang),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF5C5C5C),
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
              Text(
                _t('topics_mastered_label', lang),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF5C5C5C)),
              ),
              Text(
                _t('topics_mastered_value', lang),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0056D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.75,
              minHeight: 8,
              backgroundColor: Color(0xFFEEF0F2),
              color: Color(0xFF0056D2),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0056D2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => setState(() => _currentNav = 1),
              icon: const Icon(Icons.document_scanner_rounded, size: 18),
              label: Text(
                _t('start_scan_book', lang),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, ColorScheme scheme) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                  child: _buildNavItem(
                      Icons.home_rounded, 'bottom_nav_home', 0, isDark)),
              Expanded(
                  child: _buildNavItem(
                      Icons.search_rounded, 'bottom_nav_scan', 1, isDark)),
              Expanded(
                  child: _buildNavItem(
                      Icons.view_in_ar_rounded, 'bottom_nav_3d', 2, isDark)),
              Expanded(
                  child: _buildNavItem(
                      Icons.person_rounded, 'bottom_nav_profile', 3, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String labelKey, int index, bool isDark) {
    final isActive = _currentNav == index;
    final lang = context.read<ApiService>().language;
    return GestureDetector(
      onTap: () => setState(() => _currentNav = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive
                ? const Color(0xFF0056D2)
                : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF8C8C8C)),
          ),
          const SizedBox(height: 4),
          Text(
            _t(labelKey, lang),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? const Color(0xFF0056D2)
                  : (isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF8C8C8C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ApiService apiService, bool isDark,
      ColorScheme scheme) {
    final lang = apiService.language;
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundImage: AssetImage('assets/images/pp.jpg'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_t('welcome', lang),
                  style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF5C5C5C),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('Defender',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F1F1F))),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => apiService.toggleTheme(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFF5F7F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFD6DBDF)),
            ),
            child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 18,
                color: isDark ? Colors.amber[300] : const Color(0xFF5C5C5C)),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, ApiService apiService,
      bool isDark, ColorScheme scheme) {
    final lang = apiService.language;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0056D2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.document_scanner_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('pindai_buku_cetak', lang),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_t('ai_analyze_desc', lang),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color(0xFF0056D2),
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: apiService.isLoading ? null : _handleCameraScan,
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: Text(_t('open_camera_scanner', lang),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child:
                      Divider(color: Colors.white.withOpacity(0.2), height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(_t('or_paste_url', lang),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
              ),
              Expanded(
                  child:
                      Divider(color: Colors.white.withOpacity(0.2), height: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style:
                        const TextStyle(color: Color(0xFF1F1F1F), fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'https://example.com/halaman-buku.jpg',
                      hintStyle: const TextStyle(
                          color: Color(0xFF8C8C8C), fontSize: 12),
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      prefixIcon: const Icon(Icons.link_rounded,
                          color: Color(0xFF8C8C8C), size: 20),
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
                        backgroundColor: const Color(0xFF0056D2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Row(children: [
                              const Icon(Icons.send_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text(_t('send', lang),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13))
                            ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(_t('try_fast_preset', lang),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip(context, _t('jantung', lang),
                  'https://images.unsplash.com/photo-1530026405186-ed1ea0ac7a63'),
              _buildPresetChip(context, _t('dna', lang),
                  'https://images.unsplash.com/photo-1507679799987-c73779587ccf'),
              _buildPresetChip(context, _t('water', lang),
                  'https://images.unsplash.com/photo-1544383835-bda2bc66a55d'),
              _buildPresetChip(context, _t('atom_bohr', lang),
                  'https://images.unsplash.com/photo-1635070041078-e363dbe005cb'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, bool isDark, ColorScheme scheme, String lang) {
    final actions = [
      _QuickAction(
          _t('quick_action_scan', lang),
          _t('quick_action_scan_sub', lang),
          Icons.auto_stories_rounded,
          const Color(0xFF0056D2),
          const Color(0xFF0056D2)),
      _QuickAction(
          _t('quick_action_3d', lang),
          _t('quick_action_3d_sub', lang),
          Icons.view_in_ar_rounded,
          const Color(0xFF1FA15F),
          const Color(0xFF1FA15F)),
      _QuickAction(
          _t('quick_action_ar', lang),
          _t('quick_action_ar_sub', lang),
          Icons.camera_rounded,
          const Color(0xFFF5AF02),
          const Color(0xFFF5AF02)),
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
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFEEF0F2)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: action.color1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(action.icon, color: action.color1, size: 18),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color:
                              isDark ? Colors.white : const Color(0xFF1F1F1F),
                        ),
                      ),
                      Text(
                        action.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF5C5C5C),
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

  Widget _buildStatsRow(
      BuildContext context, bool isDark, ColorScheme scheme, String lang) {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard('4', _t('active_classes', lang),
                Icons.school_rounded, const Color(0xFF0056D2), isDark)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('12', _t('models_count', lang),
                Icons.view_in_ar_rounded, const Color(0xFF1FA15F), isDark)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('94%', _t('rag_score', lang),
                Icons.verified_rounded, const Color(0xFFF5AF02), isDark)),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: isDark ? Colors.white : const Color(0xFF1F1F1F))),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF5C5C5C),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon,
      bool isDark, String lang) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F1F1F)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => setState(() => _currentNav = 2),
          child: Text(_t('view_all', lang),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0056D2))),
        ),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context, ApiService apiService,
      bool isDark, ColorScheme scheme) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: apiService.history.length,
        itemBuilder: (context, index) {
          final item = apiService.history[index];
          final iconColors = [
            const Color(0xFFEF4444),
            const Color(0xFF3B82F6),
            const Color(0xFF14B8A6),
            const Color(0xFFF59E0B),
          ];
          final iconColor = iconColors[index % iconColors.length];
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
                borderRadius: BorderRadius.circular(16),
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFEEF0F2)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
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
                                  decoration: BoxDecoration(
                                      color: iconColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(
                                    item.asset3dUrl == 'heart'
                                        ? Icons.favorite_rounded
                                        : item.asset3dUrl == 'dna_helix'
                                            ? Icons.bubble_chart_rounded
                                            : item.asset3dUrl ==
                                                    'water_molecule'
                                                ? Icons.water_drop_rounded
                                                : Icons.science_rounded,
                                    color: iconColor,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(item.subjectTopic,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1F1F1F)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                                item.explanation
                                    .replaceAll(RegExp(r'[#\*]'), ''),
                                style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF5C5C5C),
                                    fontSize: 11,
                                    height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF1FA15F)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: Color(0xFF1FA15F), size: 11),
                                      const SizedBox(width: 4),
                                      Text(
                                          '${(item.confidence * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                              color: Color(0xFF1FA15F),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF8C8C8C)),
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

  Widget _buildCatalogGrid(
      BuildContext context, bool isDark, ColorScheme scheme, String lang) {
    final items = [
      _CatalogItem(
          _t('catalog_heart', lang),
          _t('catalog_heart_sub', lang),
          Icons.favorite_rounded,
          'heart',
          const Color(0xFFEF4444),
          const Color(0xFFF97316),
          _t('biologi', lang)),
      _CatalogItem(
          _t('catalog_dna', lang),
          _t('catalog_dna_sub', lang),
          Icons.bubble_chart_rounded,
          'dna_helix',
          const Color(0xFF3B82F6),
          const Color(0xFF8B5CF6),
          _t('biologi', lang)),
      _CatalogItem(
          _t('catalog_water', lang),
          _t('catalog_water_sub', lang),
          Icons.water_drop_rounded,
          'water_molecule',
          const Color(0xFF14B8A6),
          const Color(0xFF06B6D4),
          _t('kimia', lang)),
      _CatalogItem(
          _t('catalog_bohr', lang),
          _t('catalog_bohr_sub', lang),
          Icons.wb_sunny_rounded,
          'atom',
          const Color(0xFFF59E0B),
          const Color(0xFFF97316),
          _t('fisika', lang)),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                        color: item.color1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, color: item.color1, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xFFF5F7F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_outward_rounded,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF5C5C5C)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1F1F1F))),
                    const SizedBox(height: 4),
                    Text(item.subtitle,
                        style: TextStyle(
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF5C5C5C),
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _t(String key, String lang) {
    const translations = {
      'id': {
        'welcome': 'Selamat Datang 👋',
        'search_hint': 'Cari model 3D (jantung, dna, dll)...',
        'not_found': 'Model tidak ditemukan',
        'dark_light': 'Mode Gelap / Terang',
        'curriculum': 'Grounding Kurikulum Resmi',
        'validation': 'Validasi RAG aktif & tersertifikasi',
        'delete_history': 'Hapus Riwayat Belajar',
        'delete_history_confirm':
            'Apakah Anda yakin ingin menghapus semua riwayat pemindaian?',
        'cancel': 'Batal',
        'delete': 'Hapus',
        'progress': 'Progres Pembelajaran',
        'understanding_level': 'Tingkat pemahaman materi sains',
        'topics_mastered_label': 'Topik Terkuasai',
        'topics_mastered_value': '3 / 4 Topik (75%)',
        'start_scan_book': 'MULAI SCAN BUKU CETAK',
        'pangkat': 'Pangkat: Penjelajah Sains',
        'level_rank': 'Level 4 (Orde Atom)',
        'scan_success': 'Scan Sukses',
        'achievements': 'Pencapaian',
        'rag_accuracy': 'Akurasi RAG',
        'unlocked_achievements': 'Pencapaian Unlocked',
        'badge_atom_title': 'Pakar Atom',
        'badge_atom_desc': 'Pindai model Atom Bohr',
        'badge_dna_title': 'Peneliti DNA',
        'badge_dna_desc': 'Pindai model Helix DNA',
        'badge_water_title': 'Pencari Air',
        'badge_water_desc': 'Pindai model Molekul H2O',
        'badge_heart_title': 'Ahli Jantung',
        'badge_heart_desc': 'Pindai model Jantung',
        'active_classes': 'Kelas Aktif',
        'models_count': 'Model 3D',
        'rag_score': 'RAG Score',
        'history_title': 'Riwayat Pemindaian',
        'explore_3d_title': 'Eksplorasi Model 3D',
        'view_all': 'Lihat Semua',
        'pindai_buku_cetak': 'Pindai Buku Cetak',
        'ai_analyze_desc': 'AI menganalisis & membuat model 3D interaktif',
        'open_camera_scanner': 'BUKA KAMERA SCANNER',
        'or_paste_url': 'ATAU TEMPEL URL',
        'try_fast_preset': 'COBA CONTOH CEPAT',
        'jantung': '❤️ Jantung',
        'dna': '🧬 DNA',
        'water': '💧 H2O',
        'atom_bohr': '⚛️ Atom',
        'jantung_chip': '❤️ Jantung',
        'dna_helix_chip': '🧬 DNA Helix',
        'water_molecule_chip': '💧 Molekul H2O',
        'atom_bohr_chip': '⚛️ Atom Bohr',
        'biologi': 'Biologi',
        'kimia': 'Kimia',
        'fisika': 'Fisika',
        'semua': 'Semua',
        'input_error_url': 'Masukkan URL gambar atau gunakan contoh preset',
        'camera_error_access': 'Gagal mengakses kamera: ',
        'multimodal_title': 'Analisis AI Multimodal',
        'image_success_taken': 'Gambar berhasil diambil!',
        'input_context_label': 'Masukkan petunjuk materi atau pilih topik:',
        'context_label_optional': 'Konteks Materi (Opsional)',
        'hint_text_context': 'jantung, dna, h2o, atom...',
        'quick_topic_title': 'TOPIK CEPAT',
        'start_analysis_btn': 'Mulai Analisis',
        'bottom_nav_home': 'Beranda',
        'bottom_nav_scan': 'Pindai',
        'bottom_nav_3d': 'Model 3D',
        'bottom_nav_profile': 'Profil',
        'quick_action_scan': 'Scan Buku',
        'quick_action_scan_sub': 'Analisis AI',
        'quick_action_3d': 'Model 3D',
        'quick_action_3d_sub': 'Lihat Katalog',
        'quick_action_ar': 'AR Mode',
        'quick_action_ar_sub': 'Augmented Reality',
        'catalog_heart': 'Jantung Manusia',
        'catalog_heart_sub': 'Kardiologi & Aliran Darah',
        'catalog_dna': 'Heliks DNA',
        'catalog_dna_sub': 'Genetika & Kromosom',
        'catalog_water': 'Molekul H₂O',
        'catalog_water_sub': 'Kepolaran & Ikatan Kovalen',
        'catalog_bohr': 'Model Bohr',
        'catalog_bohr_sub': 'Fisika Kuantum & Orbit',
        'pilih_bahasa': 'Pilih Bahasa',
        'bahasa_indonesia': 'Bahasa Indonesia',
        'bahasa_inggris': 'Bahasa Inggris',
        'send': 'Kirim',
      },
      'en': {
        'welcome': 'Welcome 👋',
        'search_hint': 'Search 3D models (heart, dna, etc)...',
        'not_found': 'Model not found',
        'dark_light': 'Dark / Light Mode',
        'curriculum': 'Official Curriculum Grounding',
        'validation': 'RAG validation active & certified',
        'delete_history': 'Clear Study History',
        'delete_history_confirm':
            'Are you sure you want to delete all scan history?',
        'cancel': 'Cancel',
        'delete': 'Delete',
        'progress': 'Learning Progress',
        'understanding_level': 'Science material comprehension level',
        'topics_mastered_label': 'Topics Mastered',
        'topics_mastered_value': '3 / 4 Topics (75%)',
        'start_scan_book': 'START SCANNING TEXTBOOK',
        'pangkat': 'Rank: Science Explorer',
        'level_rank': 'Level 4 (Atomic Order)',
        'scan_success': 'Success Scans',
        'achievements': 'Achievements',
        'rag_accuracy': 'RAG Accuracy',
        'unlocked_achievements': 'Unlocked Achievements',
        'badge_atom_title': 'Atom Expert',
        'badge_atom_desc': 'Scan Bohr Atom model',
        'badge_dna_title': 'DNA Researcher',
        'badge_dna_desc': 'Scan DNA Helix model',
        'badge_water_title': 'Water Seeker',
        'badge_water_desc': 'Scan H2O Molecule model',
        'badge_heart_title': 'Cardiologist',
        'badge_heart_desc': 'Scan Heart model',
        'active_classes': 'Active Classes',
        'models_count': '3D Models',
        'rag_score': 'RAG Score',
        'history_title': 'Scan History',
        'explore_3d_title': 'Explore 3D Models',
        'view_all': 'View All',
        'pindai_buku_cetak': 'Scan Textbook',
        'ai_analyze_desc': 'AI analyzes & creates interactive 3D models',
        'open_camera_scanner': 'OPEN CAMERA SCANNER',
        'or_paste_url': 'OR PASTE URL',
        'try_fast_preset': 'TRY FAST PRESET',
        'jantung': '❤️ Heart',
        'dna': '🧬 DNA',
        'water': '💧 H2O',
        'atom_bohr': '⚛️ Atom',
        'jantung_chip': '❤️ Heart',
        'dna_helix_chip': '🧬 DNA Helix',
        'water_molecule_chip': '💧 H2O Molecule',
        'atom_bohr_chip': '⚛️ Bohr Atom',
        'biologi': 'Biology',
        'kimia': 'Chemistry',
        'fisika': 'Physics',
        'semua': 'All',
        'input_error_url': 'Please enter image URL or use a preset',
        'camera_error_access': 'Failed to access camera: ',
        'multimodal_title': 'Multimodal AI Analysis',
        'image_success_taken': 'Image successfully captured!',
        'input_context_label': 'Enter material hint or select topic:',
        'context_label_optional': 'Material Context (Optional)',
        'hint_text_context': 'heart, dna, h2o, atom...',
        'quick_topic_title': 'QUICK TOPICS',
        'start_analysis_btn': 'Start Analysis',
        'bottom_nav_home': 'Home',
        'bottom_nav_scan': 'Scan',
        'bottom_nav_3d': '3D Model',
        'bottom_nav_profile': 'Profile',
        'quick_action_scan': 'Scan Book',
        'quick_action_scan_sub': 'AI Analysis',
        'quick_action_3d': '3D Models',
        'quick_action_3d_sub': 'View Catalog',
        'quick_action_ar': 'AR Mode',
        'quick_action_ar_sub': 'Augmented Reality',
        'catalog_heart': 'Human Heart',
        'catalog_heart_sub': 'Cardiology & Blood Flow',
        'catalog_dna': 'DNA Helix',
        'catalog_dna_sub': 'Genetics & Chromosome',
        'catalog_water': 'H₂O Molecule',
        'catalog_water_sub': 'Polarity & Covalent Bond',
        'catalog_bohr': 'Bohr Model',
        'catalog_bohr_sub': 'Quantum Physics & Orbit',
        'pilih_bahasa': 'Select Language',
        'bahasa_indonesia': 'Indonesian',
        'bahasa_inggris': 'English',
        'send': 'Send',
      }
    };
    return translations[lang]?[key] ?? key;
  }
}

class BookScannerPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  BookScannerPainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paintCorner = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw 4 corner brackets of viewfinder
    const len = 16.0;
    // Top Left
    canvas.drawPath(
        Path()
          ..moveTo(0, len)
          ..lineTo(0, 0)
          ..lineTo(len, 0),
        paintCorner);
    // Top Right
    canvas.drawPath(
        Path()
          ..moveTo(size.width - len, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, len),
        paintCorner);
    // Bottom Left
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height - len)
          ..lineTo(0, size.height)
          ..lineTo(len, size.height),
        paintCorner);
    // Bottom Right
    canvas.drawPath(
        Path()
          ..moveTo(size.width - len, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width, size.height - len),
        paintCorner);

    // Draw horizontal scanning laser line
    final y = size.height * animationValue;
    final paintLine = Paint()
      ..color = color
      ..strokeWidth = 2.0;

    // Laser glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawRect(
      Rect.fromLTRB(4, y - 4, size.width - 4, y + 4),
      glowPaint,
    );

    // Laser line itself
    canvas.drawLine(
      Offset(4, y),
      Offset(size.width - 4, y),
      paintLine,
    );
  }

  @override
  bool shouldRepaint(covariant BookScannerPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.color != color;
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
  _CatalogItem(this.title, this.subtitle, this.icon, this.assetId, this.color1,
      this.color2, this.category);
}
