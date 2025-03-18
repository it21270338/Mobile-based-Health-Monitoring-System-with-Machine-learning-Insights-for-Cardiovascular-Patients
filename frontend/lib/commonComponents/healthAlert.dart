import 'package:flutter/material.dart';

import '../services/apiDio.dart';

class HealthAlertPopup extends StatelessWidget {
  final String alertTitle;
  final String alertMessage;
  final VoidCallback? onNotifyContact;
  final VoidCallback? onDismiss;
  final Color backgroundColor;
  final Color iconColor;

  const HealthAlertPopup({
    Key? key,
    required this.alertTitle,
    required this.alertMessage,
    this.onNotifyContact,
    this.onDismiss,
    this.backgroundColor = const Color(0xFFFF3B30),
    this.iconColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeOut,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.favorite, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alertTitle,
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alertMessage,
                            style: TextStyle(
                              color: iconColor.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // IconButton(
                    //   icon: Icon(
                    //     Icons.close,
                    //     color: iconColor.withOpacity(0.8),
                    //     size: 20,
                    //   ),
                    //   onPressed: () {
                    //     if (onDismiss != null) {
                    //       onDismiss!();
                    //     }
                    //     Navigator.of(context).pop();
                    //   },
                    // ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor.darken(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: iconColor.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ElevatedButton(
                        onPressed: onNotifyContact,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: backgroundColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Notify Contact',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to darken colors
extension ColorExtension on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

// Show the alert from top of the screen
void showHealthAlert(BuildContext context, String userId) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: HealthAlertPopup(
            alertTitle: 'Heart Rate Risk Detected',
            alertMessage:
                'We detected an unusually high risk. Do you want to alert your emergency contact now?',
            onNotifyContact: () async {
              await sendNotificationWithLoader(
                context,
                userId,
                "heart_rate",
                null,
              );
              Navigator.of(context).pop();
            },
            onDismiss: () {
              print('Alert dismissed');
            },
          ),
        ),
      );
    },
  );
}

void showEmotionAlert(BuildContext context, String userId, String emotion) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: HealthAlertPopup(
            alertTitle: 'Emotional Support',
            alertMessage:
                "We noticed that you're feeling $emotion. Would you like to take a moment to relax or get some support?",
            onNotifyContact: () async {
              // Add your emergency contact notification logic here
              await sendNotificationWithLoader(
                context,
                userId,
                "emotion",
                emotion,
              );
              Navigator.of(context).pop();
            },
            onDismiss: () {
              print('Alert dismissed');
            },
          ),
        ),
      );
    },
  );
}

Future<void> sendNotificationWithLoader(
  BuildContext context,
  String userId,
  String type,
  String? emotion,
) async {
  final apiDio _apiDio = apiDio();
  // Show loader dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Sending notification..."),
          ],
        ),
      );
    },
  );

  bool success = await _apiDio.sendNotification(userId, type, emotion: emotion);

  // Close loader
  Navigator.of(context).pop();

  // Show success or failure message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? "Emergency contact notified successfully!"
            : "Failed to notify emergency contact.",
      ),
      backgroundColor: success ? Colors.green : Colors.red,
    ),
  );
}
