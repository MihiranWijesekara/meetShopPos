import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Weeklysales extends StatefulWidget {
  const Weeklysales({super.key});

  @override
  State<Weeklysales> createState() => _WeeklysalesState();
}

class _WeeklysalesState extends State<Weeklysales> {
  // Sample data - replace with your actual data source
  final List<Map<String, dynamic>> items = [
    {'billNumber': 29, 'date': '2024-11-01', 'shopName': 'Thilina Store','Item': '1' ,'kg': 12.380, 'rate': 925.00, 'amount': 125000.00},
    {'billNumber': 2, 'date': '2024-11-02', 'shopName': 'Super Market B','Item': '1' , 'kg': 8.5, 'rate': 180.00, 'amount': 1530.00},
    {'billNumber': 3, 'date': '2024-11-03', 'shopName': 'Shop C', 'Item': '1' , 'kg': 120.0, 'rate': 220.00, 'amount': 2640.00},
    {'billNumber': 4, 'date': '2024-11-04', 'shopName': 'Shop D', 'Item': '1' , 'kg': 15.5, 'rate': 450.00, 'amount': 6975.00},
    {'billNumber': 5, 'date': '2024-11-05', 'shopName': 'Shop E', 'Item': '1' , 'kg': 5.0, 'rate': 120.00, 'amount': 600.00},
  ];

  void _editItem(int index) {
    // Edit item logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Text('Edit ${items[index]['shopName']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Save changes
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${items[index]['shopName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                items.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
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
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
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
                                'Weekly Sales',
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
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by shop name, bill number',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                  ),
                  suffixIcon: null,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                child: items.isEmpty
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
                        itemCount: items.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          String formattedDate = '';
                          if (item['date'] != null && item['date'].toString().length >= 10) {
                            formattedDate = item['date'].toString().substring(5, 10).replaceAll('-', '/');
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
                                    '${item['billNumber'] ?? ''}',
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
                                    formattedDate,
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
                                    item['shopName'] ?? '',
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
                                    item['Item'] ?? '',
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
                                    '${item['kg'] ?? 0}',
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
                                    '${(item['rate'] ?? 0).toStringAsFixed(0)}',
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
                                    '${(item['amount'] ?? 0).toStringAsFixed(0)}',
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