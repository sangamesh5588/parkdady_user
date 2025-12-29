import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../domain/entities/user.dart';
import '../../providers/auth_provider.dart';

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

              // Social Links
              _buildSocialSection(),
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
          'Find and book parking spaces easily',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
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
        value: 'Parking App Team',
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
      _LegalItem(
        title: 'Open Source Licenses',
        onTap: () => _showOpenSourceLicenses(),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.web,
              label: 'Website',
              onTap: () => _openWebsite(),
            ),
            SizedBox(width: AppConstants.spacing16),
            _buildSocialButton(
              icon: Icons.alternate_email,
              label: 'Twitter',
              onTap: () => _openTwitter(),
            ),
            SizedBox(width: AppConstants.spacing16),
            _buildSocialButton(
              icon: Icons.facebook,
              label: 'Facebook',
              onTap: () => _openFacebook(),
            ),
            SizedBox(width: AppConstants.spacing16),
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

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(AppConstants.radius12),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.ctaPrimary,
              size: 24,
            ),
          ),
        ),
        SizedBox(height: AppConstants.spacing8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showTermsOfService() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLegalScreen(
        title: 'Terms of Service',
        content: _getTermsOfServiceContent(),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLegalScreen(
        title: 'Privacy Policy',
        content: _getPrivacyPolicyContent(),
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

  void _showOpenSourceLicenses() {
    showLicensePage(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.ctaPrimary,
          borderRadius: BorderRadius.circular(AppConstants.radius12),
        ),
        child: Icon(
          Icons.local_parking,
          size: 30,
          color: AppColors.ctaOnPrimary,
        ),
      ),
    );
  }

  void _openWebsite() async {
    const url = 'https://parkingapp.com'; // Replace with actual website URL
    try {
      // Using url_launcher to open external links
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open website')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open website')),
      );
    }
  }

  void _openTwitter() async {
    const url = 'https://twitter.com/parkingapp'; // Replace with actual Twitter URL
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Twitter')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Twitter')),
      );
    }
  }

  void _openFacebook() async {
    const url = 'https://facebook.com/parkingapp'; // Replace with actual Facebook URL
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Facebook')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Facebook')),
      );
    }
  }

  void _shareApp() async {
    const appUrl = 'https://play.google.com/store/apps/details?id=com.parkingapp'; // Replace with actual app URL
    const shareText = 'Check out Parking App - Find and book parking spaces easily!\n\n$appUrl';

    try {
      // Using share_plus package for sharing functionality
      // For now, we'll use a simple approach with clipboard
      // In production, you would use: Share.share(shareText);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('App link copied to clipboard!'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              // Here you would implement actual sharing
              // For example: Share.share(shareText);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share app')),
      );
    }
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

  Widget _getTermsOfServiceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegalContentSection(
          'Acceptance of Terms',
          'By accessing and using the Parking App, you accept and agree to be bound by the terms and provision of this agreement.',
        ),
        _buildLegalContentSection(
          'Use License',
          'Permission is granted to temporarily use the Parking App for personal, non-commercial transitory viewing only.',
        ),
        _buildLegalContentSection(
          'User Responsibilities',
          'You agree to use the app only for lawful purposes and in accordance with these terms. You are responsible for maintaining the confidentiality of your account.',
        ),
        _buildLegalContentSection(
          'Booking Terms',
          'All bookings are subject to availability and confirmation. Cancellations must be made according to our cancellation policy.',
        ),
        _buildLegalContentSection(
          'Payment Terms',
          'All payments are processed securely. You agree to pay all charges associated with your bookings.',
        ),
        _buildLegalContentSection(
          'Disclaimer',
          'The information on this app is provided on an "as is" basis. We disclaim all warranties, express or implied.',
        ),
        _buildLegalContentSection(
          'Contact Information',
          'If you have any questions about these Terms of Service, please contact us at support@parkingapp.com.',
        ),
      ],
    );
  }

  Widget _getPrivacyPolicyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegalContentSection(
          'Information We Collect',
          'We collect information you provide directly to us, such as when you create an account, make a booking, or contact us for support.',
        ),
        _buildLegalContentSection(
          'How We Use Your Information',
          'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.',
        ),
        _buildLegalContentSection(
          'Information Sharing',
          'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.',
        ),
        _buildLegalContentSection(
          'Data Security',
          'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
        ),
        _buildLegalContentSection(
          'Data Retention',
          'We retain your information for as long as necessary to provide our services and comply with legal obligations.',
        ),
        _buildLegalContentSection(
          'Your Rights',
          'You have the right to access, update, or delete your personal information. Contact us to exercise these rights.',
        ),
        _buildLegalContentSection(
          'Cookies',
          'We use cookies and similar technologies to enhance your experience and analyze app usage.',
        ),
        _buildLegalContentSection(
          'Changes to This Policy',
          'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page.',
        ),
        _buildLegalContentSection(
          'Contact Us',
          'If you have any questions about this Privacy Policy, please contact us at privacy@parkingapp.com.',
        ),
      ],
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
