import 'package:flutter/material.dart';

class MemberPhoto extends StatelessWidget {
  const MemberPhoto({
    super.key,
    required this.url,
    required this.size,
    required this.placeholder,
  });

  final String url;
  final double size;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox.square(
      dimension: size,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    ),
  );
}
