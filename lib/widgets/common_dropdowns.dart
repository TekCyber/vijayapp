// lib/widgets/common_dropdowns.dart
import 'package:flutter/material.dart';

// Brand Dropdown Widget - Reusable
class BrandDropdownFilter extends StatefulWidget {
  final List<String> brands;
  final String? selectedBrand;
  final ValueChanged<String?> onChanged;
  final String label;

  const BrandDropdownFilter({
    Key? key,
    required this.brands,
    this.selectedBrand,
    required this.onChanged,
    this.label = "Brand",
  }) : super(key: key);

  @override
  State<BrandDropdownFilter> createState() => _BrandDropdownFilterState();
}

class _BrandDropdownFilterState extends State<BrandDropdownFilter> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white.withOpacity(0.8) : Colors.black54;
    final iconColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: widget.selectedBrand,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.branding_watermark,
            color: iconColor,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: iconColor,
        ),
        selectedItemBuilder: (BuildContext context) {
          return widget.brands.map<Widget>((String brand) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Text(
                brand,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            );
          }).toList();
        },
        items: widget.brands.map((String brand) {
          return DropdownMenuItem<String>(
            value: brand,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 48,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  brand,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// Route Dropdown Widget - Reusable
class RouteDropdownFilter extends StatefulWidget {
  final List<String> routes;
  final String? selectedRoute;
  final ValueChanged<String?> onChanged;
  final String label;

  const RouteDropdownFilter({
    Key? key,
    required this.routes,
    this.selectedRoute,
    required this.onChanged,
    this.label = "Select Route",
  }) : super(key: key);

  @override
  State<RouteDropdownFilter> createState() => _RouteDropdownFilterState();
}

class _RouteDropdownFilterState extends State<RouteDropdownFilter> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white.withOpacity(0.8) : Colors.black54;
    final iconColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: widget.selectedRoute,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.route,
            color: iconColor,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: iconColor,
        ),
        selectedItemBuilder: (BuildContext context) {
          return widget.routes.map<Widget>((String route) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Text(
                route,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            );
          }).toList();
        },
        items: widget.routes.map((String route) {
          return DropdownMenuItem<String>(
            value: route,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 48,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  route,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// Period Dropdown Widget - Reusable
class PeriodDropdownFilter extends StatefulWidget {
  final List<String> periods;
  final String? selectedPeriod;
  final ValueChanged<String?> onChanged;
  final String label;

  const PeriodDropdownFilter({
    Key? key,
    required this.periods,
    this.selectedPeriod,
    required this.onChanged,
    this.label = "Period",
  }) : super(key: key);

  @override
  State<PeriodDropdownFilter> createState() => _PeriodDropdownFilterState();
}

class _PeriodDropdownFilterState extends State<PeriodDropdownFilter> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white.withOpacity(0.8) : Colors.black54;
    final iconColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: widget.selectedPeriod,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.calendar_today,
            color: iconColor,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: iconColor,
        ),
        selectedItemBuilder: (BuildContext context) {
          return widget.periods.map<Widget>((String period) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Text(
                period,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            );
          }).toList();
        },
        items: widget.periods.map((String period) {
          return DropdownMenuItem<String>(
            value: period,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 48,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  period,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// Category Dropdown Widget - Reusable
class CategoryDropdownFilter extends StatefulWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;
  final String label;

  const CategoryDropdownFilter({
    Key? key,
    required this.categories,
    this.selectedCategory,
    required this.onChanged,
    this.label = "Category",
  }) : super(key: key);

  @override
  State<CategoryDropdownFilter> createState() => _CategoryDropdownFilterState();
}

class _CategoryDropdownFilterState extends State<CategoryDropdownFilter> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white.withOpacity(0.8) : Colors.black54;
    final iconColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: widget.selectedCategory,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.category,
            color: iconColor,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: iconColor,
        ),
        selectedItemBuilder: (BuildContext context) {
          return widget.categories.map<Widget>((String category) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Text(
                category,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            );
          }).toList();
        },
        items: widget.categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 48,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  category,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: widget.onChanged,
      ),
    );
  }
}