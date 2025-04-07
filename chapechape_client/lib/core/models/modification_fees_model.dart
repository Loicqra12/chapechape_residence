import 'package:json_annotation/json_annotation.dart';

part 'modification_fees_model.g.dart';

@JsonSerializable()
class ModificationFees {
  final double baseFee;
  final double priceDifference;
  final double totalFee;
  final String currency;

  ModificationFees({
    required this.baseFee,
    required this.priceDifference,
    required this.totalFee,
    required this.currency,
  });

  factory ModificationFees.fromJson(Map<String, dynamic> json) =>
      _$ModificationFeesFromJson(json);

  Map<String, dynamic> toJson() => _$ModificationFeesToJson(this);

  @override
  String toString() {
    return 'ModificationFees(baseFee: $baseFee, priceDifference: $priceDifference, totalFee: $totalFee, currency: $currency)';
  }
}
