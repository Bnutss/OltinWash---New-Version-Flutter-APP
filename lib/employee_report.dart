import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'employee_detail_report.dart';

class EmployeeReportPage extends StatefulWidget {
  const EmployeeReportPage({Key? key}) : super(key: key);

  @override
  _EmployeeReportPageState createState() => _EmployeeReportPageState();
}

class _EmployeeReportPageState extends State<EmployeeReportPage>
    with SingleTickerProviderStateMixin {
  List<EmployeeStats> _employeeStats = [];
  String _message = '';
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  Future<void>? _initialLoad;
  final String baseUrl = 'https://oltinwash.pythonanywhere.com';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _initialLoad = _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await fetchEmployeeStats();
      if (mounted) {
        setState(() {
          _employeeStats = data;
          _message = '';
          if (_employeeStats.isEmpty) {
            _message = 'На выбранную дату нет данных';
          }
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Ошибка загрузки данных';
        });
      }
    }
  }

  Future<List<EmployeeStats>> fetchEmployeeStats() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final response = await http.get(
        Uri.parse('$baseUrl/api/employee-stats/?date=$formattedDate'));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is Map && data.containsKey('message')) {
        if (mounted) {
          setState(() {
            _message = data['message'];
          });
        }
        return [];
      } else {
        List<dynamic> jsonList = data;
        List<EmployeeStats> statsList = jsonList
            .map((json) => EmployeeStats.fromJson(json, baseUrl))
            .toList();
        statsList.sort((a, b) =>
            b.washedCarsCount.compareTo(a.washedCarsCount));
        return statsList;
      }
    } else {
      throw Exception('Не удалось загрузить статистику сотрудников.');
    }
  }

  void _filterResults() {
    setState(() {
      _employeeStats = _employeeStats.where((stats) {
        final nameMatch = stats.name.toLowerCase().contains(
            _searchQuery.toLowerCase());
        final dateMatch = stats.date == null ||
            (_selectedDate.year == stats.date!.year &&
                _selectedDate.month == stats.date!.month &&
                _selectedDate.day == stats.date!.day);
        return nameMatch && dateMatch;
      }).toList();
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterResults();
    });
  }

  String formatNumber(double number) {
    return NumberFormat("#,##0", "en_US").format(number).replaceAll(',', ' ');
  }

  Future<void> _completeOrdersForToday(int employeeId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/employee-stats/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'employee_id': employeeId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _employeeStats = _employeeStats.map((stats) {
          if (stats.id == employeeId) {
            stats.isCompleted = true;
            stats.completionDate = DateTime.now();
          }
          return stats;
        }).toList();
      });
      _showNotification('Касса сдана', isError: false);
    } else {
      _showNotification('Ошибка', isError: true);
    }
  }

  DateTime _parseServerTime(String timeString) {
    final serverTime = DateTime.parse(timeString);
    final localTime = serverTime.toLocal();
    return localTime;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.grey[700]!,
              onPrimary: Colors.white,
              surface: Colors.grey[850]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[850],
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _initialLoad = _loadData();
      });
    }
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Отчет по сотрудникам',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                DateFormat('dd MMMM yyyy', 'ru').format(
                                    _selectedDate),
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[700]!, Colors.grey[800]!],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(
                                Icons.refresh, color: Colors.white, size: 22),
                            onPressed: () {
                              setState(() {
                                _initialLoad = _loadData();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
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
                                hintText: 'Поиск...',
                                hintStyle: TextStyle(
                                    color: Colors.grey[400], fontSize: 14),
                                prefixIcon: Icon(
                                    Icons.search, color: Colors.grey[600],
                                    size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
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
                            icon: Icon(
                                Icons.calendar_today, color: Colors.white,
                                size: 20),
                            onPressed: _selectDate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<void>(
                  future: _initialLoad,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[400]!),
                        ),
                      );
                    } else if (_message.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, color: Colors.white38,
                                size: 50),
                            SizedBox(height: 16),
                            Text(
                              _message,
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    } else if (_employeeStats.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, color: Colors.white38,
                                size: 50),
                            SizedBox(height: 16),
                            Text(
                              'Нет данных',
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
                        itemCount: _employeeStats.length,
                        itemBuilder: (context, index) {
                          var stats = _employeeStats[index];
                          return FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0)
                                .animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  (index / _employeeStats.length) * 0.5,
                                  1.0,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            ),
                            child: Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: stats.isCompleted
                                    ? Colors.green[700]?.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: stats.isCompleted
                                      ? Colors.green[600]!.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.08),
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 55,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: stats.isCompleted
                                              ? Colors.green[600]!
                                              : Colors.grey[700]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: stats.photoUrl.isNotEmpty
                                            ? Image.network(
                                          stats.photoUrl,
                                          fit: BoxFit.cover,
                                          width: 55,
                                          height: 55,
                                          errorBuilder: (context, error,
                                              stackTrace) {
                                            return Container(
                                              color: Colors.grey[700],
                                              child: Icon(Icons.person,
                                                  color: Colors.white,
                                                  size: 30),
                                            );
                                          },
                                        )
                                            : Container(
                                          color: Colors.grey[700],
                                          child: Icon(
                                              Icons.person, color: Colors.white,
                                              size: 30),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            stats.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.car_repair,
                                                  color: Colors.white60,
                                                  size: 14),
                                              SizedBox(width: 6),
                                              Text(
                                                '${stats
                                                    .washedCarsCount} машин',
                                                style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12),
                                              ),
                                              SizedBox(width: 12),
                                              Icon(Icons.payments,
                                                  color: Colors.white60,
                                                  size: 14),
                                              SizedBox(width: 6),
                                              Text(
                                                '${formatNumber(
                                                    stats.employeeShare)} сум',
                                                style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          if (stats.isCompleted &&
                                              stats.completionDate != null)
                                            Padding(
                                              padding: EdgeInsets.only(top: 6),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.check_circle,
                                                      color: Colors.green[400],
                                                      size: 14),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Сдано ${DateFormat('HH:mm')
                                                        .format(
                                                        _parseServerTime(stats
                                                            .completionDate!
                                                            .toIso8601String()))}',
                                                    style: TextStyle(
                                                      color: Colors.green[400],
                                                      fontSize: 11,
                                                      fontWeight: FontWeight
                                                          .w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[700],
                                            borderRadius: BorderRadius.circular(
                                                8),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.info_outline,
                                                color: Colors.white, size: 20),
                                            padding: EdgeInsets.all(8),
                                            constraints: BoxConstraints(),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EmployeeDetailPage(
                                                        employeeStats: stats,
                                                        selectedDate: _selectedDate,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        if (!stats.isCompleted) ...[
                                          SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.green[700],
                                              borderRadius: BorderRadius
                                                  .circular(8),
                                            ),
                                            child: IconButton(
                                              icon: Icon(
                                                  Icons.check_circle_outline,
                                                  color: Colors.white,
                                                  size: 20),
                                              padding: EdgeInsets.all(8),
                                              constraints: BoxConstraints(),
                                              onPressed: () =>
                                                  _completeOrdersForToday(
                                                      stats.id),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
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
            ],
          ),
        ),
      ),
    );
  }
}

class EmployeeStats {
  final int id;
  final int orderId;
  final String name;
  final int washedCarsCount;
  final double totalWashAmount;
  final double employeeShare;
  final double companyShare;
  final double fundShare;
  final DateTime? date;
  final String photoUrl;
  bool isCompleted;
  DateTime? completionDate;

  EmployeeStats({
    required this.id,
    required this.orderId,
    required this.name,
    required this.washedCarsCount,
    required this.totalWashAmount,
    required this.employeeShare,
    required this.companyShare,
    required this.fundShare,
    required this.date,
    required this.photoUrl,
    this.isCompleted = false,
    this.completionDate,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json, String baseUrl) {
    return EmployeeStats(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      name: json['name_employees'] ?? '',
      washedCarsCount: json['washed_cars_count'] ?? 0,
      totalWashAmount: _toDouble(json['total_wash_amount'] ?? 0.0),
      employeeShare: _toDouble(json['employee_share'] ?? 0.0),
      companyShare: _toDouble(json['company_share'] ?? 0.0),
      fundShare: _toDouble(json['fund_share'] ?? 0.0),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      photoUrl: json['photo_url'] != null ? '$baseUrl${json['photo_url']}' : '',
      isCompleted: json['is_completed'] ?? false,
      completionDate: json['completion_date'] != null ? DateTime.parse(
          json['completion_date']) : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      return 0.0;
    }
  }
}