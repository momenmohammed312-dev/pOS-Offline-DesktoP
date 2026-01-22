# StreamBuilder + Drift Usage Guide

## Basic Examples

### 1. Simple Products Page
```dart
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
            return ListTile(
              title: Text(p.name),
              subtitle: Text('السعر: ${p.price}'),
            );
          },
        );
      },
    );
  }
}
```

### 2. Simple Customers Page
```dart
StreamBuilder<List<Customer>>(
  stream: db.select(db.customers).watch(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Center(child: Text('لا يوجد عملاء'));
    }
    final customers = snapshot.data!;
    return ListView(
      children: customers.map((c) => ListTile(
        title: Text(c.name),
        subtitle: Text(c.phone ?? ''),
      )).toList(),
    );
  },
)
```

## Advanced Features

### 1. Search and Filter
```dart
// Add search functionality
TextField(
  controller: _searchController,
  decoration: InputDecoration(
    labelText: 'بحث...',
    prefixIcon: const Icon(Icons.search),
  ),
  onChanged: (value) {
    setState(() {
      _searchQuery = value;
    });
  },
),

// Filter in StreamBuilder
final filteredProducts = snapshot.data!.where((product) {
  return product.name.toLowerCase().contains(_searchQuery.toLowerCase());
}).toList();
```

### 2. Status Filtering
```dart
DropdownButton<String>(
  value: _selectedStatus,
  items: [
    DropdownMenuItem(value: 'الكل', child: Text('الكل')),
    DropdownMenuItem(value: 'Active', child: Text('نشط')),
    DropdownMenuItem(value: 'Inactive', child: Text('غير نشط')),
  ],
  onChanged: (value) {
    setState(() {
      _selectedStatus = value!;
    });
  },
),
```

### 3. Sorting
```dart
// Sort customers by balance
filteredCustomers.sort((a, b) => b.openingBalance.compareTo(a.openingBalance));

// Sort products by name
filteredProducts.sort((a, b) => a.name.compareTo(b.name));
```

### 4. Pull to Refresh
```dart
RefreshIndicator(
  onRefresh: () async {
    setState(() {}); // Trigger rebuild
  },
  child: ListView.builder(...),
)
```

### 5. Swipe to Delete
```dart
Dismissible(
  key: Key(product.id.toString()),
  direction: DismissDirection.endToStart,
  background: Container(
    color: Colors.red,
    child: const Icon(Icons.delete, color: Colors.white),
  ),
  onDismissed: (direction) async {
    await db.productDao.deleteProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الحذف')),
    );
  },
  child: Card(...),
)
```

## Stream States Handling

### 1. Loading State
```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator());
}
```

### 2. Error State
```dart
if (snapshot.hasError) {
  return Center(
    child: Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        Text('خطأ: ${snapshot.error}'),
        ElevatedButton(
          onPressed: () => setState(() {}),
          child: const Text('إعادة المحاولة'),
        ),
      ],
    ),
  );
}
```

### 3. Empty State
```dart
if (!snapshot.hasData || snapshot.data!.isEmpty) {
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_outlined, size: 64),
        Text('لا يوجد منتجات'),
        Text('أضف منتجات جديدة للبدء'),
      ],
    ),
  );
}
```

## Best Practices

### 1. Use StatefulWidget for Interactive Features
```dart
class ProductsPage extends StatefulWidget {
  // ...
}

class _ProductsPageState extends State<ProductsPage> {
  // Handle search, filter, sort states here
}
```

### 2. Efficient Filtering
```dart
// Filter in the builder, not in the stream
final filteredData = snapshot.data!.where((item) {
  return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
         (_selectedStatus == 'الكل' || item.status == _selectedStatus);
}).toList();
```

### 3. Memory Management
```dart
@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}
```

### 4. Error Recovery
```dart
ElevatedButton(
  onPressed: () {
    setState(() {}); // Trigger rebuild to retry
  },
  child: const Text('إعادة المحاولة'),
)
```

## Real-world Examples

See the following files for complete implementations:
- `lib/ui/product/examples/products_page_example.dart`
- `lib/ui/product/examples/advanced_products_page_example.dart`
- `lib/ui/customer/examples/customers_page_example.dart`
- `lib/ui/customer/examples/advanced_customers_page_example.dart`

## Common Patterns

### 1. Status Badge
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  decoration: BoxDecoration(
    color: status == 'Active' 
      ? Colors.green.withOpacity(0.1)
      : Colors.red.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    status,
    style: TextStyle(
      color: status == 'Active' ? Colors.green : Colors.red,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
  ),
)
```

### 2. Action Buttons
```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.edit_outlined),
      onPressed: () => _editItem(item),
    ),
    IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () => _deleteItem(item),
    ),
  ],
)
```

### 3. Expansion Tile for Details
```dart
ExpansionTile(
  title: Text(item.name),
  children: [
    Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('التفاصيل: ${item.details}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => _editItem(item),
                child: const Text('تعديل'),
              ),
            ],
          ),
        ],
      ),
    ),
  ],
)
```
