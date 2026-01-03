import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../domain/entities/user.dart';
import '../../providers/auth_provider.dart';
import 'web_view_screen.dart';

class AboutItem {
  final String title;
  final String value;
  final IconData icon;

  const AboutItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'About',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppConstants.spacing16),
          child: Column(
            children: [
              // App Logo/Branding
              _buildAppHeader(),

              SizedBox(height: AppConstants.spacing32),

              // App Information
              _buildAppInfo(),

              SizedBox(height: AppConstants.spacing32),

              // Legal & Links
              _buildLegalSection(),

              SizedBox(height: AppConstants.spacing32),

              // Connect with Us
              _buildSocialSection(),

              SizedBox(height: AppConstants.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.ctaPrimary,
            borderRadius: BorderRadius.circular(AppConstants.radius16),
          ),
          child: Icon(
            Icons.local_parking,
            size: 40,
            color: AppColors.ctaOnPrimary,
          ),
        ),
        SizedBox(height: AppConstants.spacing16),
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.spacing8),
        Text(
          AppConstants.appTagline,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.ctaPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAppInfo() {
    final appInfo = [
      AboutItem(
        title: 'Version',
        value: AppConstants.appVersion,
        icon: Icons.info,
      ),
      AboutItem(
        title: 'Build',
        value: '1',
        icon: Icons.build,
      ),
      AboutItem(
        title: 'Developer',
        value: 'Park Daddy Team',
        icon: Icons.developer_mode,
      ),
      AboutItem(
        title: 'Platform',
        value: 'Flutter',
        icon: Icons.phone_android,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.spacing16),
        ...appInfo.map((info) => _buildInfoCard(info)),
      ],
    );
  }

  Widget _buildLegalSection() {
    final legalItems = [
      _LegalItem(
        title: 'Terms of Service',
        onTap: () => _showTermsOfService(),
      ),
      _LegalItem(
        title: 'Privacy Policy',
        onTap: () => _showPrivacyPolicy(),
      ),
      _LegalItem(
        title: 'License Agreement',
        onTap: () => _showLicenseAgreement(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.spacing16),
        ...legalItems.map((item) => _buildLegalCard(item)),
      ],
    );
  }

  Widget _buildInfoCard(AboutItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacing8),
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [AppColors.lightShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(AppConstants.radius8),
            ),
            child: Icon(
              item.icon,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          SizedBox(width: AppConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard(_LegalItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacing8),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [AppColors.lightShadow],
      ),
      child: ListTile(
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
        onTap: item.onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius12),
        ),
      ),
    );
  }

  void _showTermsOfService() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WebViewScreen(
          url: 'https://www.parkdady.com/terms-of-service',
          title: 'Terms of Service',
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WebViewScreen(
          url: 'https://www.parkdady.com/privacy-policy',
          title: 'Privacy Policy',
        ),
      ),
    );
  }

  void _showLicenseAgreement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLegalScreen(
        title: 'License Agreement',
        content: _getLicenseAgreementContent(),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect With Us',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.spacing16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialButton(
              icon: Icons.language,
              label: 'Website',
              onTap: () => _openWebsite(),
            ),
            _buildSocialButton(
              icon: Icons.phone,
              label: 'Contact',
              onTap: () => _openContact(),
            ),
            _buildSocialButton(
              icon: Icons.email,
              label: 'Email',
              onTap: () => _openEmail(),
            ),
            _buildSocialButton(
              icon: Icons.share,
              label: 'Share',
              onTap: () => _shareApp(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radius12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.ctaPrimary,
                  AppColors.ctaPrimary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radius12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ctaPrimary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(height: AppConstants.spacing8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _openWebsite() async {
    final Uri url = Uri.parse('https://www.parkdady.com');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open website'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening website'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openContact() async {
    final Uri url = Uri.parse('https://www.parkdady.com/connect');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open contact page'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening contact page'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@parkdaddy.com',
      queryParameters: {
        'subject': 'Support Request - Park Daddy App',
        'body': '''Hello Park Daddy Support Team,

I am reaching out regarding:
[ ] Booking Issue
[ ] Payment/Refund Query
[ ] Account Help
[ ] Technical Problem
[ ] General Inquiry
[ ] Other

Details:


Thank you for your assistance!

Best regards,
''',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email: support@parkdaddy.com'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _shareApp() {
    const appUrl = 'https://www.parkdady.com';
    const shareText = 'Check out Park Daddy - The Parking Boss! 🚗\n\nFind and book parking spaces easily with the best rates.\n\nVisit: $appUrl';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.share, color: AppColors.ctaPrimary),
            SizedBox(width: 12),
            Text('Share Park Daddy'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[ Text(
              shareText,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Tap below to copy the message and share with friends!',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Capture the ScaffoldMessenger before closing the dialog
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              // Show snackbar using captured messenger
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Text('Share Park Daddy with your friends via WhatsApp, SMS, or any app!'),
                  backgroundColor: AppColors.ctaPrimary,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaPrimary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalScreen({required String title, required Widget content}) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance the close button
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: content,
            ),
          ),
        ],
      ),
    );
  }


  Widget _getLicenseAgreementContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegalContentSection(
          'License Grant',
          'Subject to the terms of this agreement, we grant you a limited, non-exclusive, non-transferable license to use the Parking App.',
        ),
        _buildLegalContentSection(
          'Restrictions',
          'You may not: modify, copy, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, or sell the app.',
        ),
        _buildLegalContentSection(
          'Intellectual Property',
          'The Parking App and its original content, features, and functionality are owned by us and are protected by copyright, trademark, and other laws.',
        ),
        _buildLegalContentSection(
          'User Content',
          'By posting content to the app, you grant us a non-exclusive, royalty-free, perpetual, irrevocable, and fully sublicensable right to use, reproduce, modify, adapt, publish, translate, create derivative works from, distribute, and display such content.',
        ),
        _buildLegalContentSection(
          'Termination',
          'We may terminate or suspend your account and access to the app immediately, without prior notice, for any reason.',
        ),
        _buildLegalContentSection(
          'Disclaimer of Warranties',
          'The app is provided on an "as is" and "as available" basis. We disclaim all warranties of any kind, whether express or implied.',
        ),
        _buildLegalContentSection(
          'Limitation of Liability',
          'In no event shall we be liable for any indirect, incidental, special, consequential, or punitive damages.',
        ),
        _buildLegalContentSection(
          'Governing Law',
          'This agreement shall be governed by and construed in accordance with the laws of the jurisdiction in which we operate.',
        ),
        _buildLegalContentSection(
          'Contact Information',
          'If you have any questions about this License Agreement, please contact us at legal@parkingapp.com.',
        ),
      ],
    );
  }

  Widget _buildLegalContentSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalItem {
  final String title;
  final VoidCallback onTap;

  const _LegalItem({
    required this.title,
    required this.onTap,
  });
}
