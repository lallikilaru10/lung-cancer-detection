import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadZone extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? fileName;
  final VoidCallback onTap;
  final bool isLoading;

  const UploadZone({
    super.key,
    this.imageBytes,
    this.fileName,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<UploadZone> createState() => _UploadZoneState();
}

class _UploadZoneState extends State<UploadZone>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 280,
          decoration: BoxDecoration(
            color: _isHovering
                ? const Color(0xFF1A2040)
                : const Color(0xFF111729),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.imageBytes != null
                  ? const Color(0xFF00D4AA).withValues(alpha: 0.3)
                  : _isHovering
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
              width: widget.imageBytes != null ? 2 : 1.5,
            ),
          ),
          child: widget.imageBytes != null
              ? _buildPreview()
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.memory(
            widget.imageBytes!,
            fit: BoxFit.contain,
          ),

          // Gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.image_rounded,
                    color: Color(0xFF00D4AA),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.fileName ?? 'Selected image',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Change',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF00D4AA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _borderController,
          builder: (context, child) {
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withValues(
                    alpha: 0.15 + (_borderController.value * 0.15),
                  ),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Color(0xFF6C63FF),
                  size: 32,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Click to upload a CT scan',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Supports PNG, JPG, JPEG, DICOM',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white30,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open_rounded,
                color: Color(0xFF6C63FF),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Browse Files',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
