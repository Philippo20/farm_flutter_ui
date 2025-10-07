import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/manage_users_screen.dart';
import 'screens/admin/admin_farms_dashboard_screen.dart';
import 'screens/admin/admin_sensors_dashboard_screen.dart';
import 'screens/admin/settings_screen.dart';
import 'screens/owner/owner_dashboard_screen.dart';
import 'screens/owner/farm_screen.dart';
import 'screens/owner/farm_settings_screen.dart';
import 'screens/caretaker/caretaker_dashboard_screen.dart';
import 'screens/caretaker/caretaker_farm_screen.dart';
import 'screens/caretaker/care_taker_settings.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grow Room Dashboard',
      debugShowCheckedModeBanner: false,
      //home: AdminDashboardScreen(),
      initialRoute: '/login',
      routes: {
        //Admin
        '/dashboard': (context) => AdminDashboardScreen(),
        '/users': (context) => UsersScreen(), 
        '/farms': (context) => FarmsScreen(),
        '/sensors': (context) => SensorsScreen(),
        '/settings': (context) => FarmSettingsScreen(),
        '/login': (context) => LoginScreen(),
        //Owner
        '/owner_dashboard': (context) => OwnerDashboardScreen(),
        '/owner_farm': (context) => ownerFarmsScreen(),
        '/owner_settings': (context) => OwnerFarmsSettingsScreen(),
        //Caretaker
        '/caretaker_dashboard': (context) => CaretakerDashboardScreen(),
        '/farm': (context) => CaretakerFarmScreen(),
        '/caretaker_settings': (context) => CareTakerSettingsScreen(),
        /*
        '/alerts': (context) => AlertsScreen(),
        '/analytics': (context) => AnalyticsScreen(),
       
        */
      },
    );
  }
}
