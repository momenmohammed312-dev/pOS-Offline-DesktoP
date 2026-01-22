import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product icon with darker background
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).primaryColor.withAlpha(204), // لون أغمق
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined, // أيقونة بسيطة
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
            const Gap(8),

            // Product name
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Gap(4),

            // Price and stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${product.price.toStringAsFixed(2)} جنيه',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: product.quantity > 0
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.quantity > 0 ? 'Stock: ${product.quantity}' : 'نفذ',
                    style: TextStyle(
                      fontSize: 9,
                      color: product.quantity > 0
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
