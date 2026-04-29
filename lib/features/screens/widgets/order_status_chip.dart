import 'package:flutter/material.dart';

Widget orderStatusChip(String status) {
  final normalized = status.toLowerCase();
  Color color;
  if (normalized.contains('active') || normalized.contains('processing')) {
    color = const Color(0xFF0369A1);
  } else if (normalized.contains('completed') ||
      normalized.contains('delivered')) {
    color = const Color(0xFF166534);
  } else {
    color = const Color(0xFF92400E);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );
}
