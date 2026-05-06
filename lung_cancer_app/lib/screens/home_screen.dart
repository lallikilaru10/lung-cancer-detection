import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/upload_zone.dart';
import '../widgets/result_card.dart';
import '../widgets/probability_chart.dart';
import '../widgets/header_section.dart';
import '../widgets/status_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  PredictionResult? _result;
  bool _isLoading = false;
  String? _error;
  bool _serverOnline = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkServer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkServer() async {
    final online = await ApiService.healthCheck();
    if (mounted) {
      setState(() => _serverOnline = online);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedImageBytes = result.files.single.bytes;
        _selectedFileName = result.files.single.name;
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _predict() async {
    if (_selectedImageBytes == null || _selectedFileName == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await ApiService.predict(
        _selectedImageBytes!,
        _selectedFileName!,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _selectedImageBytes = null;
      _selectedFileName = null;
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E1A),
              Color(0xFF0F1628),
              Color(0xFF0A0E1A),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 80 : 20,
              vertical: 24,
            ),
            child: Column(
              children: [
                // Header
                const HeaderSection(),
                const SizedBox(height: 12),

                // Server status
                StatusIndicator(
                  isOnline: _serverOnline,
                  onRefresh: _checkServer,
                ),
                const SizedBox(height: 32),

                // Main content
                if (isWide)
                  _buildWideLayout()
                else
                  _buildNarrowLayout(),

                const SizedBox(height: 48),

                // Footer
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Text(
                    '⚕️ This tool is for research and educational purposes only. Always consult a qualified medical professional for diagnosis.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel – Upload
        Expanded(
          flex: 5,
          child: FadeInLeft(
            child: _buildUploadPanel(),
          ),
        ),
        const SizedBox(width: 32),
        // Right panel – Results
        Expanded(
          flex: 5,
          child: FadeInRight(
            child: _buildResultsPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        FadeInUp(child: _buildUploadPanel()),
        const SizedBox(height: 24),
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: _buildResultsPanel(),
        ),
      ],
    );
  }

  Widget _buildUploadPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withValues(alpha: 0.03),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xFF00D4AA),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Upload CT Scan',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Upload a chest CT scan image for AI-powered analysis',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 24),

            // Upload zone
            UploadZone(
              imageBytes: _selectedImageBytes,
              fileName: _selectedFileName,
              onTap: _pickImage,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildAnalyzeButton(),
                ),
                if (_selectedImageBytes != null) ...[
                  const SizedBox(width: 12),
                  _buildResetButton(),
                ],
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    final canAnalyze =
        _selectedImageBytes != null && !_isLoading && _serverOnline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: canAnalyze
            ? const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
              )
            : null,
        color: canAnalyze ? null : const Color(0xFF1E2438),
        boxShadow: canAnalyze
            ? [
                BoxShadow(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canAnalyze ? _predict : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.biotech_outlined,
                        color: canAnalyze ? Colors.white : Colors.white30,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Analyze Scan',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: canAnalyze ? Colors.white : Colors.white30,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2438),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _reset,
          borderRadius: BorderRadius.circular(14),
          child: const Center(
            child: Icon(
              Icons.refresh_rounded,
              color: Colors.white54,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4757).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF4757).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF4757), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.inter(
                color: const Color(0xFFFF4757),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_result == null) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ResultCard(result: _result!),
        const SizedBox(height: 20),
        ProbabilityChart(probabilities: _result!.allProbabilities),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00D4AA).withValues(
                      alpha: 0.05 + _pulseController.value * 0.1,
                    ),
                    border: Border.all(
                      color: const Color(0xFF00D4AA).withValues(
                        alpha: 0.2 + _pulseController.value * 0.3,
                      ),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.biotech,
                      color: Color(0xFF00D4AA),
                      size: 36,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Analyzing CT Scan...',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Running hybrid ensemble model with 4 neural networks',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  backgroundColor: Color(0xFF1E2438),
                  color: Color(0xFF00D4AA),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
              ),
              child: const Center(
                child: Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF6C63FF),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Analysis Results',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a CT scan and click Analyze\nto see the results here',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white24,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
