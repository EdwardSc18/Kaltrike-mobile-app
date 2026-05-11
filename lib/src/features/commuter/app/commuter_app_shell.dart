import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/splash_screen.dart';

class CommuterAppShell extends StatefulWidget {
  const CommuterAppShell({super.key});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_CommuterAppShellState>()?.restartApp();
  }

  @override
  State<CommuterAppShell> createState() => _CommuterAppShellState();
}

class _CommuterAppShellState extends State<CommuterAppShell> {
  Key _appKey = UniqueKey();

  void restartApp() {
    setState(() {
      _appKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _appKey,
      child: const MySplashScreen(),
    );
  }
}
