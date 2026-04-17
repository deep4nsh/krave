import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { credit, debit, refund }
enum TransactionStatus { pending, success, failed }

class WalletTransaction {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime timestamp;
  final String title;
  final String? refId; // Order ID or Payment Gateway ID
  final Map<String, dynamic>? metadata;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.title,
    this.refId,
    this.metadata,
  });

  factory WalletTransaction.fromMap(String id, Map<String, dynamic> m) {
    return WalletTransaction(
      id: id,
      userId: m['userId'] ?? '',
      amount: (m['amount'] ?? 0.0).toDouble(),
      type: _parseType(m['type']),
      status: _parseStatus(m['status']),
      timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      title: m['title'] ?? 'Transaction',
      refId: m['refId'],
      metadata: m['metadata'] as Map<String, dynamic>?,
    );
  }

  static TransactionType _parseType(String? t) {
    switch (t) {
      case 'debit': return TransactionType.debit;
      case 'refund': return TransactionType.refund;
      default: return TransactionType.credit;
    }
  }

  static TransactionStatus _parseStatus(String? s) {
    switch (s) {
      case 'pending': return TransactionStatus.pending;
      case 'failed': return TransactionStatus.failed;
      default: return TransactionStatus.success;
    }
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'amount': amount,
    'type': type.name,
    'status': status.name,
    'timestamp': timestamp,
    'title': title,
    'refId': refId,
    'metadata': metadata,
  };
}
