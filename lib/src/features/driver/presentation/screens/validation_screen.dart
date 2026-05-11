import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kaltrike_driver_app/src/features/driver/auth/presentation/screens/login_screen.dart';
import 'package:kaltrike_driver_app/src/features/driver/config/global.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/main_screen.dart';
import 'package:firebase_database/firebase_database.dart';

class ValidationScreen extends StatefulWidget {
  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  File? _idImage, _selfieImage, _permitImage;
  bool _isUploading = false;
  final DatabaseReference _driverRef = FirebaseDatabase.instance.ref("drivers");
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _pickImage(String type) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75, // Reduced from 85 for faster uploads
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > 3 * 1024 * 1024) { // Reduced from 5MB to 3MB
          Fluttertoast.showToast(msg: "Image must be under 3MB for faster upload");
          return;
        }

        setState(() {
          if (type == 'id') _idImage = file;
          else if (type == 'selfie') _selfieImage = file;
          else if (type == 'permit') _permitImage = file;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to select image");
    }
  }

  Future<String> _uploadImage(File image, String fileName) async {
    try {
      final ref = _storage.ref('driver_validations/${currentFirebaseUser!.uid}/$fileName.jpg');

      // Compress image further if needed
      final compressedImage = await _compressImageIfNeeded(image);

      // Upload with minimal metadata
      await ref.putFile(
        compressedImage,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception("Upload failed");
    }
  }

  Future<File> _compressImageIfNeeded(File image) async {
    final fileSize = await image.length();
    // If image is already under 1MB, don't compress further
    if (fileSize <= 1024 * 1024) return image;

    // For larger images, we could compress further here
    // For now, return original as compression is already done in picker
    return image;
  }

  Future<void> _submitValidation() async {
    if (_idImage == null || _selfieImage == null || _permitImage == null) {
      Fluttertoast.showToast(msg: "Please upload all required images");
      return;
    }

    setState(() => _isUploading = true);

    // Show upload progress indicator
    int uploadProgress = 0;
    const totalSteps = 4; // 3 images + database update

    void _updateProgress() {
      setState(() {
        uploadProgress++;
      });
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Upload images in sequence (better for slow connections)
      _updateProgress(); // Step 1 started
      final idUrl = await _uploadImage(_idImage!, 'id_$timestamp');

      _updateProgress(); // Step 2 started
      final selfieUrl = await _uploadImage(_selfieImage!, 'selfie_$timestamp');

      _updateProgress(); // Step 3 started
      final permitUrl = await _uploadImage(_permitImage!, 'permit_$timestamp');

      // Minimal database update
      _updateProgress(); // Step 4 started
      await _driverRef.child(currentFirebaseUser!.uid).update({
        "validationStatus": "pending",
        "validationIdUrl": idUrl,
        "validationSelfieUrl": selfieUrl,
        "validationPermitUrl": permitUrl,
        "validationNotes": "Pending review",
        "updatedAt": timestamp,
      });

      Fluttertoast.showToast(msg: "✅ Validation submitted!");

      // Navigate immediately after success
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
              (_) => false,
        );
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Upload failed. Check connection & retry.");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _imageUploadCard(String title, File? image, String type, String desc, IconData icon) {
    final isUploaded = image != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isUploaded ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isUploaded ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              if (isUploaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        "Ready",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => _pickImage(type),
            child: Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isUploaded ? Colors.green.withOpacity(0.02) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUploaded ? Colors.green.withOpacity(0.3) : Colors.grey.shade300,
                  width: isUploaded ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: image == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 28,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Tap to Upload",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Max 3MB",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                )
                    : Stack(
                  children: [
                    Image.file(image, fit: BoxFit.cover, width: double.infinity),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              "Change",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final total = 3;
    final completed = [_idImage, _selfieImage, _permitImage].where((img) => img != null).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Upload Progress",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: completed / total,
                  backgroundColor: Colors.blue.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "$completed/$total",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade700),
                    ),
                    Expanded(
                      child: Text(
                        "Account Validation",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade200,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.verified_outlined,
                          color: Colors.blue.shade700,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Verify Your Account",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Upload documents to start driving. Use Wi-Fi for faster uploads.",
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Progress Indicator
                _buildProgressIndicator(),

                const SizedBox(height: 28),

                // Upload Sections
                _imageUploadCard(
                  "Valid ID Photo",
                  _idImage,
                  'id',
                  "Upload a clear photo of your ID",
                  Icons.badge_outlined,
                ),

                _imageUploadCard(
                  "Selfie with ID",
                  _selfieImage,
                  'selfie',
                  "Selfie holding your ID",
                  Icons.face_outlined,
                ),

                _imageUploadCard(
                  "Driver's Permit",
                  _permitImage,
                  'permit',
                  "Tricycle/vehicle permit",
                  Icons.description_outlined,
                ),

                const SizedBox(height: 32),

                // Submit Button with lightweight warning
                Column(
                  children: [
                    if (_isUploading)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi, size: 18, color: Colors.orange.shade700),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Uploading... Keep app open & stay connected",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _idImage != null && _selfieImage != null && _permitImage != null && !_isUploading
                            ? _submitValidation
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          disabledBackgroundColor: Colors.blue.shade300,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isUploading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Uploading...",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              "Submit for Validation",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Skip Option
                Center(
                  child: TextButton(
                    onPressed: _isUploading
                        ? null
                        : () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                            (_) => false,
                      );
                    },
                    child: Text(
                      "Validate Later",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Footer Note
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Text(
                        "Tip: Connect to Wi-Fi for faster uploads",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "All information is securely stored for verification",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}