import 'package:campha_moblie/app/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Search input thuần UI. Debounce và request cancellation thuộc feature sử dụng.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
    required this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.loading = false,
    this.maxLength = 100,
  });

  final TextEditingController controller;
  final String hintText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool loading;
  final int maxLength;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          autofocus: autofocus,
          maxLength: maxLength,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            counterText: '',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: SizedBox.square(
              dimension: 48,
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.quick),
                switchInCurve: AppMotion.stateCurve,
                switchOutCurve: AppMotion.stateCurve,
                child: loading
                    ? const Padding(
                        key: ValueKey('search-loading'),
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : value.text.isEmpty
                    ? const SizedBox.shrink(key: ValueKey('search-empty'))
                    : IconButton(
                        key: const ValueKey('search-clear'),
                        tooltip: clearTooltip,
                        onPressed: () {
                          controller.clear();
                          if (onClear case final clear?) {
                            clear();
                          } else {
                            onChanged('');
                          }
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
        ),
      );
}
