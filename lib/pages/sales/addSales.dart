import 'package:chicken_dilivery/Model/CartItemModel.dart';
import 'package:chicken_dilivery/Model/ItemModel.dart';
import 'package:chicken_dilivery/Model/RootModel.dart';
import 'package:chicken_dilivery/Model/ShopModel.dart';
import 'package:chicken_dilivery/Model/salesModel.dart';
import 'package:chicken_dilivery/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chicken_dilivery/bluthooth/printer_service.dart'; // Add this import

class Addsales extends StatefulWidget {
  const Addsales({super.key});

  @override
  State<Addsales> createState() => _AddsalesState();
}

class _AddsalesState extends State<Addsales> {
  final _formKey = GlobalKey<FormState>();
  final _sellingRateController = TextEditingController();
  final _weightController = TextEditingController();
  final _billNumberController = TextEditingController();
  final _vatController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedItemId;

  // Cart items list
  List<CartItem> _cartItems = [];

  // Items state
  List<ItemModel> _items = [];
  bool _isLoadingItems = true;

  // Root + shops state
  List<RootModel> _roots = [];
  List<Shopmodel> _shops = [];
  int? _selectedRootId;
  Shopmodel? _selectedShop;
  bool _isLoadingRoots = true;
  bool _isLoadingShops = true;
  bool _isGeneratingBillNumber = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadRoots();
    _loadShops();
    _generateBillNumber();
    _selectedDate = DateTime.now();
    _dateController.text =
        '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
  }

  @override
  void dispose() {
    _sellingRateController.dispose();
    _weightController.dispose();
    _billNumberController.dispose();
    _vatController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await DatabaseHelper.instance.getAllItems();
      setState(() {
        _items = items;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() => _isLoadingItems = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading items: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadRoots() async {
    try {
      final roots = await DatabaseHelper.instance.getAllRoots();
      setState(() {
        _roots = roots;
        _isLoadingRoots = false;
      });
    } catch (e) {
      setState(() => _isLoadingRoots = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading roots: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadShops() async {
    try {
      final shops = await DatabaseHelper.instance.getAllShops();
      setState(() {
        _shops = shops;
        _isLoadingShops = false;
      });
    } catch (e) {
      setState(() => _isLoadingShops = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading shops: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _onItemSelected(int? itemId) {
    if (itemId == null) return;
    final selectedItem = _items.firstWhere((item) => item.id == itemId);
    setState(() {
      _selectedItemId = itemId;
      _sellingRateController.text = selectedItem.price.toStringAsFixed(2);
    });
  }

  Future<void> _generateBillNumber() async {
    try {
      final billNo = await DatabaseHelper.instance.getNextBillNumber();
      setState(() {
        _billNumberController.text = billNo;
        _isGeneratingBillNumber = false;
      });
    } catch (e) {
      setState(() => _isGeneratingBillNumber = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating bill number: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addToCart() {
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_sellingRateController.text.isEmpty ||
        _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter selling price and weight'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedItem = _items.firstWhere((item) => item.id == _selectedItemId);
    final sellingPrice = double.parse(_sellingRateController.text);
    final weight = double.parse(_weightController.text);
    final amount = sellingPrice * weight;

    setState(() {
      _cartItems.add(CartItem(
        itemId: _selectedItemId!,
        itemName: selectedItem.name,
        sellingPrice: sellingPrice,
        weight: weight,
        amount: amount,
      ));

      // Clear fields
      _selectedItemId = null;
      _sellingRateController.clear();
      _weightController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedItem.name} added to cart'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateCartItem(int index, double newWeight) {
    setState(() {
      _cartItems[index].weight = newWeight;
      _cartItems[index].amount = _cartItems[index].sellingPrice * newWeight;
    });
  }

  double get _totalAmount {
    return _cartItems.fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> _saveAllSales() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Add items first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shop'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final billNumber = _billNumberController.text;
      final date = _dateController.text;
      final vatNumber = _vatController.text;

      // Save each cart item to database
      for (var cartItem in _cartItems) {
        final newSales = Salesmodel(
          billNo: billNumber,
          shopId: _selectedShop!.id,
          itemId: cartItem.itemId,
          sellingPrice: cartItem.sellingPrice.toInt(),
          quantityKg: cartItem.weight.toInt(),
          amount: cartItem.amount,
          vatNumber: vatNumber,
          addedDate: date,
        );

        await DatabaseHelper.instance.insertSaleFIFO(newSales.toMap());
      }

      // Generate and print the bill
      await PrinterService.printReceipt(
        shopName: _selectedShop!.Shopname,
        billNo: billNumber,
        date: date,
        cartItems: _cartItems,
        totalAmount: _totalAmount,
        rootName: _selectedRootId != null ? _roots.firstWhere((root) => root.id == _selectedRootId!).name : '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sales saved and bill printed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear cart and reset
      setState(() {
        _cartItems.clear();
        _selectedShop = null;
        _selectedRootId = null;
        _vatController.clear();
      });

      // Generate new bill number for next sale
      _generateBillNumber();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving sales: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: const Color.fromARGB(255, 26, 11, 167),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Sales',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Info Section
            _buildSectionHeader('Bill Information'),
            const SizedBox(height: 10),
            _buildBillNumberField(),
            const SizedBox(height: 10),
            _buildDateField(),
            const SizedBox(height: 18),

            // Shop Selection Section
            _buildSectionHeader('Shop Details'),
            const SizedBox(height: 10),
            _buildRootField(),
            const SizedBox(height: 10),
            _buildShopField(),
            const SizedBox(height: 10),
            _buildVatField(),
            const SizedBox(height: 18),

            // Item Entry Section
            _buildSectionHeader('Add Items'),
            const SizedBox(height: 10),
            _buildItemField(),
            const SizedBox(height: 10),
            _buildSellingPriceField(),
            const SizedBox(height: 10),
            _buildWeightField(),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart, size: 19),
                label: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 26, 11, 167),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Cart Summary Section
            _buildSectionHeader('Cart'),
            const SizedBox(height: 10),
            _cartItems.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(
                          'Cart is empty',
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) => _buildCartItem(index),
                  ),
            const SizedBox(height: 20),

            // Total and Save Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RS ${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 26, 11, 167),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveAllSales,
                      icon: const Icon(Icons.save, size: 20), // smaller icon
                      label: const Text(
                        'Complete Sale',
                        style: TextStyle(
                          fontSize: 16, // reduced font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10), // reduced padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color.fromARGB(255, 26, 11, 167),
      ),
    );
  }

  Widget _buildBillNumberField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bill No.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _isGeneratingBillNumber
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : TextFormField(
                    controller: _billNumberController,
                    readOnly: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRootField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Root',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _selectedRootId,
              items: _roots
                  .map((r) => DropdownMenuItem<int>(
                        value: r.id,
                        child: Text(r.name),
                      ))
                  .toList(),
              decoration: InputDecoration(
                hintText: 'Select root',
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onChanged: (val) {
                setState(() {
                  _selectedRootId = val;
                  _selectedShop = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shop Name',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Autocomplete<Shopmodel>(
              displayStringForOption: (s) => s.Shopname,
              optionsBuilder: (TextEditingValue text) {
                if (_selectedRootId == null) return const Iterable<Shopmodel>.empty();
                final query = text.text.toLowerCase();
                return _shops.where((shop) {
                  final matchesRoot = shop.rootId == _selectedRootId;
                  final matchesQuery =
                      query.isEmpty || shop.Shopname.toLowerCase().contains(query);
                  return matchesRoot && matchesQuery;
                });
              },
              onSelected: (shop) {
                setState(() => _selectedShop = shop);
              },
              fieldViewBuilder: (context, textController, focusNode, onSubmit) {
                return TextFormField(
                  controller: textController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: _selectedRootId == null
                        ? 'Select root first'
                        : 'Search shop name',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  enabled: _selectedRootId != null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVatField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VAT Number',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _vatController,
              decoration: InputDecoration(
                hintText: 'Enter VAT number',
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Item Name',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _selectedItemId,
              onChanged: _onItemSelected,
              decoration: InputDecoration(
                hintText: 'Select Item',
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              items: _items
                  .map((item) => DropdownMenuItem<int>(
                        value: item.id,
                        child: Text(item.name),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellingPriceField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price (RS/kg)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sellingRateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'RS ',
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weight (kg)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.00',
                suffixText: 'kg',
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final item = _cartItems[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8), // less margin
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6), // smaller radius
      ),
      child: Padding(
        padding: const EdgeInsets.all(8), // less padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                      fontSize: 13, // reduced font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), // smaller icon
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _removeFromCart(index),
                ),
              ],
            ),
            const SizedBox(height: 4), // less spacing
            Row(
              children: [
                Text(
                  'RS ${item.sellingPrice.toStringAsFixed(2)}/kg',
                  style: TextStyle(
                    fontSize: 11, // reduced font size
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 10), // less spacing
                Text(
                  '× ${item.weight.toStringAsFixed(2)} kg',
                  style: TextStyle(
                    fontSize: 11, // reduced font size
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4), // less spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RS ${item.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13, // reduced font size
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 26, 11, 167),
                  ),
                ),
                SizedBox(
                  width: 80, // reduced width
                  child: TextFormField(
                    initialValue: item.weight.toStringAsFixed(2),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 11), // reduced font size
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      labelStyle: const TextStyle(fontSize: 11),
                      suffixText: 'kg',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final newWeight = double.tryParse(value);
                      if (newWeight != null && newWeight > 0) {
                        _updateCartItem(index, newWeight);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}