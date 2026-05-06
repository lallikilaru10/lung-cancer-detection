import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusIndicator extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onRefresh;

  const StatusIndicator({
    super.key,
    required this.isOnline,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onRefresh,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isOnline
                ? const Color(0xFF00D4AA).withValues(alpha: 0.08)
                : const Color(0xFFFF4757).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOnline
                  ? const Color(0xFF00D4AA).withValues(alpha: 0.2)
                  : const Color(0xFFFF4757).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline
                      ? const Color(0xFF00D4AA)
                      : const Color(0xFFFF4757),
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline
                              ? const Color(0xFF00D4AA)
                              : const Color(0xFFFF4757))
                          .withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOnline
                    ? 'Backend Server Online'
                    : 'Backend Offline — Tap to Retry',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isOnline
                      ? const Color(0xFF00D4AA)
                      : const Color(0xFFFF4757),
                ),
              ),
              if (!isOnline) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: const Color(0xFFFF4757).withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
