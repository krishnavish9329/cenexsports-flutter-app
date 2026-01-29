import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  String _getOrderDetailsText() {
    final buffer = StringBuffer();
    buffer.writeln('Order Details');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Order #${_order.id ?? 'N/A'}');
    buffer.writeln('Status: ${(_order.status ?? 'pending').toUpperCase()}');
    if (_order.dateCreated != null) {
      buffer.writeln('Date: ${_formatDate(_order.dateCreated!)}');
    }
    buffer.writeln('');
    buffer.writeln('Order Items:');
    for (var item in _order.lineItems) {
      buffer.writeln('• ${item.name ?? 'Product #${item.productId}'}');
      buffer.writeln('  Qty: ${item.quantity} × ₹${(item.price ?? 0).toStringAsFixed(0)} = ₹${((item.price ?? 0) * item.quantity).toStringAsFixed(0)}');
    }
    buffer.writeln('');
    buffer.writeln('Subtotal: ₹${_calculateSubtotal().toStringAsFixed(0)}');
    buffer.writeln('Tax: ₹${(_order.total != null ? (_order.total! - _calculateSubtotal()) : 0).toStringAsFixed(0)}');
    buffer.writeln('Total: ₹${_order.total?.toStringAsFixed(0) ?? '0'}');
    buffer.writeln('');
    buffer.writeln('Billing Address:');
    buffer.writeln('${_order.billing.firstName} ${_order.billing.lastName}');
    if (_order.billing.address1.isNotEmpty) buffer.writeln(_order.billing.address1);
    if (_order.billing.address2.isNotEmpty) buffer.writeln(_order.billing.address2);
    buffer.writeln('${_order.billing.city}, ${_order.billing.state} ${_order.billing.postcode}');
    if (_order.billing.phone.isNotEmpty) buffer.writeln('Phone: ${_order.billing.phone}');
    if (_order.billing.email.isNotEmpty) buffer.writeln('Email: ${_order.billing.email}');
    buffer.writeln('');
    buffer.writeln('Shipping Address:');
    buffer.writeln('${_order.shipping.firstName} ${_order.shipping.lastName}');
    if (_order.shipping.address1.isNotEmpty) buffer.writeln(_order.shipping.address1);
    if (_order.shipping.address2.isNotEmpty) buffer.writeln(_order.shipping.address2);
    buffer.writeln('${_order.shipping.city}, ${_order.shipping.state} ${_order.shipping.postcode}');
    buffer.writeln('');
    buffer.writeln('Payment Information:');
    buffer.writeln('Payment Method: ${_order.paymentMethodTitle ?? 'N/A'}');
    buffer.writeln('Status: ${_order.setPaid ? 'Paid' : 'Pending'}');
    return buffer.toString();
  }

  Future<void> _copyToClipboard() async {
    final text = _getOrderDetailsText();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order details copied to clipboard'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareViaWhatsApp() async {
    final text = _getOrderDetailsText();
    final encodedText = Uri.encodeComponent(text);
    final whatsappUrl = 'https://wa.me/?text=$encodedText';
    
    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp not installed'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _shareViaGmail() async {
    final text = _getOrderDetailsText();
    final subject = Uri.encodeComponent('Order #${_order.id ?? 'N/A'} Details');
    final body = Uri.encodeComponent(text);
    final gmailUrl = 'mailto:?subject=$subject&body=$body';
    
    try {
      final uri = Uri.parse(gmailUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email app not available'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Share Order Details',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.primaryColor),
              title: const Text('Copy to Clipboard'),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
              title: const Text('Share via WhatsApp'),
              onTap: () {
                Navigator.pop(context);
                _shareViaWhatsApp();
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFFEA4335)),
              title: const Text('Share via Gmail'),
              onTap: () {
                Navigator.pop(context);
                _shareViaGmail();
              },
            ),
            const SizedBox(height: AppTheme.spacingS),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order.id ?? 'N/A'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showShareOptions,
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
