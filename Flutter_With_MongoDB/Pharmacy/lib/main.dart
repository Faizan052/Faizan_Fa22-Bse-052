import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Your backend API URL (ensure it's running)
const String apiUrl = "http://localhost:3000/api/medicines";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharmacy App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> medicines = [];
  bool isLoading = false;

  // Fetch medicines from the server
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
      // Handle error
      print('Failed to load medicines');
    }
  }

  // Add new medicine
  Future<void> addMedicine(String name, double price, int quantity) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'name': name, 'price': price, 'quantity': quantity}),
    );

    if (response.statusCode == 201) {
      fetchMedicines();
    } else {
      print('Failed to add medicine');
    }
  }

  // Delete medicine
  Future<void> deleteMedicine(String id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));

    if (response.statusCode == 200) {
      fetchMedicines();
    } else {
      print('Failed to delete medicine');
    }
  }

  // Modify medicine
  Future<void> updateMedicine(String id, String name, double price, int quantity) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$id'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'name': name, 'price': price, 'quantity': quantity}),
    );

    if (response.statusCode == 200) {
      fetchMedicines();
    } else {
      print('Failed to update medicine');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMedicines();
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.refresh),
            onPressed: fetchMedicines,
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.green),
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
              ),
              onPressed: () => showAddMedicineDialog(context),
              child: Text("Add Medicine", style: TextStyle(fontSize: 18)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                var medicine = medicines[index];
                return Card(
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [Colors.greenAccent, Colors.white.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: ListTile(
                      title: Text(
                        medicine['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
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
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteMedicine(medicine['_id']),
                      ),
                      onTap: () => showUpdateMedicineDialog(
                          context, medicine['_id'], medicine['name'], medicine['price'], medicine['quantity']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog to add a new medicine
  void showAddMedicineDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Medicine'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Medicine Name'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price'),
              ),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantity'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                addMedicine(
                  nameController.text,
                  double.parse(priceController.text),
                  int.parse(quantityController.text),
                );
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to update a medicine
  void showUpdateMedicineDialog(BuildContext context, String id, String name, double price, int quantity) {
    final nameController = TextEditingController(text: name);
    final priceController = TextEditingController(text: price.toString());
    final quantityController = TextEditingController(text: quantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Medicine'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Medicine Name'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price'),
              ),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantity'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                updateMedicine(
                  id,
                  nameController.text,
                  double.parse(priceController.text),
                  int.parse(quantityController.text),
                );
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
