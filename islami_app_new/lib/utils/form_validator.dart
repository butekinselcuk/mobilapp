import 'package:flutter/material.dart';

/// Form validation kuralları
class AppFormValidator {
  /// Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email adresi gereklidir';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir email adresi giriniz';
    }

    return null;
  }

  /// Şifre validation
  static String? password(String? value, {
    int minLength = 6,
    bool requireUppercase = false,
    bool requireLowercase = false,
    bool requireNumbers = false,
    bool requireSpecialChars = false,
  }) {
    if (value == null || value.isEmpty) {
      return 'Şifre gereklidir';
    }

    if (value.length < minLength) {
      return 'Şifre en az $minLength karakter olmalıdır';
    }

    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Şifre en az bir büyük harf içermelidir';
    }

    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Şifre en az bir küçük harf içermelidir';
    }

    if (requireNumbers && !value.contains(RegExp(r'[0-9]'))) {
      return 'Şifre en az bir rakam içermelidir';
    }

    if (requireSpecialChars && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Şifre en az bir özel karakter içermelidir';
    }

    return null;
  }

  /// Zorunlu alan validation
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName gereklidir' : 'Bu alan gereklidir';
    }
    return null;
  }

  /// Minimum uzunluk validation
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null ? '$fieldName gereklidir' : 'Bu alan gereklidir';
    }

    if (value.length < minLength) {
      return fieldName != null 
        ? '$fieldName en az $minLength karakter olmalıdır'
        : 'En az $minLength karakter olmalıdır';
    }

    return null;
  }

  /// Maksimum uzunluk validation
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      return fieldName != null 
        ? '$fieldName en fazla $maxLength karakter olmalıdır'
        : 'En fazla $maxLength karakter olmalıdır';
    }
    return null;
  }

  /// Telefon numarası validation
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası gereklidir';
    }

    // Türkiye telefon numarası formatı
    final phoneRegex = RegExp(r'^(\+90|0)?[5][0-9]{9}$');
    final cleanValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!phoneRegex.hasMatch(cleanValue)) {
      return 'Geçerli bir telefon numarası giriniz';
    }

    return null;
  }

  /// Sayı validation
  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null ? '$fieldName gereklidir' : 'Bu alan gereklidir';
    }

    if (double.tryParse(value) == null) {
      return fieldName != null ? '$fieldName geçerli bir sayı olmalıdır' : 'Geçerli bir sayı giriniz';
    }

    return null;
  }

  /// URL validation
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL gereklidir';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Geçerli bir URL giriniz';
    }

    return null;
  }

  /// Birden fazla validator'ı birleştir
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }
}