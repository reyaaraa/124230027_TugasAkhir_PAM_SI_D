import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectmobile/models/feedback_model.dart';
import 'package:projectmobile/services/database_service.dart';
import 'package:projectmobile/services/secure_store.dart';

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _dbService = DatabaseService();
  final _kesanController = TextEditingController();
  final _pesanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final username = await SecureStore.readEncrypted('session_user');
      final feedback = FeedbackModel(
        username: username ?? 'unknown',
        kesan: _kesanController.text,
        pesan: _pesanController.text,
        createdAt: DateTime.now(),
      );

      await _dbService.addFeedback(feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terima kasih atas masukan Anda!'),
            backgroundColor: Colors.green,
          ),
        );
        // Kembali ke halaman profil dan kirim sinyal untuk refresh
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFB),
      appBar: AppBar(
        title: Text('Beri Masukan', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF2BB5A3),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            TextFormField(
              controller: _kesanController,
              decoration: const InputDecoration(
                labelText: 'Kesan Anda',
                hintText: 'Apa kesan pertama Anda tentang aplikasi ini?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sentiment_satisfied_alt_outlined),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Kesan tidak boleh kosong'
                  : null,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pesanController,
              decoration: const InputDecoration(
                labelText: 'Pesan/Saran',
                hintText: 'Ada saran untuk pengembangan selanjutnya?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lightbulb_outline),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Pesan tidak boleh kosong'
                  : null,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _submitFeedback,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      'Kirim Masukan',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFF00796B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
