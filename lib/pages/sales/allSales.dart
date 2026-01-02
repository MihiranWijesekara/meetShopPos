import 'package:chicken_dilivery/Model/salesModel.dart';
import 'package:chicken_dilivery/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Allsales extends StatefulWidget {
  final int month;
  const Allsales({super.key, required this.month});

  @override
  State<Allsales> createState() => _AllsalesState();
}

class _AllsalesState extends State<Allsales> {
  List<Salesmodel> sales = [];
  List<Salesmodel> filteredSales = [];
  bool isLoading = false;

  List<Map<String, dynamic>> _items = [];
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  // ✅ Year selector (default current year)
  int _selectedYear = DateTime.now().year;

  int _currentPage = 0;
  final int _pageSize = 30;

  // For expansion state
  final Set<String> _expandedBills = {};

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _loadItems();
    _loadStocks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await DatabaseHelper.instance.getAllItems();
    if (!mounted) return;
    setState(() {
      _items = items.map((item) => {'id': item.id, 'name': item.name}).toList();
    });
  }

  // ✅ Loads sales by (month + year)
  Future<void> _loadStocks() async {
    setState(() => isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getSalesByMonthAndYear(
        widget.month,
        _selectedYear,
      );

      if (!mounted) return;
      setState(() {
        sales = data.map((map) => Salesmodel.fromMap(map)).toList();
        filteredSales = List.from(sales);
        isLoading = false;
        _expandedBills.clear();
        _currentPage = 0;
      });

      // Apply current filters again (date/search)
      _filterSales();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading sales: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Group sales by billNo
  Map<String, List<Salesmodel>> get _groupedSales {
    final Map<String, List<Salesmodel>> grouped = {};
    for (final sale in filteredSales) {
      final key =
          '${sale.billNo ?? ''}|${sale.addedDate ?? ''}|${sale.shopName ?? ''}';
      grouped.putIfAbsent(key, () => []).add(sale);
    }
    return grouped;
  }

  // Get item name by ID
  String _getItemName(int? itemId) {
    if (itemId == null) return 'Unknown';
    final item = _items.firstWhere(
      (item) => item['id'] == itemId,
      orElse: () => {'name': 'Item $itemId'},
    );
    return item['name'];
  }

  void _filterSales() {
    if (!mounted) return;
    setState(() {
      filteredSales = sales.where((sale) {
        final q = _searchController.text.trim().toLowerCase();

        final matchesSearch =
            q.isEmpty ||
            (sale.shopName?.toLowerCase().contains(q) ?? false) ||
            (sale.billNo?.toString().contains(q) ?? false);

        final matchesDate =
            _selectedDate == null ||
            (sale.addedDate != null &&
                _isSameDate(sale.addedDate!, _selectedDate!));

        return matchesSearch && matchesDate;
      }).toList();

      _currentPage = 0;
    });
  }

  bool _isSameDate(String dateString, DateTime selectedDate) {
    try {
      // Handles "DD/MM/YYYY" and "D/M/YYYY"
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return day == selectedDate.day &&
            month == selectedDate.month &&
            year == selectedDate.year;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  String _formatDDMMYYYY(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  void _editItem(Salesmodel sale) async {
    int? selectedItemId = sale.itemId;
    final shopController = TextEditingController(text: sale.shopName ?? '');
    final billController = TextEditingController(
      text: sale.billNo?.toString() ?? '',
    );
    final quantityController = TextEditingController(
      text: sale.quantityKg?.toString() ?? '',
    );
    final rateController = TextEditingController(
      text: sale.sellingPrice.toString(),
    );
    final amountController = TextEditingController(
      text: (sale.amount ?? (sale.sellingPrice * (sale.quantityKg ?? 0)))
          .toString(),
    );
    final dateController = TextEditingController(text: sale.addedDate ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Sale'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: billController,
                  decoration: const InputDecoration(
                    labelText: 'Bill No',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shopController,
                  decoration: const InputDecoration(
                    labelText: 'Shop Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedItemId,
                  decoration: const InputDecoration(
                    labelText: 'Item',
                    border: OutlineInputBorder(),
                  ),
                  items: _items.map((item) {
                    return DropdownMenuItem<int>(
                      value: item['id'],
                      child: Text(item['name']),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedItemId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (grams)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() {
                    final qty = double.tryParse(quantityController.text) ?? 0;
                    final rate = double.tryParse(rateController.text) ?? 0;
                    amountController.text = (qty * rate).toStringAsFixed(2);
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(
                    labelText: 'Selling Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() {
                    final qty = double.tryParse(quantityController.text) ?? 0;
                    final rate = double.tryParse(rateController.text) ?? 0;
                    amountController.text = (qty * rate).toStringAsFixed(2);
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        dateController.text = _formatDDMMYYYY(picked);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedItemId == null) return;

                final updateData = {
                  'id': sale.id,
                  'bill_no': billController.text.trim(),
                  'shop_id': sale.shopId,
                  'item_id': selectedItemId,
                  'selling_price': int.tryParse(rateController.text) ?? 0,
                  'quantity_kg': int.tryParse(quantityController.text),
                  'amount': double.tryParse(amountController.text),
                  'Vat_Number': sale.vatNumber,
                  'added_date': dateController.text,
                };

                await DatabaseHelper.instance.updateSale(sale.id!, updateData);
                if (!mounted) return;
                Navigator.pop(context);
                await _loadStocks();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sale updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteItem(Salesmodel sale) {
    final id = sale.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: missing id'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sale'),
        content: Text('Delete sale for ${sale.shopName ?? 'shop'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final rows = await DatabaseHelper.instance.deleteSale(id);
              if (!mounted) return;
              Navigator.pop(context);
              if (rows > 0) {
                await _loadStocks();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sale deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _filterSales();
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
    _filterSales();
  }

  List<MapEntry<String, List<Salesmodel>>> get _pagedGroupedSales {
    final entries = _groupedSales.entries.toList();
    final start = _currentPage * _pageSize;
    return entries.skip(start).take(_pageSize).toList();
  }

  int get _totalPages {
    final total = _groupedSales.length;
    if (total == 0) return 1;
    return ((total + _pageSize - 1) / _pageSize).floor();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 26, 11, 167),
                Color.fromARGB(255, 21, 5, 196),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      Text(
                        'All Sales - Month: ${widget.month} / $_selectedYear',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Filters
            Row(
              children: [
                // ✅ Year dropdown
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        isExpanded: true,
                        items: List.generate(10, (i) {
                          final year = DateTime.now().year - i;
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(
                              'Year: $year',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }),
                        onChanged: (v) async {
                          if (v == null) return;
                          setState(() => _selectedYear = v);
                          await _loadStocks();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Date Filter
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedDate == null
                                  ? 'Date'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedDate == null
                                    ? Colors.grey[400]
                                    : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_selectedDate != null)
                                InkWell(
                                  onTap: _clearDate,
                                  child: Icon(
                                    Icons.clear,
                                    color: Colors.grey[600],
                                    size: 16,
                                  ),
                                ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.calendar_today,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Search Bar
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 5, 0, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _filterSales(),
                      decoration: InputDecoration(
                        hintText: 'Search by shop name, bill number',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 26, 11, 167),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredSales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No sales available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _pagedGroupedSales.length,
                      itemBuilder: (context, index) {
                        final entry = _pagedGroupedSales[index];
                        final billKey = entry.key;
                        final billSales = entry.value;
                        final firstSale = billSales.first;
                        final isExpanded = _expandedBills.contains(billKey);

                        final totalAmount = billSales.fold<double>(
                          0,
                          (sum, sale) => sum + (sale.amount ?? 0),
                        );
                        final totalItems = billSales.length;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedBills.remove(billKey);
                                    } else {
                                      _expandedBills.add(billKey);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            255,
                                            26,
                                            11,
                                            167,
                                          ).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.receipt,
                                          color: Color.fromARGB(
                                            255,
                                            26,
                                            11,
                                            167,
                                          ),
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Bill #${firstSale.billNo ?? 'N/A'}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    firstSale.shopName ??
                                                        'Unknown Shop',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '$totalItems items',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.green[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 10,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  firstSale.addedDate ?? 'N/A',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  'Total: ${totalAmount.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: Colors.grey[600],
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (isExpanded) ...[
                                Divider(height: 1, color: Colors.grey[300]),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'Item',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 70,
                                              child: Text(
                                                'Qty',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 55,
                                              child: Text(
                                                'Rate',
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 70,
                                              child: Text(
                                                'Amount',
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 70,
                                              child: Text(
                                                'Action',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      ...billSales.map((sale) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          margin: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  _getItemName(sale.itemId),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 70,
                                                child: Text(
                                                  '${((sale.quantityKg ?? 0) / 1000).toStringAsFixed(2)} kg',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 55,
                                                child: Text(
                                                  sale.sellingPrice.toString(),
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 70,
                                                child: Text(
                                                  (sale.amount ?? 0)
                                                      .toStringAsFixed(2),
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 70,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    InkWell(
                                                      onTap: () =>
                                                          _editItem(sale),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.edit_outlined,
                                                          color: Colors.blue,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    InkWell(
                                                      onTap: () =>
                                                          _deleteItem(sale),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.delete_outline,
                                                          color: Colors.red,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Pagination
            if (!isLoading && filteredSales.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 0
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                    ),
                    Text(
                      'Page ${_currentPage + 1} of $_totalPages',
                      style: const TextStyle(fontSize: 14),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _totalPages - 1
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
