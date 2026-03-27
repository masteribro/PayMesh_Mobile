import 'package:pay_mesh_mobile/data/models/transaction_model.dart';

class SyncResponse {
  final List<TransactionModel> accepted;
  final List<ConflictModel> conflicts;
  final String message;

  SyncResponse({
    required this.accepted,
    required this.conflicts,
    required this.message,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      accepted: (json['accepted'] as List?)
              ?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      conflicts: (json['conflicts'] as List?)
              ?.map((e) => ConflictModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'accepted': accepted.map((e) => e.toJson()).toList(),
    'conflicts': conflicts.map((e) => e.toJson()).toList(),
    'message': message,
  };

  bool get hasConflicts => conflicts.isNotEmpty;
}

class ConflictModel {
  final String id;
  final String status;
  final String? conflictReason;

  ConflictModel({
    required this.id,
    required this.status,
    this.conflictReason,
  });

  factory ConflictModel.fromJson(Map<String, dynamic> json) {
    return ConflictModel(
      id: json['id'] as String,
      status: json['status'] as String,
      conflictReason: json['conflictReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'conflictReason': conflictReason,
  };
}

