import 'package:flutter/material.dart';

import '../../../../widgets/dashboard_status_badge.dart';

class StockStatusBadge extends DashboardStatusBadge {
  StockStatusBadge({super.key, required super.label})
    : super(color: _colorFor(label));

  static Color _colorFor(String label) {
    return switch (label) {
      '부족' => const Color(0xFFB91C1C),
      '주의' => const Color(0xFFC2410C),
      '정상' => const Color(0xFF15803D),
      _ => const Color(0xFF475569),
    };
  }
}

class ForecastRiskBadge extends DashboardStatusBadge {
  ForecastRiskBadge({super.key, required super.label})
    : super(color: _colorFor(label));

  static Color _colorFor(String label) {
    return switch (label) {
      '위험' => const Color(0xFFB91C1C),
      '주의' => const Color(0xFFC2410C),
      '양호' => const Color(0xFF15803D),
      _ => const Color(0xFF64748B),
    };
  }
}
