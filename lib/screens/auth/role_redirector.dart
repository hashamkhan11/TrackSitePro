import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:track_site_pro_app/screens/dashboard/admin_dashboard.dart';
import '../dashboard/contractor_dashboard.dart';
import '../dashboard/supervisor_dashboard.dart';
import 'login_screen.dart';

class RoleRedirector extends StatelessWidget {
  const RoleRedirector({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const LoginScreen();
        } else {
          final role = snapshot.data!.get('role');
          if (role == 'contractor') {
            return const ContractorDashboard();
          } else if (role == 'supervisor') {
            return const SupervisorDashboard();
          }else if(role=='admin') {
            return const AdminDashboard();
          }
          else {
            return const LoginScreen();
          }
        }
      },
    );
  }
}
