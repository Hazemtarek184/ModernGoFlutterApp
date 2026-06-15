class VerifyPhotoResult {
  final String status;
  final bool matched;
  final double? distance;
  final String? detail;

  const VerifyPhotoResult({
    required this.status,
    required this.matched,
    this.distance,
    this.detail,
  });
}
