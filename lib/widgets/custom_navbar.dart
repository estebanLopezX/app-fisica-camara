import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants.dart';

class CustomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0), // 🧱 Padding exterior
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor, // 🎨 Fondo azul #0088FF
          borderRadius: BorderRadius.circular(25), // 🔵 Bordes redondeados
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: widget.currentIndex,
            onTap: widget.onTap,
            backgroundColor:
                Colors.transparent, // Fondo transparente (usa el container)
            elevation: 0, // Sin sombra del propio BottomNavigationBar
            type: BottomNavigationBarType.fixed,

            // 🔹 Colores personalizados
            selectedItemColor: whiteColor,
            unselectedItemColor: whiteColor.withOpacity(0.7),

            items: const [
              BottomNavigationBarItem(
                icon: Icon(
                  PhosphorIconsFill.compass,
                  color: whiteColor,
                ), // 🧭 Minimalista para "Navegar"
                label: "Navegar",
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  PhosphorIconsFill.camera,
                  color: whiteColor,
                ), // 📷 Cámara sólida
                label: "Cámara",
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  PhosphorIconsFill.user,
                  color: whiteColor,
                ), // 👤 Perfil con relleno
                label: "Perfil",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
