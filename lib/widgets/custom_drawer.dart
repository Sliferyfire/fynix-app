import 'package:flutter/material.dart';
import 'package:fynix/providers/user_data_provider.dart';
import 'package:fynix/services/database/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserDataProvider>(context); 

    return Drawer(
      width: 250,
      child: Container(
        color: const Color(0xFF06373E),
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF06373E)),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: userProvider.photoUrl != null
                          ? NetworkImage(userProvider.photoUrl ?? "")
                          : null,
                      child: userProvider.photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.black87,
                            )
                          : null,
                    ),
                    SizedBox(height: 15,),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        userProvider.username ?? "",
                        style: GoogleFonts.lilitaOne(
                          color: Color(0xffFFFFFF),
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              drawerItem(Icons.home, "Inicio", "/home", context),
              drawerItem(Icons.show_chart, "Finanzas", "/finanzas", context),
              drawerItem(Icons.person, "Proveedores", "/proveedores", context),
              drawerItem(Icons.people, "Personal", "/personal", context),
              drawerItem(Icons.store, "Almacén", "/almacen", context),
              const Spacer(),
              logOutItem(Icons.logout, "Salir", "/login", context),
            ],
          ),
        ),
      ),
    );
  }

  Widget drawerItem(
    IconData icon,
    String title,
    String route,
    BuildContext context,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget logOutItem(
    IconData icon,
    String title,
    String route,
    BuildContext context,
  ) {
    final authService = Provider.of<AuthService>(context);
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: () {
        authService.signOut();
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}
