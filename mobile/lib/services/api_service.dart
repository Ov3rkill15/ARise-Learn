import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:dio/dio.dart';
import '../models/scan_result.dart';

class ApiService extends ChangeNotifier {
  // Auto-detect platform: web uses localhost, Android emulator uses 10.0.2.2
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://10.0.2.2:8080'; // Android emulator
  }

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
  ));

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ScanResult? _lastResult;
  ScanResult? get lastResult => _lastResult;

  String? _error;
  String? get error => _error;

  final List<ScanResult> _history = [
    ScanResult(
      id: 'demo-heart',
      explanation: '### Anatomi Jantung Manusia\n\nJantung adalah organ berongga yang tersusun atas otot jantung (miokardium) khusus, berukuran kira-kira sebesar kepalan tangan pemiliknya, dan terletak di rongga dada sebelah kiri.\n\n**Bagian Utama Jantung:**\n1. Atrium Kanan & Kiri (Serambi)\n2. Ventrikel Kanan & Kiri (Bilik)\n3. Katup Jantung (Valvula)',
      subjectTopic: 'Anatomi Jantung Manusia',
      confidence: 0.95,
      asset3dUrl: 'heart',
    ),
    ScanResult(
      id: 'demo-dna',
      explanation: '### Struktur Helix Ganda DNA\n\nDNA (Deoxyribonucleic Acid) menyimpan informasi genetik seluruh makhluk hidup. Molekul ini berbentuk seperti tangga berpilin ganda (*double helix*) berputar ke arah kanan.',
      subjectTopic: 'Genetika - Helix Ganda DNA',
      confidence: 0.92,
      asset3dUrl: 'dna_helix',
    ),
  ];
  List<ScanResult> get history => _history;

  /// Sends an image URL to the backend for AI analysis
  Future<ScanResult?> submitScan(String imageUrl, {String? context}) async {
    _isLoading = true;
    _error = null;
    _lastResult = null;
    notifyListeners();

    try {
      final response = await _dio.post('/api/v1/scan', data: {
        'user_id': 'demo-user',
        'image_url': imageUrl,
        if (context != null) 'context': context,
      });

      _lastResult = ScanResult.fromJson(response.data);
      
      // Add to local history list
      if (_lastResult != null) {
        _history.removeWhere((item) => item.subjectTopic == _lastResult!.subjectTopic);
        _history.insert(0, _lastResult!);
        if (_history.length > 10) _history.removeLast();
      }
      
      _isLoading = false;
      notifyListeners();
      return _lastResult;
    } on DioException catch (e) {
      _error = 'Network error: ${e.message}';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Unexpected error: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Sets the lastResult manually (e.g. when selecting from history)
  void selectResult(ScanResult result) {
    _lastResult = result;
    notifyListeners();
  }

  /// Fetches a previous scan result by ID
  Future<ScanResult?> getScan(String scanId) async {
    try {
      final response = await _dio.get('/api/v1/scan/$scanId');
      return ScanResult.fromJson(response.data);
    } catch (e) {
      _error = 'Failed to fetch scan: $e';
      notifyListeners();
      return null;
    }
  }
}
