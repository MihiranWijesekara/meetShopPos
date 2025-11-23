import 'package:chicken_dilivery/Model/ItemModel.dart';
import 'package:chicken_dilivery/Model/StockModel.dart';
import 'package:chicken_dilivery/database/database_helper.dart';
import 'package:chicken_dilivery/pages/stock/addStock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Allstock extends StatefulWidget {
  const Allstock({super.key});

  @override
  State<Allstock> createState() => _AllstockState();
}

class _AllstockState extends State<Allstock> {
  List<StockModel> stocks = [];
  List<StockModel> filteredStocks = [];
  List<ItemModel> _items = [];
  bool isLoading = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadStocks();
  }

  Future<void> _loadItems() async {
    try {
      final data = await DatabaseHelper.instance.getAllItems();
      setState(() => _items = data);
    } catch (_) {}
  }

  Future<void> _loadStocks() async {
    setState(() => isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getAllStock(); // NEW method
      setState(() {
        stocks = data;
        _applyDateFilter();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading stocks: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyDateFilter() {
    if (_selectedDate == null) {
      filteredStocks = stocks;
    } else {
      final targetDate = '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
      filteredStocks = stocks.where((s) => s.added_date == targetDate).toList();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _applyDateFilter();
      });
    }
  }

  void _editStock(int index) async {
    final stock = filteredStocks[index];

    int? selectedItemId = stock.item_id;
    final qtyController = TextEditingController(text: stock.QTY?.toString() ?? '');
    final weightController = TextEditingController(text: stock.quantity_kg?.toString() ?? '');
    final rateController = TextEditingController(text: stock.stock_price.toString());
    final amountController = TextEditingController(
        text: (stock.amount ?? (stock.stock_price * (stock.quantity_kg ?? 0))).toString());
    final remainController = TextEditingController(text: stock.remain_quantity?.toString() ?? '');
    final dateController = TextEditingController(text: stock.added_date ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Stock'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedItemId,
                  decoration: const InputDecoration(
                    labelText: 'Item',
                    border: OutlineInputBorder(),
                  ),
                  items: _items.map((item) {
                    return DropdownMenuItem<int>(
                      value: item.id,
                      child: Text(item.name),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedItemId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  decoration: const InputDecoration(
                    labelText: 'QTY',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (Kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() {
                    final w = int.tryParse(weightController.text) ?? 0;
                    final r = double.tryParse(rateController.text) ?? 0;
                    amountController.text = (w * r).toStringAsFixed(2);
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(
                    labelText: 'Rate',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() {
                    final w = int.tryParse(weightController.text) ?? 0;
                    final r = double.tryParse(rateController.text) ?? 0;
                    amountController.text = (w * r).toStringAsFixed(2);
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
                  controller: remainController,
                  decoration: const InputDecoration(
                    labelText: 'Remain Stock',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
                        dateController.text = '${picked.day}/${picked.month}/${picked.year}';
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
                final updated = StockModel(
                  id: stock.id,
                  item_id: selectedItemId!,
                  stock_price: int.tryParse(rateController.text) ?? stock.stock_price,
                  quantity_kg: int.tryParse(weightController.text),
                  remain_quantity: double.tryParse(remainController.text),
                  amount: double.tryParse(amountController.text),
                  QTY: double.tryParse(qtyController.text),
                  added_date: dateController.text,
                );
                await DatabaseHelper.instance.updateStock(updated);
                Navigator.pop(context);
                await _loadStocks();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stock updated'), backgroundColor: Colors.green),
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
    final stock = filteredStocks[index];
    final id = stock.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: missing id'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stock'),
        content: Text('Delete ${stock.item_name ?? 'item'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final rows = await DatabaseHelper.instance.deleteStock(id);
              Navigator.pop(context);
              if (rows > 0) {
                await _loadStocks();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stock deleted'), backgroundColor: Colors.red),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete failed'), backgroundColor: Colors.orange),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 40),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'All Stocks',
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
              child: Column(
                children: [
                  // Date Picker only
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedDate == null ? Colors.grey[400] : Colors.black87,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            'Item Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            'QTY',
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
                            'Weight',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 40,
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
                          width: 50,
                          child: Text(
                            'Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 45,
                          child: Text(
                            'R-Stock',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
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
                              fontSize: 10,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredStocks.isEmpty
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
                            itemCount: filteredStocks.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            itemBuilder: (context, index) {
                              final stock = filteredStocks[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        stock.item_name ?? '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        stock.QTY?.toString() ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 42,
                                      child: Text(
                                        stock.quantity_kg?.toString() ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        stock.stock_price.toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        stock.amount?.toStringAsFixed(0) ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 45,
                                      child: Text(
                                        stock.remain_quantity?.toString() ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 48,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatDateYear(stock.added_date ?? ''),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                          Text(
                                            _formatDateDayMonth(stock.added_date ?? ''),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          InkWell(
                                            onTap: () => _editStock(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(
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
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStockPage()));
          if (result == true) await _loadStocks();
        },
        backgroundColor: const Color.fromARGB(255, 224, 237, 51),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Stock',
          style: TextStyle(
            color: Color.fromARGB(255, 18, 16, 16),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _formatDateYear(String date) {
    if (date.isEmpty) return '';
    final parts = date.split('/');
    if (parts.length != 3) return date;
    return parts[2];
  }

  String _formatDateDayMonth(String date) {
    if (date.isEmpty) return '';
    final parts = date.split('/');
    if (parts.length != 3) return date;
    return '${parts[0]}/${parts[1]}';
  }
}