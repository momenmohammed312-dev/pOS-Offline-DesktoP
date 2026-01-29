# SOP 4.0 Migration Guide

## Overview
This guide helps migrate existing export functions to use the new `UnifiedPrintService` for consistent formatting across all documents.

## Key Changes Required

### 1. Replace Direct PDF Generation
**Before:**
```dart
final pdf = pw.Document();
// Custom PDF building code...
```

**After:**
```dart
import 'package:pos_offline_desktop/core/services/unified_print_service.dart';

// For invoices
final pdf = await UnifiedPrintService.generateUnifiedDocument(
  documentType: DocumentType.salesInvoice,
  data: invoiceData,
  storeInfo: storeInfo,
  additionalData: {'paidAmount': paidAmount},
);

// For customer statements
final pdf = await UnifiedPrintService.generateUnifiedDocument(
  documentType: DocumentType.customerStatement,
  data: transactions,
  storeInfo: storeInfo,
  additionalData: {
    'customerName': customer.name,
    'currentBalance': currentBalance,
  },
);
```

### 2. Replace Direct Print Calls
**Before:**
```dart
await Printing.layoutPdf(onLayout: (format) => pdf.save());
```

**After:**
```dart
await UnifiedPrintService.printToThermalPrinter(
  documentType: DocumentType.salesInvoice,
  data: invoiceData,
  storeInfo: storeInfo,
);
```

### 3. Replace Export Functions
**Before:**
```dart
final file = File('path');
await file.writeAsBytes(await pdf.save());
```

**After:**
```dart
final file = await UnifiedPrintService.exportToPDFFile(
  documentType: DocumentType.salesInvoice,
  data: invoiceData,
  storeInfo: storeInfo,
  fileName: 'invoice_${invoiceNumber}.pdf',
);
```

## Specific Migration Examples

### Invoice Pages
```dart
// Import the new service
import 'package:pos_offline_desktop/core/services/unified_print_service.dart';
import 'package:pos_offline_desktop/core/services/balance_calculation_service.dart';

class InvoicePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice')),
      body: FutureBuilder(
        future: _loadInvoiceData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          
          final invoice = snapshot.data!;
          final balanceService = BalanceCalculationService(database);
          
          return ElevatedButton(
            onPressed: () async {
              // Get previous balance
              final previousBalance = await balanceService.getPreviousBalance(
                invoice.customerId,
                invoice.invoiceDate,
              );
              
              // Create unified invoice data
              final invoiceData = InvoiceData(
                invoice: invoice,
                items: invoice.items,
                storeInfo: await _getStoreInfo(),
              );
              
              // Print using unified service
              await UnifiedPrintService.printToThermalPrinter(
                documentType: DocumentType.salesInvoice,
                data: invoiceData,
                storeInfo: invoiceData.storeInfo,
                additionalData: {
                  'paidAmount': invoice.paidAmount,
                },
              );
            },
            child: Text('Print Invoice'),
          );
        },
      ),
    );
  }
}
```

### Customer Statement Pages
```dart
class CustomerStatementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Customer Statement')),
      body: FutureBuilder(
        future: _loadStatementData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          
          final transactions = snapshot.data!;
          final balanceService = BalanceCalculationService(database);
          
          return ElevatedButton(
            onPressed: () async {
              // Generate statement with running balance
              final statementData = await balanceService.generateCustomerStatement(
                customerId,
                startDate,
                endDate,
              );
              
              // Export using unified service
              await UnifiedPrintService.exportToPDFFile(
                documentType: DocumentType.customerStatement,
                data: statementData,
                storeInfo: await _getStoreInfo(),
                additionalData: {
                  'customerName': customer.name,
                  'currentBalance': await balanceService.getCurrentCustomerBalance(customerId),
                },
              );
            },
            child: Text('Export Statement'),
          );
        },
      ),
    );
  }
}
```

### Report Pages
```dart
class SalesReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sales Report')),
      body: FutureBuilder(
        future: _loadReportData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          
          final balanceService = BalanceCalculationService(database);
          
          return ElevatedButton(
            onPressed: () async {
              // Generate enhanced sales report
              final reportData = await balanceService.generateSalesReport(
                startDate: startDate,
                endDate: endDate,
                customerId: selectedCustomerId,
              );
              
              // Export using unified service
              await UnifiedPrintService.exportToPDFFile(
                documentType: DocumentType.salesReport,
                data: reportData,
                storeInfo: await _getStoreInfo(),
              );
            },
            child: Text('Export Report'),
          );
        },
      ),
    );
  }
}
```

## Required Data Models

### InvoiceData Model
The `UnifiedPrintService` expects data in specific formats:

#### For Invoices:
```dart
final invoiceData = InvoiceData(
  invoice: Invoice(
    id: invoice.id,
    invoiceNumber: invoice.invoiceNumber,
    customerName: invoice.customerName,
    customerPhone: invoice.customerPhone,
    customerZipCode: invoice.customerZipCode,
    customerState: invoice.customerState,
    invoiceDate: invoice.date,
    subtotal: invoice.subtotal,
    isCreditAccount: invoice.paymentMethod == 'credit',
    previousBalance: previousBalance, // Calculated from BalanceCalculationService
    totalAmount: invoice.totalAmount,
    notes: invoice.notes,
  ),
  items: invoice.items.map((item) => InvoiceItem(
    id: item.id,
    invoiceId: item.invoiceId,
    description: item.description,
    unit: item.unit, // NEW: Unit field
    quantity: item.quantity,
    unitPrice: item.unitPrice,
    totalPrice: item.totalPrice,
    sortOrder: item.sortOrder,
  )).toList(),
  storeInfo: StoreInfo(
    storeName: store.name,
    phone: store.phone,
    zipCode: store.zipCode,
    state: store.state,
    taxNumber: store.taxNumber,
  ),
);
```

#### For Account Statements:
```dart
final statementData = [
  {
    'date': transaction.date,
    'receiptNumber': transaction.receiptNumber,
    'description': enhancedDescription, // With nested product details
    'debit': transaction.debit,
    'credit': transaction.credit,
    'balance': runningBalance,
    'origin': transaction.origin,
  },
  // ... more transactions
];
```

## Benefits of Migration

1. **Consistent Branding**: All documents will have "Developed by MO2" header
2. **Unified Layout**: 5-column grid tables for all invoices
3. **Running Balance**: Automatic balance calculations for ledgers
4. **Nested Details**: Product breakdowns in account statements
5. **Thermal Support**: Built-in 80mm printer compatibility
6. **Reduced Code**: Single service handles all document types

## Final Audit Checklist

After migration, verify:

- [ ] "Developed by MO2" appears at top of ALL exports
- [ ] Every invoice shows Previous Balance and Grand Total
- [ ] Running Balance column exists in Customer and Supplier ledgers
- [ ] Item table is 5-column grid (including "Unit") with borders
- [ ] Customer/Supplier statements show full item details when expanded
- [ ] Product Name font size is 18.0 and bold during selection

## Testing

Test each migrated function:

1. **Invoice Printing**: Verify 5-column layout and credit footer
2. **Customer Statements**: Check running balance calculations
3. **Sales Reports**: Confirm enhanced data structure
4. **Thermal Printing**: Test with 80mm printer format
5. **PDF Export**: Validate Arabic font rendering

## Support

For issues during migration:
1. Check `BalanceCalculationService` for correct data access patterns
2. Verify `StoreInfo` model matches your database structure
3. Test with real data to ensure balance calculations work
4. Validate Arabic text rendering in PDF output
