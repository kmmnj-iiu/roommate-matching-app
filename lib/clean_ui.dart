import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const blue = Color(0xFF2563EB);
  static const lightBlue = Color(0xFFEFF6FF);
  static const background = Color(0xFFF7F8FA);
  static const text = Color(0xFF172033);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E7EC);
  static const teal = Color(0xFF0F766E);
  static const warning = Color(0xFFFFF4E5);
}

class WhitePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const WhitePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class ChoiceTiles<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const ChoiceTiles({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final selected = value == entry.key;

        return ChoiceChip(
          label: Text(entry.value),
          selected: selected,
          showCheckmark: true,
          checkmarkColor: AppColors.blue,
          selectedColor: AppColors.lightBlue,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? AppColors.blue : AppColors.text,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          side: BorderSide(
            color: selected ? AppColors.blue : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          onSelected: (_) => onChanged(entry.key),
        );
      }).toList(),
    );
  }
}

class InfoPill extends StatelessWidget {
  final String text;

  const InfoPill({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String formatMinutes(int minutes) {
  final h = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}