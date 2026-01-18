import 'package:flutter/material.dart';
import '../../../../core/ui_kit/pulse_page.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Категории",
      showBackButton: true,
      body: Center(child: Text("Категории")),
    );
  }
}
