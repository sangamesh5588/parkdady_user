import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../domain/entities/user.dart';
import '../../../services/payment_methods_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';



class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  final PaymentMethodsService _paymentService = PaymentMethodsService();
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);
      final methods = await _paymentService.getUserPaymentMethods();

      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load payment methods');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
          'Payment Methods',
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
        child: Column(
          children: [
            Expanded(
              child: _paymentMethods.isEmpty
                  ? _buildEmptyState()
                  : _buildPaymentMethodsList(),
            ),
            Padding(
              padding: EdgeInsets.all(AppConstants.spacing16),
              child: CustomButton(
                text: 'Add Payment Method',
                onPressed: () => _showAddPaymentMethodDialog(context),
                icon: Icons.add,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card,
            size: 64,
            color: AppColors.textMuted,
          ),
          SizedBox(height: AppConstants.spacing16),
          Text(
            'No payment methods added',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spacing8),
          Text(
            'Add a payment method to book parking spaces',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    return ListView.builder(
      padding: EdgeInsets.all(AppConstants.spacing16),
      itemCount: _paymentMethods.length,
      itemBuilder: (context, index) {
        final paymentMethod = _paymentMethods[index];
        return _buildPaymentMethodCard(paymentMethod);
      },
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod paymentMethod) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacing12),
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(
          color: paymentMethod.isDefault ? AppColors.ctaPrimary : AppColors.borderLight,
          width: paymentMethod.isDefault ? 2 : 1,
        ),
        boxShadow: [AppColors.lightShadow],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(AppConstants.radius12),
                ),
                child: Icon(
                  paymentMethod.icon,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
              SizedBox(width: AppConstants.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paymentMethod.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing4),
                    Text(
                      paymentMethod.maskedDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (paymentMethod.type == 'card' && paymentMethod.cardExpiryMonth != null && paymentMethod.cardExpiryMonth!.isNotEmpty)
                      SizedBox(height: AppConstants.spacing4),
                    if (paymentMethod.type == 'card' && paymentMethod.cardExpiryMonth != null && paymentMethod.cardExpiryMonth!.isNotEmpty)
                      Text(
                        'Expires ${paymentMethod.cardExpiryMonth}/${paymentMethod.cardExpiryYear}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (paymentMethod.isDefault)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacing8,
                    vertical: AppConstants.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ctaPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                  ),
                  child: Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ctaPrimary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppConstants.spacing16),
          Row(
            children: [
              if (!paymentMethod.isDefault)
                Expanded(
                  child: CustomButton(
                    text: 'Set as Default',
                    onPressed: () => _setAsDefault(paymentMethod),
                    variant: CustomButtonVariant.outlined,
                  ),
                ),
              if (!paymentMethod.isDefault) SizedBox(width: AppConstants.spacing12),
              Expanded(
                child: CustomButton(
                  text: 'Remove',
                  onPressed: () => _showRemoveConfirmation(context, paymentMethod),
                  variant: CustomButtonVariant.outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setAsDefault(PaymentMethod paymentMethod) async {
    try {
      await _paymentService.setDefaultPaymentMethod(paymentMethod.id);
      await _loadPaymentMethods(); // Reload to get updated state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${paymentMethod.displayName} set as default')),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to set default payment method');
    }
  }

  void _showAddPaymentMethodDialog(BuildContext context) {
    final cardNumberController = TextEditingController();
    final expiryMonthController = TextEditingController();
    final expiryYearController = TextEditingController();
    final cvvController = TextEditingController();
    final cardholderNameController = TextEditingController();
    String selectedType = 'card';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.primaryBackground,
          title: Text(
            'Add Payment Method',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Payment Type Selection
                Container(
                  padding: EdgeInsets.all(AppConstants.spacing8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(AppConstants.radius8),
                  ),
                  child: Row(
                    children: [
                      _buildPaymentTypeOption(
                        context,
                        'Card',
                        'card',
                        selectedType,
                        () => setState(() => selectedType = 'card'),
                      ),
                      SizedBox(width: AppConstants.spacing8),
                      _buildPaymentTypeOption(
                        context,
                        'UPI',
                        'upi',
                        selectedType,
                        () => setState(() => selectedType = 'upi'),
                      ),
                      SizedBox(width: AppConstants.spacing8),
                      _buildPaymentTypeOption(
                        context,
                        'Net Banking',
                        'netbanking',
                        selectedType,
                        () => setState(() => selectedType = 'netbanking'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppConstants.spacing16),

                // Card/UPI specific fields
                if (selectedType == 'card') ...[
                  CustomTextField(
                    controller: cardNumberController,
                    label: 'Card Number',
                    hintText: '1234 5678 9012 3456',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Card number is required';
                      }
                      final cleanNumber = value!.replaceAll(' ', '');
                      if (cleanNumber.length < 13 || cleanNumber.length > 19) {
                        return 'Invalid card number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppConstants.spacing12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: expiryMonthController,
                          decoration: InputDecoration(
                            labelText: 'MM',
                            hintText: '12',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                        ),
                      ),
                      SizedBox(width: AppConstants.spacing8),
                      Expanded(
                        child: TextField(
                          controller: expiryYearController,
                          decoration: InputDecoration(
                            labelText: 'YY',
                            hintText: '25',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                        ),
                      ),
                      SizedBox(width: AppConstants.spacing8),
                      Expanded(
                        child: TextField(
                          controller: cvvController,
                          decoration: InputDecoration(
                            labelText: 'CVV',
                            hintText: '123',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacing12),
                  CustomTextField(
                    controller: cardholderNameController,
                    label: 'Cardholder Name',
                    hintText: 'JOHN DOE',
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                ] else if (selectedType == 'upi') ...[
                  CustomTextField(
                    controller: cardholderNameController,
                    label: 'UPI ID',
                    hintText: 'user@paytm',
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'UPI ID is required';
                      }
                      if (!value!.contains('@')) {
                        return 'Invalid UPI ID format';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppConstants.spacing12),
                  Container(
                    padding: EdgeInsets.all(AppConstants.spacing12),
                    decoration: BoxDecoration(
                      color: AppColors.ctaPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radius8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.ctaPrimary,
                          size: 20,
                        ),
                        SizedBox(width: AppConstants.spacing8),
                        Expanded(
                          child: Text(
                            'You will be redirected to your UPI app for verification',
                            style: TextStyle(
                              color: AppColors.ctaPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (selectedType == 'netbanking') ...[
                  CustomTextField(
                    controller: cardholderNameController,
                    label: 'Bank Name',
                    hintText: 'HDFC Bank',
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Bank name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppConstants.spacing12),
                  Container(
                    padding: EdgeInsets.all(AppConstants.spacing12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radius8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        SizedBox(width: AppConstants.spacing8),
                        Expanded(
                          child: Text(
                            'You will be redirected to your bank\'s website for secure login',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Validate and add payment method
                final errors = _validatePaymentMethod(
                  selectedType,
                  cardNumberController.text,
                  expiryMonthController.text,
                  expiryYearController.text,
                  cvvController.text,
                  cardholderNameController.text,
                );

                if (errors.isNotEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(errors.first),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                  return;
                }

                try {
                  // Add payment method via service
                  final newMethod = await _paymentService.addPaymentMethod(
                    type: selectedType,
                    displayName: _generateDisplayName(selectedType, cardholderNameController.text),
                    lastFour: _getLast4(selectedType, cardNumberController.text),
                    cardExpiryMonth: selectedType == 'card' ? expiryMonthController.text : null,
                    cardExpiryYear: selectedType == 'card' ? expiryYearController.text : null,
                    upiId: selectedType == 'upi' ? cardholderNameController.text : null,
                    bankName: selectedType == 'netbanking' ? cardholderNameController.text : null,
                  );

                  // Reload payment methods to get updated list
                  await _loadPaymentMethods();

                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${newMethod.displayName} added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add payment method: ${e.toString()}'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              },
              child: Text(
                'Add Method',
                style: TextStyle(color: AppColors.ctaPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeOption(
    BuildContext context,
    String label,
    String type,
    String selectedType,
    VoidCallback onTap,
  ) {
    final isSelected = type == selectedType;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppConstants.spacing8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.ctaPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radius4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  List<String> _validatePaymentMethod(
    String type,
    String cardNumber,
    String expiryMonth,
    String expiryYear,
    String cvv,
    String name,
  ) {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Name is required');
      return errors;
    }

    if (type == 'card') {
      final cleanNumber = cardNumber.replaceAll(' ', '');
      if (cleanNumber.isEmpty) {
        errors.add('Card number is required');
      } else if (cleanNumber.length < 13 || cleanNumber.length > 19) {
        errors.add('Invalid card number');
      }

      final month = int.tryParse(expiryMonth);
      if (month == null || month < 1 || month > 12) {
        errors.add('Invalid expiry month');
      }

      final year = int.tryParse('20$expiryYear');
      final currentYear = DateTime.now().year;
      if (year == null || year < currentYear) {
        errors.add('Card has expired');
      }

      if (cvv.length < 3 || cvv.length > 4) {
        errors.add('Invalid CVV');
      }
    } else if (type == 'upi') {
      if (!name.contains('@')) {
        errors.add('Invalid UPI ID format');
      }
    }

    return errors;
  }

  String _generateDisplayName(String type, String name) {
    switch (type) {
      case 'card':
        return name.isNotEmpty ? name : 'Credit Card';
      case 'upi':
        return '$name (UPI)';
      case 'netbanking':
        return '$name (Net Banking)';
      default:
        return 'Payment Method';
    }
  }

  String _getLast4(String type, String cardNumber) {
    if (type == 'card') {
      final cleanNumber = cardNumber.replaceAll(' ', '');
      return cleanNumber.length >= 4 ? cleanNumber.substring(cleanNumber.length - 4) : 'XXXX';
    }
    return 'XXXX';
  }

  void _showRemoveConfirmation(BuildContext context, PaymentMethod paymentMethod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryBackground,
        title: Text(
          'Remove Payment Method',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove ${paymentMethod.displayName}?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _paymentService.deletePaymentMethod(paymentMethod.id);
                await _loadPaymentMethods(); // Reload to get updated list
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${paymentMethod.displayName} removed')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                _showErrorSnackBar('Failed to remove payment method');
              }
            },
            child: Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
