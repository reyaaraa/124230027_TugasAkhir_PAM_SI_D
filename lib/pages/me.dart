// lib/pages/me_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:projectmobile/models/feedback_model.dart';
import 'package:projectmobile/services/database_service.dart';
import 'package:projectmobile/services/secure_store.dart';
import 'package:projectmobile/pages/feedback_form_page.dart';
import 'package:projectmobile/pages/login_page.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  final _dbService = DatabaseService();

  String? _username;
  List<FeedbackModel> _feedbackList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final username = await SecureStore.readEncrypted('session_user');
    final feedback = await _dbService.getFeedback(username ?? '');

    if (mounted) {
      setState(() {
        _username = username;
        _feedbackList = feedback;
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text("Hapus Masukan"),
          content: const Text("Apakah Anda yakin ingin menghapus masukan ini?"),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                "Hapus",
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () async {
                await _dbService.deleteFeedback(id);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Masukan berhasil dihapus.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  _loadData(); // Muat ulang daftar setelah menghapus
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ====== LOGOUT ======
  Future<void> _logout() async {
    await SecureStore.delete('session_user');
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
  // =====================

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            onPressed: _showLogoutConfirmation,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00796B)),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // FOTO PROFIL
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: const Color(0xFF2BB5A3),
                      child: CircleAvatar(
                        radius: 76,
                        backgroundImage: const AssetImage(
                          'assets/images/ara.jpg',
                        ),
                        backgroundColor: const Color(0xFFF9FCFB),
                        onBackgroundImageError: (exception, stackTrace) {
                          const Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.white70,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // USERNAME
                    Text(
                      _username ?? 'Pengguna',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // KARTU INFO
                    _buildInfoCard(
                      icon: Icons.person_outline,
                      title: "Nama",
                      value: "Fatimatuzzahra Filhayati",
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.badge_outlined,
                      title: "NIM",
                      value: "124230027",
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.school_outlined,
                      title: "Kelas",
                      value: "PAM-D",
                    ),
                    const SizedBox(height: 40),

                    // RIWAYAT MASUKAN
                    Text(
                      "RIWAYAT MASUKAN",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        letterSpacing: 1,
                        color: const Color(0xFF00796B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeedbackList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FeedbackFormPage()),
          );

          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: const Color(0xFF00796B),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildFeedbackList() {
    if (_feedbackList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text(
            "Belum ada kesan dan pesan.",
            style: GoogleFonts.poppins(color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _feedbackList.length,
      itemBuilder: (context, index) {
        final feedback = _feedbackList[index];

        return Stack(
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kesan: "${feedback.kesan}"',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Pesan: "${feedback.pesan}"'),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        'Dikirim: ${DateFormat('d MMM yyyy, HH:mm').format(feedback.createdAt)}',
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirmation(feedback.id!),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00796B), size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
