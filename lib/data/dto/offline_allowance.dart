import 'package:json_annotation/json_annotation.dart';

part 'offline_allowance.g.dart';

@JsonSerializable()
class OfflineAllowance {
  final double maxAmount;
  final int maxTransactions;
  final double currentBalance;

  OfflineAllowance({
    required this.maxAmount,
    required this.maxTransactions,
    required this.currentBalance,
  });

  factory OfflineAllowance.fromJson(Map<String, dynamic> json) =>
      _$OfflineAllowanceFromJson(json);

  Map<String, dynamic> toJson() => _$OfflineAllowanceToJson(this);
}
