import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

class AdvancedProductsPage extends StatefulWidget {
  final AppDatabase db;
  const AdvancedProductsPage(this.db, {super.key});

  @override
  State<AdvancedProductsPage> createState() => _AdvancedProductsPageState();
}

class _AdvancedProductsPageState extends State<AdvancedProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'الكل';

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
                  labelText: 'بحث عن منتج',
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
                  const Text('الحالة: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                      DropdownMenuItem(value: 'Active', child: Text('نشط')),
                      DropdownMenuItem(
                        value: 'Inactive',
                        child: Text('غير نشط'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Products StreamBuilder
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: widget.db.select(widget.db.products).watch(),
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
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text('لا يوجد منتجات'),
                      SizedBox(height: 8),
                      Text(
                        'أضف منتجات جديدة للبدء',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // Filter products based on search and status
              final filteredProducts = snapshot.data!.where((product) {
                final matchesSearch = product.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
                final matchesStatus =
                    _selectedStatus == 'الكل' ||
                    (product.status ?? 'Active') == _selectedStatus;
                return matchesSearch && matchesStatus;
              }).toList();

              if (filteredProducts.isEmpty) {
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
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Dismissible(
                      key: Key(product.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        await widget.db.productDao.deleteProduct(product);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حذف المنتج'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (product.status ?? 'Active') == 'Active'
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.inventory,
                              color: (product.status ?? 'Active') == 'Active'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'السعر: ${product.price} ريال | الكمية: ${product.quantity}',
                            style: const TextStyle(color: Colors.grey),
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
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  // Show more options
                                },
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('الحالة: '),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (product.status ?? 'Active') ==
                                                  'Active'
                                              ? Colors.green.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.red.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          product.status ?? 'Active',
                                          style: TextStyle(
                                            color:
                                                (product.status ?? 'Active') ==
                                                    'Active'
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'السعر الإجمالي: ${(product.price * product.quantity).toStringAsFixed(2)} ريال',
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          // Edit product
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: const Text('تعديل'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          // Delete product
                                        },
                                        icon: const Icon(Icons.delete),
                                        label: const Text('حذف'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
