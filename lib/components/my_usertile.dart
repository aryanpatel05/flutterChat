import 'package:flutter/material.dart';

class MyUsertile extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  final Widget? trailing;
  final VoidCallback? onRefresh; // Add an optional refresh callback

  const MyUsertile({
    super.key,
    required this.onTap,
    required this.text,
    this.trailing,
    this.onRefresh, // Add the refresh callback
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(); // Call the onTap function
        }
        if (onRefresh != null) {
          onRefresh!(); // Call the refresh callback if provided
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 20),
            Expanded(
              child: Text(text),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
