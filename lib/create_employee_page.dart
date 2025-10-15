import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;

class CreateEmployeePage extends StatefulWidget {
  @override
  _CreateEmployeePageState createState() => _CreateEmployeePageState();
}

class _CreateEmployeePageState extends State<CreateEmployeePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passportNumberController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  String? _gender;
  String? _position;
  List<Map<String, String>> _positions = [];
  Uint8List? _imageBytes;
  io.File? _imageFile;
  bool _isLoading = false;
  bool _isSubmitting = false;
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
    _fetchPositions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _passportNumberController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchPositions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse(
          'https://oltinwash.pythonanywhere.com/employees/api/positions/'));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(
            utf8.decode(response.bodyBytes));
        setState(() {
          _positions = responseData
              .map((data) =>
          {
            'id': data['id'].toString(),
            'name': data['name_positions'] as String,
          })
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load positions');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showNotification('Ошибка загрузки должностей', isError: true);
    }
  }

  Future<void> _createEmployee() async {
    if (_position == null) {
      _showNotification('Выберите должность', isError: true);
      return;
    }

    if (_gender == null) {
      _showNotification('Выберите пол', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final uri = Uri.parse(
        'https://oltinwash.pythonanywhere.com/employees/api/employees/add/');
    var request = http.MultipartRequest('POST', uri);

    request.fields['name_employees'] = _nameController.text;
    request.fields['position'] = _position!;
    request.fields['birth_date'] = _birthDateController.text;
    request.fields['phone_number'] = _phoneNumberController.text;
    request.fields['address'] = _addressController.text;
    request.fields['passport_number'] = _passportNumberController.text;
    request.fields['gender'] = _gender!;

    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('photo', _imageFile!.path),
      );
    } else if (_imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
            'photo', _imageBytes!, filename: 'upload.jpg'),
      );
    }

    try {
      final response = await request.send();

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 201) {
        _showNotification('Сотрудник создан!', isError: false);
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.of(context).pop(true);
      } else {
        _showNotification('Ошибка создания', isError: true);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showNotification('Ошибка сервера', isError: true);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await showModalBottomSheet<XFile>(
      context: context,
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Выбор фото',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 22),
                ),
                title: Text('Камера', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final XFile? photo = await picker.pickImage(
                      source: ImageSource.camera);
                  Navigator.pop(context, photo);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                      Icons.photo_library, color: Colors.white, size: 22),
                ),
                title: Text('Галерея', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final XFile? photo = await picker.pickImage(
                      source: ImageSource.gallery);
                  Navigator.pop(context, photo);
                },
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      } else {
        setState(() {
          _imageFile = io.File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
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
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd.MM.yyyy').format(picked);
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

  Widget _buildTextField(TextEditingController controller, String hintText,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextFormField(
          controller: controller,
          style: TextStyle(fontSize: 14, color: Colors.grey[900]),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          keyboardType: keyboardType,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Заполните поле';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String hintText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextFormField(
          controller: controller,
          style: TextStyle(fontSize: 14, color: Colors.grey[900]),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            suffixIcon: Icon(
                Icons.calendar_today, color: Colors.grey[600], size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          readOnly: true,
          onTap: () => _selectDate(context),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Выберите дату';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hintText, List<Map<String, String>> options,
      String? value, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(fontSize: 14, color: Colors.grey[900]),
          value: value,
          items: options.map((Map<String, String> item) {
            return DropdownMenuItem<String>(
              value: item['id'],
              child: Text(item['name']!, style: TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Выберите вариант';
            }
            return null;
          },
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
                    Text(
                      'Новый сотрудник',
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
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[400]!),
                  ),
                )
                    : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1.5,
                              ),
                            ),
                            child: _imageBytes != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                  _imageBytes!, fit: BoxFit.cover),
                            )
                                : _imageFile != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add, size: 40,
                                    color: Colors.white38),
                                SizedBox(height: 8),
                                Text(
                                  'Добавить фото',
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildTextField(_nameController, 'Имя сотрудника'),
                        _buildDropdownField(
                            'Должность', _positions, _position, (
                            String? newValue) {
                          setState(() {
                            _position = newValue;
                          });
                        }),
                        _buildDateField(_birthDateController, 'Дата рождения'),
                        _buildTextField(_phoneNumberController, 'Телефон',
                            keyboardType: TextInputType.phone),
                        _buildTextField(_addressController, 'Адрес'),
                        _buildTextField(
                            _passportNumberController, 'Номер паспорта'),
                        _buildDropdownField(
                          'Пол',
                          [
                            {'id': 'Мужской', 'name': 'Мужской'},
                            {'id': 'Женский', 'name': 'Женский'}
                          ],
                          _gender,
                              (String? newValue) {
                            setState(() {
                              _gender = newValue;
                            });
                          },
                        ),
                        SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                  Colors.grey[700]!,
                                  Colors.grey[800]!,
                                  Colors.grey[900]!
                                ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                              if (_formKey.currentState!.validate()) {
                                _createEmployee();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                                : Text(
                              'Создать сотрудника',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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