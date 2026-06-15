class VerifyPhotoResult {
  final String status;
  final bool matched;
  final double? distance;

  const VerifyPhotoResult({
    required this.status,
    required this.matched,
    this.distance,
  });
}
