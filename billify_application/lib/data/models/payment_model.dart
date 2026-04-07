class Payment {
  final int? id;
  final int businessId;
  final int customerId;
  final double amount;
  final String type; // 'credit', 'debit'
  final String paymentMethod;
  final String? note;
  final int? referenceInvoiceId;
  final DateTime? createdAt;
  final Map<String, dynamic>? customerDetails;

  Payment({
    this.id,
    required this.businessId,
    required this.customerId,
    required this.amount,
    required this.type,
    this.paymentMethod = 'Cash',
    this.note,
    this.referenceInvoiceId,
    this.createdAt,
    this.customerDetails,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      businessId: json['business_id'],
      customerId: json['customer_id'],
      amount: double.parse(json['amount'].toString()),
      type: json['type'],
      paymentMethod: json['payment_method'],
      note: json['note'],
      referenceInvoiceId: json['reference_invoice_id'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      customerDetails: json['customer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'amount': amount,
      'type': type,
      'payment_method': paymentMethod,
      'note': note,
      'reference_invoice_id': referenceInvoiceId,
    };
  }
}
