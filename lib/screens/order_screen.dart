import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class OrderDashboardScreen extends StatefulWidget {
  const OrderDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OrderDashboardScreen> createState() => _OrderDashboardScreenState();
}

class _OrderDashboardScreenState extends State<OrderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');
  final DateFormat _timeFormatter = DateFormat('hh:mm a');

  String _selectedStatus = 'all';
  List<OrderModel> _filteredOrders = [];
  bool _isSearching = false;

  final List<String> _statusOptions = [
    'all',
    'placed',
    'delivered',
    'cancelled',
  ];

  final Map<String, String> _statusLabels = {
    'all': 'All Orders',
    'placed': 'Placed',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  final Map<String, Color> _statusColors = {
    'placed': Colors.blue,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusOptions.length, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    if (_searchController.text.isEmpty) {
      setState(() => _isSearching = false);
    } else {
      setState(() => _isSearching = true);
      _performSearch();
    }
  }

  void _performSearch() async {
    if (!mounted) return;
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final query = _searchController.text;
    final results = await provider.searchOrders(query);
    if (!mounted) return;
    setState(() => _filteredOrders = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildTabBar(),
          Expanded(child: _buildOrdersList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Order Management',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.analytics_outlined),
      //     onPressed: _showAnalytics,
      //   ),
      //   IconButton(
      //     icon: const Icon(Icons.more_vert),
      //     onPressed: _showMoreOptions,
      //   ),
      // ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search orders, products, or customer ID...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _isSearching = false);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Quick Stats Row
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        return StreamBuilder<List<OrderModel>>(
          stream: provider.streamOrders(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            final orders = snapshot.data!;
            final todayOrders = orders
                .where(
                  (o) => DateTime.now().difference(o.createdAt).inDays == 0,
                )
                .length;
            final pendingOrders = orders
                .where((o) => o.status == 'placed')
                .length;
            final totalRevenue = orders
                .where((o) => o.status == 'delivered')
                .fold(0.0, (sum, o) => sum + o.totalAmount);

            return Row(
              children: [
                _buildStatCard(
                  'Today',
                  todayOrders.toString(),
                  Icons.today,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Pending',
                  pendingOrders.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Revenue',
                  '₹${totalRevenue.toStringAsFixed(0)}',
                  Icons.payments,
                  Colors.green,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Theme.of(context).primaryColor,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedStatus = _statusOptions[index];
            _isSearching = false;
            _searchController.clear();
          });
        },
        tabs: _statusOptions
            .map((status) => Tab(text: _statusLabels[status]))
            .toList(),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_isSearching) {
      return _buildSearchResults();
    }

    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        return StreamBuilder<List<OrderModel>>(
          stream: provider.streamOrders(
            status: _selectedStatus == 'all' ? null : _selectedStatus,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading orders',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) => _buildOrderCard(orders[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_filteredOrders.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No orders found', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) => _buildOrderCard(_filteredOrders[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _selectedStatus == 'all'
                ? 'No orders yet'
                : 'No ${_statusLabels[_selectedStatus]?.toLowerCase()} orders',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders will appear here once customers start placing them.',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateFormatter.format(order.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 12),

              // Customer Info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'User ID: ${order.userId.substring(0, 8)}...',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items Preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    ...order.items
                        .take(2)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.count}x ${item.name}',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '₹${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    if (order.items.length > 2)
                      Text(
                        '+ ${order.items.length - 2} more items',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Total and Actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.savings != null && order.savings! > 0) ...[
                          Text(
                            '₹${order.originalAmount?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Row(
                          children: [
                            Text(
                              '₹${order.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                            if (order.savings != null && order.savings! > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Saved ₹${order.savings!.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showStatusUpdateDialog(order),
                        tooltip: 'Update Status',
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showOrderActions(order),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColors[status] ?? Colors.grey;
    final label = _statusLabels[status] ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(order: order),
    );
  }

  void _showStatusUpdateDialog(OrderModel order) {
    final BuildContext parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatusUpdateDialog(
        order: order,
        onStatusUpdate: (newStatus) async {
          if (!mounted) return;
          final provider = Provider.of<OrderProvider>(
            parentContext,
            listen: false,
          );
          await provider.updateOrderStatus(order.id, newStatus);
          if (!mounted) return;
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text(
                'Order status updated to ${_statusLabels[newStatus]}',
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOrderActions(OrderModel order) {
    final BuildContext parentContext = context;
    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) => OrderActionsSheet(
        order: order,
        onDelete: () async {
          if (!mounted) return;
          final provider = Provider.of<OrderProvider>(
            parentContext,
            listen: false,
          );
          await provider.deleteOrder(order.id);
          // Close the bottom sheet
          Navigator.pop(parentContext);
          if (!mounted) return;
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('Order deleted successfully')),
          );
        },
      ),
    );
  }

  void _showAnalytics() {
    // Implement analytics view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics feature coming soon!')),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Orders'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
        ],
      ),
    );
  }
}

// Order Details Dialog
class OrderDetailsDialog extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsDialog({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Info
                    _buildInfoRow('Order ID', order.id),
                    _buildInfoRow('Customer ID', order.userId),
                    _buildInfoRow('Status', order.status),
                    _buildInfoRow(
                      'Created At',
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(order.createdAt),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Items List
                    ...order.items
                        .map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Quantity: ${item.quantity} × ${item.count}',
                                ),
                                Text(
                                  'Price: ₹${item.price.toStringAsFixed(2)} each',
                                ),
                                Text(
                                  'Total: ₹${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (item.savings > 0)
                                  Text(
                                    'Savings: ₹${item.savings.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                              ],
                            ),
                          ),
                        )
                        .toList(),

                    const SizedBox(height: 20),

                    // Total Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (order.originalAmount != null &&
                              order.originalAmount! > order.totalAmount)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Original Amount'),
                                Text(
                                  '₹${order.originalAmount!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          if (order.savings != null && order.savings! > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Savings',
                                  style: TextStyle(color: Colors.green),
                                ),
                                Text(
                                  '₹${order.savings!.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${order.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Delivery Address if available
                    if (order.deliveryAddress != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(order.deliveryAddress.toString()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// Status Update Dialog
class StatusUpdateDialog extends StatefulWidget {
  final OrderModel order;
  final Function(String) onStatusUpdate;

  const StatusUpdateDialog({
    Key? key,
    required this.order,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  State<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  late String _selectedStatus;

  final List<String> _statuses = ['placed', 'delivered', 'cancelled'];

  final Map<String, String> _statusLabels = {
    'placed': 'Placed',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Order Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Order #${widget.order.id.substring(0, 8).toUpperCase()}'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: _statuses
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(_statusLabels[status] ?? status),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStatus = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onStatusUpdate(_selectedStatus);
            Navigator.pop(context);
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

// Order Actions Bottom Sheet
class OrderActionsSheet extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onDelete;

  const OrderActionsSheet({
    Key? key,
    required this.order,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text(
            'Delete Order',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () {
            // Show confirmation dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Order'),
                content: const Text(
                  'Are you sure you want to delete this order? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      onDelete();
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
