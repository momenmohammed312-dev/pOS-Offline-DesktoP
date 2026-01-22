import 'package:drift/drift.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/database/tables/employees_table.dart';
import 'package:pos_offline_desktop/core/database/tables/sales_table.dart';

part 'employees_dao.g.dart';

@DriftAccessor(tables: [Employees, Sales])
class EmployeesDao extends DatabaseAccessor<AppDatabase>
    with _$EmployeesDaoMixin {
  EmployeesDao(super.db);

  Future<List<Employee>> getAllEmployees() => select(employees).get();

  Future<Employee> getEmployeeById(String id) =>
      (select(employees)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<void> addEmployee(EmployeesCompanion employee) =>
      into(employees).insert(employee);

  Future<void> updateEmployee(Employee employee) =>
      update(employees).replace(employee);

  Future<void> deleteEmployee(String id) =>
      (delete(employees)..where((tbl) => tbl.id.equals(id))).go();

  // Employee summary for sales report
  Future<List<EmployeeSummary>> getEmployeesSummary() async {
    return await customSelect(
      '''
      SELECT 
        e.id,
        e.name,
        e.position,
        COALESCE(SUM(s.total), 0) as total_sales,
        COUNT(s.id) as sales_count
      FROM employees e
      LEFT JOIN sales s ON s.employee_id = e.id
      GROUP BY e.id, e.name, e.position
      ORDER BY total_sales DESC
    ''',
      readsFrom: {employees, sales},
    ).map((row) {
      return EmployeeSummary(
        id: row.read<String>('id'),
        name: row.read<String>('name'),
        position: row.read<String>('position'),
        totalSales: row.read<double>('total_sales'),
        salesCount: row.read<int>('sales_count'),
      );
    }).get();
  }

  // Employee summary for sales report with date range filtering
  Future<List<EmployeeSummary>> getEmployeesSummaryByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await customSelect(
      '''
      SELECT 
        e.id,
        e.name,
        e.position,
        COALESCE(SUM(s.total), 0) as total_sales,
        COUNT(s.id) as sales_count
      FROM employees e
      LEFT JOIN sales s ON s.employee_id = e.id
      WHERE s.date >= ? AND s.date <= ?
      GROUP BY e.id, e.name, e.position
      ORDER BY total_sales DESC
    ''',
      readsFrom: {employees, sales},
      variables: [
        Variable<String>(startDate.toIso8601String()),
        Variable<String>(endDate.toIso8601String()),
      ],
    ).map((row) {
      return EmployeeSummary(
        id: row.read<String>('id'),
        name: row.read<String>('name'),
        position: row.read<String>('position'),
        totalSales: row.read<double>('total_sales'),
        salesCount: row.read<int>('sales_count'),
      );
    }).get();
  }

  // Add a sale record for an employee
  Future<void> addSale(SalesCompanion sale) => into(sales).insert(sale);

  // Get all sales for an employee
  Future<List<Sale>> getSalesByEmployee(String employeeId) =>
      (select(sales)..where((tbl) => tbl.employeeId.equals(employeeId))).get();

  Stream<double> watchTotalSales() {
    return customSelect(
      'SELECT SUM(amount) as total FROM sales',
    ).map((row) => row.read<double>('total')).watchSingle();
  }

  Future<double> getTotalSales() async {
    final result = await customSelect(
      'SELECT SUM(amount) as total FROM sales',
    ).getSingle();
    return result.read<double>('total');
  }

  Future<void> deleteSale(String id) =>
      (delete(sales)..where((tbl) => tbl.id.equals(id))).go();

  Future<List<Sale>> getAllSales() => (select(sales)).get();

  Stream<List<Sale>> watchAllSales() => (select(sales)).watch();
}

// Employee summary model for reports
class EmployeeSummary {
  final String id;
  final String name;
  final String position;
  final double totalSales;
  final int salesCount;

  EmployeeSummary({
    required this.id,
    required this.name,
    required this.position,
    required this.totalSales,
    required this.salesCount,
  });
}
