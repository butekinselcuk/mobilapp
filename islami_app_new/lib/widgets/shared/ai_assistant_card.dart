import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/typography.dart';
import '../animations/fade_in_animation.dart';
import '../animations/slide_animation.dart';
import 'app_input.dart';
import 'app_button.dart';

/// Modern AI asistanı kartı
class AIAssistantCard extends StatelessWidget {
  /// Input controller
  final TextEditingController controller;
  
  /// Loading durumu
  final bool isLoading;
  
  /// Hata mesajı
  final String? errorMessage;
  
  /// AI cevabı
  final String? answer;
  
  /// Soru gönderme callback'i
  final VoidCallback? onSendMessage;
  
  /// Örnek soru tıklama callback'i
  final Function(String)? onExampleTap;
  
  /// Örnek sorular
  final List<String> exampleQuestions;

  const AIAssistantCard({
    Key? key,
    required this.controller,
    this.isLoading = false,
    this.errorMessage,
    this.answer,
    this.onSendMessage,
    this.onExampleTap,
    this.exampleQuestions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.marginMd(context)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.aiCardRadius(context)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2D2D2D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.aiCardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            FadeInAnimation(
              delay: const Duration(milliseconds: 100),
              child: _buildHeader(context),
            ),
            
            SizedBox(height: AppDimensions.paddingMd(context)),
            
            // Input alanı
            SlideAnimation(
              delay: const Duration(milliseconds: 200),
              direction: SlideDirection.leftToRight,
              distance: 0.3,
              child: _buildInputSection(context),
            ),
            
            SizedBox(height: AppDimensions.paddingMd(context)),
            
            // Cevap alanı
            if (answer != null || errorMessage != null || isLoading)
              FadeInAnimation(
                delay: const Duration(milliseconds: 300),
                child: _buildResponseSection(context),
              ),
            
            // Örnek sorular
            if (exampleQuestions.isNotEmpty && answer == null && !isLoading)
              SlideAnimation(
                delay: const Duration(milliseconds: 400),
                direction: SlideDirection.bottomToTop,
                distance: 0.2,
                child: _buildExampleQuestions(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppDimensions.paddingSm(context)),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          ),
          child: Icon(
            Icons.psychology,
            color: AppColors.secondary,
            size: 20,
          ),
        ),
        SizedBox(width: AppDimensions.paddingSm(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Asistanı',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Dini sorularınızı sorun',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSm(context),
            vertical: AppDimensions.paddingXs(context),
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: AppDimensions.paddingXs(context)),
              Text(
                'Aktif',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd(context)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppInput(
              controller: controller,
              hint: 'Neye ihtiyacın var?',
              type: AppInputType.filled,
              size: AppInputSize.medium,
              onSubmitted: (_) => onSendMessage?.call(),
              semanticLabel: 'AI asistanına soru yazın',
              borderRadius: AppDimensions.radiusMd(context),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMd(context),
                vertical: AppDimensions.paddingSm(context),
              ),
            ),
          ),
          SizedBox(width: AppDimensions.paddingSm(context)),
          AppButton(
            text: '',
            icon: Icons.send,
            onPressed: isLoading ? null : onSendMessage,
            loading: isLoading,
            semanticLabel: 'AI asistanına soru gönder',
            type: AppButtonType.primary,
            size: AppButtonSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildResponseSection(BuildContext context) {
    if (isLoading) {
      return _buildLoadingResponse(context);
    }
    
    if (errorMessage != null) {
      return _buildErrorResponse(context);
    }
    
    if (answer != null) {
      return _buildAnswerResponse(context);
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildLoadingResponse(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMd(context)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd(context)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              color: AppColors.secondary,
              size: 18,
            ),
          ),
          SizedBox(width: AppDimensions.paddingSm(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                      ),
                    ),
                    SizedBox(width: AppDimensions.paddingSm(context)),
                    Text(
                      'Düşünüyor...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.paddingXs(context)),
                Text(
                  'Güvenilir kaynaklardan cevap hazırlanıyor',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorResponse(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMd(context)),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd(context)),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          SizedBox(width: AppDimensions.paddingSm(context)),
          Expanded(
            child: Text(
              errorMessage!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerResponse(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMd(context)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd(context)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
              SizedBox(width: AppDimensions.paddingSm(context)),
              Expanded(
                child: Text(
                  'AI Asistanı',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.share,
                  color: Colors.white54,
                  size: 18,
                ),
                onPressed: () {
                  // Paylaşma işlevi
                },
                tooltip: 'Cevabı paylaş',
              ),
            ],
          ),
          SizedBox(height: AppDimensions.paddingSm(context)),
          Text(
            answer!,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleQuestions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Örnek sorular:',
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppDimensions.paddingSm(context)),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: exampleQuestions.length,
            separatorBuilder: (context, index) => 
              SizedBox(width: AppDimensions.paddingSm(context)),
            itemBuilder: (context, index) {
              final question = exampleQuestions[index];
              return _buildExampleChip(question, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExampleChip(String question, BuildContext context) {
    return GestureDetector(
      onTap: () => onExampleTap?.call(question),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd(context),
          vertical: AppDimensions.paddingSm(context),
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg(context)),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: AppColors.primary,
              size: 16,
            ),
            SizedBox(width: AppDimensions.paddingXs(context)),
            Text(
              question,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI asistanı kartı için skeleton loader
class AIAssistantCardSkeleton extends StatelessWidget {
  const AIAssistantCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.marginMd(context)),
      padding: EdgeInsets.all(AppDimensions.aiCardPadding(context)),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(AppDimensions.aiCardRadius(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              SizedBox(width: AppDimensions.paddingSm(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppDimensions.paddingMd(context)),
          
          // Input skeleton
          Container(
            height: AppDimensions.aiInputHeight(context),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd(context)),
            ),
          ),
          
          SizedBox(height: AppDimensions.paddingMd(context)),
          
          // Example questions skeleton
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: AppDimensions.paddingSm(context)),
              Row(
                children: List.generate(3, (index) => 
                  Container(
                    margin: EdgeInsets.only(
                      right: index < 2 ? AppDimensions.paddingSm(context) : 0,
                    ),
                    width: 80 + (index * 20).toDouble(),
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg(context)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}