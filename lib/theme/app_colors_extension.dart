import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.mascotBadgeBg,
    required this.mascotBadgeIcon,
    required this.userText,
    required this.userAvatarBg,
    required this.typingIndicatorBubble,
    required this.errorBg,
    required this.errorText,
    required this.warningBg,
    required this.warningText,
    required this.downloadingBg,
    required this.downloadingText,
    required this.suggestionChipBg,
    required this.stopPillBg,
    required this.stopPillText,
    required this.feedbackIcon,
    required this.cardShadow,
    required this.disabledButton,
    required this.progressTrack,
    required this.divider,
    required this.textMuted,
    required this.textOnCard,
    required this.textOnCardSecondary,
    required this.inputFill,
    required this.surfaceCard,
    required this.primaryDim,
    required this.mascotBadgeBgLight,
    required this.mascotBadgeIconLight,
  });

  final Color mascotBadgeBg;
  final Color mascotBadgeIcon;
  final Color userText;
  final Color userAvatarBg;
  final Color typingIndicatorBubble;
  final Color errorBg;
  final Color errorText;
  final Color warningBg;
  final Color warningText;
  final Color downloadingBg;
  final Color downloadingText;
  final Color suggestionChipBg;
  final Color stopPillBg;
  final Color stopPillText;
  final Color feedbackIcon;
  final Color cardShadow;
  final Color disabledButton;
  final Color progressTrack;
  final Color divider;
  final Color textMuted;
  final Color textOnCard;
  final Color textOnCardSecondary;
  final Color inputFill;
  final Color surfaceCard;
  final Color primaryDim;
  final Color mascotBadgeBgLight;
  final Color mascotBadgeIconLight;

  @override
  AppColorsExtension copyWith({
    Color? mascotBadgeBg,
    Color? mascotBadgeIcon,
    Color? userText,
    Color? userAvatarBg,
    Color? typingIndicatorBubble,
    Color? errorBg,
    Color? errorText,
    Color? warningBg,
    Color? warningText,
    Color? downloadingBg,
    Color? downloadingText,
    Color? suggestionChipBg,
    Color? stopPillBg,
    Color? stopPillText,
    Color? feedbackIcon,
    Color? cardShadow,
    Color? disabledButton,
    Color? progressTrack,
    Color? divider,
    Color? textMuted,
    Color? textOnCard,
    Color? textOnCardSecondary,
    Color? inputFill,
    Color? surfaceCard,
    Color? primaryDim,
    Color? mascotBadgeBgLight,
    Color? mascotBadgeIconLight,
  }) {
    return AppColorsExtension(
      mascotBadgeBg: mascotBadgeBg ?? this.mascotBadgeBg,
      mascotBadgeIcon: mascotBadgeIcon ?? this.mascotBadgeIcon,
      userText: userText ?? this.userText,
      userAvatarBg: userAvatarBg ?? this.userAvatarBg,
      typingIndicatorBubble: typingIndicatorBubble ?? this.typingIndicatorBubble,
      errorBg: errorBg ?? this.errorBg,
      errorText: errorText ?? this.errorText,
      warningBg: warningBg ?? this.warningBg,
      warningText: warningText ?? this.warningText,
      downloadingBg: downloadingBg ?? this.downloadingBg,
      downloadingText: downloadingText ?? this.downloadingText,
      suggestionChipBg: suggestionChipBg ?? this.suggestionChipBg,
      stopPillBg: stopPillBg ?? this.stopPillBg,
      stopPillText: stopPillText ?? this.stopPillText,
      feedbackIcon: feedbackIcon ?? this.feedbackIcon,
      cardShadow: cardShadow ?? this.cardShadow,
      disabledButton: disabledButton ?? this.disabledButton,
      progressTrack: progressTrack ?? this.progressTrack,
      divider: divider ?? this.divider,
      textMuted: textMuted ?? this.textMuted,
      textOnCard: textOnCard ?? this.textOnCard,
      textOnCardSecondary: textOnCardSecondary ?? this.textOnCardSecondary,
      inputFill: inputFill ?? this.inputFill,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      primaryDim: primaryDim ?? this.primaryDim,
      mascotBadgeBgLight: mascotBadgeBgLight ?? this.mascotBadgeBgLight,
      mascotBadgeIconLight: mascotBadgeIconLight ?? this.mascotBadgeIconLight,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      mascotBadgeBg: Color.lerp(mascotBadgeBg, other.mascotBadgeBg, t)!,
      mascotBadgeIcon: Color.lerp(mascotBadgeIcon, other.mascotBadgeIcon, t)!,
      userText: Color.lerp(userText, other.userText, t)!,
      userAvatarBg: Color.lerp(userAvatarBg, other.userAvatarBg, t)!,
      typingIndicatorBubble: Color.lerp(typingIndicatorBubble, other.typingIndicatorBubble, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      downloadingBg: Color.lerp(downloadingBg, other.downloadingBg, t)!,
      downloadingText: Color.lerp(downloadingText, other.downloadingText, t)!,
      suggestionChipBg: Color.lerp(suggestionChipBg, other.suggestionChipBg, t)!,
      stopPillBg: Color.lerp(stopPillBg, other.stopPillBg, t)!,
      stopPillText: Color.lerp(stopPillText, other.stopPillText, t)!,
      feedbackIcon: Color.lerp(feedbackIcon, other.feedbackIcon, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      disabledButton: Color.lerp(disabledButton, other.disabledButton, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnCard: Color.lerp(textOnCard, other.textOnCard, t)!,
      textOnCardSecondary: Color.lerp(textOnCardSecondary, other.textOnCardSecondary, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      primaryDim: Color.lerp(primaryDim, other.primaryDim, t)!,
      mascotBadgeBgLight: Color.lerp(mascotBadgeBgLight, other.mascotBadgeBgLight, t)!,
      mascotBadgeIconLight: Color.lerp(mascotBadgeIconLight, other.mascotBadgeIconLight, t)!,
    );
  }
}

const AppColorsExtension lightAppColors = AppColorsExtension(
  mascotBadgeBg: Color(0xFF27AE60),
  mascotBadgeIcon: Color(0xFFFFFFFF),
  userText: Color(0xFF1A1A1A),
  userAvatarBg: Color(0xFF27AE60),
  typingIndicatorBubble: Color(0xFFE8F5E9),
  errorBg: Color(0xFFFDEDEC),
  errorText: Color(0xFFC62828),
  warningBg: Color(0xFFFFF8E1),
  warningText: Color(0xFFF57F17),
  downloadingBg: Color(0xFFE8F5E9),
  downloadingText: Color(0xFF27AE60),
  suggestionChipBg: Color(0xFFE8F5E9),
  stopPillBg: Color(0xFFE8F5E9),
  stopPillText: Color(0xFF2E7D32),
  feedbackIcon: Color(0xFF9E9E9E),
  cardShadow: Color(0x1A000000),
  disabledButton: Color(0xFFE0E0E0),
  progressTrack: Color(0xFFE0E0E0),
  divider: Color(0xFFE0E0E0),
  textMuted: Color(0xFF9E9E9E),
  textOnCard: Color(0xFF1A1A1A),
  textOnCardSecondary: Color(0xFF424242),
  inputFill: Color(0xFFF5F5F5),
  surfaceCard: Color(0xFFFFFFFF),
  primaryDim: Color(0xFFE8F5E9),
  mascotBadgeBgLight: Color(0xFF27AE60),
  mascotBadgeIconLight: Color(0xFFFFFFFF),
);

const AppColorsExtension darkAppColors = AppColorsExtension(
  mascotBadgeBg: Color(0xFF2ECC71),
  mascotBadgeIcon: Color(0xFF121212),
  userText: Color(0xFFC7C7CC),
  userAvatarBg: Color(0xFF2E7D32),
  typingIndicatorBubble: Color(0xFF1E2B1E),
  errorBg: Color(0xFF3A1F1F),
  errorText: Color(0xFFEF5350),
  warningBg: Color(0xFF332B1A),
  warningText: Color(0xFFFFA726),
  downloadingBg: Color(0xFF16261A),
  downloadingText: Color(0xFF2ECC71),
  suggestionChipBg: Color(0xFF16261A),
  stopPillBg: Color(0xFF1E3A26),
  stopPillText: Color(0xFF8FE0AC),
  feedbackIcon: Color(0xFF8A8A80),
  cardShadow: Color(0x1A000000),
  disabledButton: Color(0xFF3A3A3C),
  progressTrack: Color(0xFF2C2C2E),
  divider: Color(0xFF2C2C2E),
  textMuted: Color(0xFF6B6B6E),
  textOnCard: Color(0xFF1A1A1A),
  textOnCardSecondary: Color(0xFF2A2A28),
  inputFill: Color(0xFF1E1E20),
  surfaceCard: Color(0xFFF5F1E8),
  primaryDim: Color(0xFF16261A),
  mascotBadgeBgLight: Color(0xFF2ECC71),
  mascotBadgeIconLight: Color(0xFF121212),
);