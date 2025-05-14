import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Backend API URL
const String apiUrl = "http://localhost:3000/api/medicines";

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharmacy App',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.lightGreen[100],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.greenAccent[900],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent[700],
          ),
        ),
      ),
      home: HomePage(toggleTheme: toggleTheme, themeMode: _themeMode),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const HomePage({Key? key, required this.toggleTheme, required this.themeMode}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> medicines = [];
  bool isLoading = false;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchMedicines();
  }

  Future<void> fetchMedicines() async {
    setState(() {
      isLoading = true;
    });
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      setState(() {
        medicines = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('Failed to load medicines');
    }
  }

  Future<void> addMedicine(String name, double price, int quantity) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'name': name, 'price': price, 'quantity': quantity}),
    );

    if (response.statusCode == 201) {
      await fetchMedicines();
    } else {
      print('Failed to add medicine');
    }
  }

  Future<void> deleteMedicine(String id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));

    if (response.statusCode == 200) {
      await fetchMedicines();
    } else {
      print('Failed to delete medicine');
    }
  }

  Future<void> updateMedicine(String id, String name, double price, int quantity) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$id'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'name': name, 'price': price, 'quantity': quantity}),
    );

    if (response.statusCode == 200) {
      await fetchMedicines();
    } else {
      print('Failed to update medicine');
    }
  }

  void confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await deleteMedicine(id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"$name" deleted successfully')),
              );
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filteredMedicines = medicines.where((med) =>
        med['name'].toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.local_pharmacy),
            SizedBox(width: 8),
            Text('Pharmacy App'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(widget.themeMode == ThemeMode.light ? Icons.nightlight_round : Icons.wb_sunny),
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchMedicines,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Medicines...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor.withOpacity(0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: Icon(Icons.add_circle_outline),
              label: Text("Add Medicine", style: TextStyle(fontSize: 18)),
              onPressed: () => showAddMedicineDialog(context),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: filteredMedicines.length,
              itemBuilder: (context, index) {
                var medicine = filteredMedicines[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      medicine['name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price: \$${medicine['price']}'),
                        Text('Quantity: ${medicine['quantity']}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => confirmDelete(context, medicine['_id'], medicine['name']),
                    ),
                    onTap: () => showUpdateMedicineDialog(
                        context, medicine['_id'], medicine['name'], medicine['price'], medicine['quantity']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void showAddMedicineDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Medicine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Medicine Name')),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Price')),
            TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await addMedicine(
                nameController.text,
                double.tryParse(priceController.text) ?? 0,
                int.tryParse(quantityController.text) ?? 0,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Medicine added successfully')),
              );
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void showUpdateMedicineDialog(BuildContext context, String id, String name, double price, int quantity) {
    final nameController = TextEditingController(text: name);
    final priceController = TextEditingController(text: price.toString());
    final quantityController = TextEditingController(text: quantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Medicine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Medicine Name')),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Price')),
            TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await updateMedicine(
                id,
                nameController.text,
                double.tryParse(priceController.text) ?? 0,
                int.tryParse(quantityController.text) ?? 0,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Medicine updated successfully')),
              );
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }
}
