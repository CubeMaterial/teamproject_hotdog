import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('품목 등록'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '상품명'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: '카테고리'),
                items: [
                  for (final category in _availableCategories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedMaker,
                decoration: const InputDecoration(labelText: '제조사'),
                items: [
                  for (final maker in widget.makers)
                    DropdownMenuItem(value: maker, child: Text(maker)),
                ],
                onChanged: (value) => setState(() => _selectedMaker = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: '판매가'),
                      keyboardType: TextInputType.number,
                      validator: _number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: '초기 재고'),
                      keyboardType: TextInputType.number,
                      validator: _number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isSubmitting ? '등록 중' : '등록'),
        ),
      ],
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
