import 'package:flutter/material.dart';
import 'app_colors.dart';

extension ChatColorScheme on ColorScheme {
  Color get sentMessageBubble =>
      brightness == Brightness.light
          ? AppColors.lightSentBubble
          : AppColors.darkSentBubble;

  Color get receivedMessageBubble =>
      brightness == Brightness.light
          ? AppColors.lightReceivedBubble
          : AppColors.darkReceivedBubble;

  Color get sentMessageText =>
      brightness == Brightness.light
          ? AppColors.lightSentBubbleText
          : AppColors.darkSentBubbleText;

  Color get receivedMessageText =>
      brightness == Brightness.light
          ? AppColors.lightReceivedBubbleText
          : AppColors.darkReceivedBubbleText;
}
