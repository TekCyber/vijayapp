import 'package:flutter/material.dart';

import '../salesman/salesman_menu_screen.dart';
import 'dealer_dashboard_screen.dart';
import 'dealer_sales_view.dart';

// import other screens as needed

class MenuNavigator {
  static void handleMenuSelection(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DealerDashboardScreen()),
      );
        break;
      case 1: // Dealer
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DealerSalesView()),
        );
        break;
      case 2: // Salesman
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SalesmanMenuScreen(title: 'Salesman Reports',

          )),
        );
        break;
      case 3: // More
      // Navigator.push to More screen
        break;
    }
  }
}
