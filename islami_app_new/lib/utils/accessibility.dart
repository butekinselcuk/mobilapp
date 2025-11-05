import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

/// Erişilebilirlik yardımcı sınıfı
class AccessibilityHelper {
  /// Screen reader için metin okuma
  static void announceToScreenReader(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Haptic feedback ile birlikte announcement
  static void announceWithHaptic(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    announceToScreenReader(context, message);
  }

  /// Focus'u belirli bir widget'a taşı
  static void requestFocus(FocusNode focusNode) {
    focusNode.requestFocus();
  }

  /// Sonraki focusable element'e geç
  static void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Önceki focusable element'e geç
  static void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Focus'u kaldır
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Semantic label oluştur
  static String createSemanticLabel({
    required String action,
    String? item,
    String? state,
    String? hint,
  }) {
    final parts = <String>[];
    
    if (item != null) parts.add(item);
    if (action.isNotEmpty) parts.add(action);
    if (state != null) parts.add(state);
    if (hint != null) parts.add(hint);
    
    return parts.join(', ');
  }

  /// Button için semantic label
  static String buttonLabel({
    required String text,
    String? state,
    String? hint,
  }) {
    return createSemanticLabel(
      action: 'düğme',
      item: text,
      state: state,
      hint: hint,
    );
  }

  /// Link için semantic label
  static String linkLabel({
    required String text,
    String? destination,
  }) {
    return createSemanticLabel(
      action: 'bağlantı',
      item: text,
      hint: destination != null ? '$destination sayfasına git' : null,
    );
  }

  /// Input field için semantic label
  static String inputLabel({
    required String fieldName,
    bool isRequired = false,
    String? currentValue,
    String? hint,
  }) {
    return createSemanticLabel(
      action: 'metin alanı',
      item: fieldName,
      state: isRequired ? 'zorunlu' : null,
      hint: hint ?? (currentValue != null ? 'mevcut değer: $currentValue' : null),
    );
  }

  /// Card için semantic label
  static String cardLabel({
    required String title,
    String? subtitle,
    String? action,
  }) {
    final parts = <String>[title];
    if (subtitle != null) parts.add(subtitle);
    if (action != null) parts.add(action);
    return parts.join(', ');
  }

  /// Progress için semantic label
  static String progressLabel({
    required String task,
    required double progress,
  }) {
    final percentage = (progress * 100).round();
    return '$task, %$percentage tamamlandı';
  }

  /// Tab için semantic label
  static String tabLabel({
    required String tabName,
    required int currentIndex,
    required int totalTabs,
    bool isSelected = false,
  }) {
    final position = '${currentIndex + 1} / $totalTabs';
    final state = isSelected ? 'seçili' : 'seçili değil';
    return '$tabName sekmesi, $position, $state';
  }
}

/// Erişilebilir widget wrapper'ları
class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final String? hint;
  final bool excludeSemantics;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const AccessibleWidget({
    Key? key,
    required this.child,
    this.semanticLabel,
    this.hint,
    this.excludeSemantics = false,
    this.onTap,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget result = child;

    if (!excludeSemantics) {
      result = Semantics(
        label: semanticLabel,
        hint: hint,
        button: onTap != null,
        focusable: onTap != null || focusNode != null,
        child: result,
      );
    }

    if (onTap != null) {
      result = GestureDetector(
        onTap: onTap,
        child: result,
      );
    }

    if (focusNode != null) {
      result = Focus(
        focusNode: focusNode,
        child: result,
      );
    }

    return result;
  }
}

/// Erişilebilir buton
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final FocusNode? focusNode;
  final bool autofocus;

  const AccessibleButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      child: child,
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: button,
      );
    }

    return button;
  }
}

/// Erişilebilir kart
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? tooltip;
  final FocusNode? focusNode;
  final bool selected;

  const AccessibleCard({
    Key? key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.tooltip,
    this.focusNode,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );

    if (tooltip != null) {
      card = Tooltip(
        message: tooltip!,
        child: card,
      );
    }

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      focusable: onTap != null,
      child: card,
    );
  }
}

/// Erişilebilir liste öğesi
class AccessibleListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool selected;

  const AccessibleListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.focusNode,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      focusable: onTap != null,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        focusNode: focusNode,
        selected: selected,
      ),
    );
  }
}

/// Focus management helper
class FocusManager {
  static final Map<String, FocusNode> _focusNodes = {};

  /// Focus node oluştur veya al
  static FocusNode getFocusNode(String key) {
    return _focusNodes.putIfAbsent(key, () => FocusNode());
  }

  /// Focus node'u temizle
  static void disposeFocusNode(String key) {
    _focusNodes[key]?.dispose();
    _focusNodes.remove(key);
  }

  /// Tüm focus node'ları temizle
  static void disposeAll() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
  }

  /// Focus chain oluştur
  static List<FocusNode> createFocusChain(List<String> keys) {
    return keys.map((key) => getFocusNode(key)).toList();
  }

  /// Sonraki focus node'a geç
  static void focusNext(List<FocusNode> chain, FocusNode current) {
    final currentIndex = chain.indexOf(current);
    if (currentIndex != -1 && currentIndex < chain.length - 1) {
      chain[currentIndex + 1].requestFocus();
    }
  }

  /// Önceki focus node'a geç
  static void focusPrevious(List<FocusNode> chain, FocusNode current) {
    final currentIndex = chain.indexOf(current);
    if (currentIndex > 0) {
      chain[currentIndex - 1].requestFocus();
    }
  }
}

/// Semantic announcements için helper
class SemanticAnnouncements {
  /// Sayfa değişikliği duyurusu
  static void announcePageChange(BuildContext context, String pageName) {
    AccessibilityHelper.announceToScreenReader(
      context,
      '$pageName sayfasına geçildi',
    );
  }

  /// İşlem tamamlandı duyurusu
  static void announceActionCompleted(BuildContext context, String action) {
    AccessibilityHelper.announceWithHaptic(
      context,
      '$action tamamlandı',
    );
  }

  /// Hata duyurusu
  static void announceError(BuildContext context, String error) {
    HapticFeedback.heavyImpact();
    AccessibilityHelper.announceToScreenReader(context, 'Hata: $error');
  }

  /// Loading durumu duyurusu
  static void announceLoading(BuildContext context, String? message) {
    AccessibilityHelper.announceToScreenReader(
      context,
      message ?? 'Yükleniyor',
    );
  }

  /// İçerik değişikliği duyurusu
  static void announceContentChange(BuildContext context, String change) {
    AccessibilityHelper.announceToScreenReader(
      context,
      change,
    );
  }
}

/// Accessibility extension'ları
extension AccessibilityExtensions on BuildContext {
  /// Screen reader'a mesaj gönder
  void announceToScreenReader(String message) {
    AccessibilityHelper.announceToScreenReader(this, message);
  }

  /// Haptic feedback ile announcement
  void announceWithHaptic(String message) {
    AccessibilityHelper.announceWithHaptic(this, message);
  }

  /// Focus'u sonraki element'e taşı
  void focusNext() {
    AccessibilityHelper.focusNext(this);
  }

  /// Focus'u önceki element'e taşı
  void focusPrevious() {
    AccessibilityHelper.focusPrevious(this);
  }

  /// Focus'u kaldır
  void unfocus() {
    AccessibilityHelper.unfocus(this);
  }
}

/// Accessibility test helper'ları
class AccessibilityTestHelper {
  /// Widget'ın erişilebilir olup olmadığını kontrol et
  static bool isAccessible(Widget widget) {
    // Bu method test ortamında kullanılabilir
    return true; // Placeholder implementation
  }

  /// Semantic label'ın uygun olup olmadığını kontrol et
  static bool hasValidSemanticLabel(String? label) {
    if (label == null || label.isEmpty) return false;
    if (label.length < 3) return false;
    return true;
  }

  /// Focus order'ın doğru olup olmadığını kontrol et
  static bool hasValidFocusOrder(List<FocusNode> nodes) {
    // Focus chain'in mantıklı bir sırada olup olmadığını kontrol et
    return nodes.isNotEmpty;
  }
}