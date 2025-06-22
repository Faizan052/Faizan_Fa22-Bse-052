import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/complaint.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';

class ComplaintForm extends StatefulWidget {
  @override
  State<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<ComplaintForm> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final imgCtrl = TextEditingController();
  final vidCtrl = TextEditingController();
  bool _isSubmitting = false;

  Future<String?> _fetchAdvisorId(String batchId) async {
    return await SupabaseService.getAdvisorIdForBatch(batchId);
  }

  bool _validateFields() {
    if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty) return false;
    if (imgCtrl.text.isNotEmpty && !imgCtrl.text.contains('drive.google.com')) return false;
    if (vidCtrl.text.isNotEmpty && !vidCtrl.text.contains('drive.google.com')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user!;
    return Scaffold(
      appBar: AppBar(title: Text("Submit Complaint")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleCtrl, decoration: InputDecoration(labelText: "Title")),
            TextField(controller: descCtrl, decoration: InputDecoration(labelText: "Description")),
            TextField(controller: imgCtrl, decoration: InputDecoration(labelText: "Image URL (Google Drive)")),
            TextField(controller: vidCtrl, decoration: InputDecoration(labelText: "Video URL (Google Drive)")),
            SizedBox(height: 20),
            _isSubmitting
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      if (!_validateFields()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please fill all fields correctly.')),
                        );
                        return;
                      }
                      setState(() => _isSubmitting = true);
                      try {
                        final advisorId = await _fetchAdvisorId(user.batchId);
                        if (advisorId == null || advisorId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Advisor not found for your batch.')),
                          );
                          setState(() => _isSubmitting = false);
                          return;
                        }
                        if (user.id.isEmpty || user.batchId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Student or batch ID missing.')),
                          );
                          setState(() => _isSubmitting = false);
                          return;
                        }
                        // Fetch HOD id for student's department
                        String? hodId;
                        if (user.departmentId.isNotEmpty) {
                          hodId = await SupabaseService.getHodIdForDepartment(user.departmentId);
                        }
                        final complaint = Complaint(
                          id: null, // Let backend generate the ID
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          imageUrl: imgCtrl.text,
                          videoUrl: vidCtrl.text,
                          studentId: user.id,
                          batchId: user.batchId,
                          advisorId: advisorId,
                          hodId: hodId,
                          status: 'Submitted',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        await SupabaseService.createComplaint(complaint.toMap());
                        // Refresh complaints after submission
                        await Provider.of<ComplaintProvider>(context, listen: false)
                            .fetchComplaints(user.id, 'student');
                        setState(() => _isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Complaint submitted successfully!')),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        setState(() => _isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Submission failed: \\${e.toString()}')),
                        );
                      }
                    },
                    child: Text("Submit"),
                  )
          ],
        ),
      ),
    );
  }
}

// TODOs:
// - Validation: Ensure image/video URLs are valid Google Drive links
// - Notifications: Show success/failure notification on complaint submission
