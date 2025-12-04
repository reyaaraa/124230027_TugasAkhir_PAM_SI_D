// lib/pages/me_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectmobile/services/secure_store.dart';
import 'package:projectmobile/pages/login_page.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  @override
  Widget build(BuildContext context) {
    const String name = "Fatimatuzzahra Filhayati";
    const String nim = "124230027";
    const String kelas = "Praktikum Mobile SI-E";

    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2BB5A3),
        title: Text(
          "PROFIL SAYA",
          style: GoogleFonts.poppins(
            fontSize: 20,
            letterSpacing: 2,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // FOTO PROFIL
                CircleAvatar(
                  radius: 80,
                  backgroundColor: const Color(0xFF2BB5A3),
                  child: CircleAvatar(
                    radius: 76,
                    backgroundImage: const AssetImage('assets/images/ara.jpg'),
                    backgroundColor: const Color(0xFFF9FCFB),
                  ),
                ),
                const SizedBox(height: 20),

                // NAMA
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // NIM
                Text(
                  nim,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 6),

                // KELAS
                Text(
                  kelas,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 40),

                // =============================
                // TOMBOL LOGOUT (menggunakan SecureStore.delete)
                // =============================
                ElevatedButton.icon(
                  onPressed: () async {
                    // PENTING: gunakan method yang ada di SecureStore milikmu.
                    // Di kode asli yang kamu kirim sebelumnya, nama method untuk hapus adalah:
                    //    SecureStore.delete('session_user');
                    // jadi kita panggil yang sama di sini.
                    await SecureStore.delete('session_user');

                    if (!mounted) return;

                    // Bersihkan navigation stack dan kembali ke LoginPage
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    "Logout",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
