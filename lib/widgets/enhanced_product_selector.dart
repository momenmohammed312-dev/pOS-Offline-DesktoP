import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

/// SOP 4.0: Enhanced Product Selection Widget
/// MANDATORY: Improved visibility with larger fonts and highlighting
class EnhancedProductSelector extends StatefulWidget {
  final List<Product> products;
  final Product? selectedProduct;
  final Function(Product?) onProductSelected;
  final String? hintText;
  final bool enabled;

  const EnhancedProductSelector({
    super.key,
    required this.products,
    this.selectedProduct,
    required this.onProductSelected,
    this.hintText,
    this.enabled = true,
  });

  @override
  State<EnhancedProductSelector> createState() =>
      _EnhancedProductSelectorState();
}

class _EnhancedProductSelectorState extends State<EnhancedProductSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.selectedProduct;
    _filteredProducts = widget.products;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _filteredProducts = widget.products.where((product) {
          return product.name.toLowerCase().contains(query) ||
              (product.barcode?.toLowerCase().contains(query) ?? false) ||
              (product.category?.toLowerCase().contains(query) ?? false);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field with enhanced styling
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: widget.enabled ? Colors.white : Colors.grey.shade100,
          ),
          child: TextField(
            controller: _searchController,
            enabled: widget.enabled,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'ابحث عن منتج...',
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Selected product display (if any)
        if (_selectedProduct != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedProduct!.name,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.enabled
                      ? () {
                          setState(() {
                            _selectedProduct = null;
                            _searchController.clear();
                            widget.onProductSelected(null);
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Product list with enhanced visibility
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد منتجات مطابقة',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final isSelected = _selectedProduct?.id == product.id;

                      return _ProductTile(
                        product: product,
                        isSelected: isSelected,
                        onTap: widget.enabled
                            ? () {
                                setState(() {
                                  _selectedProduct = product;
                                  _searchController.text = product.name;
                                  widget.onProductSelected(product);
                                });
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// Enhanced Product Tile with improved visibility
class _ProductTile extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ProductTile({
    required this.product,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade100 : Colors.transparent,
        border: Border.all(
          color: isSelected ? Colors.blue.shade400 : Colors.transparent,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        enabled: onTap != null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? Colors.blue.shade200
              : Colors.grey.shade200,
          child: Icon(
            Icons.inventory_2_outlined,
            color: isSelected ? Colors.blue.shade800 : Colors.grey.shade600,
            size: 20,
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.blue.shade800 : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.barcode != null) ...[
              const SizedBox(height: 2),
              Text(
                'الكود: ${product.barcode}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            if (product.category != null) ...[
              const SizedBox(height: 2),
              Text(
                'التصنيف: ${product.category}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'السعر: ${product.price.toStringAsFixed(2)} ج.م',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.inventory, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'المخزن: ${product.quantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        trailing: isSelected
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            : null,
      ),
    );
  }
}

/// Enhanced Product Dropdown for forms
/// MANDATORY: Larger fonts and better visibility
class EnhancedProductDropdown extends StatelessWidget {
  final List<Product> products;
  final Product? selectedProduct;
  final Function(Product?) onChanged;
  final String? hintText;
  final bool enabled;

  const EnhancedProductDropdown({
    super.key,
    required this.products,
    this.selectedProduct,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Product>(
          value: selectedProduct,
          isExpanded: true,
          hint: Text(
            hintText ?? 'اختر المنتج',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          disabledHint: Text(
            hintText ?? 'اختر المنتج',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          items: products.map((product) {
            return DropdownMenuItem<Product>(
              value: product,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.blue.shade600,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (product.barcode != null)
                            Text(
                              'الكود: ${product.barcode}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}
