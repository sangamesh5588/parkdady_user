# Razorpay Payment Gateway Integration

This guide explains how to set up Razorpay payment gateway integration for the Parking App.

## 🚀 Quick Setup

### 1. Get Your Razorpay Keys

1. **Sign up** at [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. **Create a new application** or use existing one
3. **Get your API keys** from the Dashboard → Settings → API Keys
4. **Note the keys**:
   - **Test Key ID**: `rzp_test_xxxxxxxxxxxxxx`
   - **Test Key Secret**: `xxxxxxxxxxxxxx`
   - **Live Key ID**: `rzp_live_xxxxxxxxxxxxxx` (for production)

### 2. Environment Configuration

Add your Razorpay keys to the `.env` file:

```env
# Razorpay Configuration
RAZORPAY_TEST_KEY=rzp_test_your_test_key_here
RAZORPAY_LIVE_KEY=rzp_live_your_live_key_here
RAZORPAY_ENVIRONMENT=test  # Use 'live' for production
```

### 3. Update Payment Service

In `lib/core/payment_service.dart`, update the key usage:

```dart
// Replace this line in _handleConfirmBooking():
const razorpayKey = 'rzp_test_your_test_key_here';

// With this:
const razorpayKey = String.fromEnvironment(
  'RAZORPAY_TEST_KEY',
  defaultValue: 'rzp_test_your_test_key_here',
);
```

### 4. Backend Integration (Optional but Recommended)

For production, implement these backend endpoints:

#### Create Order Endpoint
```javascript
// POST /api/create-order
{
  "amount": 50000,  // Amount in paisa (₹500.00)
  "currency": "INR",
  "notes": {
    "parking_space_id": "space_123",
    "user_id": "user_456"
  }
}
```

#### Verify Payment Endpoint
```javascript
// POST /api/verify-payment
{
  "payment_id": "pay_xxx",
  "order_id": "order_xxx",
  "signature": "signature_xxx"
}
```

### 5. Test the Integration

1. **Run the app** with test keys
2. **Go through booking flow**:
   - Select parking space → Details → Book → Confirm & Pay
3. **Use test payment details**:
   - **Card Number**: `4111 1111 1111 1111`
   - **Expiry**: `12/25`
   - **CVV**: `123`
   - **Name**: `Test User`

## 📋 Features Implemented

### ✅ Payment Flow
- **Secure checkout** with Razorpay
- **Multiple payment methods**: Cards, UPI, Net Banking, Wallets
- **Real-time validation** and error handling
- **Success/failure callbacks**

### ✅ Booking Integration
- **Pre-payment confirmation** screen
- **Order creation** with booking details
- **Payment verification** and booking completion
- **Digital ticket** generation

### ✅ User Experience
- **Seamless flow** from booking to payment
- **Clear pricing** and fee breakdown
- **Payment status** updates
- **Error recovery** and retry options

## 🔧 Technical Details

### Payment Service Architecture

```
lib/core/payment_service.dart
├── PaymentService (Singleton)
│   ├── initialize() - Setup event handlers
│   ├── openCheckout() - Launch Razorpay UI
│   └── createOrder() - Backend order creation
├── PaymentState - State management
└── PaymentNotifier - Riverpod state notifier
```

### Integration Points

1. **Booking Confirmation Screen**
   - Initializes payment service
   - Handles payment callbacks
   - Manages booking completion

2. **Payment Callbacks**
   - `onSuccess` - Payment completed → Show success screen
   - `onFailure` - Payment failed → Show error message
   - `onExternalWallet` - Wallet selection handling

3. **Order Management**
   - Creates order with booking details
   - Links payment to specific booking
   - Handles payment verification

## 🧪 Testing

### Test Cards
```
Success Card: 4111 1111 1111 1111
Failed Card:  4000 0000 0000 0002
```

### Test UPI IDs
```
Success: success@razorpay
Failure: failure@razorpay
```

### Test Scenarios
- ✅ Successful payment → Booking confirmed
- ✅ Failed payment → Error message shown
- ✅ Cancel payment → Return to booking screen
- ✅ Network issues → Retry option provided

## 🚀 Production Deployment

### Pre-launch Checklist

1. **Switch to Live Keys**
   ```env
   RAZORPAY_ENVIRONMENT=live
   RAZORPAY_LIVE_KEY=rzp_live_your_live_key_here
   ```

2. **Enable Live Mode**
   ```dart
   const razorpayKey = String.fromEnvironment(
     'RAZORPAY_LIVE_KEY',
     defaultValue: 'rzp_live_your_live_key_here',
   );
   ```

3. **Implement Webhooks**
   - Set up payment success/failure webhooks
   - Implement payment verification on backend
   - Update booking status based on payment

4. **Security Measures**
   - Validate payment signatures
   - Implement fraud detection
   - Add rate limiting

5. **Compliance**
   - PCI DSS compliance for card data
   - GDPR compliance for user data
   - Local payment regulations

## 🆘 Troubleshooting

### Common Issues

1. **"Invalid API Key" Error**
   - Check if key is correct and matches environment (test/live)
   - Ensure key is not expired

2. **Payment Not Completing**
   - Verify internet connection
   - Check if order ID is valid
   - Ensure amount is in paisa (multiply by 100)

3. **Callback Not Working**
   - Ensure event handlers are properly initialized
   - Check for navigation conflicts during payment

### Debug Mode

Enable debug logging in payment service:
```dart
debugPrint('Payment Success: ${response.paymentId}');
debugPrint('Payment Failed: ${response.message}');
```

## 📚 Resources

- [Razorpay Flutter SDK Docs](https://razorpay.com/docs/payment-gateway/flutter-integration/)
- [Razorpay Dashboard](https://dashboard.razorpay.com/)
- [Payment Gateway Testing](https://razorpay.com/docs/payment-gateway/test-card-details/)
- [API Reference](https://razorpay.com/docs/api/)

## 💡 Next Steps

1. **Add payment methods**: Google Pay, PhonePe, Paytm integration
2. **Implement refunds**: Cancellation refund processing
3. **Add subscriptions**: Monthly parking plans
4. **Analytics**: Payment conversion tracking
5. **Multi-currency**: Support for international payments

---

**🎉 Your parking app now supports secure payments with Razorpay!**
