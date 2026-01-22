import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

class AdvancedCustomersPage extends StatefulWidget {
  final AppDatabase db;
  const AdvancedCustomersPage(this.db, {super.key});

  @override
  State<AdvancedCustomersPage> createState() => _AdvancedCustomersPageState();
}

class _AdvancedCustomersPageState extends State<AdvancedCustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  dynamic _selectedStatus = 'الكل';
  String _sortBy = 'name'; // name, balance, date

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'بحث عن عميل',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<dynamic>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'الحالة',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                        DropdownMenuItem(value: 1, child: Text('نشط')),
                        DropdownMenuItem(value: 0, child: Text('غير نشط')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      decoration: const InputDecoration(
                        labelText: 'ترتيب حسب',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('الاسم')),
                        DropdownMenuItem(
                          value: 'balance',
                          child: Text('الرصيد'),
                        ),
                        DropdownMenuItem(value: 'date', child: Text('التاريخ')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Customers StreamBuilder
        Expanded(
          child: StreamBuilder<List<Customer>>(
            stream: widget.db.select(widget.db.customers).watch(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('خطأ: ${snapshot.error}'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا يوجد عملاء'),
                      SizedBox(height: 8),
                      Text(
                        'أضف عملاء جدد للبدء',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // Filter and sort customers
              var filteredCustomers = snapshot.data!.where((customer) {
                final matchesSearch =
                    customer.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (customer.phone?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false);
                final matchesStatus =
                    _selectedStatus == 'الكل' ||
                    (customer.status ?? 1) == _selectedStatus;
                return matchesSearch && matchesStatus;
              }).toList();

              // Sort customers
              switch (_sortBy) {
                case 'name':
                  filteredCustomers.sort((a, b) => a.name.compareTo(b.name));
                  break;
                case 'balance':
                  filteredCustomers.sort(
                    (a, b) => b.openingBalance.compareTo(a.openingBalance),
                  );
                  break;
                case 'date':
                  filteredCustomers.sort(
                    (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                      a.createdAt ?? DateTime.now(),
                    ),
                  );
                  break;
              }

              if (filteredCustomers.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا توجد نتائج للبحث'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (customer.status ?? 1) == 1
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: (customer.status ?? 1) == 1
                                  ? Colors.blue
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customer.phone != null)
                              Text('📱 ${customer.phone ?? ''}'),
                            if (customer.address != null)
                              Text('📍 ${customer.address ?? ''}'),
                            Row(
                              children: [
                                Text('الرصيد: ${customer.openingBalance} ريال'),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (customer.status ?? 1) == 1
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (customer.status ?? 1) == 1
                                        ? 'Active'
                                        : 'Inactive',
                                    style: TextStyle(
                                      color: (customer.status ?? 1) == 1
                                          ? Colors.green
                                          : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined),
                                  SizedBox(width: 8),
                                  Text('تعديل'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility),
                                  SizedBox(width: 8),
                                  Text('عرض التفاصيل'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'statement',
                              child: Row(
                                children: [
                                  Icon(Icons.description),
                                  SizedBox(width: 8),
                                  Text('كشف حساب'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'حذف',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                // Navigate to edit customer
                                break;
                              case 'view':
                                // Show customer details
                                break;
                              case 'statement':
                                // Generate account statement
                                break;
                              case 'delete':
                                // Show delete confirmation
                                break;
                            }
                          },
                        ),
                        onTap: () {
                          // Show customer details or navigate to customer page
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
