import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../utils/validator.dart';
import '../widgets/custom_button.dart';
import '../utils/theme.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({Key? key}) : super(key: key);

  @override
  _SubmitComplaintScreenState createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = Provider.of<AuthProvider>(context, listen: false).user!;
        final batch = await Supabase.instance.client
            .from('batches')
            .select()
            .eq('id', user.batchId!)
            .single();
        await DatabaseService().submitComplaint(
          title: _titleController.text,
          description: _descriptionController.text,
          imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
          videoUrl: _videoUrlController.text.isEmpty ? null : _videoUrlController.text,
          studentId: user.id,
          batchId: user.batchId!,
          advisorId: batch['advisor_id'],
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit complaint: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Complaint')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: AppTheme.glassDecoration(),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) => Validator.validateRequired(value, 'Title'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 4,
                      validator: (value) => Validator.validateRequired(value, 'Description'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Image URL (Google Drive, optional)',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _videoUrlController,
                      decoration: InputDecoration(
                        labelText: 'Video URL (Google Drive, optional)',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : CustomButton(text: 'Submit', onPressed: _submitComplaint),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}