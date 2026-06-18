import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

class ItemFormDialog extends StatefulWidget {
  const ItemFormDialog({
    super.key,
    required this.categories,
    required this.makers,
    required this.onSubmit,
  });

  final List<String> categories;
  final List<String> makers;
  final Future<void> Function({
    required String name,
    required String category,
    required String maker,
    required int price,
    required int stock,
  })
  onSubmit;

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _stockController = TextEditingController(text: '0');

  String? _selectedCategory;
  String? _selectedMaker;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final categories = _availableCategories;
    if (categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }
    if (widget.makers.isNotEmpty) {
      _selectedMaker = widget.makers.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  List<String> get _availableCategories =>
      widget.categories.where((category) => category != '전체').toList();

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
                          '품목 등록',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
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
                    label: '상품명',
                    child: TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('상품명'),
                      validator: _required,
                    ),
                  ),
                  _FormRow(
                    label: '카테고리',
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: _inputDecoration('카테고리'),
                      items: [
                        for (final category in _availableCategories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      validator: _required,
                    ),
                  ),
                  _FormRow(
                    label: '제조사',
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedMaker,
                      decoration: _inputDecoration('제조사'),
                      items: [
                        for (final maker in widget.makers)
                          DropdownMenuItem(value: maker, child: Text(maker)),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedMaker = value),
                    ),
                  ),
                  _FormRow(
                    label: '판매가',
                    child: TextFormField(
                      controller: _priceController,
                      decoration: _inputDecoration('판매가'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _number,
                    ),
                  ),
                  _FormRow(
                    label: '초기 재고',
                    child: TextFormField(
                      controller: _stockController,
                      decoration: _inputDecoration('초기 재고'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _number,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(_isSubmitting ? '등록 중' : '등록'),
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

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: const OutlineInputBorder(),
      isDense: true,
      errorStyle: const TextStyle(color: Colors.red, fontSize: 10, height: 1.1),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '필수 입력 항목입니다.';
    }

    return null;
  }

  String? _number(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) {
      return '0 이상의 숫자를 입력해주세요.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        name: _nameController.text.trim(),
        category: _selectedCategory ?? '',
        maker: _selectedMaker ?? '',
        price: int.parse(_priceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
