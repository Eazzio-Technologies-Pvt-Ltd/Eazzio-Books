import 'package:flutter/material.dart';

class AppAnimations {
  static const Duration defaultDuration = Duration(milliseconds: 200);

  // Fade In Transition
  static Widget fadeIn({
    required Widget child,
    Duration duration = defaultDuration,
    Key? key,
  }) {
    return _FadeInWidget(key: key, duration: duration, child: child);
  }

  // Slide Up Transition
  static Widget slideUp({
    required Widget child,
    Duration duration = defaultDuration,
    Key? key,
  }) {
    return _SlideUpWidget(key: key, duration: duration, child: child);
  }

  // Combined Slide and Fade Transition
  static Widget slideFade({
    required Widget child,
    Duration duration = defaultDuration,
    Key? key,
  }) {
    return _FadeInWidget(
      duration: duration,
      child: _SlideUpWidget(key: key, duration: duration, child: child),
    );
  }
}

class _FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _FadeInWidget({super.key, required this.child, required this.duration});

  @override
  State<_FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<_FadeInWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

class _SlideUpWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _SlideUpWidget({super.key, required this.child, required this.duration});

  @override
  State<_SlideUpWidget> createState() => _SlideUpWidgetState();
}

class _SlideUpWidgetState extends State<_SlideUpWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<Offset>(
      begin: const Offset(0.0, 0.08), // Subtle slide up
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _animation, child: widget.child);
  }
}
