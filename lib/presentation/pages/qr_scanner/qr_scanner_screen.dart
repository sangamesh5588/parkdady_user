import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../core/qr_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Scan Parking Ticket',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _scannerController.toggleTorch(),
            icon: Icon(
              _scannerController.torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () => _scannerController.switchCamera(),
            icon: Icon(
              Icons.flip_camera_android,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _scannerController,
            onDetect: _onQRCodeDetected,
          ),

          // Overlay with scan area
          _buildScanOverlay(),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: AppConstants.spacing16),
                    Text(
                      'Validating ticket...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      child: Stack(
        children: [
          // Top section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: (MediaQuery.of(context).size.height - 300) / 2,
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),

          // Bottom section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: (MediaQuery.of(context).size.height - 300) / 2,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              padding: EdgeInsets.all(AppConstants.spacing16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Position QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppConstants.spacing8),
                  Text(
                    'Ensure good lighting for better scanning',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Left section
          Positioned(
            top: (MediaQuery.of(context).size.height - 300) / 2,
            left: 0,
            width: (MediaQuery.of(context).size.width - 300) / 2,
            height: 300,
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),

          // Right section
          Positioned(
            top: (MediaQuery.of(context).size.height - 300) / 2,
            right: 0,
            width: (MediaQuery.of(context).size.width - 300) / 2,
            height: 300,
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),

          // Scan frame
          Positioned(
            top: (MediaQuery.of(context).size.height - 300) / 2,
            left: (MediaQuery.of(context).size.width - 300) / 2,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppConstants.radius8),
              ),
              child: Stack(
                children: [
                  // Corner brackets
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.ctaPrimary, width: 4),
                          left: BorderSide(color: AppColors.ctaPrimary, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.ctaPrimary, width: 4),
                          right: BorderSide(color: AppColors.ctaPrimary, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.ctaPrimary, width: 4),
                          left: BorderSide(color: AppColors.ctaPrimary, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.ctaPrimary, width: 4),
                          right: BorderSide(color: AppColors.ctaPrimary, width: 4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String qrData = barcodes.first.rawValue ?? '';
    if (qrData.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    // Process QR code
    _processQRCode(qrData);
  }

  void _processQRCode(String qrData) async {
    try {
      // Validate QR code
      if (!QRService.isValidAppQR(qrData)) {
        _showResultDialog(
          isValid: false,
          title: 'Invalid QR Code',
          message: 'This QR code is not from our parking app.',
        );
        return;
      }

      // Parse booking data
      final bookingData = QRService.parseBookingQR(qrData);
      if (bookingData == null) {
        _showResultDialog(
          isValid: false,
          title: 'Invalid Ticket',
          message: 'This ticket appears to be invalid or expired.',
        );
        return;
      }

      // Check if booking is active
      if (bookingData.isExpired) {
        _showResultDialog(
          isValid: false,
          title: 'Expired Ticket',
          message: 'This parking ticket has expired.',
        );
        return;
      }

      if (bookingData.isUpcoming) {
        _showResultDialog(
          isValid: false,
          title: 'Early Arrival',
          message: 'This booking starts at ${bookingData.startTime.hour}:${bookingData.startTime.minute.toString().padLeft(2, '0')}. Please arrive on time.',
        );
        return;
      }

      // Valid booking - allow entry
      _showResultDialog(
        isValid: true,
        title: 'Valid Ticket',
        message: 'Booking ID: ${bookingData.bookingId}\nVehicle: ${bookingData.vehicleNumber}\nValid until: ${bookingData.endTime.hour}:${bookingData.endTime.minute.toString().padLeft(2, '0')}',
        bookingData: bookingData,
      );

    } catch (e) {
      _showResultDialog(
        isValid: false,
        title: 'Error',
        message: 'Failed to process QR code. Please try again.',
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showResultDialog({
    required bool isValid,
    required String title,
    required String message,
    QRBookingData? bookingData,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius12),
        ),
        title: Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.error,
              color: isValid ? Colors.green : Colors.red,
            ),
            SizedBox(width: AppConstants.spacing8),
            Text(
              title,
              style: TextStyle(
                color: isValid ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (bookingData != null && isValid) ...[
              SizedBox(height: AppConstants.spacing16),
              Container(
                padding: EdgeInsets.all(AppConstants.spacing12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radius8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: Colors.green,
                      size: 24,
                    ),
                    SizedBox(width: AppConstants.spacing12),
                    Expanded(
                      child: Text(
                        'Allow Entry',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (!isValid) {
                // Resume scanning for invalid codes
                setState(() {
                  _isProcessing = false;
                });
              } else {
                // Return to home for valid codes
                Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
              }
            },
            child: Text(
              isValid ? 'Done' : 'Try Again',
              style: TextStyle(
                color: isValid ? Colors.green : AppColors.ctaPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
