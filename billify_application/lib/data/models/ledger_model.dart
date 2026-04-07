import 'customer_model.dart';
import 'payment_model.dart';

class CustomerLedger {
  final Customer customer;
  final List<Payment> ledger;
  final LedgerSummary summary;

  CustomerLedger({
    required this.customer,
    required this.ledger,
    required this.summary,
  });

  factory CustomerLedger.fromJson(Map<String, dynamic> json) {
    return CustomerLedger(
      customer: Customer.fromJson(json['customer']),
      ledger: (json['ledger'] as List).map((i) => Payment.fromJson(i)).toList(),
      summary: LedgerSummary.fromJson(json['summary']),
    );
  }
}

class LedgerSummary {
  final double openingBalance;
  final double totalCredit;
  final double totalDebit;
  final double remainingBalance;

  LedgerSummary({
    required this.openingBalance,
    required this.totalCredit,
    required this.totalDebit,
    required this.remainingBalance,
  });

  factory LedgerSummary.fromJson(Map<String, dynamic> json) {
    return LedgerSummary(
      openingBalance: double.parse(json['openingBalance'].toString()),
      totalCredit: double.parse(json['totalCredit'].toString()),
      totalDebit: double.parse(json['totalDebit'].toString()),
      remainingBalance: double.parse(json['remainingBalance'].toString()),
    );
  }
}
