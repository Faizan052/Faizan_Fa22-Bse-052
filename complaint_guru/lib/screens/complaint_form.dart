import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/complaint.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';

class ComplaintForm extends StatefulWidget {
  @override
  State<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<ComplaintForm> with SingleTickerProviderStateMixin {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final imgCtrl = TextEditingController();
  final vidCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showImageHint = false;
  bool _showVideoHint = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    titleCtrl.dispose();
    descCtrl.dispose();
    imgCtrl.dispose();
    vidCtrl.dispose();
    super.dispose();
  }

  Future<String?> _fetchAdvisorId(String batchId) async {
    return await SupabaseService.getAdvisorIdForBatch(batchId);
  }

  bool _validateFields() {
    if (!_formKey.currentState!.validate()) return false;
    if (imgCtrl.text.isNotEmpty && !imgCtrl.text.contains('drive.google.com')) return false;
    if (vidCtrl.text.isNotEmpty && !vidCtrl.text.contains('drive.google.com')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final user = Provider.of<AuthProvider>(context).user!;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            colors: [Color(0xFF4F8FFF), Color(0xFF1CB5E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          child: Text(
            "Submit Complaint",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 1.1,
            ),
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F8FFF), Color(0xFF1CB5E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F8FFF).withOpacity(0.08), Color(0xFF1CB5E0).withOpacity(0.08), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  TextFormField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: "Title",
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.blue[900]),
                      prefixIcon: Icon(Icons.title, color: Color(0xFF4F8FFF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Description Field
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: "Description",
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.blue[900]),
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description, color: Color(0xFF4F8FFF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.length < 20) {
                        return 'Description should be at least 20 characters';
                      }
                      return null;
                    },
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Image URL Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: imgCtrl,
                        decoration: InputDecoration(
                          labelText: "Image URL (Google Drive)",
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.blue[900]),
                          prefixIcon: Icon(Icons.image, color: Color(0xFF4F8FFF)),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.info_outline, color: Color(0xFF1CB5E0)),
                            onPressed: () {
                              setState(() {
                                _showImageHint = !_showImageHint;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && !value.contains('drive.google.com')) {
                            return 'Please enter a valid Google Drive URL';
                          }
                          return null;
                        },
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (_showImageHint)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 8),
                          child: Text(
                            'Upload image to Google Drive and paste the shareable link here',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Video URL Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: vidCtrl,
                        decoration: InputDecoration(
                          labelText: "Video URL (Google Drive)",
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.blue[900]),
                          prefixIcon: Icon(Icons.video_library, color: Color(0xFF4F8FFF)),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.info_outline, color: Color(0xFF1CB5E0)),
                            onPressed: () {
                              setState(() {
                                _showVideoHint = !_showVideoHint;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && !value.contains('drive.google.com')) {
                            return 'Please enter a valid Google Drive URL';
                          }
                          return null;
                        },
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (_showVideoHint)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 8),
                          child: Text(
                            'Upload video to Google Drive and paste the shareable link here',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1CB5E0),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Color(0xFF1CB5E0).withOpacity(0.3),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                        if (!_validateFields()) return;

                        setState(() => _isSubmitting = true);
                        try {
                          final advisorId = await _fetchAdvisorId(user.batchId);
                          if (advisorId == null || advisorId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Advisor not found for your batch.'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                            setState(() => _isSubmitting = false);
                            return;
                          }

                          if (user.id.isEmpty || user.batchId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Student or batch ID missing.'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
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

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Complaint submitted successfully!'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Submission failed: ${e.toString()}'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } finally {
                          setState(() => _isSubmitting = false);
                        }
                      },
                      child: _isSubmitting
                          ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        "SUBMIT COMPLAINT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}