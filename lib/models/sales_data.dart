// lib/models/sales_data.dart
import 'package:flutter/material.dart';

class SalesData {
  final String period;
  final double amount;
  final Color color;

  SalesData(this.period, this.amount, this.color);
}

class MonthlyData {
  final String category;
  final double value;
  final double percentage;
  final Color color;

  MonthlyData(this.category, this.value, this.percentage, this.color);
}

class OutstandingBill {
  final String cdReg;
  final double pendingBills;
  final double lessThan30Days;
  final double days30To60;
  final double days60To75;
  final double days75To90;
  final double moreThan90Days;
  final double onAccount;

  OutstandingBill({
    required this.cdReg,
    required this.pendingBills,
    required this.lessThan30Days,
    required this.days30To60,
    required this.days60To75,
    required this.days75To90,
    required this.moreThan90Days,
    required this.onAccount,
  });

  // Factory constructor to create OutstandingBill from JSON
  factory OutstandingBill.fromJson(Map<String, dynamic> json) {
    return OutstandingBill(
      cdReg: json['CD/REG']?.toString() ?? '',
      pendingBills: double.tryParse(json['Pending Bills']?.toString() ?? '0') ?? 0.0,
      lessThan30Days: double.tryParse(json['(< 30 days )']?.toString() ?? '0') ?? 0.0,
      days30To60: double.tryParse(json['30 to 60 days']?.toString() ?? '0') ?? 0.0,
      days60To75: double.tryParse(json['60 to 75 days']?.toString() ?? '0') ?? 0.0,
      days75To90: double.tryParse(json['75 to 90 days']?.toString() ?? '0') ?? 0.0,
      moreThan90Days: double.tryParse(json['(> 90 days )']?.toString() ?? '0') ?? 0.0,
      onAccount: double.tryParse(json['On Account']?.toString() ?? '0') ?? 0.0,
    );
  }

  // Convert OutstandingBill to JSON
  Map<String, dynamic> toJson() {
    return {
      'CD/REG': cdReg,
      'Pending Bills': pendingBills,
      '(< 30 days )': lessThan30Days,
      '30 to 60 days': days30To60,
      '60 to 75 days': days60To75,
      '75 to 90 days': days75To90,
      '(> 90 days )': moreThan90Days,
      'On Account': onAccount,
    };
  }

  // Get total outstanding amount (excluding On Account)
  double get totalOutstanding => pendingBills;

  // Get breakdown as a list for easier iteration
  List<BillBreakdown> get breakdown => [
    BillBreakdown('< 30 days', lessThan30Days),
    BillBreakdown('30-60 days', days30To60),
    BillBreakdown('60-75 days', days60To75),
    BillBreakdown('75-90 days', days75To90),
    BillBreakdown('> 90 days', moreThan90Days),
  ];

  // Get priority level based on aging
  String get priority {
    if (moreThan90Days > 0) return 'High';
    if (days75To90 > 0 || days60To75 > 0) return 'Medium';
    return 'Low';
  }

  // Get priority color based on aging
  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return Color(0xFFFF4757);
      case 'medium':
        return Color(0xFFFFB142);
      default:
        return Color(0xFF2ED573);
    }
  }

  // Get status based on priority
  String get status {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'Critical';
      case 'medium':
        return 'Overdue';
      default:
        return 'Current';
    }
  }

  @override
  String toString() {
    return 'OutstandingBill(cdReg: $cdReg, pendingBills: $pendingBills, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OutstandingBill &&
        other.cdReg == cdReg &&
        other.pendingBills == pendingBills &&
        other.lessThan30Days == lessThan30Days &&
        other.days30To60 == days30To60 &&
        other.days60To75 == days60To75 &&
        other.days75To90 == days75To90 &&
        other.moreThan90Days == moreThan90Days &&
        other.onAccount == onAccount;
  }

  @override
  int get hashCode {
    return cdReg.hashCode ^
    pendingBills.hashCode ^
    lessThan30Days.hashCode ^
    days30To60.hashCode ^
    days60To75.hashCode ^
    days75To90.hashCode ^
    moreThan90Days.hashCode ^
    onAccount.hashCode;
  }
}

// Helper class for bill breakdown display
class BillBreakdown {
  final String ageGroup;
  final double amount;

  BillBreakdown(this.ageGroup, this.amount);

  bool get isNegative => amount < 0;
  double get absoluteAmount => amount.abs();
}