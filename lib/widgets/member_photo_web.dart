import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:web/web.dart' as web;

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
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      fit: StackFit.expand,
      children: [
        placeholder,
        HtmlElementView.fromTagName(
          tagName: 'img',
          hitTestBehavior: PlatformViewHitTestBehavior.translucent,
          onElementCreated: (element) {
            final image = element as web.HTMLImageElement;
            image.src = url;
            image.alt = 'Photo du membre';
            image.style
              ..width = '100%'
              ..height = '100%'
              ..objectFit = 'cover'
              ..borderRadius = '50%';
          },
        ),
      ],
    ),
  );
}
