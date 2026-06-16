import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

class PurchaseOrderFormDialog extends StatefulWidget {
  const PurchaseOrderFormDialog({super.key});

  @override
  State<PurchaseOrderFormDialog> createState() =>
      _PurchaseOrderFormDialogState();
}

class _PurchaseOrderFormDialogState extends State<PurchaseOrderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vendorController = TextEditingController();
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController();
  final _createdAtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _createdAtController.text = _formatDate(DateTime.now());
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _itemController.dispose();
    _quantityController.dispose();
    _createdAtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '발주 등록',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: const Color(0xFF333333),
                        iconSize: 30,
                        tooltip: '닫기',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Divider(height: 1, color: AppColors.border),
                  _FormRow(
                    label: '거래처',
                    child: TextFormField(
                      controller: _vendorController,
                      decoration: const InputDecoration(
                        hintText: '거래처',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: _required,
                    ),
                  ),
                  _FormRow(
                    label: '품목',
                    child: TextFormField(
                      controller: _itemController,
                      decoration: const InputDecoration(
                        hintText: '품목',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: _required,
                    ),
                  ),
                  _FormRow(
                    label: '수량',
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: '수량',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: _validateQuantity,
                    ),
                  ),
                  _FormRow(
                    label: '발주일',
                    child: TextFormField(
                      controller: _createdAtController,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [_DateInputFormatter()],
                      decoration: const InputDecoration(
                        hintText: 'YYYY-MM-DD',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: _validateDate,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('등록'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '필수 입력 항목입니다.';
    }

    return null;
  }

  String? _validateQuantity(String? value) {
    final requiredMessage = _required(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final quantity = int.tryParse(value ?? '');
    if (quantity == null || quantity <= 0) {
      return '수량은 1 이상이어야 합니다.';
    }

    return null;
  }

  String? _validateDate(String? value) {
    final requiredMessage = _required(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }

    if (_parseDate(value ?? '') == null) {
      return '발주일은 YYYY-MM-DD 형식으로 입력해 주세요.';
    }

    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      PurchaseOrderFormData(
        vendor: _vendorController.text.trim(),
        itemName: _itemController.text.trim(),
        quantity: int.parse(_quantityController.text),
        createdAt: _parseDate(_createdAtController.text)!,
      ),
    );
  }

  DateTime? _parseDate(String value) {
    final dateText = value.trim();
    final date = DateTime.tryParse(dateText);

    if (date == null || dateText.length != 10) {
      return null;
    }

    if (_formatDate(date) != dateText) {
      return null;
    }

    return date;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class PurchaseOrderFormData {
  const PurchaseOrderFormData({
    required this.vendor,
    required this.itemName,
    required this.quantity,
    required this.createdAt,
  });

  final String vendor;
  final String itemName;
  final int quantity;
  final DateTime createdAt;
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
    final formatted = _format(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    if (digits.length <= 4) {
      return digits;
    }

    if (digits.length <= 6) {
      return '${digits.substring(0, 4)}-${digits.substring(4)}';
    }

    return '${digits.substring(0, 4)}-${digits.substring(4, 6)}-${digits.substring(6)}';
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 150,
              color: AppColors.beige,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
