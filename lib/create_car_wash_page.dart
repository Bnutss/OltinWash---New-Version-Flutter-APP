import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:dropdown_search/dropdown_search.dart';

class CreateCarWashPage extends StatefulWidget {
  const CreateCarWashPage({Key? key}) : super(key: key);

  @override
  _CreateCarWashPageState createState() => _CreateCarWashPageState();
}

class _CreateCarWashPageState extends State<CreateCarWashPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  io.File? _imageFile;
  int? _serviceClassId;
  double? _negotiatedPrice;
  int? _employeeId;
  List<dynamic> _serviceClasses = [];
  List<dynamic> _employees = [];
  final TextEditingController _negotiatedPriceController = TextEditingController();
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
    _fetchData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _negotiatedPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([
      _fetchServiceClasses(),
      _fetchEmployees(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchServiceClasses() async {
    try {
      final response = await http.get(
          Uri.parse(
              'https://oltinwash.pythonanywhere.com/api/service_classes/'));
      if (response.statusCode == 200) {
        setState(() {
          _serviceClasses = json.decode(utf8.decode(response.bodyBytes));
          _serviceClasses.sort((a, b) => a['name'].compareTo(b['name']));
        });
      }
    } catch (e) {
      _showNotification('Ошибка загрузки услуг', isError: true);
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      final response = await http.get(Uri.parse(
          'https://oltinwash.pythonanywhere.com/employees/api/washer_employees/'));
      if (response.statusCode == 200) {
        setState(() {
          _employees = json.decode(utf8.decode(response.bodyBytes));
          _employees.sort((a, b) =>
              a['name_employees'].compareTo(b['name_employees']));
        });
      }
    } catch (e) {
      _showNotification('Ошибка загрузки сотрудников', isError: true);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb) {
      final html.FileUploadInputElement uploadInput = html
          .FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files!.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsDataUrl(files[0]);
          reader.onLoadEnd.listen((e) {
            setState(() {
              _imageBytes = Base64Decoder().convert(
                  reader.result
                      .toString()
                      .split(',')
                      .last);
            });
          });
        }
      });
    } else {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = io.File(pickedFile.path);
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_serviceClassId != null && _employeeId != null) {
        if (_imageBytes == null && _imageFile == null) {
          _showNotification('Добавьте фото автомобиля', isError: true);
          return;
        }
        _sendDataToServer();
      } else {
        _showNotification('Заполните все поля', isError: true);
      }
    }
  }

  Future<void> _sendDataToServer() async {
    setState(() {
      _isSubmitting = true;
    });

    final uri = Uri.parse(
        'https://oltinwash.pythonanywhere.com/api/add_order/');
    final request = http.MultipartRequest('POST', uri);

    String username = 'your_username';
    String password = 'your_password';
    String basicAuth = 'Basic ' +
        base64Encode(utf8.encode('$username:$password'));
    request.headers['Authorization'] = basicAuth;

    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('car_photo', _imageFile!.path),
      );
    } else if (_imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
            'car_photo', _imageBytes!, filename: 'upload.jpg'),
      );
    }

    request.fields['type_of_car_wash'] = _serviceClassId.toString();
    request.fields['employees'] = _employeeId.toString();
    if (_negotiatedPrice != null) {
      request.fields['negotiated_price'] = _negotiatedPrice.toString();
    }

    try {
      final response = await request.send();

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 201) {
        _showNotification('Мойка успешно добавлена!', isError: false);
        await Future.delayed(Duration(milliseconds: 500));
        _clearFormFields();
      } else {
        _showNotification('Ошибка добавления мойки', isError: true);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showNotification('Ошибка сервера', isError: true);
    }
  }

  void _clearFormFields() {
    setState(() {
      _imageBytes = null;
      _imageFile = null;
      _serviceClassId = null;
      _negotiatedPrice = null;
      _employeeId = null;
      _negotiatedPriceController.clear();
    });
    _formKey.currentState?.reset();
  }

  String _formatPrice(String price) {
    if (price.isEmpty) return '';
    final buffer = StringBuffer();
    final characters = price.replaceAll(RegExp(r'\D'), '').split('');
    for (int i = 0; i < characters.length; i++) {
      if (i > 0 && (characters.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(characters[i]);
    }
    return buffer.toString();
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
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
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
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
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
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
                      'Создать мойку',
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
                          onTap: _showImageSourceDialog,
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1.5,
                              ),
                            ),
                            child: _imageBytes != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                  _imageBytes!, fit: BoxFit.cover),
                            )
                                : _imageFile != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40,
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
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownSearch<String>(
                            items: _serviceClasses.map((e) =>
                                e['service_name'].toString()).toList(),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              menuProps: MenuProps(
                                backgroundColor: Colors.grey[850],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              itemBuilder: (context, item, isSelected) {
                                return Container(
                                  padding: EdgeInsets.all(14),
                                  color: isSelected ? Colors.grey[700] : Colors
                                      .transparent,
                                  child: Text(item, style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                                );
                              },
                            ),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                hintText: "Тип мойки",
                                hintStyle: TextStyle(
                                    color: Colors.grey[400], fontSize: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              baseStyle: TextStyle(fontSize: 14,
                                  color: Colors.grey[900],
                                  fontWeight: FontWeight.w500),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _serviceClassId = _serviceClasses.firstWhere((
                                    e) => e['service_name'] == value)['id'];
                              });
                            },
                            selectedItem: _serviceClassId != null
                                ? _serviceClasses.firstWhere((e) =>
                            e['id'] == _serviceClassId)['service_name']
                                : null,
                            validator: (value) =>
                            value == null
                                ? 'Выберите тип'
                                : null,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextFormField(
                            controller: _negotiatedPriceController,
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[900]),
                            decoration: InputDecoration(
                              hintText: 'Стоимость',
                              hintStyle: TextStyle(
                                  color: Colors.grey[400], fontSize: 14),
                              suffixText: 'сум',
                              suffixStyle: TextStyle(
                                  color: Colors.grey[600], fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Введите стоимость';
                              if (double.tryParse(value.replaceAll(' ', '')) ==
                                  null) return 'Некорректная сумма';
                              return null;
                            },
                            onChanged: (value) {
                              final formatted = _formatPrice(value);
                              _negotiatedPriceController.value =
                                  _negotiatedPriceController.value.copyWith(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                        offset: formatted.length),
                                  );
                            },
                            onSaved: (value) {
                              if (value!.isNotEmpty) {
                                _negotiatedPrice =
                                    double.parse(value.replaceAll(' ', ''));
                              }
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownSearch<String>(
                            items: _employees.map((e) =>
                                e['name_employees'].toString()).toList(),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              menuProps: MenuProps(
                                backgroundColor: Colors.grey[850],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              itemBuilder: (context, item, isSelected) {
                                return Container(
                                  padding: EdgeInsets.all(14),
                                  color: isSelected ? Colors.grey[700] : Colors
                                      .transparent,
                                  child: Text(item, style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                                );
                              },
                            ),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                hintText: "Автомойщик",
                                hintStyle: TextStyle(
                                    color: Colors.grey[400], fontSize: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              baseStyle: TextStyle(fontSize: 14,
                                  color: Colors.grey[900],
                                  fontWeight: FontWeight.w500),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _employeeId = _employees.firstWhere((
                                    e) => e['name_employees'] == value)['id'];
                              });
                            },
                            selectedItem: _employeeId != null
                                ? _employees.firstWhere((e) =>
                            e['id'] == _employeeId)['name_employees']
                                : null,
                            validator: (value) =>
                            value == null
                                ? 'Выберите сотрудника'
                                : null,
                          ),
                        ),
                        SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.grey[700]!,
                              Colors.grey[800]!,
                              Colors.grey[900]!
                            ]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
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
                              'Создать мойку',
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