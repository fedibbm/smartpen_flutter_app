import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';
import '../config/email_config.dart';

/// Service for sending emails via SMTP (Brevo)
class EmailService {
  // Brevo SMTP configuration loaded from config
  static const String _smtpHost = EmailConfig.smtpHost;
  static const int _smtpPort = EmailConfig.smtpPort;
  static const String _smtpUsername = EmailConfig.smtpUsername;
  
  static const String _smtpPassword = EmailConfig.smtpPassword;
  static const String _senderEmail = EmailConfig.senderEmail;
  static const String _senderName = EmailConfig.senderName;

  /// Send notification email to parent when child exits the app
  Future<bool> sendAppExitNotification({
    required String parentEmail,
    required String childName,
    required DateTime exitTime,
  }) async {
    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
      );

      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(parentEmail)
        ..subject = 'DyslexiPen Reader - Activity Notification'
        ..text = _buildPlainTextMessage(childName, exitTime)
        ..html = _buildHtmlMessage(childName, exitTime);

      final sendReport = await send(message, smtpServer);
      debugPrint('✅ Email sent successfully to $parentEmail');
      debugPrint('   Report: ${sendReport.toString()}');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending email: $e');
      return false;
    }
  }

  /// Build plain text email message
  String _buildPlainTextMessage(String childName, DateTime exitTime) {
    final formattedTime = _formatDateTime(exitTime);
    
    return '''
Hello,

This is a notification from DyslexiPen Reader.

$childName has exited the app at $formattedTime.

Session Summary:
- Exit Time: $formattedTime
- Device: Mobile App

This is an automated message to keep you informed about your child's app usage.

Best regards,
DyslexiPen Reader Team
''';
  }

  /// Build HTML email message
  String _buildHtmlMessage(String childName, DateTime exitTime) {
    final formattedTime = _formatDateTime(exitTime);
    
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px; }
    .content { background-color: #f9f9f9; padding: 20px; margin-top: 20px; border-radius: 5px; }
    .info-box { background-color: white; padding: 15px; margin: 10px 0; border-left: 4px solid #4CAF50; }
    .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2>📱 DyslexiPen Reader</h2>
      <p>Activity Notification</p>
    </div>
    
    <div class="content">
      <h3>Hello,</h3>
      <p>This is a notification from DyslexiPen Reader.</p>
      
      <div class="info-box">
        <strong>$childName</strong> has exited the app.
      </div>
      
      <div class="info-box">
        <strong>Exit Time:</strong> $formattedTime
      </div>
      
      <div class="info-box">
        <strong>Device:</strong> Mobile App
      </div>
      
      <p>This is an automated message to keep you informed about your child's app usage.</p>
    </div>
    
    <div class="footer">
      <p>This is an automated message from DyslexiPen Reader</p>
      <p>&copy; 2025 DyslexiPen Reader Team</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Format DateTime to readable string
  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$month $day, $year at $hour:$minute';
  }

  /// Test email configuration
  Future<bool> testEmailConfiguration(String testRecipient) async {
    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
      );

      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(testRecipient)
        ..subject = 'DyslexiPen Reader - Test Email'
        ..text = 'This is a test email to verify the email configuration is working correctly.';

      await send(message, smtpServer);
      debugPrint('✅ Test email sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Test email failed: $e');
      return false;
    }
  }
}
