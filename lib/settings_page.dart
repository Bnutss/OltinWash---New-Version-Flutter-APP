import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  bool _isUpdating = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C2C2C),
              Color(0xFF3D3D3D),
              Color(0xFF4A4A4A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Настройки',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Управление параметрами приложения',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ListView(
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(20, 10, 20, 100),
                          children: [
                            _buildSettingsSection(
                              context,
                              'Общие настройки',
                              Icons.tune_rounded,
                              [
                                _buildSettingsItem(
                                  context,
                                  icon: Icons.language_rounded,
                                  title: 'Язык интерфейса',
                                  subtitle: 'Русский',
                                  onTap: () => _showLanguageDialog(),
                                ),
                                _buildDivider(),
                                _buildSwitchItem(
                                  context,
                                  icon: Icons.notifications_active_rounded,
                                  title: 'Push-уведомления',
                                  subtitle: 'Получать уведомления о событиях',
                                  value: _notificationsEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _notificationsEnabled = value;
                                    });
                                    _showNotification('Уведомления ${value
                                        ? 'включены'
                                        : 'выключены'}');
                                  },
                                ),
                                _buildDivider(),
                                _buildSwitchItem(
                                  context,
                                  icon: Icons.dark_mode_rounded,
                                  title: 'Темная тема',
                                  subtitle: 'Использовать темное оформление',
                                  value: _darkModeEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _darkModeEnabled = value;
                                    });
                                    _showNotification('Темная тема ${value
                                        ? 'включена'
                                        : 'выключена'}');
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            _buildSettingsSection(
                              context,
                              'Учетная запись',
                              Icons.person_rounded,
                              [
                                _buildSettingsItem(
                                  context,
                                  icon: Icons.account_circle_rounded,
                                  title: 'Профиль пользователя',
                                  subtitle: 'Редактирование данных профиля',
                                  onTap: () =>
                                      _showNotification('Раздел в разработке'),
                                ),
                                _buildDivider(),
                                _buildSettingsItem(
                                  context,
                                  icon: Icons.lock_rounded,
                                  title: 'Конфиденциальность',
                                  subtitle: 'Настройки безопасности данных',
                                  onTap: () =>
                                      _showNotification('Раздел в разработке'),
                                ),
                                _buildDivider(),
                                _buildSettingsItem(
                                  context,
                                  icon: Icons.fingerprint_rounded,
                                  title: 'Биометрия',
                                  subtitle: 'Face ID и отпечаток пальца',
                                  onTap: () =>
                                      _showNotification('Раздел в разработке'),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            _buildSettingsSection(
                              context,
                              'О приложении',
                              Icons.info_rounded,
                              [
                                _buildSettingsItem(
                                  context,
                                  icon: Icons.policy_rounded,
                                  title: 'Политика конфиденциальности',
                                  subtitle: 'Условия использования данных',
                                  onTap: () =>
                                      _showNotification('Раздел в разработке'),
                                ),
                                _buildDivider(),
                                _buildSettingsItem(
                                  context,
                                  icon: Icons.description_rounded,
                                  title: 'Пользовательское соглашение',
                                  subtitle: 'Условия использования приложения',
                                  onTap: () =>
                                      _showNotification('Раздел в разработке'),
                                ),
                                _buildDivider(),
                                _buildSettingsItem(
                                  context,
                                  icon: Icons.star_rounded,
                                  title: 'Версия приложения',
                                  subtitle: '1.0.8 - Актуальная версия',
                                  showArrow: false,
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
                            _buildUpdateButton(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isUpdating)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 30,
                                offset: Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  strokeWidth: 5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey[400]!),
                                ),
                              ),
                              SizedBox(height: 30),
                              Text(
                                'Проверка обновлений',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Пожалуйста, подождите...',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
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

  Widget _buildSettingsSection(BuildContext context,
      String title,
      IconData headerIcon,
      List<Widget> items,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  headerIcon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.4),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.grey[300],
              activeTrackColor: Colors.grey[600],
              inactiveThumbColor: Colors.grey[600],
              inactiveTrackColor: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildUpdateButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[700]!,
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isUpdating ? null : _update,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.system_update_rounded,
              color: Colors.white,
              size: 26,
            ),
            SizedBox(width: 12),
            Text(
              'Проверить обновления',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _update() async {
    setState(() {
      _isUpdating = true;
    });

    await Future.delayed(Duration(seconds: 3));

    setState(() {
      _isUpdating = false;
    });

    _showUpdateNotification();
  }

  void _showUpdateNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Обновление проверено',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'У вас установлена последняя версия',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[850],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.grey[850],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.grey[850],
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Выбор языка',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('Русский', true),
              _buildLanguageOption('English', false),
              _buildLanguageOption('O\'zbekcha', false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String language, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.grey[700]
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? Colors.grey[500]!
              : Colors.white.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: ListTile(
        title: Text(
          language,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: Colors.white)
            : null,
        onTap: () {
          Navigator.of(context).pop();
          _showNotification('Язык изменен на $language');
        },
      ),
    );
  }
}