import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kaltrike_driver_app/src/features/driver/state/app_info.dart';
import 'package:kaltrike_driver_app/src/core/utils/responsive.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/tabs/home_tab.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/tabs/profile_tab.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/tabs/ratings_tab.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/tabs/settings_tab.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/tabs/earnings_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin
{
  late final AppInfo _driverAppInfo;

  TabController? tabController;
  int selectIndex = 0;

  onItemClicked(int index)
  {
    setState((){
      selectIndex = index;
      tabController!.index = selectIndex;
    });
  }

  checkConnection() async {
    var connection = await Connectivity().checkConnectivity();
    if (connection == ConnectivityResult.none){
      return AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        width: context.r.wp(0.88, min: 280, max: 360),
        buttonsBorderRadius: const BorderRadius.all(
          Radius.circular(16),
        ),
        dismissOnTouchOutside: false,
        dismissOnBackKeyPress: false,
        onDismissCallback: (type) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dismissed by $type'),
            ),
          );
        },
        headerAnimationLoop: false,
        animType: AnimType.bottomSlide,
        title: 'No Internet Connection',
        desc: 'Please check your internet connection and try again.',
        btnOkOnPress: () {
          SystemNavigator.pop();
        },
        btnOkText: "Exit App",
        btnOkColor: const Color(0xFF2563EB),
      )..show();
    }
  }

  @override
  void initState()
  {
    super.initState();
    _driverAppInfo = AppInfo();
    checkConnection();
    tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppInfo>.value(
      value: _driverAppInfo,
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: tabController,
        children: [
          ChangeNotifierProvider<AppInfo>.value(
            value: _driverAppInfo,
            child: const HomeTabPage(),
          ),
          ChangeNotifierProvider<AppInfo>.value(
            value: _driverAppInfo,
            child: const EarningsTabPage(),
          ),
          ChangeNotifierProvider<AppInfo>.value(
            value: _driverAppInfo,
            child: const RatingsTabPage(),
          ),
          ChangeNotifierProvider<AppInfo>.value(
            value: _driverAppInfo,
            child: const ProfileTabPage(),
          ),
          ChangeNotifierProvider<AppInfo>.value(
            value: _driverAppInfo,
            child: const SettingsTabPage(),
          ), // New Settings Tab
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selectIndex == 0
                      ? const Color(0xFF2563EB).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home_rounded,
                  color: selectIndex == 0
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                  size: 26,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Color(0xFF2563EB),
                  size: 26,
                ),
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selectIndex == 1
                      ? const Color(0xFF2563EB).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.credit_card_rounded,
                  color: selectIndex == 1
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                  size: 26,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Color(0xFF2563EB),
                  size: 26,
                ),
              ),
              label: "Earnings",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selectIndex == 2
                      ? const Color(0xFF2563EB).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: selectIndex == 2
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                  size: 26,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFF2563EB),
                  size: 26,
                ),
              ),
              label: "Ratings",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selectIndex == 3
                      ? const Color(0xFF2563EB).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: selectIndex == 3
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                  size: 26,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF2563EB),
                  size: 26,
                ),
              ),
              label: "Profile",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selectIndex == 4
                      ? const Color(0xFF2563EB).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: selectIndex == 4
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                  size: 26,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Color(0xFF2563EB),
                  size: 26,
                ),
              ),
              label: "Settings",
            ),
          ],

          unselectedItemColor: const Color(0xFF64748B),
          selectedItemColor: const Color(0xFF2563EB),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          currentIndex: selectIndex,
          onTap: onItemClicked,
          elevation: 0,
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    tabController?.dispose();
    _driverAppInfo.dispose();
    super.dispose();
  }
}