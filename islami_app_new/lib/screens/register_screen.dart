import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/shared/app_input.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/dimensions.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;
  const RegisterScreen({required this.onRegisterSuccess, Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  String? _success;
  bool _loading = false;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final url = Uri.parse('$apiUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      }),
    );
    setState(() {
      _loading = false;
    });
    if (response.statusCode == 200) {
      setState(() {
        _success = 'Kayıt başarılı! Giriş yapabilirsiniz.';
      });
      widget.onRegisterSuccess();
    } else {
      setState(() {
        _error = 'Kayıt başarısız: ${response.body}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kayıt Ol',
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
                      Icons.person_add,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                
                SizedBox(height: AppDimensions.paddingLgStatic),
                
                Text(
                  'Hesap Oluştur',
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: AppDimensions.paddingSmStatic),
                
                Text(
                  'Yeni hesabınızı oluşturun',
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
                        controller: _emailController,
                        label: 'E-posta',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.isEmpty ? 'E-posta girin' : null,
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
                      
                      if (_success != null) ...[
                        SizedBox(height: AppDimensions.paddingMdStatic),
                        Container(
                          padding: EdgeInsets.all(AppDimensions.paddingMdStatic),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                          ),
                          child: Text(
                            _success!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                      
                      SizedBox(height: AppDimensions.paddingLgStatic),
                      
                      AppButton(
                        text: 'Kayıt Ol',
                        onPressed: _loading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _register();
                                }
                              },
                        isLoading: _loading,
                        backgroundColor: AppColors.primary,
                        icon: Icons.person_add,
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