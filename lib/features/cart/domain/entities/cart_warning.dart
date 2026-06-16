/// Represents a health warning returned by the AI for a specific cart item.
class CartWarning {
  final String productName;

  /// 'critical', 'severe', or 'moderate'
  final String severity;

  /// 'allergy', 'drug_interaction', 'dietary', or 'condition'
  final String type;

  final String message;

  const CartWarning({
    required this.productName,
    required this.severity,
    required this.type,
    required this.message,
  });

  factory CartWarning.fromJson(Map<String, dynamic> json) {
    return CartWarning(
      productName: (json['productName'] as String? ?? '').toLowerCase(),
      severity: json['severity'] as String? ?? 'moderate',
      type: json['type'] as String? ?? 'condition',
      message: json['message'] as String? ?? 'Health warning detected',
    );
  }

  bool get isCritical => severity == 'critical';
  bool get isSevere => severity == 'severe';
  bool get isCriticalOrSevere => isCritical || isSevere;
}
