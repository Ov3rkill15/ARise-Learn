class ScanResult {
  final String id;
  final String explanation;
  final String subjectTopic;
  final double confidence;
  final String? asset3dUrl;

  ScanResult({
    required this.id,
    required this.explanation,
    required this.subjectTopic,
    required this.confidence,
    this.asset3dUrl,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return ScanResult(
      id: data['id'] ?? '',
      explanation: data['explanation'] ?? '',
      subjectTopic: data['subject_topic'] ?? 'Unknown',
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      asset3dUrl: data['asset_3d_url'],
    );
  }
}
