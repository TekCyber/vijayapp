// lib/models/search_filter_models.dart
import 'package:flutter/material.dart';

// Search filter option model - widget-only approach
class SearchFilterOption {
  final String key;
  final Widget widget;

  SearchFilterOption({
    required this.key,
    required this.widget,
  });
}