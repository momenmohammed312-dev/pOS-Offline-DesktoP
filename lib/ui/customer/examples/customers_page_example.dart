import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

class CustomersPage extends StatelessWidget {
  final AppDatabase db;
  const CustomersPage(this.db, {super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Customer>>(
      stream: db.select(db.customers).watch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا يوجد عملاء'));
        }
        final customers = snapshot.data!;
        return ListView.builder(
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final c = customers[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (c.status ?? 1) == 1
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    color: (c.status ?? 1) == 1 ? Colors.blue : Colors.grey,
                  ),
                ),
                title: Text(
                  c.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.phone != null) Text('الهاتف: ${c.phone ?? ''}'),
                    if (c.address != null) Text('العنوان: ${c.address ?? ''}'),
                    if (c.gstinNumber != null)
                      Text('الرقم الضريبي: ${c.gstinNumber ?? ''}'),
                    Text('الرصيد الافتتاحي: ${c.openingBalance} ريال'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (c.status ?? 1) == 1
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (c.status ?? 1) == 1 ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: (c.status ?? 1) == 1
                              ? Colors.green
                              : Colors.grey,
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
                        // Navigate to edit customer
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
