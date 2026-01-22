import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pos_offline_desktop/l10n/l10n.dart';
import 'package:pos_offline_desktop/ui/pages/sidebar_page.dart';

class SideBarMenu extends StatelessWidget {
  final SideBarPage selectedPage;
  final ValueChanged<SideBarPage> onPageSelected;

  const SideBarMenu({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          svgAssetPath: 'assets/svg/house.svg',
          title: context.l10n.home,
          page: SideBarPage.home,
        ),
        _buildMenuItem(
          context,
          svgAssetPath: 'assets/svg/product.svg',
          title: context.l10n.products,
          page: SideBarPage.products,
        ),
        _buildMenuItem(
          context,
          svgAssetPath: 'assets/svg/customer.svg',
          title: context.l10n.customers,
          page: SideBarPage.customers,
        ),
        _buildMenuItem(
          context,
          svgAssetPath: 'assets/svg/invoice.svg',
          title: context.l10n.sales_and_invoices,
          page: SideBarPage.invoice,
        ),
        _buildMenuItem(
          context,
          svgAssetPath: 'assets/svg/enhanced_invoice.svg',
          title: 'Enhanced Invoice',
          page: SideBarPage.enhancedInvoice,
        ),
        _buildMenuItem(
          context,
          svgAssetPath: 'assets/svg/graph.svg',
          title: context.l10n.expenses,
          page: SideBarPage.expenses,
        ),
        _buildMenuItem(
          context,
          svgAssetPath: 'assets/svg/category.svg',
          title: 'المشتريات',
          page: SideBarPage.purchases,
        ),
        _buildMenuItem(
          context,
          svgAssetPath: 'assets/svg/graph.svg',
          title: 'التقارير والمبيعات',
          page: SideBarPage.reports,
        ),
        _buildMenuItem(
          context,
          svgAssetPath: 'assets/svg/customer.svg',
          title: context.l10n.cashier,
          page: SideBarPage.cashier,
        ),
      ],
    );
  }

  // List Tile
  Widget _buildMenuItem(
    BuildContext context, {
    required String svgAssetPath,
    required String title,
    required SideBarPage page,
  }) {
    final isSelected = selectedPage == page;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: SvgPicture.asset(
        svgAssetPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          isSelected
              ? colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.surfaceTint.withValues(alpha: 0.3),
      onTap: () => onPageSelected(page),
    );
  }
}
