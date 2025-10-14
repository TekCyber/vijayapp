// =====================================
// lib/utils/formatters.dart
import 'package:intl/intl.dart';

class Formatters {


  static String formatCurrency(double amount) {
    bool isNegative = amount < 0;
    double absAmount = amount.abs();

    String formatted;
    if (absAmount >= 100000) {
      formatted = '₹${(absAmount / 100000).toStringAsFixed(1)}L';
    } else if (absAmount >= 1000) {
      formatted = '₹${(absAmount / 1000).toStringAsFixed(1)}K';
    } else {
      formatted = '₹${absAmount.toStringAsFixed(0)}';
    }

    return isNegative ? '-$formatted' : formatted;
  }

  static String formatNumber(double number, {int decimals = 2}) {
    // Split into integer and decimal parts
    String numberStr = number.toStringAsFixed(decimals);
    List<String> parts = numberStr.split('.');

    // Format the integer part with commas
    String integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );

    // Return with decimal part if it exists
    if (decimals > 0 && parts.length > 1) {
      return '$integerPart.${parts[1]}';
    }

    return integerPart;
  }

  /// Format DateTime as dd-MM-yyyy
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd-MM-yyyy');
    return formatter.format(date);
  }

  /// Get financial year from date string in "dd-MM-yy" format
  /// Example: "20-04-25" returns "25-26"
  /// Example: "15-03-25" returns "24-25"
  static String getFYFromDateString(String dateString) {
    // Parse date string format: "dd-MM-yy"
    List<String> parts = dateString.split('-');

    if (parts.length != 3) {
      throw FormatException('Invalid date format. Expected: dd-MM-yy');
    }

    int day = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int year = int.parse(parts[2]);

    // Convert 2-digit year to 4-digit year
    // Assuming 00-99 represents 2000-2099
    int fullYear = 2000 + year;

    // Financial year starts in April (month 4)
    if (month >= 4) {
      // April to December: Current year to next year
      int startYear = fullYear % 100;
      int endYear = (fullYear + 1) % 100;
      return '$startYear-${endYear.toString().padLeft(2, '0')}';
    } else {
      // January to March: Previous year to current year
      int startYear = (fullYear - 1) % 100;
      int endYear = fullYear % 100;
      return '$startYear-${endYear.toString().padLeft(2, '0')}';
    }
  }
}
