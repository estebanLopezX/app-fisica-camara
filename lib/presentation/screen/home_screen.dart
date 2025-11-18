import 'package:flutter/material.dart';
import 'package:parabola_detector/presentation/screen/camera_screen.dart';
import 'package:parabola_detector/presentation/screen/perfil_screen.dart';
import '../../core/theme.dart';
import '../../widgets/custom_navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = [
    const Center(child: Text("⭐ Navegar")), // Aqui va ir las formulas y demás
    const CameraScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.scaffoldBackgroundColor,
      body: screens[selectedIndex],
      bottomNavigationBar: CustomNavBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}
