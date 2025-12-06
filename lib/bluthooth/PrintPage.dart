// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:chicken_dilivery/Model/salesModel.dart';

// class ReceiptPage extends StatefulWidget {
//   final Salesmodel salesData;
//   final String itemName;
//   final String shopName;
//   final String rootName;

//   const ReceiptPage({
//     super.key,
//     required this.salesData,
//     required this.itemName,
//     required this.shopName,
//     required this.rootName,
//   });

//   @override
//   State<ReceiptPage> createState() => _ReceiptPageState();
// }

// class _ReceiptPageState extends State<ReceiptPage> {
//   ReceiptController? controller;
//   BluetoothDevice? _connectedDevice;
//   bool _isPrinting = false;
//   String _printStatus = '';

//   @override
//   void initState() {
//     super.initState();
//     _checkPermissions();
//   }

//   Future<void> _checkPermissions() async {
//     // Check and request Bluetooth permissions
//     var status = await Permission.bluetooth.request();
//     if (!status.isGranted) {
//       status = await Permission.bluetooth.request();
//     }
    
//     // Also request location permission for Android
//     if (await Permission.locationWhenInUse.request().isGranted) {
//       // Permission granted
//     }
//   }

//   Future<void> _printReceipt() async {
//     if (_isPrinting) return;
    
//     setState(() {
//       _isPrinting = true;
//       _printStatus = 'Preparing to print...';
//     });

//     try {
//       // First check if device is already connected
//       if (_connectedDevice == null) {
//         setState(() {
//           _printStatus = 'Selecting printer...';
//         });
        
//         // Show device selection
//         final device = await FlutterBluetoothPrinter.selectDevice(context);
        
//         if (device == null) {
//           setState(() {
//             _printStatus = 'No printer selected';
//           });
//           _showError('Please select a printer');
//           return;
//         }
        
//         _connectedDevice = device;
        
//         setState(() {
//           _printStatus = 'Connecting to ${device.name}...';
//         });
        
//         // Try to connect to the device
//         final connected = await FlutterBluetoothPrinter.connect(device as String);
        
//         if (!connected) {
//           setState(() {
//             _printStatus = 'Failed to connect';
//           });
//           _showError('Failed to connect to printer');
//           return;
//         }
//       }

//       setState(() {
//         _printStatus = 'Printing receipt...';
//       });

//       // Ensure controller is initialized
//       if (controller == null) {
//         setState(() {
//           _printStatus = 'Receipt controller not initialized';
//         });
//         _showError('Receipt controller error');
//         return;
//       }

//       // Print the receipt
//       final result = await controller?.print(
//         address: _connectedDevice!.address,
//         // Add additional parameters if needed
//       );

//       if (result ?? false) {
//         setState(() {
//           _printStatus = 'Print successful!';
//         });
//         _showSuccess('Receipt printed successfully');
//       } else {
//         setState(() {
//           _printStatus = 'Print failed';
//         });
//         _showError('Failed to print receipt');
//       }
//     } catch (e) {
//       setState(() {
//         _printStatus = 'Error: ${e.toString()}';
//       });
//       _showError('Printing error: $e');
//     } finally {
//       setState(() {
//         _isPrinting = false;
//       });
//     }
//   }

//   Future<void> _discoverAndConnect() async {
//   try {
//     setState(() {
//       _printStatus = 'Discovering Bluetooth devices...';
//     });

//     // Discover all nearby Bluetooth devices
//     final devices = await FlutterBluetoothPrinter.discover();
    
//     // Show ALL available Bluetooth devices, not just filtered ones
//     if (devices.isEmpty) {
//       _showError('No Bluetooth devices found. Make sure:\n1. Bluetooth is turned ON\n2. Printer is in pairing mode\n3. You are within range');
//       return;
//     }

//     // Show device selection dialog with ALL devices
//     final selectedDevice = await showDialog<BluetoothDevice>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Select Bluetooth Printer'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Select any Bluetooth printer from the list below:',
//                 style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//               ),
//               SizedBox(height: 10),
//               Container(
//                 height: 300,
//                 child: ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: devices.length,
//                   itemBuilder: (context, index) {
//                     final device = devices[index];
//                     // Highlight known printer types for user convenience
//                     final isPrinter = _isLikelyPrinter(device);
                    
//                     return Card(
//                       margin: EdgeInsets.symmetric(vertical: 4),
//                       color: isPrinter ? Colors.green[50] : null,
//                       child: ListTile(
//                         leading: Icon(
//                           isPrinter ? Icons.print : Icons.bluetooth,
//                           color: isPrinter ? Colors.green : Colors.blue,
//                         ),
//                         title: Text(
//                           device.name ?? 'Unknown Device',
//                           style: TextStyle(
//                             fontWeight: isPrinter ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(device.address ?? 'No Address'),
//                             if (isPrinter)
//                               Text(
//                                 'Printer detected',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.green,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         trailing: Icon(Icons.chevron_right),
//                         onTap: () => Navigator.pop(context, device),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//         ],
//       ),
//     );

//     if (selectedDevice != null) {
//       setState(() {
//         _printStatus = 'Connecting to ${selectedDevice.name}...';
//       });
      
//       // Try to connect
//       final connected = await FlutterBluetoothPrinter.connect(selectedDevice);
      
//       if (connected) {
//         _connectedDevice = selectedDevice;
//         _showSuccess('Connected to: ${selectedDevice.name ?? selectedDevice.address}');
//       } else {
//         _showError('Failed to connect to ${selectedDevice.name}. Please try again.');
//       }
//     }
//   } catch (e) {
//     _showError('Error discovering devices: $e');
//   }
// }

// // Helper method to identify likely printers (for UI purposes only)
// bool _isLikelyPrinter(BluetoothDevice device) {
//   final name = device.name?.toLowerCase() ?? '';
//   final address = device.address ?? '';
  
//   // Common printer keywords in device names
//   final printerKeywords = [
//     'printer', 'print', 'pos', 'receipt', 'thermal',
//     'bixolon', 'spp', 'rpp', 'rp', 'sp', 'st',
//     'zjiang', 'custom', 'blueooth', 'bt',
//     'epson', 'star', 'zebra', 'brother', 'citizen',
//     'mp', 'wp', 'tp', 'ap', 'gp', 'cp',
//   ];
  
//   // Check if device name contains any printer keywords
//   for (var keyword in printerKeywords) {
//     if (name.contains(keyword)) {
//       return true;
//     }
//   }
  
//   // Also check common printer MAC address prefixes
//   final commonPrinterPrefixes = ['00:11:62', '00:19:2B', '74:FO:7D'];
//   for (var prefix in commonPrinterPrefixes) {
//     if (address.toLowerCase().startsWith(prefix.toLowerCase())) {
//       return true;
//     }
//   }
  
//   return false;
// }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sales Receipt'),
//         backgroundColor: const Color.fromARGB(255, 26, 11, 167),
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           // Status indicator
//           if (_printStatus.isNotEmpty)
//             Container(
//               padding: EdgeInsets.all(8),
//               color: Colors.grey[200],
//               child: Row(
//                 children: [
//                   if (_isPrinting)
//                     SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       _printStatus,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
          
//           Expanded(
//             child: SingleChildScrollView(
//               child: Receipt(
//                 builder: (context) => Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // Your existing receipt layout...
//                     // (Keep all your existing receipt UI code here)
//                   ],
//                 ),
//                 onInitialized: (controller) {
//                   this.controller = controller;
//                   // You can also generate raw ESC/POS commands if needed:
//                   _generateRawReceipt(controller);
//                 },
//               ),
//             ),
//           ),
          
//           // Print Buttons Section
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 // Printer Connection Status
//                 if (_connectedDevice != null)
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Row(
//                         children: [
//                           Icon(Icons.print, color: Colors.green),
//                           SizedBox(width: 8),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Connected to:',
//                                   style: TextStyle(fontSize: 12),
//                                 ),
//                                 Text(
//                                   _connectedDevice!.name ?? 'Unknown',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Text(
//                                   _connectedDevice!.address ?? '',
//                                   style: TextStyle(fontSize: 10),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.refresh),
//                             onPressed: _discoverAndConnect,
//                             tooltip: 'Rescan printers',
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
                
//                 SizedBox(height: 10),
                
//                 // Action Buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _isPrinting ? null : _printReceipt,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color.fromARGB(255, 26, 11, 167),
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         icon: _isPrinting 
//                             ? SizedBox(
//                                 width: 16,
//                                 height: 16,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: Colors.white,
//                                 ),
//                               )
//                             : Icon(Icons.print, color: Colors.white),
//                         label: Text(
//                           _isPrinting ? 'Printing...' : 'Print Receipt',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _isPrinting 
//                             ? null 
//                             : () => Navigator.pop(context),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.grey[600],
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         icon: Icon(Icons.arrow_back, color: Colors.white),
//                         label: Text(
//                           'Go Back',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
                
//                 SizedBox(height: 10),
                
//                 // Discover Printers Button
//                 OutlinedButton.icon(
//                   onPressed: _discoverAndConnect,
//                   icon: Icon(Icons.bluetooth),
//                   label: Text('Find Printers'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Optional: Generate raw ESC/POS commands for better compatibility
//   void _generateRawReceipt(ReceiptController controller) {
//     // Add raw ESC/POS commands if needed
//     // This can help with Bixolon printer compatibility
//     controller.add([
//       // Initialize printer
//       0x1B, 0x40, // Initialize
      
//       // Set alignment center
//       0x1B, 0x61, 0x01, // Center alignment
      
//       // Your text here...
//     ]);
//   }

//   Widget _buildReceiptRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }