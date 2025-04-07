class CancellationRule {
  final int timeBeforeCheckIn;
  final int refundPercentage;
  final String description;

  CancellationRule({
    required this.timeBeforeCheckIn,
    required this.refundPercentage,
    required this.description,
  });

  factory CancellationRule.fromJson(Map<String, dynamic> json) {
    return CancellationRule(
      timeBeforeCheckIn: json['timeBeforeCheckIn'],
      refundPercentage: json['refundPercentage'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeBeforeCheckIn': timeBeforeCheckIn,
      'refundPercentage': refundPercentage,
      'description': description,
    };
  }
}

class CancellationPolicy {
  final String id;
  final String name;
  final String description;
  final List<CancellationRule> rules;
  final double modificationFee;
  final int modificationTimeLimit;
  final List<String> residenceTypes;
  final bool isDefault;

  CancellationPolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.rules,
    required this.modificationFee,
    required this.modificationTimeLimit,
    required this.residenceTypes,
    required this.isDefault,
  });

  factory CancellationPolicy.fromJson(Map<String, dynamic> json) {
    return CancellationPolicy(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      rules: (json['rules'] as List)
          .map((rule) => CancellationRule.fromJson(rule))
          .toList(),
      modificationFee: json['modificationFee']?.toDouble() ?? 0.0,
      modificationTimeLimit: json['modificationTimeLimit'] ?? 48,
      residenceTypes: List<String>.from(json['residenceTypes'] ?? []),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'rules': rules.map((rule) => rule.toJson()).toList(),
      'modificationFee': modificationFee,
      'modificationTimeLimit': modificationTimeLimit,
      'residenceTypes': residenceTypes,
      'isDefault': isDefault,
    };
  }

  double calculateRefund(double bookingTotal, int hoursBeforeCheckIn) {
    // Trouver la règle applicable
    final applicableRule = rules
        .where((rule) => rule.timeBeforeCheckIn >= hoursBeforeCheckIn)
        .toList()
      ..sort((a, b) => a.timeBeforeCheckIn.compareTo(b.timeBeforeCheckIn));

    if (applicableRule.isEmpty) {
      // Si aucune règle ne s'applique, prendre la règle avec le plus petit délai
      if (rules.isNotEmpty) {
        final smallestTimeRule = rules.reduce((a, b) => a.timeBeforeCheckIn < b.timeBeforeCheckIn ? a : b);
        return (smallestTimeRule.refundPercentage / 100) * bookingTotal;
      }
      return 0; // Pas de remboursement si aucune règle
    }

    return (applicableRule.first.refundPercentage / 100) * bookingTotal;
  }

  bool isModificationAllowed(int hoursBeforeCheckIn) {
    return hoursBeforeCheckIn >= modificationTimeLimit;
  }

  double calculateModificationFee(double newTotal, double oldTotal) {
    // Appliquer des frais fixes, plus la différence si le nouveau total est plus élevé
    final priceDifference = newTotal > oldTotal ? newTotal - oldTotal : 0;
    return modificationFee + priceDifference;
  }
} 