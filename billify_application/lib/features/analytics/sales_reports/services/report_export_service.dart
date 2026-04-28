import 'dart:io';
import 'dart:typed_data';
import 'package:billify/features/analytics/sales_reports/providers/sales_reports_provider.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ReportExportService {
  static Future<void> exportToPdf(SalesReportsState state) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Sales Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${dateFormat.format(state.startDate ?? DateTime.now())} - ${dateFormat.format(state.endDate ?? DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Section
            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfSummaryItem(
                  'Total Sales',
                  currencyFormat.format(state.summary.totalSales),
                ),
                _pdfSummaryItem(
                  'Total Orders',
                  state.summary.totalOrders.toString(),
                ),
                _pdfSummaryItem(
                  'Average Bill',
                  currencyFormat.format(state.summary.avgBillValue),
                ),
                _pdfSummaryItem(
                  'Items Sold',
                  state.summary.totalItemsSold.toString(),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Top Products Section
            if (state.topProducts.isNotEmpty) ...[
              pw.Text(
                'Top Products',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                headers: ['Product Name', 'Quantity', 'Revenue'],
                data: state.topProducts
                    .map(
                      (p) => [
                        p.name,
                        p.quantity.toString(),
                        currencyFormat.format(p.revenue),
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 20),
            ],

            // Transactions Section
            pw.Text(
              'Recent Transactions',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              headers: [
                'Invoice #',
                'Date',
                'Customer Details',
                'Items (Qty)',
                'Total',
                'Payment',
              ],
              data: state.invoices
                  .map(
                    (inv) => [
                      inv.id,
                      dateFormat.format(inv.date),
                      "${inv.customer_name ?? 'Walk-in'}\n${inv.customer_phone ?? ''}",
                      inv.items
                          .map((i) => "${i.name} (x${i.quantity})")
                          .join("\n"),
                      currencyFormat.format(inv.final_amount),
                      inv.payment_mode,
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();

    // Preview and download/print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Sales_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _pdfSummaryItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static Future<void> exportToExcel(SalesReportsState state) async {
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Sales Report'];

    final dateFormat = DateFormat('yyyy-MM-dd');

    // Add Summary
    sheet.appendRow([excel_lib.TextCellValue('Sales Report Summary')]);
    sheet.appendRow([
      excel_lib.TextCellValue('From'),
      excel_lib.TextCellValue(
        dateFormat.format(state.startDate ?? DateTime.now()),
      ),
      excel_lib.TextCellValue('To'),
      excel_lib.TextCellValue(
        dateFormat.format(state.endDate ?? DateTime.now()),
      ),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      excel_lib.TextCellValue('Metric'),
      excel_lib.TextCellValue('Value'),
    ]);
    sheet.appendRow([
      excel_lib.TextCellValue('Total Sales'),
      excel_lib.DoubleCellValue(state.summary.totalSales),
    ]);
    sheet.appendRow([
      excel_lib.TextCellValue('Total Orders'),
      excel_lib.IntCellValue(state.summary.totalOrders),
    ]);
    sheet.appendRow([
      excel_lib.TextCellValue('Average Bill'),
      excel_lib.DoubleCellValue(state.summary.avgBillValue),
    ]);
    sheet.appendRow([
      excel_lib.TextCellValue('Items Sold'),
      excel_lib.IntCellValue(state.summary.totalItemsSold),
    ]);
    sheet.appendRow([]);

    // Top Products
    if (state.topProducts.isNotEmpty) {
      sheet.appendRow([excel_lib.TextCellValue('Top Products')]);
      sheet.appendRow([
        excel_lib.TextCellValue('Product Name'),
        excel_lib.TextCellValue('Quantity'),
        excel_lib.TextCellValue('Revenue'),
      ]);
      for (var p in state.topProducts) {
        sheet.appendRow([
          excel_lib.TextCellValue(p.name),
          excel_lib.IntCellValue(p.quantity),
          excel_lib.DoubleCellValue(p.revenue),
        ]);
      }
      sheet.appendRow([]);
    }

    // Transactions Table
    sheet.appendRow([excel_lib.TextCellValue('Transaction Details')]);
    sheet.appendRow([
      excel_lib.TextCellValue('Invoice #'),
      excel_lib.TextCellValue('Date'),
      excel_lib.TextCellValue('Customer Name'),
      excel_lib.TextCellValue('Phone Number'),
      excel_lib.TextCellValue('Items (Qty)'),
      excel_lib.TextCellValue('Total Amount'),
      excel_lib.TextCellValue('Payment Mode'),
    ]);

    for (var inv in state.invoices) {
      sheet.appendRow([
        excel_lib.TextCellValue(inv.id),
        excel_lib.TextCellValue(dateFormat.format(inv.date)),
        excel_lib.TextCellValue(inv.customer_name ?? 'Walk-in'),
        excel_lib.TextCellValue(inv.customer_phone ?? ''),
        excel_lib.TextCellValue(
          inv.items.map((i) => "${i.name} (x${i.quantity})").join(", "),
        ),
        excel_lib.DoubleCellValue(inv.final_amount),
        excel_lib.TextCellValue(inv.payment_mode),
      ]);
    }

    // Delete default sheet if exists
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final directory = await getTemporaryDirectory();
    final fileName =
        'Sales_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    // Share/Export the file
    await Share.shareXFiles([XFile(file.path)], text: 'Sales Report Excel');
  }
}
