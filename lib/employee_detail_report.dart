import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'employee_report.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmployeeDetailPage extends StatefulWidget {
  final EmployeeStats employeeStats;
  final DateTime selectedDate;

  const EmployeeDetailPage({
    Key? key,
    required this.employeeStats,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _EmployeeDetailPageState createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage>
    with SingleTickerProviderStateMixin {
  late Future<List<WashOrder>> futureWashOrders;
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
    futureWashOrders =
        fetchWashOrders(widget.employeeStats.id, widget.selectedDate);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<WashOrder>> fetchWashOrders(int employeeId,
      DateTime selectedDate) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final response = await http.get(Uri.parse(
        'https://oltinwash.pythonanywhere.com/api/employee/$employeeId/wash_orders/?date=$formattedDate'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse.map((order) => WashOrder.fromJson(order)).toList();
    } else {
      throw Exception('Failed to load wash orders');
    }
  }

  String formatNumber(double number) {
    return NumberFormat("#,##0", "en_US").format(number).replaceAll(',', ' ');
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      placeholder: (context, url) =>
                          Container(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors
                                  .grey[400]!),
                            ),
                          ),
                      errorWidget: (context, url, error) =>
                          Container(
                            padding: EdgeInsets.all(40),
                            color: Colors.grey[850],
                            child: Icon(
                                Icons.error_outline, color: Colors.white,
                                size: 50),
                          ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Помытые машины',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            widget.employeeStats.name,
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
                            futureWashOrders = fetchWashOrders(
                                widget.employeeStats.id, widget.selectedDate);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<WashOrder>>(
                  future: futureWashOrders,
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
                            Icon(Icons.car_repair, color: Colors.white38,
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
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ListView.builder(
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final order = snapshot.data![index];
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
                                padding: EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () =>
                                          _showImageDialog(
                                              context, order.carPhoto),
                                      child: Container(
                                        width: 65,
                                        height: 65,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              12),
                                          border: Border.all(
                                            color: Colors.grey[700]!,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              10),
                                          child: CachedNetworkImage(
                                            imageUrl: order.carPhoto,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<
                                                        Color>(
                                                        Colors.grey[400]!),
                                                  ),
                                                ),
                                            errorWidget: (context, url,
                                                error) =>
                                                Container(
                                                  color: Colors.grey[700],
                                                  child: Icon(Icons.car_repair,
                                                      color: Colors.white,
                                                      size: 30),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[700],
                                                  borderRadius: BorderRadius
                                                      .circular(6),
                                                ),
                                                child: Text(
                                                  '#${index + 1}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  order.typeOfCarWash,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (order.isCompleted)
                                                Icon(Icons.check_circle,
                                                    color: Colors.green[400],
                                                    size: 18)
                                              else
                                                Icon(Icons.pending,
                                                    color: Colors.orange[400],
                                                    size: 18),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          _buildInfoRow(Icons.payments, 'Цена',
                                              '${formatNumber(
                                                  order.negotiatedPrice)} сум'),
                                          SizedBox(height: 4),
                                          _buildInfoRow(
                                              Icons.account_balance_wallet,
                                              'На руки', '${formatNumber(
                                              order.employeeShare)} сум'),
                                          SizedBox(height: 4),
                                          _buildInfoRow(
                                              Icons.access_time, 'Время',
                                              DateFormat('HH:mm').format(
                                                  order.orderDate)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 14),
        SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class WashOrder {
  final String carPhoto;
  final String typeOfCarWash;
  final double negotiatedPrice;
  final double fund;
  final double employeeShare;
  final double companyShare;
  final DateTime orderDate;
  final bool isCompleted;

  WashOrder({
    required this.carPhoto,
    required this.typeOfCarWash,
    required this.negotiatedPrice,
    required this.fund,
    required this.employeeShare,
    required this.companyShare,
    required this.orderDate,
    required this.isCompleted,
  });

  factory WashOrder.fromJson(Map<String, dynamic> json) {
    return WashOrder(
      carPhoto: json['car_photo_url'] ?? '',
      typeOfCarWash: json['type_of_car_wash']['name'] ?? '',
      negotiatedPrice: double.tryParse(json['negotiated_price'].toString()) ??
          0.0,
      fund: double.tryParse(json['fund'].toString()) ?? 0.0,
      employeeShare: double.tryParse(json['employee_share'].toString()) ?? 0.0,
      companyShare: double.tryParse(json['company_share'].toString()) ?? 0.0,
      orderDate: DateTime.parse(json['order_date']).toLocal(),
      isCompleted: json['is_completed'] ?? false,
    );
  }
}