import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'washed_cars_page.dart';

class DetailWashedCarsPage extends StatefulWidget {
  final WashedCar car;

  const DetailWashedCarsPage({Key? key, required this.car}) : super(key: key);

  @override
  _DetailWashedCarsPageState createState() => _DetailWashedCarsPageState();
}

class _DetailWashedCarsPageState extends State<DetailWashedCarsPage>
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showImageDialog() {
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
                    child: widget.car.carPhoto != null &&
                        widget.car.carPhoto!.isNotEmpty
                        ? Image.network(
                      widget.car.carPhoto!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: EdgeInsets.all(40),
                          color: Colors.grey[850],
                          child: Icon(Icons.error_outline, color: Colors.white,
                              size: 50),
                        );
                      },
                    )
                        : Container(
                      padding: EdgeInsets.all(40),
                      color: Colors.grey[850],
                      child: Icon(
                          Icons.car_repair, color: Colors.white, size: 50),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white60, size: 18),
          SizedBox(width: 12),
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
    final formatter = NumberFormat("#,###", "ru_RU");

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
                      'Детали мойки',
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: [
                      GestureDetector(
                        onTap: _showImageDialog,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: widget.car.carPhoto != null &&
                                widget.car.carPhoto!.isNotEmpty
                                ? Image.network(
                              widget.car.carPhoto!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 240,
                                  color: Colors.grey[700],
                                  child: Center(
                                    child: Icon(
                                        Icons.car_repair, color: Colors.white,
                                        size: 60),
                                  ),
                                );
                              },
                            )
                                : Container(
                              height: 240,
                              color: Colors.grey[700],
                              child: Center(
                                child: Icon(
                                    Icons.car_repair, color: Colors.white,
                                    size: 60),
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
                            _buildInfoRow(
                              Icons.person_rounded,
                              'Мойщик',
                              widget.car.washerName,
                            ),
                            _buildInfoRow(
                              Icons.local_car_wash_rounded,
                              'Тип мойки',
                              widget.car.washType,
                            ),
                            _buildInfoRow(
                              Icons.payments_rounded,
                              'Цена',
                              '${formatter.format(widget.car.washPrice)} сум',
                            ),
                            _buildInfoRow(
                              Icons.calendar_today_rounded,
                              'Дата',
                              widget.car.orderDate != null
                                  ? DateFormat('dd.MM.yyyy').format(
                                  DateTime.parse(widget.car.orderDate!))
                                  : 'Неизвестно',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Нажмите на фото для увеличения',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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