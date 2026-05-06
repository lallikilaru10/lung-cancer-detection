import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../services/api_service.dart';

class ProbabilityChart extends StatelessWidget {
  final List<ClassProbability> probabilities;

  const ProbabilityChart({super.key, required this.probabilities});

  Color _getBarColor(String severity, int index) {
    switch (severity) {
      case 'critical':
        return const Color(0xFFFF4757);
      case 'high':
        return const Color(0xFFFF8C42);
      case 'none':
        return const Color(0xFF00D4AA);
      default:
        return [
          const Color(0xFF6C63FF),
          const Color(0xFF00D4AA),
          const Color(0xFFFF8C42),
          const Color(0xFFFF4757),
        ][index % 4];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF141929),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF6C63FF),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Class Probabilities',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bars
            ...List.generate(probabilities.length, (index) {
              final prob = probabilities[index];
              final color = _getBarColor(prob.severity, index);
              final percentage = prob.probability * 100;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < probabilities.length - 1 ? 16 : 0,
                ),
                child: _buildBar(prob, color, percentage, index),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(
      ClassProbability prob, Color color, double percentage, int index) {
    return FadeInLeft(
      delay: Duration(milliseconds: 100 * index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prob.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1628),
              borderRadius: BorderRadius.circular(4),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 800 + (index * 200)),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * prob.probability,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withValues(alpha: 0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
