import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/order_model.dart';
import 'order_history_page.dart';
import '../../pages/main_navigation.dart';

class OrderSuccessPage extends StatelessWidget {
  final OrderModel order;

  const OrderSuccessPage({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              // Success Message
              Text(
                'Order Placed Successfully!',
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              Text(
                'Thank you for your purchase. Your order has been received and is being processed.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              // Order Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: AppTextStyles.h4,
                      ),
                      const Divider(),
                      const SizedBox(height: AppTheme.spacingM),
                      
                      _buildDetailRow('Order ID', '#${order.id ?? 'N/A'}'),
                      if (order.orderKey != null)
                        _buildDetailRow('Order Key', order.orderKey!),
                      if (order.status != null)
                        _buildDetailRow(
                          'Status',
                          order.status!.toUpperCase(),
                          valueColor: AppTheme.successColor,
                        ),
                      if (order.dateCreated != null)
                        _buildDetailRow(
                          'Date',
                          _formatDate(order.dateCreated!),
                        ),
                      if (order.total != null)
                        _buildDetailRow(
                          'Total Amount',
                          '₹${order.total!.toStringAsFixed(0)}',
                          valueStyle: AppTextStyles.h4.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (order.paymentMethodTitle.isNotEmpty)
                        _buildDetailRow(
                          'Payment Method',
                          order.paymentMethodTitle,
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              // Billing Address Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            'Billing Address',
                            style: AppTextStyles.h4,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        order.billing.fullName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.billing.fullAddress,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${order.billing.email}',
                        style: AppTextStyles.bodySmall,
                      ),
                      Text(
                        'Phone: ${order.billing.phone}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to home and clear navigation stack
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const MainNavigation(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Continue Shopping'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderHistoryPage(),
                    ),
                  );
                },
                child: const Text('View Order History'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
