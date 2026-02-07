import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';

/// Service for generating PDF reports from alert data
/// Creates formatted incident reports for the Ministry of Education Malaysia
class PDFGenerator {
  /// Generates and displays a PDF report for a given alert
  /// Opens the system print dialog with the generated PDF
  static Future<void> generateReport(AlertModel alert) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header section with ministry branding
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 2),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'KEMENTERIAN PENDIDIKAN MALAYSIA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'MINISTRY OF EDUCATION MALAYSIA',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Text(
                        'SCHOOL DISCIPLINE INCIDENT REPORT',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
                
                // Incident details
                _buildPDFRow(
                    'Report Date:', DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())),
                _buildPDFRow(
                    'Incident Date:', DateFormat('dd MMMM yyyy, HH:mm').format(alert.timestamp)),
                _buildPDFRow('Location:', alert.location),
                _buildPDFRow('Incident Type:', alert.type),
                _buildPDFRow('Severity Level:', alert.severity),
                pw.SizedBox(height: 20),
                
                // AI analysis section
                pw.Text('AI ANALYSIS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text(alert.details, style: const pw.TextStyle(fontSize: 11)),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Open print dialog with generated PDF
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  /// Builds a labeled row for PDF content with consistent formatting
  static pw.Widget _buildPDFRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(label,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }
}
