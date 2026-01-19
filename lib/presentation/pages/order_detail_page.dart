import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/order_model.dart';
import '../../data/models/billing_model.dart';
import '../../data/models/shipping_model.dart';

import '../../data/services/order_api_service.dart';
import '../../presentation/pages/order_history_page.dart';

/// Order Detail Page - Shows invoice/bill for a single order
class OrderDetailPage extends StatefulWidget {
  final OrderModel order;

  const OrderDetailPage({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late OrderModel _order;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep Order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isCancelling = true;
      });

      try {
        final apiService = OrderApiService();
        final updatedOrder = await apiService.cancelOrder(_order.id!);
        
        setState(() {
          _order = updatedOrder;
          _isCancelling = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isCancelling = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order.id ?? 'N/A'}'),
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
            _buildAddressSection('Billing Address', _order.billing),
            const SizedBox(height: AppTheme.spacingM),
            
            // Shipping Address
            _buildAddressSection('Shipping Address', _order.shipping),
            const SizedBox(height: AppTheme.spacingM),
            
            // Payment Info
            _buildPaymentInfo(),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Cancel Button
            if (_order.status == 'pending' || _order.status == 'processing')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCancelling ? null : _cancelOrder,
                  icon: _isCancelling 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cancel_outlined),
                  label: Text(_isCancelling ? 'Cancelling...' : 'Cancel Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
            const SizedBox(height: AppTheme.spacingXL),
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
                  'Order #${_order.id ?? 'N/A'}',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(_order.status ?? 'pending'),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            if (_order.dateCreated != null)
              Text(
                'Date: ${_formatDate(_order.dateCreated!)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            const Divider(),
            const SizedBox(height: AppTheme.spacingS),
            _buildPriceRow('Subtotal', _calculateSubtotal()),
            _buildPriceRow('Tax', _order.total != null ? (_order.total! - _calculateSubtotal()) : 0),
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
                  '₹${_order.total?.toStringAsFixed(0) ?? '0'}',
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
            const SizedBox(height: AppTheme.spacingM),
            ..._order.lineItems.map((item) => Padding(
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
            _buildInfoRow('Payment Method', _order.paymentMethodTitle),
            _buildInfoRow('Status', _order.setPaid ? 'Paid' : 'Pending'),
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
    return _order.lineItems.fold(
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
