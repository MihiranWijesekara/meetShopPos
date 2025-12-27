import 'package:chicken_dilivery/Model/salesModel.dart';
import 'package:chicken_dilivery/database/database_helper.dart';
import 'package:chicken_dilivery/pages/sales/addSales.dart';
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
  bool isLoading = false;
  List<Map<String, dynamic>> _items = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadStocks();
  }

  Future<void> _loadItems() async {
    final items = await DatabaseHelper.instance.getAllItems();
    setState(() {
      _items = items.map((item) => {'id': item.id, 'name': item.name}).toList();
    });
  }

  String _formatDateYear(String date) {
    if (date.isEmpty || date.length < 10) return '';
    return date.substring(0, 4); // Returns year (YYYY)
  }

  String _formatDateDayMonth(String date) {
    if (date.isEmpty || date.length < 10) return '';
    return date.substring(5, 10).replaceAll('-', '/'); // Returns MM/DD
  }

  Future<void> _loadStocks() async {
    setState(() => isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getSalesByMonths(widget.month);
      print('Loaded sales data: $data');
      setState(() {
        sales = data.map((map) => Salesmodel.fromMap(map)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading sales: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editItem(int index) async {
    final sale = sales[index];

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
                    labelText: 'Quantity (Kg)',
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
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        dateController.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
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

                // Create map without shop_name
                final updateData = {
                  'id': sale.id,
                  'bill_no': billController.text.trim(),
                  'shop_id': sale.shopId, // Keep original shop_id
                  'item_id': selectedItemId!,
                  'selling_price': int.tryParse(rateController.text) ?? 0,
                  'quantity_kg': int.tryParse(quantityController.text),
                  'amount': double.tryParse(amountController.text),
                  'Vat_Number': sale.vatNumber,
                  'added_date': dateController.text,
                };

                await DatabaseHelper.instance.updateSale(sale.id!, updateData);
                Navigator.pop(context);
                await _loadStocks();
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

  void _deleteItem(int index) {
    final sale = sales[index];
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
              Navigator.pop(context);
              if (rows > 0) {
                await _loadStocks();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sale deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delete failed'),
                    backgroundColor: Colors.orange,
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
      setState(() {
        _selectedDate = picked;
      });
      // Optionally, you can trigger a search or filter function here
      // _searchSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 26, 11, 167),
                const Color.fromARGB(255, 21, 5, 196),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 40),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Sales - Month: ${widget.month}',
                                style: TextStyle(
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
            Row(
              children: [
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
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey[600],
                            size: 18,
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
                          borderSide: BorderSide(
                            color: const Color.fromARGB(255, 26, 11, 167),
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

            // Table Header
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        'Bill',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Shop Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: Text(
                        'Item',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        'KG',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        'Rate',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(
                      width: 55,
                      child: Text(
                        'Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        'Action',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Table Body
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: sales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No items available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: sales.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Colors.grey[200]),
                        itemBuilder: (context, index) {
                          final saless = sales[index];
                          String formattedDate = '';
                          if (saless.addedDate != null &&
                              saless.addedDate!.toString().length >= 10) {
                            formattedDate = saless.addedDate!
                                .toString()
                                .substring(5, 10)
                                .replaceAll('-', '/');
                          } else {
                            formattedDate = 'N/A';
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    saless.billNo?.toString() ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 42,
                                  child: Text(
                                    saless.addedDate != null &&
                                            saless.addedDate!.isNotEmpty
                                        ? (() {
                                            final parts = saless.addedDate!
                                                .split('/');
                                            if (parts.length == 3) {
                                              final day = parts[0].padLeft(
                                                2,
                                                '0',
                                              );
                                              final month = parts[1].padLeft(
                                                2,
                                                '0',
                                              );
                                              return '$day/$month';
                                            }
                                            return saless.addedDate!;
                                          })()
                                        : 'N/A',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    saless.shopName ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    saless.shortCode ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    saless.quantityKg?.toString() ?? '0',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                SizedBox(
                                  width: 42,
                                  child: Text(
                                    saless.sellingPrice.toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                SizedBox(
                                  width: 55,
                                  child: Text(
                                    saless.amount?.toString() ?? '0',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      InkWell(
                                        onTap: () => _editItem(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            color: Colors.blue,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      InkWell(
                                        onTap: () => _deleteItem(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
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
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
