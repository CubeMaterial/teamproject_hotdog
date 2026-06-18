import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../../../domain/entities/refund.dart';
import '../../../../widgets/dashboard_text_detail_dialog.dart';

class RefundDetailDialog extends StatefulWidget {
  const RefundDetailDialog({
    super.key,
    required this.refund,
    required this.onStatusChanged,
  });

  final Refund refund;
  final Future<void> Function({
    required String refundId,
    required String action,
  })
  onStatusChanged;

  @override
  State<RefundDetailDialog> createState() => _RefundDetailDialogState();
}

class _RefundDetailDialogState extends State<RefundDetailDialog> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final refund = widget.refund;

    return DashboardTextDetailDialog(
      title: '환불 상세',
      items: [
        DashboardTextDetailItem(label: '환불번호', value: '${refund.refundSeq}'),
        DashboardTextDetailItem(label: '주문번호', value: refund.orderNumber),
        DashboardTextDetailItem(label: '구매번호', value: '${refund.buySeq}'),
        DashboardTextDetailItem(label: '회원번호', value: '${refund.userSeq}'),
        DashboardTextDetailItem(label: '회원명', value: refund.memberName),
        DashboardTextDetailItem(label: '상품명', value: refund.itemName),
        DashboardTextDetailItem(label: '수량', value: '${refund.quantity}'),
        DashboardTextDetailItem(
          label: '환불금액',
          value: '${_formatNumber(refund.amount)}원',
        ),
        DashboardTextDetailItem(label: '환불상태', value: refund.status),
        DashboardTextDetailItem(label: '원본상태', value: refund.rawStatus),
        DashboardTextDetailItem(label: '주문상태', value: refund.orderStatus),
        DashboardTextDetailItem(
          label: '구매일',
          value: _formatDateTime(refund.orderedAt),
        ),
        DashboardTextDetailItem(
          label: '요청일',
          value: _formatDateTime(refund.requestedAt),
        ),
        DashboardTextDetailItem(
          label: '환불 상세내용',
          value: refund.refundDetails.trim().isEmpty
              ? '-'
              : refund.refundDetails,
        ),
      ],
      actions: [
        OutlinedButton(
          onPressed: _isUpdating ? null : () => _updateStatus('canceled'),
          style: _refundActionButtonStyle,
          child: const Text('환불 취소 하기'),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: _isUpdating ? null : () => _updateStatus('pending'),
          style: _refundActionButtonStyle,
          child: const Text('환불 보류하기'),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: _isUpdating ? null : () => _updateStatus('approved'),
          style: _refundActionButtonStyle,
          child: Text(_isUpdating ? '처리 중' : '환불 처리하기'),
        ),
      ],
    );
  }

  ButtonStyle get _refundActionButtonStyle {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.deepOrange.withValues(alpha: 0.45);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return Colors.white;
        }
        return AppColors.deepOrange;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return AppColors.deepOrange;
        }
        return Colors.transparent;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final opacity = states.contains(WidgetState.disabled) ? 0.45 : 1.0;
        return BorderSide(
          color: AppColors.deepOrange.withValues(alpha: opacity),
        );
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }

  Future<void> _updateStatus(String action) async {
    setState(() => _isUpdating = true);

    try {
      await widget.onStatusChanged(refundId: widget.refund.id, action: action);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('환불 상태가 변경되었습니다.')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('환불 상태 변경에 실패했습니다.')));
    }
  }

  String _formatDateTime(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) {
      return '-';
    }

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$month-$day $hour:$minute';
  }

  String _formatNumber(int value) {
    final sign = value < 0 ? '-' : '';
    final text = value.abs().toString();
    final buffer = StringBuffer(sign);

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}
