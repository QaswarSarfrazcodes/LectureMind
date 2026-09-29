import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';

class ApiKeyField extends StatefulWidget {
  const ApiKeyField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    required this.onValidate,
    this.hintText,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final Future<bool> Function(String key) onValidate;
  final String? hintText;

  @override
  State<ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<ApiKeyField> {
  late final TextEditingController _controller;
  bool _obscured = true;
  bool _isValidating = false;
  bool? _isValid;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant ApiKeyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!.trim();
      widget.onChanged(_controller.text);
      _validate();
    }
  }

  Future<void> _validate() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _isValidating = true;
      _isValid = null;
    });

    final valid = await widget.onValidate(key);

    if (mounted) {
      setState(() {
        _isValidating = false;
        _isValid = valid;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(valid ? '${widget.label} is valid & connected!' : 'Invalid key format or network error.'),
          backgroundColor: valid ? AppColors.success : AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: _obscured,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_obscured ? AppIcons.eye : AppIcons.eyeOff, size: AppDimens.iconSm),
              tooltip: _obscured ? 'Show key' : 'Hide key',
              onPressed: () => setState(() => _obscured = !_obscured),
            ),
            IconButton(
              icon: const Icon(Icons.paste, size: AppDimens.iconSm),
              tooltip: 'Paste from clipboard',
              onPressed: _pasteFromClipboard,
            ),
            if (_isValidating)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              IconButton(
                icon: Icon(
                  _isValid == true
                      ? AppIcons.checkCircle
                      : (_isValid == false ? Icons.error_outline : AppIcons.checkCircle),
                  color: _isValid == true
                      ? AppColors.success
                      : (_isValid == false ? AppColors.error : Colors.grey),
                  size: AppDimens.iconSm,
                ),
                tooltip: 'Validate API key',
                onPressed: _validate,
              ),
            const SizedBox(width: AppDimens.space4),
          ],
        ),
      ),
    );
  }
}
