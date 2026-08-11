import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/certificate_model.dart';

class CertificatePdfService {
  static Future<File> generateAndSave(Certificate cert) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green800, width: 3),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('EARTHOS',
                    style: pw.TextStyle(
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800)),
                pw.SizedBox(height: 8),
                pw.Text('Environmental Impact Certificate',
                    style: pw.TextStyle(
                        fontSize: 18, color: PdfColors.green700)),
                pw.Divider(color: PdfColors.green600, thickness: 2),
                pw.SizedBox(height: 24),
                pw.Text('This certifies that',
                    style: const pw.TextStyle(
                        fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 12),
                pw.Text(cert.userName,
                    style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black)),
                pw.SizedBox(height: 24),
                pw.Text('has made a verified environmental impact through',
                    style: const pw.TextStyle(
                        fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 24),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBox('Verified Cleanups', '${cert.verifiedCleanups}'),
                    _statBox('CO2 Diverted',
                        '${cert.carbonDiverted.toStringAsFixed(1)} kg'),
                  ],
                ),
                pw.SizedBox(height: 32),
                pw.Text(_getTitle(cert.carbonDiverted),
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800)),
                pw.SizedBox(height: 32),
                pw.Divider(color: PdfColors.green600),
                pw.SizedBox(height: 12),
                pw.Text(
                    'Generated: ${cert.generatedAt.toLocal().toString().split('.')[0]}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
                pw.Text('EarthOS — AI 4 Earth Hackathon 2026',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/earthos_certificate_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    print('Certificate saved to: $path');
    return file;
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green600),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800)),
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 12, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static String _getTitle(double carbon) {
    if (carbon >= 200) return 'Climate Champion';
    if (carbon >= 100) return 'Environmental Guardian';
    if (carbon >= 50) return 'Carbon Cutter';
    return 'Eco Warrior';
  }

  static Future<void> shareCertificate(Certificate cert) async {
    final file = await generateAndSave(cert);
    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: 'EarthOS_Certificate_${cert.userName}.pdf',
    );
  }
}
