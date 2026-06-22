import 'package:flutter/material.dart';

const List<String> indianStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Andaman and Nicobar Islands',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry'
];

class StateDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const StateDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Normalise/ensure that value matches one of the items or defaults to Jharkhand
    String? normalisedValue = value;
    if (normalisedValue != null) {
      final match = indianStates.firstWhere(
        (s) => s.toLowerCase().trim() == normalisedValue!.toLowerCase().trim(),
        orElse: () => '',
      );
      normalisedValue = match.isNotEmpty ? match : null;
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      value: normalisedValue,
      items: indianStates.map((state) {
        return DropdownMenuItem<String>(
          value: state,
          child: Text(state),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
