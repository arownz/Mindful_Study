import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class ProfileInfoScreen extends StatelessWidget {
  const ProfileInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea( 
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                'Profile Info',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.64,
                  height: 1.2,
                ),
              ),
              Text(
                'Profile Info',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.tertiary,
                ),
              ),
              Text(
                'Profile Info',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
