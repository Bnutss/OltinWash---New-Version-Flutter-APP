import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class GeneralReportPage extends StatefulWidget {
  const GeneralReportPage({Key? key}) : super(key: key);

  @override
  _GeneralReportPageState createState() => _GeneralReportPageState();
}

class _GeneralReportPageState extends State<GeneralReportPage>
    with SingleTickerProviderStateMixin {
  late Future<List<ReportData>> reportData;
  DateTimeRange selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: 30)),
    end: DateTime.now(),
  );
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
    reportData = fetchReportData(selectedDateRange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<ReportData>> fetchReportData(DateTimeRange dateRange) async {
    final formattedStartDate = DateFormat('yyyy-MM-dd').format(dateRange.start);
    final formattedEndDate = DateFormat('yyyy-MM-dd').format(dateRange.end);
    final response = await http.get(
      Uri.parse(
          'https://oltinwash.pythonanywhere.com/api/report?start_date=$formattedStartDate&end_date=$formattedEndDate'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => ReportData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load report');
    }
  }

  void _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
        reportData = fetchReportData(selectedDateRange);
      });
      _animationController.forward(from: 0);
    }
  }

  void _refreshData() {
    setState(() {
      reportData = fetchReportData(selectedDateRange);
    });
    _animationController.forward(from: 0);
  }

  Future<void> _sendReportToTelegram(double totalAmount, double cashierAmount,
      double employeesAmount, int totalWashes) async {
    final String apiUrl = 'https://oltinwash.pythonanywhere.com/api/send_telegram_message/';
    final String startDate = DateFormat('dd.MM.yyyy').format(
        selectedDateRange.start);
    final String endDate = DateFormat('dd.MM.yyyy').format(
        selectedDateRange.end);

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'total_amount': totalAmount.toString(),
        'cashier_amount': cashierAmount.toString(),
        'employees_amount': employeesAmount.toString(),
        'total_washes': totalWashes.toString(),
        'start_date': startDate,
        'end_date': endDate,
      },
    );

    if (response.statusCode == 200) {
      _showNotification('Отчет отправлен в Telegram', isError: false);
    } else {
      _showNotification('Ошибка отправки', isError: true);
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

  String formatNumber(double number) {
    if (number % 1 == 0) {
      final formatter = NumberFormat("#,###", "en_US");
      return formatter.format(number).replaceAll(',', ' ');
    } else {
      final formatter = NumberFormat("#,##0.0", "en_US");
      return formatter.format(number).replaceAll(',', ' ');
    }
  }

  double calculateTotal(List<ReportData> data,
      double Function(ReportData) selector) {
    return data.fold(0, (sum, item) => sum + selector(item));
  }

  int calculateTotalWashes(List<ReportData> data) {
    return data.fold(0, (sum, item) => sum + item.totalWashes);
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
                            'Общий отчет',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
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
                                Icons.calendar_today, color: Colors.white,
                                size: 20),
                            onPressed: () => _selectDateRange(context),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[700]!, Colors.grey[800]!],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(
                                Icons.refresh, color: Colors.white, size: 20),
                            onPressed: _refreshData,
                          ),
                        ),
                        SizedBox(width: 8),
                        FutureBuilder<List<ReportData>>(
                          future: reportData,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final totalAmount = calculateTotal(
                                  snapshot.data!, (item) => item.totalAmount);
                              final totalCashierAmount = calculateTotal(
                                  snapshot.data!, (item) => item.cashierAmount);
                              final totalEmployeesAmount = calculateTotal(
                                  snapshot.data!, (item) =>
                              item
                                  .employeesAmount);
                              final totalWashes = calculateTotalWashes(
                                  snapshot.data!);

                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[600]!,
                                      Colors.blue[800]!
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.send, color: Colors.white,
                                      size: 20),
                                  onPressed: () =>
                                      _sendReportToTelegram(
                                          totalAmount, totalCashierAmount,
                                          totalEmployeesAmount, totalWashes),
                                ),
                              );
                            } else {
                              return Container();
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.date_range, color: Colors.white70,
                              size: 18),
                          SizedBox(width: 10),
                          Text(
                            "${DateFormat('dd.MM.yyyy').format(
                                selectedDateRange.start)} - ${DateFormat(
                                'dd.MM.yyyy').format(selectedDateRange.end)}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<ReportData>>(
                  future: reportData,
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
                            Text('Ошибка загрузки', style: TextStyle(
                                color: Colors.white60, fontSize: 16)),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, color: Colors.white38,
                                size: 50),
                            SizedBox(height: 16),
                            Text('Нет данных', style: TextStyle(
                                color: Colors.white60, fontSize: 16)),
                          ],
                        ),
                      );
                    } else {
                      final totalAmount = calculateTotal(
                          snapshot.data!, (item) => item.totalAmount);
                      final totalCashierAmount = calculateTotal(
                          snapshot.data!, (item) => item.cashierAmount);
                      final totalEmployeesAmount = calculateTotal(
                          snapshot.data!, (item) => item.employeesAmount);
                      final totalWashes = calculateTotalWashes(snapshot.data!);

                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                physics: BouncingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  return ReportCard(
                                    data: snapshot.data![index],
                                    formatNumber: formatNumber,
                                  );
                                },
                              ),
                            ),
                            _buildTotalBlock(totalAmount, totalCashierAmount,
                                totalEmployeesAmount, totalWashes),
                          ],
                        ),
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

  Widget _buildTotalBlock(double totalAmount, double totalCashierAmount,
      double totalEmployeesAmount, int totalWashes) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calculate, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Итоги',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTotalItem(Icons.car_repair, 'Машин', '$totalWashes'),
          SizedBox(height: 10),
          _buildTotalItem(Icons.payments, 'Общая сумма',
              '${formatNumber(totalAmount)} сум'),
          SizedBox(height: 10),
          _buildTotalItem(Icons.account_balance_wallet, 'Касса',
              '${formatNumber(totalCashierAmount)} сум'),
          SizedBox(height: 10),
          _buildTotalItem(Icons.people, 'Мойщики',
              '${formatNumber(totalEmployeesAmount)} сум'),
        ],
      ),
    );
  }

  Widget _buildTotalItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class ReportCard extends StatelessWidget {
  final ReportData data;
  final String Function(double) formatNumber;

  const ReportCard({Key? key, required this.data, required this.formatNumber})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                      Icons.calendar_today, color: Colors.white, size: 16),
                ),
                SizedBox(width: 12),
                Text(
                  DateFormat('dd MMMM yyyy', 'ru').format(data.orderDate),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            _buildReportItem(Icons.car_repair, 'Моек', '${data.totalWashes}'),
            SizedBox(height: 8),
            _buildReportItem(Icons.payments, 'Сумма',
                '${formatNumber(data.totalAmount)} сум'),
            SizedBox(height: 8),
            _buildReportItem(Icons.account_balance_wallet, 'Касса',
                '${formatNumber(data.cashierAmount)} сум'),
            SizedBox(height: 8),
            _buildReportItem(Icons.people, 'Мойщики',
                '${formatNumber(data.employeesAmount)} сум'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 16),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class ReportData {
  final DateTime orderDate;
  final int totalWashes;
  final double totalAmount;
  final double cashierAmount;
  final double employeesAmount;

  ReportData({
    required this.orderDate,
    required this.totalWashes,
    required this.totalAmount,
    required this.cashierAmount,
    required this.employeesAmount,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      orderDate: DateTime.parse(json['order_date_only']),
      totalWashes: json['total_washes'] ?? 0,
      totalAmount: json['total_amount'] != null
          ? double.tryParse(json['total_amount'].toString()) ?? 0.0
          : 0.0,
      cashierAmount: json['cashier_amount'] != null
          ? double.tryParse(json['cashier_amount'].toString()) ?? 0.0
          : 0.0,
      employeesAmount: json['employees_amount'] != null
          ? double.tryParse(json['employees_amount'].toString()) ?? 0.0
          : 0.0,
    );
  }
}