import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF2ECC71);
  static const Color primaryDim = Color(0xFF16261A);

  // Background & Surface
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceCard = Color(0xFFF5F1E8); // Warm cream for AI response cards
  static const Color inputFill = Color(0xFF1E1E20);

  // Text
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF8A8A8E);
  static const Color textMuted = Color(0xFF6B6B6E);
  static const Color textOnCard = Color(0xFF1A1A1A);
  static const Color textOnCardSecondary = Color(0xFF2A2A28);
  static const Color userText = Color(0xFFC7C7CC);

  // Mascot badge
  static const Color mascotBadgeBg = Color(0xFF2ECC71);
  static const Color mascotBadgeIcon = Color(0xFF121212);

  // Chat bubbles (legacy - kept for compatibility)
  static const Color userBubble = Color(0xFF1B5E20);
  static const Color userAvatarBg = Color(0xFF2E7D32);
  static const Color typingIndicatorBubble = Color(0xFF1E2B1E);

  // Status banners
  static const Color errorBg = Color(0xFF3A1F1F);
  static const Color errorText = Color(0xFFEF5350);
  static const Color warningBg = Color(0xFF332B1A);
  static const Color warningText = Color(0xFFFFA726);
  static const Color downloadingBg = Color(0xFF16261A);
  static const Color downloadingText = Color(0xFF2ECC71);

  // Suggestion chips
  static const Color suggestionChipBg = Color(0xFF16261A);

  // Stop generating pill
  static const Color stopPillBg = Color(0xFF1E3A26);
  static const Color stopPillText = Color(0xFF8FE0AC);

  // Feedback icons
  static const Color feedbackIcon = Color(0xFF8A8A80);

  // Card shadow
  static const Color cardShadow = Color(0x1A000000);

  // Misc
  static const Color disabledButton = Color(0xFF3A3A3C);
  static const Color progressTrack = Color(0xFF2C2C2E);
  static const Color divider = Color(0xFF2C2C2E);
}