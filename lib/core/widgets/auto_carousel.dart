import 'dart:async';

import 'package:flutter/material.dart';

/// Auto-sliding carousel with a smooth page indicator, per
/// docs/IMPLEMENTATION_ROADMAP.md §2 (`ImageCarousel`) — used for the Home
/// hero banner today; generic enough to reuse for a product image gallery
/// once Product Detail exists. Animation is a plain [PageView] slide (the
/// framework default) plus a fading/scaling dot indicator — nothing
/// flashier, per the Phase 2B brief's "subtle animations only".
class AutoCarousel extends StatefulWidget {
  const AutoCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 200,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.viewportFraction = 0.9,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;
  final Duration autoPlayInterval;
  final double viewportFraction;

  @override
  State<AutoCarousel> createState() => _AutoCarouselState();
}

class _AutoCarouselState extends State<AutoCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: widget.viewportFraction,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.itemCount > 1) {
      _timer = Timer.periodic(widget.autoPlayInterval, (_) => _advance());
    }
  }

  void _advance() {
    if (!_controller.hasClients) return;
    final next = (_controller.page ?? 0).round() + 1;
    _controller.animateToPage(
      next % widget.itemCount,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.itemCount,
            itemBuilder: widget.itemBuilder,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final page = _controller.hasClients
                ? (_controller.page ?? 0)
                : 0.0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.itemCount, (i) {
                final distance = (page - i).abs().clamp(0.0, 1.0);
                final isActive = distance < 0.5;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 1 - distance * 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
