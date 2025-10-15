import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class EmployeeDetailPage extends StatefulWidget {
  final int employeeId;

  EmployeeDetailPage({required this.employeeId});

  @override
  _EmployeeDetailPageState createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage>
    with SingleTickerProviderStateMixin {
  late Future<Employee> _employeeDetail;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
    _employeeDetail = fetchEmployeeDetail();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Employee> fetchEmployeeDetail() async {
    final response = await http.get(Uri.parse(
        'https://oltinwash.pythonanywhere.com/employees/api/employee/${widget
            .employeeId}/'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(
          utf8.decode(response.bodyBytes));
      return Employee.fromJson(jsonResponse);
    } else {
      throw Exception('Не удалось загрузить данные сотрудника');
    }
  }

  Future<void> fireEmployee(int employeeId) async {
    final response = await http.post(
      Uri.parse(
          'https://oltinwash.pythonanywhere.com/employees/api/employee/$employeeId/fire/'),
    );

    if (response.statusCode == 200) {
      _showNotification('Сотрудник уволен', isError: false);
      Navigator.of(context).pop(true);
    } else {
      _showNotification('Не удалось уволить', isError: true);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunch(launchUri.toString())) {
      await launch(launchUri.toString());
    } else {
      _showNotification('Ошибка звонка', isError: true);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _employeeDetail = fetchEmployeeDetail();
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

  void _showFireDialog(Employee employee) {
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
                  child: Icon(Icons.block, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Уволить?',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'Уволить сотрудника ${employee.name}?',
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
                  fireEmployee(employee.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Уволить',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                child: Row(
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
                    Text(
                      'Детали сотрудника',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: Colors.grey[400],
                  child: FutureBuilder<Employee>(
                    future: _employeeDetail,
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
                      } else if (!snapshot.hasData) {
                        return Center(
                          child: Text(
                            'Нет данных',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 16),
                          ),
                        );
                      } else {
                        var employee = snapshot.data!;
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: ListView(
                            physics: BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                            children: [
                              Center(
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey[700]!,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: employee.photoUrl != null &&
                                        employee.photoUrl!.isNotEmpty
                                        ? Image.network(
                                      employee.photoUrl!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      errorBuilder: (context, error,
                                          stackTrace) {
                                        return Container(
                                          color: Colors.grey[700],
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 60,
                                          ),
                                        );
                                      },
                                    )
                                        : Container(
                                      color: Colors.grey[700],
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 60,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 24),
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildInfoRow('Имя', employee.name),
                                    _buildInfoRow(
                                        'Должность', employee.positionName),
                                    _buildInfoRow('Возраст',
                                        employee.age?.toString() ??
                                            'Не указан'),
                                    _buildInfoRow('Телефон',
                                        employee.phoneNumber ?? 'Не указан'),
                                    _buildInfoRow('Адрес',
                                        employee.address ?? 'Не указан'),
                                    _buildInfoRow('Дата приёма',
                                        employee.hireDate ?? 'Не указана'),
                                    _buildInfoRow(
                                      'Дата увольнения',
                                      employee.dateOfTermination ?? 'Не уволен',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red[600]!,
                                            Colors.red[800]!
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _showFireDialog(employee),
                                        icon: Icon(
                                            Icons.block, color: Colors.white,
                                            size: 20),
                                        label: Text(
                                          'Уволить',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green[600]!,
                                            Colors.green[800]!
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (employee.phoneNumber != null &&
                                              employee.phoneNumber!
                                                  .isNotEmpty) {
                                            _makePhoneCall(
                                                employee.phoneNumber!);
                                          } else {
                                            _showNotification('Номер не указан',
                                                isError: true);
                                          }
                                        },
                                        icon: Icon(
                                            Icons.phone, color: Colors.white,
                                            size: 20),
                                        label: Text(
                                          'Позвонить',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
  final String positionName;
  final int? age;
  final String? phoneNumber;
  final String? address;
  final String? hireDate;
  final String? dateOfTermination;
  final String? photoUrl;

  Employee({
    required this.id,
    required this.name,
    required this.positionName,
    this.age,
    this.phoneNumber,
    this.address,
    this.hireDate,
    this.dateOfTermination,
    this.photoUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name_employees'] ?? '',
      positionName: json['position_name'] ?? '',
      age: json['age'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      hireDate: json['hire_date'],
      dateOfTermination: json['date_of_termination'],
      photoUrl: json['photo_url'],
    );
  }
}