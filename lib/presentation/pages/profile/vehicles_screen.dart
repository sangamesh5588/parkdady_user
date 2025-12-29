import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../domain/entities/vehicle.dart';
import '../../../services/vehicle_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> with TickerProviderStateMixin {
  final VehicleService _vehicleService = VehicleService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    _fabAnimationController.forward();
    // Add slight delay for smoother initial load
    Future.delayed(const Duration(milliseconds: 150), _loadVehicles);
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);
      final vehicles = await _vehicleService.fetchUserVehicles();
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load vehicles. Please check your connection and try again.');
      }
    }
  }

  Future<void> _refreshVehicles() async {
    if (!mounted || _isRefreshing) return;

    try {
      setState(() => _isRefreshing = true);
      final vehicles = await _vehicleService.fetchUserVehicles();
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _showErrorSnackBar('Failed to refresh vehicles. Please try again.');
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
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadVehicles,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'My Vehicles',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
        actions: [
          if (!_isLoading && _vehicles.isNotEmpty)
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isRefreshing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaPrimary),
                        ),
                      )
                    : Icon(Icons.refresh, color: AppColors.textSecondary),
              ),
              onPressed: _isRefreshing ? null : _refreshVehicles,
              splashRadius: 24,
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLoading
              ? _buildLoadingState()
              : Column(
                  key: const ValueKey('vehicles_content'),
                  children: [
                    if (_vehicles.isNotEmpty)
                      AnimatedOpacity(
                        opacity: _vehicles.isNotEmpty ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppConstants.spacing16,
                            vertical: AppConstants.spacing8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              SizedBox(width: AppConstants.spacing8),
                              Text(
                                '${_vehicles.length} vehicle${_vehicles.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _vehicles.isEmpty
                            ? _buildEmptyState()
                            : _buildVehiclesList(),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _fabAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _fabAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - _fabAnimation.value)),
                            child: Padding(
                              padding: EdgeInsets.all(AppConstants.spacing16),
                              child: CustomButton(
                                text: 'Add Vehicle',
                                onPressed: () => _showAddVehicleDialog(context),
                                icon: Icons.add,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaPrimary),
          ),
          SizedBox(height: AppConstants.spacing16),
          Text(
            'Loading your vehicles...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(AppConstants.radius24),
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: AppConstants.spacing24),
          Text(
            'No vehicles yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spacing12),
          Text(
            'Add your first vehicle to get started with parking bookings',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 16,
                color: AppColors.ctaPrimary,
              ),
              SizedBox(width: AppConstants.spacing4),
              Text(
                'Tap "Add Vehicle" below to begin',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.ctaPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesList() {
    return ListView.builder(
      padding: EdgeInsets.all(AppConstants.spacing16),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: AppConstants.spacing12),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(
          color: vehicle.isDefault ? AppColors.ctaPrimary : AppColors.borderLight,
          width: vehicle.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: vehicle.isDefault
                ? AppColors.ctaPrimary.withOpacity(0.1)
                : AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: vehicle.isDefault
            ? LinearGradient(
                colors: [
                  AppColors.ctaPrimary.withOpacity(0.05),
                  AppColors.primaryBackground,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radius16),
          onTap: () => _showEditVehicleDialog(context, vehicle),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with vehicle icon and default badge
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.ctaPrimary.withOpacity(0.1),
                            AppColors.secondaryBackground,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppConstants.radius12),
                        border: Border.all(
                          color: vehicle.isDefault
                              ? AppColors.ctaPrimary.withOpacity(0.3)
                              : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: vehicle.isDefault
                            ? AppColors.ctaPrimary
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: AppConstants.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${vehicle.make} ${vehicle.model}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (vehicle.isDefault)
                                Container(
                                  margin: EdgeInsets.only(left: AppConstants.spacing8),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacing8,
                                    vertical: AppConstants.spacing4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.ctaPrimary,
                                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: AppConstants.spacing4),
                          Row(
                            children: [
                              Icon(
                                Icons.tag,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: AppConstants.spacing4),
                              Text(
                                vehicle.licensePlate.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Vehicle details row
                SizedBox(height: AppConstants.spacing16),
                Row(
                  children: [
                    if (vehicle.color != null)
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.palette,
                          label: 'Color',
                          value: vehicle.color!,
                        ),
                      ),
                    if (vehicle.year != null)
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.calendar_today,
                          label: 'Year',
                          value: vehicle.year!.toString(),
                        ),
                      ),
                    if (vehicle.color == null && vehicle.year == null)
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.info_outline,
                          label: 'Status',
                          value: 'Ready to use',
                        ),
                      ),
                  ],
                ),

                // Action buttons
                SizedBox(height: AppConstants.spacing20),
                Row(
                  children: [
                    if (!vehicle.isDefault)
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.star_border,
                          label: 'Set Default',
                          onPressed: () => _setAsDefault(vehicle),
                          color: AppColors.ctaPrimary,
                        ),
                      ),
                    if (!vehicle.isDefault) SizedBox(width: AppConstants.spacing8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.edit,
                        label: 'Edit',
                        onPressed: () => _showEditVehicleDialog(context, vehicle),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: AppConstants.spacing8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        onPressed: () => _showDeleteConfirmation(context, vehicle),
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textMuted,
        ),
        SizedBox(width: AppConstants.spacing4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radius8),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacing12,
            vertical: AppConstants.spacing8,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppConstants.radius8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              SizedBox(width: AppConstants.spacing4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setAsDefault(Vehicle vehicle) async {
    try {
      final updatedVehicle = await _vehicleService.setDefaultVehicle(vehicle.id);
      await _loadVehicles(); // Reload the list to reflect changes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${vehicle.make} ${vehicle.model} set as default')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set default vehicle: $e')),
        );
      }
    }
  }

  void _showAddVehicleDialog(BuildContext context) {
    final licensePlateController = TextEditingController();
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final colorController = TextEditingController();
    final yearController = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColors.primaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Padding(
              padding: EdgeInsets.all(AppConstants.spacing16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: AppColors.ctaPrimary,
                        size: 28,
                      ),
                      SizedBox(width: AppConstants.spacing12),
                      Text(
                        'Add Vehicle',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacing20),

                  // Form Content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Required Fields Section
                          Text(
                            'Required Information',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppConstants.spacing12),

                          CustomTextField(
                            controller: licensePlateController,
                            label: 'License Plate *',
                            hintText: 'ABC-123',
                          ),
                          SizedBox(height: AppConstants.spacing16),

                          CustomTextField(
                            controller: makeController,
                            label: 'Make *',
                            hintText: 'Toyota, Honda, etc.',
                          ),
                          SizedBox(height: AppConstants.spacing16),

                          CustomTextField(
                            controller: modelController,
                            label: 'Model *',
                            hintText: 'Camry, Civic, etc.',
                          ),
                          SizedBox(height: AppConstants.spacing20),

                          // Optional Fields Section
                          Text(
                            'Optional Information',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppConstants.spacing12),

                          CustomTextField(
                            controller: colorController,
                            label: 'Color',
                            hintText: 'Blue, Red, etc.',
                          ),
                          SizedBox(height: AppConstants.spacing16),

                          CustomTextField(
                            controller: yearController,
                            label: 'Year',
                            hintText: '2020',
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: AppConstants.spacing20),

                          // Default Vehicle Option
                          Container(
                            padding: EdgeInsets.all(AppConstants.spacing12),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(AppConstants.radius12),
                              border: Border.all(
                                color: AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isDefault,
                                  onChanged: (value) {
                                    setState(() {
                                      isDefault = value ?? false;
                                    });
                                  },
                                  activeColor: AppColors.ctaPrimary,
                                ),
                                SizedBox(width: AppConstants.spacing8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Set as default vehicle',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: AppConstants.spacing4),
                                      Text(
                                        'This vehicle will be selected automatically for bookings',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppConstants.spacing24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radius8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppConstants.spacing12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final licensePlate = licensePlateController.text.trim();
                            final make = makeController.text.trim();
                            final model = modelController.text.trim();
                            final color = colorController.text.trim().isEmpty
                                ? null
                                : colorController.text.trim();
                            final year = yearController.text.trim().isEmpty
                                ? null
                                : int.tryParse(yearController.text.trim());

                            if (licensePlate.isEmpty || make.isEmpty || model.isEmpty) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(content: Text('Please fill in all required fields')),
                              );
                              return;
                            }

                            try {
                              await _vehicleService.addVehicle(
                                licensePlate: licensePlate,
                                make: make,
                                model: model,
                                color: color,
                                year: year,
                                isDefault: isDefault,
                              );

                              if (mounted) {
                                await _loadVehicles();
                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vehicle added successfully')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Failed to add vehicle: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ctaPrimary,
                            foregroundColor: AppColors.ctaOnPrimary,
                            padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radius8),
                            ),
                          ),
                          child: Text(
                            'Add Vehicle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditVehicleDialog(BuildContext context, Vehicle vehicle) {
    final licensePlateController = TextEditingController(text: vehicle.licensePlate);
    final makeController = TextEditingController(text: vehicle.make);
    final modelController = TextEditingController(text: vehicle.model);
    final colorController = TextEditingController(text: vehicle.color);
    final yearController = TextEditingController(text: vehicle.year?.toString());
    bool isDefault = vehicle.isDefault;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColors.primaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Padding(
              padding: EdgeInsets.all(AppConstants.spacing16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: AppColors.ctaPrimary,
                        size: 28,
                      ),
                      SizedBox(width: AppConstants.spacing12),
                      Text(
                        'Edit Vehicle',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacing20),

                  // Form Content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Required Fields Section
                          Text(
                            'Required Information',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppConstants.spacing12),

                          CustomTextField(
                            controller: licensePlateController,
                            label: 'License Plate *',
                            hintText: 'ABC-123',
                          ),
                          SizedBox(height: AppConstants.spacing16),

                          CustomTextField(
                            controller: makeController,
                            label: 'Make *',
                            hintText: 'Toyota, Honda, etc.',
                          ),
                          SizedBox(height: AppConstants.spacing16),

                          CustomTextField(
                            controller: modelController,
                            label: 'Model *',
                            hintText: 'Camry, Civic, etc.',
                          ),
                          SizedBox(height: AppConstants.spacing20),

                          // Optional Fields Section
                          Text(
                            'Optional Information',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppConstants.spacing12),

                          CustomTextField(
                            controller: colorController,
                            label: 'Color',
                            hintText: 'Blue, Red, etc.',
                          ),
                          SizedBox(height: AppConstants.spacing16),

                          CustomTextField(
                            controller: yearController,
                            label: 'Year',
                            hintText: '2020',
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: AppConstants.spacing20),

                          // Default Vehicle Option
                          Container(
                            padding: EdgeInsets.all(AppConstants.spacing12),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(AppConstants.radius12),
                              border: Border.all(
                                color: AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isDefault,
                                  onChanged: (value) {
                                    setState(() {
                                      isDefault = value ?? false;
                                    });
                                  },
                                  activeColor: AppColors.ctaPrimary,
                                ),
                                SizedBox(width: AppConstants.spacing8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Set as default vehicle',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: AppConstants.spacing4),
                                      Text(
                                        'This vehicle will be selected automatically for bookings',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppConstants.spacing24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radius8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppConstants.spacing12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final licensePlate = licensePlateController.text.trim();
                            final make = makeController.text.trim();
                            final model = modelController.text.trim();
                            final color = colorController.text.trim().isEmpty
                                ? null
                                : colorController.text.trim();
                            final year = yearController.text.trim().isEmpty
                                ? null
                                : int.tryParse(yearController.text.trim());

                            if (licensePlate.isEmpty || make.isEmpty || model.isEmpty) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(content: Text('Please fill in all required fields')),
                              );
                              return;
                            }

                            try {
                              await _vehicleService.updateVehicle(
                                vehicleId: vehicle.id,
                                licensePlate: licensePlate,
                                make: make,
                                model: model,
                                color: color,
                                year: year,
                                isDefault: isDefault,
                              );

                              if (mounted) {
                                await _loadVehicles();
                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vehicle updated successfully')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Failed to update vehicle: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ctaPrimary,
                            foregroundColor: AppColors.ctaOnPrimary,
                            padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radius8),
                            ),
                          ),
                          child: Text(
                            'Update Vehicle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryBackground,
        title: Text(
          'Delete Vehicle',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete ${vehicle.make} ${vehicle.model}?',
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
                await _vehicleService.deleteVehicle(vehicle.id);
                await _loadVehicles(); // Reload the list to reflect changes
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${vehicle.make} ${vehicle.model} deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete vehicle: $e')),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
