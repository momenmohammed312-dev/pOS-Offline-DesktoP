import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

class ProductsPage extends StatelessWidget {
  final AppDatabase db;
  const ProductsPage(this.db, {super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: db.select(db.products).watch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا يوجد منتجات'));
        }
        final products = snapshot.data!;
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (p.status ?? 'Active') == 'Active'
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.inventory,
                    color: (p.status ?? 'Active') == 'Active'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                title: Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('السعر: ${p.price} ريال'),
                    Text('الكمية: ${p.quantity}'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (p.status ?? 'Active') == 'Active'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        p.status ?? 'Active',
                        style: TextStyle(
                          color: (p.status ?? 'Active') == 'Active'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        // Navigate to edit product
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        // Show delete confirmation
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
