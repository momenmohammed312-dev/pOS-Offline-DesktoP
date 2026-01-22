import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/l10n/app_localizations.dart';
import 'package:pos_offline_desktop/ui/product/product.dart';
import 'package:pos_offline_desktop/ui/cashier/cashier_page.dart';
import 'package:pos_offline_desktop/ui/home/widgets/customer_transactions_widget.dart';
import 'package:pos_offline_desktop/ui/home/widgets/suppliers_widget.dart';
import 'package:pos_offline_desktop/ui/reports/reports_page.dart';
import 'package:pos_offline_desktop/ui/purchase/purchase_page.dart';
import 'package:pos_offline_desktop/ui/invoice/widgets/enhanced_new_invoice_page.dart';

class ModernHomeScreen extends StatefulWidget {
  final AppDatabase db;
  const ModernHomeScreen({super.key, required this.db});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.point_of_sale,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Developed by MO2',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                      Text(
                        l10n.brand_name_subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Reports Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ReportsPage(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.analytics,
                              color: Colors.purple,
                              size: 20,
                            ),
                            const Gap(8),
                            Text(
                              'التقارير',
                              style: const TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: Colors.green,
                            size: 20,
                          ),
                          const Gap(8),
                          Text(
                            l10n.currency,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              indicator: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.dashboard_outlined),
                  text: l10n.dashboard,
                ),
                Tab(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  text: l10n.products,
                ),
                Tab(
                  icon: const Icon(Icons.people_outline),
                  text: l10n.customer_list,
                ),
                Tab(
                  icon: const Icon(Icons.inventory_outlined),
                  text: l10n.suppliers,
                ),
                Tab(
                  icon: const Icon(Icons.shopping_basket_outlined),
                  text: 'المشتريات',
                ),
                Tab(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  text: l10n.cash,
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Control Panel - Simplified with 3 buttons only
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'لوحة التحكم',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // New Invoice Button
                          SizedBox(
                            width: 200,
                            height: 150,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EnhancedNewInvoicePage(db: widget.db),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.receipt_long, size: 40),
                              label: const Text(
                                'فاتورة جديدة',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          // Add/Edit Customer Button
                          SizedBox(
                            width: 200,
                            height: 150,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _tabController.animateTo(
                                  2,
                                ); // Go to Customer tab
                              },
                              icon: const Icon(Icons.person_add, size: 40),
                              label: const Text(
                                'إضافة/تعديل عميل',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          // Add/Edit Product Button
                          SizedBox(
                            width: 200,
                            height: 150,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _tabController.animateTo(
                                  1,
                                ); // Go to Products tab
                              },
                              icon: const Icon(Icons.inventory, size: 40),
                              label: const Text(
                                'إضافة/تعديل منتج',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ProductScreen(db: widget.db),
                CustomerTransactionsWidget(db: widget.db),
                SuppliersWidget(db: widget.db),
                PurchasePage(db: widget.db),
                CashierPage(db: widget.db),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
