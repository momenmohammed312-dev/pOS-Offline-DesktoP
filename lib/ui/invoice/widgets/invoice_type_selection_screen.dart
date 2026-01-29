import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../purchase/widgets/enhanced_purchase_invoice_screen.dart';
import 'enhanced_new_invoice_page.dart';
import '../../../core/provider/app_database_provider.dart';

class InvoiceTypeSelectionScreen extends ConsumerWidget {
  const InvoiceTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Color(0xFF2D2D3D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFF3D3D4D)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر نوع الفاتورة',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'اختر نوع الفاتورة التي تريد إنشاؤها',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              SizedBox(height: 40),
              Row(
                children: [
                  // Purchase Invoice (NEW)
                  Expanded(
                    child: _InvoiceTypeCard(
                      icon: Icons.shopping_cart,
                      title: 'توريد',
                      subtitle: 'فاتورة شراء من مورد',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EnhancedPurchaseInvoiceScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  // Cash Invoice
                  Expanded(
                    child: _InvoiceTypeCard(
                      icon: Icons.attach_money,
                      title: 'نقدي',
                      subtitle: 'دفع فوري\nإيصال حراري',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnhancedNewInvoicePage(
                              db: ref.read(appDatabaseProvider),
                              isCredit: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  // Credit Invoice
                  Expanded(
                    child: _InvoiceTypeCard(
                      icon: Icons.credit_card,
                      title: 'آجل',
                      subtitle: 'دفع على الحساب\nفاتورة A4',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnhancedNewInvoicePage(
                              db: ref.read(appDatabaseProvider),
                              isCredit: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _InvoiceTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF3D3D4D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
