import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = '冒险岛 079';
  static const String version = 'V0.79';
  static const String apiBaseUrl = 'http://localhost:8080/api/v1';
  static const String wsUrl = 'ws://localhost:8080/ws';
  static const double defaultGameWidth = 1024;
  static const double defaultGameHeight = 768;

  static const Map<int, String> jobNames = {
    0: '新手',
    100: '战士',
    200: '法师',
    300: '弓箭手',
    400: '飞侠',
    500: '海盗',
  };

  static const Map<int, Color> jobColors = {
    0: Color(0xFF9E9E9E),
    100: Color(0xFFC62828),
    200: Color(0xFF1565C0),
    300: Color(0xFFFFA000),
    400: Color(0xFF6A1B9A),
    500: Color(0xFF00838F),
  };
}
