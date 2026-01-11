import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/order_model.dart';
import '../../data/models/billing_model.dart';
import '../../data/models/shipping_model.dart';

/// Order Detail Page - Shows invoice/bill for a single order
class OrderDetailPage extends StatelessWidget {
  final OrderModel order;

  const OrderDetailPage({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id ?? 'N/A'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share order/invoice
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            _buildOrderSummaryCard(),
            const SizedBox(height: AppTheme.spacingM),
            
            // Order Items
            _buildOrderItems(),
            const SizedBox(height: AppTheme.spacingM),
            
            // Billing Address
            _buildAddressSection('Billing Address', order.billing),
            const SizedBox(height: AppTheme.spacingM),
            
            // Shipping Address
            _buildAddressSection('Shipping Address', order.shipping),
            const SizedBox(height: AppTheme.spacingM),
            
            // Payment Info
            _buildPaymentInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id ?? 'N/A'}',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order.status ?? 'pending'),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            if (order.dateCreated != null)
              Text(
                'Date: ${_formatDate(order.dateCreated!)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            const Divider(),
            const SizedBox(height: AppTheme.spacingS),
            _buildPriceRow('Subtotal', _calculateSubtotal()),
            _buildPriceRow('Tax', order.total != null ? (order.total! - _calculateSubtotal()) : 0),
            const Divider(),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${order.total?.toStringAsFixed(0) ?? '0'}',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            ...order.lineItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name ?? 'Product #${item.productId}',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Qty: ${item.quantity}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${((item.price ?? 0) * item.quantity).toStringAsFixed(0)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(String title, dynamic address) {
    final isBilling = address is BillingModel;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              '${address.firstName} ${address.lastName}',
              style: AppTextStyles.bodyLarge,
            ),
            if (address.address1.isNotEmpty)
              Text(
                address.address1,
                style: AppTextStyles.bodyMedium,
              ),
            if (address.address2.isNotEmpty)
              Text(
                address.address2,
                style: AppTextStyles.bodyMedium,
              ),
            Text(
              '${address.city}, ${address.state} ${address.postcode}',
              style: AppTextStyles.bodyMedium,
            ),
            if (isBilling && address.phone.isNotEmpty)
              Text(
                'Phone: ${address.phone}',
                style: AppTextStyles.bodyMedium,
              ),
            if (isBilling && address.email.isNotEmpty)
              Text(
                'Email: ${address.email}',
                style: AppTextStyles.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Information',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildInfoRow('Payment Method', order.paymentMethodTitle),
            _buildInfoRow('Status', order.setPaid ? 'Paid' : 'Pending'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppTheme.successColor;
        break;
      case 'processing':
        color = AppTheme.warningColor;
        break;
      case 'cancelled':
      case 'refunded':
        color = AppTheme.errorColor;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  double _calculateSubtotal() {
    return order.lineItems.fold(
      0.0,
      (sum, item) => sum + ((item.price ?? 0) * item.quantity),
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
