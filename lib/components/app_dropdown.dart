import 'package:flutter/material.dart';

class AppDropDown extends StatelessWidget {
  const AppDropDown({
    super.key,
    this.value,
    required this.labelText,
    required this.items,
    required this.onChanged,
    this.padding,
  });
  final String? value;
  final String? labelText;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        items: items.map((value) {
          return DropdownMenuItem(
            value: value,
            child: Text(
              value.toString(),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }
}
