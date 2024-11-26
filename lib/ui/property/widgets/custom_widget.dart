import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CustomDropdownSearch extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String labelText;
  final String hintText;
  final Map<String, dynamic>? selectedItem;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final String? Function(Map<String, dynamic>?)? validator;
  final bool Function(Map<String, dynamic>, Map<String, dynamic>?) compareFn;

  CustomDropdownSearch({
    required this.items,
    required this.labelText,
    required this.hintText,
    this.selectedItem,
    required this.onChanged,
    required this.validator,
    required this.compareFn,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<Map<String, dynamic>>(
      items: items,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54,
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white54
                : Colors.black38,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.white,
        ),
      ),
      selectedItem: selectedItem,
      dropdownBuilder: (context, selectedItem) {
        final displayText =
            selectedItem != null ? selectedItem["value"] : hintText;
        return Text(
          displayText,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        );
      },
      itemAsString: (Map<String, dynamic> item) => item["value"],
      onChanged: onChanged,
      validator: validator,
      compareFn: compareFn,
    );
  }
}
