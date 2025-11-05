import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/shared/app_input.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/dimensions.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String token) onLoginSuccess;
  const LoginScreen({required this.onLoginSuccess, Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final url = Uri.parse('$apiUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
      }),
    );
    setState(() {
      _loading = false;
    });
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['access_token'];
      final userId = data['user_id'];
      final prefs = await SharedPreferences.getInstance();
      final storage = FlutterSecureStorage();
      await prefs.setString('jwt_token', token);
      await prefs.setString('flutter_jwt_token', token);
      await storage.write(key: 'jwt_token', value: token);
      await storage.write(key: 'flutter_jwt_token', value: token);
      await prefs.setInt('user_id', userId);
      
      // Başarılı giriş uyarısı göster ve yönlendir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş başarılı! Hoş geldiniz.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Callback'i çağır ve kısa bir gecikme sonrası yönlendir
        widget.onLoginSuccess(token);
        
        // Ana sayfaya yönlendirme için kısa gecikme
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            // Force rebuild için callback'i tekrar çağır
            widget.onLoginSuccess(token);
          }
        });
      } else {
        widget.onLoginSuccess(token);
      }
    } else {
      setState(() {
        _error = 'Giriş başarısız: ${response.body}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Giriş Yap',
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppDimensions.paddingLgStatic),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppDimensions.paddingXlStatic),
                
                // Logo veya İkon
                Container(
                  alignment: Alignment.center,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.mosque,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                
                SizedBox(height: AppDimensions.paddingLgStatic),
                
                Text(
                  'Hoş Geldiniz',
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: AppDimensions.paddingSmStatic),
                
                Text(
                  'Hesabınıza giriş yapın',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: AppDimensions.paddingXlStatic),
                
                AppCard(
                  child: Column(
                    children: [
                      AppInput(
                        controller: _usernameController,
                        label: 'Kullanıcı Adı',
                        prefixIcon: Icons.person,
                        validator: (v) => v == null || v.isEmpty ? 'Kullanıcı adı girin' : null,
                      ),
                      
                      SizedBox(height: AppDimensions.paddingMdStatic),
                      
                      AppInput(
                        controller: _passwordController,
                        label: 'Şifre',
                        prefixIcon: Icons.lock,
                        obscureText: true,
                        validator: (v) => v == null || v.isEmpty ? 'Şifre girin' : null,
                      ),
                      
                      if (_error != null) ...[
                        SizedBox(height: AppDimensions.paddingMdStatic),
                        Container(
                          padding: EdgeInsets.all(AppDimensions.paddingMdStatic),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                          ),
                          child: Text(
                            _error!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                      
                      SizedBox(height: AppDimensions.paddingLgStatic),
                      
                      AppButton(
                        text: 'Giriş Yap',
                        onPressed: _loading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _login();
                                }
                              },
                        isLoading: _loading,
                        backgroundColor: AppColors.primary,
                        icon: Icons.login,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}