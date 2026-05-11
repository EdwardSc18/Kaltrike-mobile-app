import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/features/role_selection/presentation/screens/role_selection_screen.dart';
import 'package:kaltrike_driver_app/src/shared/ui/app_theme.dart';
import 'package:provider/provider.dart';

import 'package:kaltrike_driver_app/src/features/driver/state/app_info.dart' as driver_state;
import 'package:kaltrike_driver_app/src/features/commuter/state/app_info.dart' as commuter_state;

class KaltrikeApp extends StatelessWidget {
  const KaltrikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<driver_state.AppInfo>(
          create: (_) => driver_state.AppInfo(),
        ),
        ChangeNotifierProvider<commuter_state.AppInfo>(
          create: (_) => commuter_state.AppInfo(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kaltrike',
        theme: AppTheme.light(),
        home: const RoleSelectionScreen(),
      ),
    );
  }
}
