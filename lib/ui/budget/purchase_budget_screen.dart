import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/dao/purchase_budget_dao.dart';
import '../../../core/provider/app_database_provider.dart';

class PurchaseBudgetScreen extends ConsumerStatefulWidget {
  const PurchaseBudgetScreen({super.key});

  @override
  ConsumerState<PurchaseBudgetScreen> createState() =>
      _PurchaseBudgetScreenState();
}

class _PurchaseBudgetScreenState extends ConsumerState<PurchaseBudgetScreen> {
  late final PurchaseBudgetDao _budgetDao;
  List<PurchaseBudget> _budgets = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _selectedStatus = 'all'; // all, active, completed, cancelled

  @override
  void initState() {
    super.initState();
    _budgetDao = PurchaseBudgetDao(ref.read(appDatabaseProvider));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final budgets = await _budgetDao.getAllBudgets();
      final statistics = await _budgetDao.getBudgetStatistics();

      setState(() {
        _budgets = budgets;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<PurchaseBudget> get _filteredBudgets {
    if (_selectedStatus == 'all') return _budgets;
    return _budgets
        .where((budget) => budget.status == _selectedStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text('إدارة ميزانية المشتريات'),
        backgroundColor: Color(0xFF2D2D3D),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createNewBudget,
            tooltip: 'إنشاء ميزانية جديدة',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          _buildStatisticsCards(),
          SizedBox(height: 16),

          // Status Filter
          _buildStatusFilter(),
          SizedBox(height: 16),

          // Budgets List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.purple))
                : _filteredBudgets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد ميزانيات',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _createNewBudget,
                          icon: Icon(Icons.add),
                          label: Text('إنشاء ميزانية جديدة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredBudgets.length,
                    itemBuilder: (context, index) {
                      final budget = _filteredBudgets[index];
                      return _buildBudgetCard(budget);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي الميزانيات',
              _statistics['totalBudgets']?.toString() ?? '0',
              Icons.account_balance_wallet,
              Colors.purple,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'نشطة',
              _statistics['activeBudgets']?.toString() ?? '0',
              Icons.play_circle,
              Colors.green,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'تجاوزت الحد',
              _statistics['overspentBudgets']?.toString() ?? '0',
              Icons.warning,
              Colors.red,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'قرب النفاد',
              _statistics['nearLimitBudgets']?.toString() ?? '0',
              Icons.warning_amber_rounded,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'تصفية بالحالة:',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('all', 'الكل'),
                  SizedBox(width: 8),
                  _buildStatusChip('active', 'نشطة'),
                  SizedBox(width: 8),
                  _buildStatusChip('completed', 'مكتملة'),
                  SizedBox(width: 8),
                  _buildStatusChip('cancelled', 'ملغية'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
      backgroundColor: Color(0xFF2D2D3D),
      selectedColor: Colors.purple.withValues(alpha: 0.3),
      labelStyle: TextStyle(color: isSelected ? Colors.purple : Colors.white),
    );
  }

  Widget _buildBudgetCard(PurchaseBudget budget) {
    final spentPercentage = budget.totalBudget > 0
        ? (budget.spentAmount / budget.totalBudget) * 100
        : 0.0;
    final isOverBudget = budget.spentAmount > budget.totalBudget;
    final isNearLimit = spentPercentage >= 80 && spentPercentage < 100;
    final daysRemaining = budget.endDate.difference(DateTime.now()).inDays;

    return Card(
      color: Color(0xFF2D2D3D),
      margin: EdgeInsets.only(bottom: 12),
      elevation: isOverBudget ? 8 : 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getBudgetStatusColor(budget, spentPercentage),
          child: Icon(
            _getBudgetStatusIcon(budget, spentPercentage),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                budget.budgetName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isOverBudget)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'تجاوز',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            if (isNearLimit)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'قريب',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الفترة: ${DateFormat('yyyy-MM-dd').format(budget.startDate)} - ${DateFormat('yyyy-MM-dd').format(budget.endDate)}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            Text(
              'المتبقي: $daysRemaining يوم',
              style: TextStyle(
                color: daysRemaining < 7 ? Colors.red : Colors.grey[400],
                fontWeight: daysRemaining < 7
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            SizedBox(height: 8),
            // Progress bar
            LinearProgressIndicator(
              value: spentPercentage > 100 ? 1.0 : spentPercentage / 100,
              backgroundColor: Color(0xFF3D3D4D),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget
                    ? Colors.red
                    : (isNearLimit ? Colors.orange : Colors.green),
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${spentPercentage.toStringAsFixed(1)}% تم الصرف (${budget.spentAmount.toStringAsFixed(0)} من ${budget.totalBudget.toStringAsFixed(0)} ج.م)',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${budget.remainingAmount.toStringAsFixed(0)} ج.م',
              style: TextStyle(
                color: budget.remainingAmount >= 0 ? Colors.purple : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getStatusLabel(budget.status),
              style: TextStyle(
                color: _getStatusColor(budget.status),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () => _viewBudgetDetails(budget),
      ),
    );
  }

  Color _getBudgetStatusColor(PurchaseBudget budget, double spentPercentage) {
    if (budget.status == 'completed') return Colors.grey;
    if (budget.status == 'cancelled') return Colors.red;
    if (budget.spentAmount > budget.totalBudget) return Colors.red;
    if (spentPercentage >= 80) return Colors.orange;
    return Colors.green;
  }

  IconData _getBudgetStatusIcon(PurchaseBudget budget, double spentPercentage) {
    if (budget.status == 'completed') return Icons.check_circle;
    if (budget.status == 'cancelled') return Icons.cancel;
    if (budget.spentAmount > budget.totalBudget) return Icons.warning;
    if (spentPercentage >= 80) return Icons.warning_amber_rounded;
    return Icons.trending_up;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'نشطة';
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغية';
      default:
        return status;
    }
  }

  void _viewBudgetDetails(PurchaseBudget budget) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetDetailsScreen(budget: budget),
      ),
    ).then((_) => _loadData());
  }

  void _createNewBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateBudgetScreen()),
    ).then((_) => _loadData());
  }
}

class BudgetDetailsScreen extends ConsumerStatefulWidget {
  final PurchaseBudget budget;

  const BudgetDetailsScreen({super.key, required this.budget});

  @override
  ConsumerState<BudgetDetailsScreen> createState() =>
      _BudgetDetailsScreenState();
}

class _BudgetDetailsScreenState extends ConsumerState<BudgetDetailsScreen> {
  late final PurchaseBudgetDao _budgetDao;
  List<BudgetCategory> _categories = [];
  List<BudgetTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _budgetDao = PurchaseBudgetDao(ref.read(appDatabaseProvider));
    _loadBudgetDetails();
  }

  Future<void> _loadBudgetDetails() async {
    setState(() => _isLoading = true);

    try {
      final categories = await _budgetDao.getCategoriesByBudget(
        widget.budget.id,
      );
      final transactions = await _budgetDao.getTransactionsByBudget(
        widget.budget.id,
      );

      setState(() {
        _categories = categories;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spentPercentage = widget.budget.totalBudget > 0
        ? (widget.budget.spentAmount / widget.budget.totalBudget) * 100
        : 0.0;

    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text('تفاصيل الميزانية'),
        backgroundColor: Color(0xFF2D2D3D),
        actions: [
          if (widget.budget.status == 'active')
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: _editBudget,
              tooltip: 'تعديل الميزانية',
            ),
          if (widget.budget.status == 'active')
            IconButton(
              icon: Icon(Icons.add, color: Colors.green),
              onPressed: _addTransaction,
              tooltip: 'إضافة معاملة',
            ),
          if (widget.budget.status == 'active')
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: _closeBudget,
              tooltip: 'إغلاق الميزانية',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Budget Info Card
                  _buildBudgetInfoCard(spentPercentage),
                  SizedBox(height: 20),

                  // Categories List
                  _buildCategoriesList(),
                  SizedBox(height: 20),

                  // Transactions List
                  _buildTransactionsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildBudgetInfoCard(double spentPercentage) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _getBudgetStatusColor(
                  widget.budget,
                  spentPercentage,
                ),
                child: Icon(
                  _getBudgetStatusIcon(widget.budget, spentPercentage),
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.budget.budgetName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _getStatusLabel(widget.budget.status),
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInfoRow(
            'إجمالي الميزانية',
            '${widget.budget.totalBudget.toStringAsFixed(2)} ج.م',
          ),
          _buildInfoRow(
            'المبلغ المصروف',
            '${widget.budget.spentAmount.toStringAsFixed(2)} ج.م',
          ),
          _buildInfoRow(
            'المبلغ المتبقي',
            '${widget.budget.remainingAmount.toStringAsFixed(2)} ج.م',
          ),
          _buildInfoRow('نسبة الصرف', '${spentPercentage.toStringAsFixed(1)}%'),
          _buildInfoRow(
            'تاريخ البدء',
            DateFormat('yyyy-MM-dd').format(widget.budget.startDate),
          ),
          _buildInfoRow(
            'تاريخ الانتهاء',
            DateFormat('yyyy-MM-dd').format(widget.budget.endDate),
          ),
          _buildInfoRow(
            'نوع الميزانية',
            _getBudgetTypeLabel(widget.budget.budgetType),
          ),
          if (widget.budget.description != null)
            _buildInfoRow('الوصف', widget.budget.description!),
          if (widget.budget.notes != null)
            _buildInfoRow('ملاحظات', widget.budget.notes!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'فئات الميزانية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (widget.budget.status == 'active')
                IconButton(
                  icon: Icon(Icons.add, color: Colors.purple),
                  onPressed: _addCategory,
                  tooltip: 'إضافة فئة',
                ),
            ],
          ),
          SizedBox(height: 16),
          ..._categories.map((category) => _buildCategoryCard(category)),
          if (_categories.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.category, size: 48, color: Colors.grey[600]),
                  SizedBox(height: 8),
                  Text(
                    'لا توجد فئات',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (widget.budget.status == 'active')
                    TextButton(
                      onPressed: _addCategory,
                      child: Text(
                        'إضافة فئة',
                        style: TextStyle(color: Colors.purple),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BudgetCategory category) {
    final spentPercentage = category.allocatedAmount > 0
        ? (category.spentAmount / category.allocatedAmount) * 100
        : 0.0;

    return Card(
      color: Color(0xFF3D3D4D),
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          category.categoryName,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${category.spentAmount.toStringAsFixed(0)} من ${category.allocatedAmount.toStringAsFixed(0)} ج.م',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: spentPercentage > 100 ? 1.0 : spentPercentage / 100,
              backgroundColor: Color(0xFF4D4D5D),
              valueColor: AlwaysStoppedAnimation<Color>(
                category.spentAmount > category.allocatedAmount
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${spentPercentage.toStringAsFixed(1)}%',
          style: TextStyle(
            color: category.spentAmount > category.allocatedAmount
                ? Colors.red
                : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سجل المعاملات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          ..._transactions
              .take(10)
              .map((transaction) => _buildTransactionCard(transaction)),
          if (_transactions.length > 10)
            TextButton(
              onPressed: () {
                // Navigate to full transactions list
              },
              child: Text(
                'عرض كل المعاملات (${_transactions.length})',
                style: TextStyle(color: Colors.purple),
              ),
            ),
          if (_transactions.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.receipt, size: 48, color: Colors.grey[600]),
                  SizedBox(height: 8),
                  Text(
                    'لا توجد معاملات',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BudgetTransaction transaction) {
    return Card(
      color: Color(0xFF3D3D4D),
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTransactionTypeColor(
            transaction.transactionType,
          ),
          child: Icon(
            _getTransactionTypeIcon(transaction.transactionType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('yyyy-MM-dd HH:mm').format(transaction.transactionDate),
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: Text(
          '${transaction.amount.toStringAsFixed(2)} ج.م',
          style: TextStyle(
            color: transaction.amount >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'purchase':
        return Colors.purple;
      case 'adjustment':
        return Colors.blue;
      case 'transfer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionTypeIcon(String type) {
    switch (type) {
      case 'purchase':
        return Icons.shopping_cart;
      case 'adjustment':
        return Icons.tune;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.receipt;
    }
  }

  String _getBudgetTypeLabel(String type) {
    switch (type) {
      case 'monthly':
        return 'شهري';
      case 'quarterly':
        return 'ربع سنوي';
      case 'yearly':
        return 'سنوي';
      case 'project':
        return 'مشروع';
      default:
        return type;
    }
  }

  void _editBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBudgetScreen(budget: widget.budget),
      ),
    ).then((_) => _loadBudgetDetails());
  }

  void _addTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(budgetId: widget.budget.id),
      ),
    ).then((_) => _loadBudgetDetails());
  }

  void _addCategory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCategoryScreen(budgetId: widget.budget.id),
      ),
    ).then((_) => _loadBudgetDetails());
  }

  void _closeBudget() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D2D3D),
        title: Text('إغلاق الميزانية', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من إغلاق هذه الميزانية؟',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await _budgetDao.closeBudget(
                  widget.budget.id,
                  'تم الإغلاق من قبل المدير',
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('تم إغلاق الميزانية بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('خطأ في إغلاق الميزانية: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getBudgetStatusColor(PurchaseBudget budget, double spentPercentage) {
    if (budget.status == 'completed') return Colors.grey;
    if (budget.status == 'cancelled') return Colors.red;
    if (budget.spentAmount > budget.totalBudget) return Colors.red;
    if (spentPercentage >= 80) return Colors.orange;
    return Colors.green;
  }

  IconData _getBudgetStatusIcon(PurchaseBudget budget, double spentPercentage) {
    if (budget.status == 'completed') return Icons.check_circle;
    if (budget.status == 'cancelled') return Icons.cancel;
    if (budget.spentAmount > budget.totalBudget) return Icons.warning;
    if (spentPercentage >= 80) return Icons.warning_amber_rounded;
    return Icons.trending_up;
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'نشطة';
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغية';
      default:
        return status;
    }
  }
}

// Placeholder screens for navigation
class CreateBudgetScreen extends StatelessWidget {
  const CreateBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text('إنشاء ميزانية جديدة'),
        backgroundColor: Color(0xFF2D2D3D),
      ),
      body: Center(
        child: Text(
          'صفحة إنشاء ميزانية جديدة - قيد التطوير',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class EditBudgetScreen extends StatelessWidget {
  final PurchaseBudget budget;

  const EditBudgetScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text('تعديل الميزانية'),
        backgroundColor: Color(0xFF2D2D3D),
      ),
      body: Center(
        child: Text(
          'صفحة تعديل الميزانية - قيد التطوير',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class AddTransactionScreen extends StatelessWidget {
  final int budgetId;

  const AddTransactionScreen({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text('إضافة معاملة'),
        backgroundColor: Color(0xFF2D2D3D),
      ),
      body: Center(
        child: Text(
          'صفحة إضافة معاملة - قيد التطوير',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class AddCategoryScreen extends StatelessWidget {
  final int budgetId;

  const AddCategoryScreen({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text('إضافة فئة'),
        backgroundColor: Color(0xFF2D2D3D),
      ),
      body: Center(
        child: Text(
          'صفحة إضافة فئة - قيد التطوير',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
