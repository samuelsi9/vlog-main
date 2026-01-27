import 'package:flutter/material.dart';

class Textfielded extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;
  const Textfielded({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          fillColor: Colors.grey[200],
          filled: true,
          hintText: hintText,
        ),
      ),
    );
  }
}
