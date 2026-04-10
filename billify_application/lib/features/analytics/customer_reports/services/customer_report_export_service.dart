import 'dart:io';
import 'dart:typed_data';
import 'package:billify_application/features/analytics/customer_reports/models/customer_report_model.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class CustomerReportExportService {
  static Future<void> exportToPdf(CustomerReportsState state) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final headerDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Customer Ledger Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Consolidated Balance Statement', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text(headerDate),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfSummaryItem('Total Customers', state.summary.totalCustomers.toString()),
                _pdfSummaryItem('Total Receivables', currencyFormat.format(state.summary.totalReceivable), color: PdfColors.red700),
                _pdfSummaryItem('Total Payables', currencyFormat.format(state.summary.totalPayable), color: PdfColors.green700),
                _pdfSummaryItem('Net Balance', 
                  state.summary.netBalance >= 0 
                  ? currencyFormat.format(state.summary.netBalance)
                  : "-${currencyFormat.format(state.summary.netBalance.abs())}"),
              ],
            ),
            pw.SizedBox(height: 25),

            // Main Ledger Table
            pw.Text('Customer Balances', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 1),
            pw.TableHelper.fromTextArray(
              headers: ['Customer Name', 'Phone', 'Total Billed', 'Total Paid', 'Balance'],
              data: state.customers.map((c) {
                final balance = c.remainingBalance;
                final balanceText = balance > 0
                  ? "${currencyFormat.format(balance.abs())} (Get)"
                  : (balance < 0
                      ? "${currencyFormat.format(balance.abs())} (Give)"
                      : "₹0.00");
                  
                return [
                  c.name,
                  c.phoneNumber,
                  currencyFormat.format(c.totalBilled),
                  currencyFormat.format(c.totalPaid),
                  balanceText,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2.5),
              },
            ),
            
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'Note: "Get" indicates money owed by the customer (Receivable). "Give" indicates money owed to the customer (Payable).',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Customer_Ledger_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _pdfSummaryItem(String label, String value, {PdfColor? color}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static Future<void> exportToExcel(CustomerReportsState state) async {
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Customer Ledger'];
    
    // Header
    sheet.appendRow([excel_lib.TextCellValue('Customer Ledger Report - Summary')]);
    sheet.appendRow([excel_lib.TextCellValue('Generated On:'), excel_lib.TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()))]);
    sheet.appendRow([]);

    // Summary
    sheet.appendRow([excel_lib.TextCellValue('Net Receivables'), excel_lib.DoubleCellValue(state.summary.totalReceivable)]);
    sheet.appendRow([excel_lib.TextCellValue('Net Payables'), excel_lib.DoubleCellValue(state.summary.totalPayable)]);
    sheet.appendRow([excel_lib.TextCellValue('Net Balance'), excel_lib.DoubleCellValue(state.summary.netBalance)]);
    sheet.appendRow([]);

    // Data Table
    sheet.appendRow([
      excel_lib.TextCellValue('Customer Name'),
      excel_lib.TextCellValue('Phone'),
      excel_lib.TextCellValue('City'),
      excel_lib.TextCellValue('Total Billed'),
      excel_lib.TextCellValue('Total Paid'),
      excel_lib.TextCellValue('Balance'),
      excel_lib.TextCellValue('Type'),
    ]);

    for (var c in state.customers) {
      sheet.appendRow([
        excel_lib.TextCellValue(c.name),
        excel_lib.TextCellValue(c.phoneNumber),
        excel_lib.TextCellValue(c.city ?? ''),
        excel_lib.DoubleCellValue(c.totalBilled),
        excel_lib.DoubleCellValue(c.totalPaid),
        excel_lib.DoubleCellValue(c.remainingBalance.abs()),
        excel_lib.TextCellValue(c.remainingBalance > 0 ? 'YOU GET' : (c.remainingBalance < 0 ? 'YOU GIVE' : 'SETTLED')),
      ]);
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final directory = await getTemporaryDirectory();
    final fileName = 'Customer_Ledger_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Customer Ledger Export');
  }
}
