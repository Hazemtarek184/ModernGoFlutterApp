import 'package:flutter/material.dart';

/// Empty cart state showing "Your cart activity will appear here!" — matches design.
class EmptyCartView extends StatelessWidget {
  const EmptyCartView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'Your cart activity\nwill appear here!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
