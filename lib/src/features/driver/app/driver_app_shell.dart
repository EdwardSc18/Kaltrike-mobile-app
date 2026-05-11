import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/splash_screen.dart';

class DriverAppShell extends StatefulWidget {
  const DriverAppShell({super.key});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_DriverAppShellState>()?.restartApp();
  }

  @override
  State<DriverAppShell> createState() => _DriverAppShellState();
}

class _DriverAppShellState extends State<DriverAppShell> {
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
