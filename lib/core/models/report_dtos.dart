class InvoiceReportDTO {
  final int id;
  final String invoiceNumber;
  final DateTime date;
  final String customerName;
  final String productNames; // Comma-separated or similar
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;

  InvoiceReportDTO({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    required this.productNames,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'الرقم': invoiceNumber,
      'التاريخ': date, // Formatted later
      'العميل': customerName,
      'المنتجات': productNames,
      'الإجمالي': totalAmount,
      'المدفوع': paidAmount,
      'المتبقي': remainingAmount,
    };
  }
}
