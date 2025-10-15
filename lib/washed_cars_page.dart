import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'detail_washed_cars_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WashedCarsPage extends StatefulWidget {
  const WashedCarsPage({Key? key}) : super(key: key);

  @override
  _WashedCarsPageState createState() => _WashedCarsPageState();
}

class _WashedCarsPageState extends State<WashedCarsPage>
    with SingleTickerProviderStateMixin {
  late Future<List<WashedCar>> futureWashedCars;
  TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  DateTime? selectedDate = DateTime.now();
  int washedCarCount = 0;
  SharedPreferences? _prefs;
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
    _initializeFuture();
    _searchController.addListener(_onSearchChanged);
    _loadPrefs();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeFuture() {
    setState(() {
      futureWashedCars = fetchWashedCars();
    });
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedDate = _prefs?.getString('selectedDate');
    if (savedDate != null) {
      setState(() {
        selectedDate = DateTime.parse(savedDate);
      });
    }
  }

  Future<List<WashedCar>> fetchWashedCars() async {
    final queryParameters = {
      if (selectedDate != null) 'order_date': DateFormat('yyyy-MM-dd').format(
          selectedDate!),
    };

    final uri = Uri.parse(
        'https://oltinwash.pythonanywhere.com/api/wash-orders/')
        .replace(queryParameters: queryParameters);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      List<WashedCar> washedCars = jsonResponse.map((car) =>
          WashedCar.fromJson(car)).toList();

      washedCars = washedCars
          .where((car) =>
      car.orderDate != null &&
          DateFormat('yyyy-MM-dd').format(DateTime.parse(car.orderDate!)) ==
              DateFormat('yyyy-MM-dd').format(selectedDate!))
          .toList();

      if (searchQuery.isNotEmpty) {
        washedCars = washedCars
            .where((car) =>
            car.washerName.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }

      setState(() {
        washedCarCount = washedCars.length;
      });

      return washedCars;
    } else {
      throw Exception('Не удалось загрузить помытые машины');
    }
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
      futureWashedCars = fetchWashedCars();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
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
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        _prefs?.setString('selectedDate', pickedDate.toIso8601String());
        futureWashedCars = fetchWashedCars();
      });
      _animationController.forward(from: 0);
    }
  }

  void _viewDetails(WashedCar car) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailWashedCarsPage(car: car)),
    );
  }

  Future<void> _deleteCar(int id) async {
    final uri = Uri.parse(
        'https://oltinwash.pythonanywhere.com/api/wash-orders/$id/');

    final response = await http.delete(uri);

    if (response.statusCode == 204) {
      setState(() {
        futureWashedCars = fetchWashedCars();
      });
      _showNotification('Мойка удалена', isError: false);
    } else {
      _showNotification('Ошибка удаления', isError: true);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      futureWashedCars = fetchWashedCars();
    });
    _animationController.forward(from: 0);
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

  void _showDeleteDialog(WashedCar car) {
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
                Text('Удалить?',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            content: Text(
              'Удалить запись о мойке?',
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
                  _deleteCar(car.id);
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
                                selectedDate != null
                                    ? DateFormat('dd MMMM yyyy', 'ru').format(
                                    selectedDate!)
                                    : 'Выберите дату',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                              Icon(Icons.directions_car, color: Colors.white,
                                  size: 18),
                              SizedBox(width: 6),
                              Text(
                                '$washedCarCount',
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
                                hintText: 'Поиск по мойщику...',
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
                            onPressed: () => _selectDate(context),
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
                  child: FutureBuilder<List<WashedCar>>(
                    future: futureWashedCars,
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
                              Icon(Icons.car_repair, color: Colors.white38,
                                  size: 50),
                              SizedBox(height: 16),
                              Text('Нет данных', style: TextStyle(
                                  color: Colors.white60, fontSize: 16)),
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
                              var car = snapshot.data![index];
                              final formatter = NumberFormat("#,###", "ru_RU");
                              return Dismissible(
                                key: Key(car.id.toString()),
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
                                  _showDeleteDialog(car);
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
                                  child: Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 55,
                                          height: 55,
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
                                            child: car.carPhoto != null &&
                                                car.carPhoto!.isNotEmpty
                                                ? Image.network(
                                              car.carPhoto!,
                                              fit: BoxFit.cover,
                                              width: 55,
                                              height: 55,
                                              errorBuilder: (context, error,
                                                  stackTrace) {
                                                return Container(
                                                  color: Colors.grey[700],
                                                  child: Icon(Icons.car_repair,
                                                      color: Colors.white,
                                                      size: 30),
                                                );
                                              },
                                            )
                                                : Container(
                                              color: Colors.grey[700],
                                              child: Icon(Icons.car_repair,
                                                  color: Colors.white,
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
                                                car.washerName,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.local_car_wash,
                                                      color: Colors.white60,
                                                      size: 14),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    car.washType,
                                                    style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.payments,
                                                      color: Colors.white60,
                                                      size: 14),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    '${formatter.format(
                                                        car.washPrice)} сум',
                                                    style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[700],
                                            borderRadius: BorderRadius.circular(
                                                8),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.visibility,
                                                color: Colors.white, size: 20),
                                            padding: EdgeInsets.all(8),
                                            constraints: BoxConstraints(),
                                            onPressed: () => _viewDetails(car),
                                          ),
                                        ),
                                      ],
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WashedCar {
  final int id;
  final String? carPhoto;
  final String washerName;
  final double washPrice;
  final String? orderDate;
  final String washType;

  WashedCar({
    required this.id,
    this.carPhoto,
    required this.washerName,
    required this.washPrice,
    this.orderDate,
    required this.washType,
  });

  factory WashedCar.fromJson(Map<String, dynamic> json) {
    double washPrice = 0.0;
    if (json['negotiated_price'] != null) {
      washPrice = double.tryParse(json['negotiated_price'].toString()) ?? 0.0;
    } else if (json['type_of_car_wash'] != null &&
        json['type_of_car_wash']['price'] != null) {
      washPrice =
          double.tryParse(json['type_of_car_wash']['price'].toString()) ?? 0.0;
    }

    return WashedCar(
      id: json['id'],
      carPhoto: json['car_photo'],
      washerName:
      json['employees'] != null
          ? json['employees']['name_employees']
          : 'Неизвестно',
      washPrice: washPrice,
      orderDate: json['order_date'],
      washType: json['type_of_car_wash'] != null
          ? json['type_of_car_wash']['name']
          : 'Неизвестно',
    );
  }

  String getFormattedOrderDate() {
    if (orderDate == null) return 'Неизвестно';
    final parsedDate = DateTime.parse(orderDate!);
    return DateFormat('dd.MM.yyyy').format(parsedDate);
  }
}