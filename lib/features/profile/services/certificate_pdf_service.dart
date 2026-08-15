import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/certificate_model.dart';

class CertificatePdfService {
  static Future<File> generateAndSave(Certificate cert) async {
    final pdf = pw.Document();
    final tier = _getTier(cert.carbonDiverted);
    final gradientColors = _getGradient(tier);
    final badge = _getBadge(tier);
    final borderColor = _getBorderColor(tier);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(colors: gradientColors),
              borderRadius: pw.BorderRadius.circular(16),
            ),
            padding: const pw.EdgeInsets.all(8),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: borderColor, width: 4),
              ),
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(badge, style: const pw.TextStyle(fontSize: 60)),
                  pw.SizedBox(height: 8),
                  pw.Text('EARTHOS',
                      style: pw.TextStyle(
                          fontSize: 42,
                          fontWeight: pw.FontWeight.bold,
                          color: borderColor,
                          letterSpacing: 4)),
                  pw.SizedBox(height: 4),
                  pw.Text('CERTIFIED ENVIRONMENTAL IMPACT',
                      style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                          letterSpacing: 3)),
                  pw.SizedBox(height: 32),
                  pw.Container(
                    width: double.infinity,
                    height: 2,
                    color: borderColor,
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text('AWARDED TO',
                      style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                          letterSpacing: 2)),
                  pw.SizedBox(height: 8),
                  pw.Text(cert.userName.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 36,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black)),
                  pw.SizedBox(height: 24),
                  pw.Text(tier.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: borderColor,
                          letterSpacing: 2)),
                  pw.SizedBox(height: 32),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      _statBox('CO2 DIVERTED',
                          '${cert.carbonDiverted.toStringAsFixed(1)} kg', borderColor),
                      _statBox('CLEANUPS',
                          '${cert.verifiedCleanups}', borderColor),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: borderColor,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      'CERTIFICATE ID: ${_generateId(cert)}',
                      style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                      'Issued ${cert.generatedAt.toLocal().toString().split(' ')[0]}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.SizedBox(height: 4),
                  pw.Text('EarthOS - AI 4 Earth Hackathon 2026',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.Text('Verified via AI Vision + Community Consensus',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ),
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/earthos_cert_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    print('Certificate saved to: $path');
    return file;
  }

  static String _getTier(double carbon) {
    if (carbon >= 200) return 'Climate Champion';
    if (carbon >= 100) return 'Environmental Guardian';
    if (carbon >= 50) return 'Carbon Cutter';
    return 'Eco Novice';
  }

  static List<PdfColor> _getGradient(String tier) {
    switch (tier) {
      case 'Climate Champion':
        return [PdfColor.fromInt(0xFFFFD700), PdfColor.fromInt(0xFF00C896)];
      case 'Environmental Guardian':
        return [PdfColor.fromInt(0xFF00C896), PdfColor.fromInt(0xFF00838F)];
      case 'Carbon Cutter':
        return [PdfColor.fromInt(0xFF00C896), PdfColor.fromInt(0xFF00A57C)];
      default:
        return [PdfColor.fromInt(0xFF7BC67B), PdfColor.fromInt(0xFF4CAF50)];
    }
  }

  static PdfColor _getBorderColor(String tier) {
    switch (tier) {
      case 'Climate Champion': return PdfColor.fromInt(0xFFDAA520);
      case 'Environmental Guardian': return PdfColor.fromInt(0xFF00838F);
      case 'Carbon Cutter': return PdfColor.fromInt(0xFF00A57C);
      default: return PdfColor.fromInt(0xFF4CAF50);
    }
  }

  static String _getBadge(String tier) {
    switch (tier) {
      case 'Climate Champion': return 'STAR';
      case 'Environmental Guardian': return 'SHIELD';
      case 'Carbon Cutter': return 'LEAF';
      default: return 'SEED';
    }
  }

  static String _generateId(Certificate cert) {
    final hash = (cert.userName.hashCode + cert.generatedAt.millisecondsSinceEpoch).abs();
    return 'EOS-${hash.toString().substring(0, 8).toUpperCase()}';
  }

  static pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
          pw.SizedBox(height: 4),
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                  letterSpacing: 1.5)),
        ],
      ),
    );
  }

  static Future<void> shareCertificate(Certificate cert) async {
    final file = await generateAndSave(cert);
    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: 'EarthOS_Certificate_${cert.userName}.pdf',
    );
  }
}
