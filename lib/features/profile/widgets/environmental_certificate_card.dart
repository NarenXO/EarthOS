import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../models/certificate_model.dart';

class EnvironmentalCertificateCard extends StatelessWidget {
  final Certificate certificate;

  const EnvironmentalCertificateCard({
    super.key,
    required this.certificate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a5f2a), Color(0xFF2d8a4e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Environmental Impact Certificate",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildCertificateRow("Name", certificate.userName),
          const SizedBox(height: 12),
          _buildCertificateRow(
            "Verified Cleanups",
            certificate.verifiedCleanups.toString(),
          ),
          const SizedBox(height: 12),
          _buildCertificateRow(
            "Carbon Diverted",
            "${certificate.carbonDiverted.toStringAsFixed(1)} kg CO₂e",
          ),
          const SizedBox(height: 12),
          _buildCertificateRow(
            "Generated",
            "${certificate.generatedAt.day}/${certificate.generatedAt.month}/${certificate.generatedAt.year}",
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
