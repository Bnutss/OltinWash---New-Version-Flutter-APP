import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'employees_detail_page.dart';
import 'create_employee_page.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({Key? key}) : super(key: key);

  @override
  _EmployeesPageState createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Employee>> futureEmployees;
  TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  int employeeCount = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _animationController.forward();
    futureEmployees = fetchEmployees();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Employee>> fetchEmployees() async {
    final response = await http.get(Uri.parse(
        'https://oltinwash.pythonanywhere.com/employees/api/employees/'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      List<Employee> employees = jsonResponse
          .map((employee) => Employee.fromJson(employee))
          .toList()
          .where((employee) =>
          employee.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
      setState(() {
        employeeCount = employees.length;
      });
      return employees;
    } else {
      throw Exception('Failed to load employees');
    }
  }

  Future<void> deleteEmployee(int id) async {
    final response = await http.delete(Uri.parse(
        'https://oltinwash.pythonanywhere.com/employees/api/employees/$id/delete/'));

    if (response.statusCode == 204) {
      _showNotification('Сотрудник удален', isError: false);
      setState(() {
        futureEmployees = fetchEmployees();
      });
    } else {
      final errorMessage = json.decode(
          utf8.decode(response.bodyBytes))['error'] ??
          'Ошибка удаления';
      _showNotification(errorMessage, isError: true);
    }
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
      futureEmployees = fetchEmployees();
    });
  }

  void _navigateToCreateEmployee() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateEmployeePage()),
    ).then((value) {
      if (value == true) {
        setState(() {
          futureEmployees = fetchEmployees();
        });
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      futureEmployees = fetchEmployees();
    });
  }

  void _showNotification(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.grey[850],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.grey[850],
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                      Icons.delete_outline, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Удалить?',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'Удалить сотрудника ${employee.name}?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Отмена',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  deleteEmployee(employee.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Удалить',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFF3D3D3D), Color(0xFF4A4A4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(
                                Icons.arrow_back_ios_new, color: Colors.white,
                                size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Сотрудники',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.people_alt, color: Colors.white,
                                  size: 18),
                              SizedBox(width: 6),
                              Text(
                                '$employeeCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[900]),
                              decoration: InputDecoration(
                                hintText: 'Поиск сотрудника...',
                                hintStyle: TextStyle(
                                    color: Colors.grey[400], fontSize: 14),
                                prefixIcon: Icon(
                                    Icons.search, color: Colors.grey[600],
                                    size: 20),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                  icon: Icon(
                                      Icons.clear, color: Colors.grey[600],
                                      size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged();
                                  },
                                )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                              ),
                              onChanged: (text) => _onSearchChanged(),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[700]!, Colors.grey[800]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.person_add, color: Colors.white,
                                size: 22),
                            onPressed: _navigateToCreateEmployee,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: Colors.grey[400],
                  child: FutureBuilder<List<Employee>>(
                    future: futureEmployees,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[400]!),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.white38,
                                  size: 50),
                              SizedBox(height: 16),
                              Text(
                                'Ошибка загрузки',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, color: Colors.white38,
                                  size: 50),
                              SizedBox(height: 16),
                              Text(
                                'Нет сотрудников',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return ListView.builder(
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            var employee = snapshot.data![index];
                            return FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0)
                                  .animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    (index / snapshot.data!.length) * 0.5,
                                    1.0,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
                              child: Dismissible(
                                key: Key(employee.id.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[700],
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  child: Icon(Icons.delete, color: Colors.white,
                                      size: 28),
                                ),
                                confirmDismiss: (direction) async {
                                  _showDeleteDialog(employee);
                                  return false;
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey[700]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: employee.photoUrl != null &&
                                            employee.photoUrl!.isNotEmpty
                                            ? Image.network(
                                          employee.photoUrl!,
                                          fit: BoxFit.cover,
                                          width: 50,
                                          height: 50,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<
                                                    Color>(
                                                    Colors.grey[400]!),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, exception,
                                              stackTrace) {
                                            return Container(
                                              color: Colors.grey[700],
                                              child: Icon(Icons.person,
                                                  color: Colors.white,
                                                  size: 28),
                                            );
                                          },
                                        )
                                            : Container(
                                          color: Colors.grey[700],
                                          child: Icon(
                                              Icons.person, color: Colors.white,
                                              size: 28),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      employee.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            employee.position,
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13),
                                          ),
                                          if (employee.age != null)
                                            Text(
                                              '${employee.age} лет',
                                              style: TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),
                                    trailing: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[700],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.info_outline,
                                            color: Colors.white, size: 20),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EmployeeDetailPage(
                                                      employeeId: employee.id),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Employee {
  final int id;
  final String name;
  final String position;
  final int? age;
  final String? photoUrl;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    this.age,
    this.photoUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name_employees'],
      position: json['position_name'],
      age: json['age'],
      photoUrl: json['photo_url'],
    );
  }
}