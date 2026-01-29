import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/dao/product_dao.dart';

class EnhancedProductSelector extends StatefulWidget {
  final AppDatabase database;

  const EnhancedProductSelector({super.key, required this.database});

  @override
  State<EnhancedProductSelector> createState() =>
      _EnhancedProductSelectorState();
}

class _EnhancedProductSelectorState extends State<EnhancedProductSelector> {
  late final ProductDao _productDao;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productDao = ProductDao(widget.database);
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await _productDao.getAllProducts();
    setState(() {
      _products = products;
      _filteredProducts = products;
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query) ||
            (product.barcode?.toLowerCase().contains(query) ?? false) ||
            (product.category?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF3D3D4D))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'اختر منتج',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث عن منتج...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Color(0xFF3D3D4D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),

          // Product Grid
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد منتجات',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _ProductCard(
                        product: product,
                        onTap: () => _showQuantityDialog(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(Product product) {
    _quantityController.text = '1';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D2D3D),
        title: Text('تحديد الكمية', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'السعر: ${product.price.toStringAsFixed(2)} ج.م',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'الكمية',
                labelStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Color(0xFF3D3D4D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixText: product.unit ?? 'قطعة',
                suffixStyle: TextStyle(color: Colors.grey[400]),
              ),
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              validator: (v) {
                final quantity = int.tryParse(v ?? '0');
                if (quantity == null || quantity <= 0) {
                  return 'يرجى إدخال كمية صحيحة';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(_quantityController.text);
              if (quantity != null && quantity > 0) {
                Navigator.pop(context, {
                  'id': product.id,
                  'name': product.name,
                  'barcode': product.barcode,
                  'unit': product.unit ?? 'قطعة',
                  'quantity': quantity,
                  'price': product.price,
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF3D3D4D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF4D4D5D)),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product icon placeholder
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, color: Colors.purple, size: 30),
              ),
              SizedBox(height: 8),

              // Product name
              Text(
                product.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),

              // Category
              if (product.category != null)
                Text(
                  product.category!,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              Spacer(),

              // Price and stock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${product.price.toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.quantity > 0
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${product.quantity}',
                      style: TextStyle(
                        color: product.quantity > 0 ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Barcode
              if (product.barcode != null)
                Text(
                  product.barcode!,
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
