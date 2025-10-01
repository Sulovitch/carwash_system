import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class Service {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String? imagePath; // Nullable path for user-uploaded image
  final String? imageUrl; // Nullable URL for the service image (dynamic)

  Service({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imagePath,
    this.imageUrl, // Make imageUrl nullable
  });
}

class ServicesScreen extends StatefulWidget {
  static const String routeName = 'Services_screen';
  final String carWashId;

  const ServicesScreen({super.key, required this.carWashId});

  @override
  _ServicesPageState createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';
  double _price = 0.0;
  String? _imagePath; // Nullable for user-uploaded image
  int? _editingIndex; // Track the index of the service being edited
  final List<Service> services = []; // List to hold services
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    if (widget.carWashId.isEmpty) {
      print('Error: carWashId is empty. Cannot fetch services.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid Car Wash ID. Cannot fetch services.')),
      );
      return;
    }

    print('Fetching services for Car Wash ID: ${widget.carWashId}');

    try {
      final url = Uri.parse('http://10.0.2.2/myapp/api/service.php');
      final response = await http.post(url, body: {
        'action': 'get_services',
        'car_wash_id': widget.carWashId,
      });

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          setState(() {
            services.clear();
            for (var service in jsonResponse['data']) {
              services.add(Service(
                id: service['ServiceID'],
                name: service['Name'],
                description: service['Description'],
                price: double.parse(service['Price'].toString()),
                imageUrl: service['image_url'] ?? '',
                imagePath: null,
              ));
            }
            print(jsonResponse);
          });
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching services: $e')),
      );
    }
  }

  Future<void> _addOrUpdateService() async {
    if (_formKey.currentState!.validate() && _imagePath != null) {
      try {
        final action = _editingIndex != null ? 'edit' : 'add';
        final url = Uri.parse('http://10.0.2.2/myapp/api/service.php');

        final request = http.MultipartRequest('POST', url)
          ..fields['action'] = action
          ..fields['name'] = _name
          ..fields['description'] = _description
          ..fields['price'] = _price.toString()
          ..fields['car_wash_id'] = widget.carWashId;

        if (_editingIndex != null) {
          request.fields['ServiceID'] = services[_editingIndex!].id.toString();
        }

        if (_imagePath != null) {
          request.files.add(
              await http.MultipartFile.fromPath('service_image', _imagePath!));
        }

        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final jsonResponse = json.decode(responseBody);

          if (jsonResponse['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      action == 'add' ? 'Service added!' : 'Service updated!')),
            );

            final newService = Service(
              id: jsonResponse['ServiceID'] != null
                  ? int.parse(jsonResponse['ServiceID'].toString())
                  : null,
              name: _name,
              description: _description,
              price: _price,
              imagePath: _imagePath,
              imageUrl: jsonResponse['image_url'] ?? '',
            );

            setState(() {
              if (_editingIndex != null) {
                services[_editingIndex!] = newService;
              } else {
                services.add(newService);
              }
              _formKey.currentState!.reset();
              _imagePath = null;
              _editingIndex = null;
            });
          } else {
            throw Exception(jsonResponse['message']);
          }
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _imagePath == null ? 'Select an image' : 'Fill all fields')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _deleteService(int index) async {
    final service = services[index];

    if (service.id == null || service.id! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid ServiceID.')),
      );
      return;
    }

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete the service "${service.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) {
      return; // Exit if the user cancels
    }

    try {
      final url = Uri.parse('http://10.0.2.2/myapp/api/service.php');
      final response = await http.post(url, body: {
        'action': 'delete',
        'ServiceID': service.id.toString(),
      });

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            services.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Service deleted successfully!')),
          );
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting service: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
              child: services.isEmpty
                  ? Center(
                      child: Text(
                        'No services available.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return Card(
                          margin: EdgeInsets.all(10),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                // Display image
                                if (service.imagePath != null &&
                                    service.imagePath!.isNotEmpty)
                                  File(service.imagePath!).existsSync()
                                      ? Image.file(
                                          File(service.imagePath!),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(Icons.image_not_supported,
                                          size: 100)
                                else if (service.imageUrl?.isNotEmpty ??
                                    false) // Check if imageUrl is not null or empty
                                  Image.network(
                                    service.imageUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.broken_image,
                                          size: 100);
                                    },
                                  )
                                else
                                  Icon(Icons.image, size: 100),
                                SizedBox(width: 16),
                                // Service Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        service.description,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '\SAR ${service.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    setState(() {
                                      _editingIndex = index;
                                      _name = service.name;
                                      _description = service.description;
                                      _price = service.price;
                                      _imagePath = service.imagePath;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteService(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Service Name',
                      labelStyle: TextStyle(color: Colors.black),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter service name';
                      }
                      return null;
                    },
                    onChanged: (value) => _name = value,
                    initialValue: _editingIndex != null
                        ? _name
                        : '', // Show existing name when editing
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.black),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                    onChanged: (value) => _description = value,
                    initialValue: _editingIndex != null
                        ? _description
                        : '', // Show existing description when editing
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Price',
                      labelStyle: TextStyle(color: Colors.black),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                        decimal: true), // Allow decimal numbers
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(
                          r'^\d+\.?\d*')), // Allow digits and decimal point
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _price = double.tryParse(value) ?? 0.0; // Parse safely
                    },
                    initialValue: _editingIndex != null
                        ? _price.toString()
                        : '', // Show existing price when editing
                  ),

                  SizedBox(height: 10),
                  // Pick Image Button
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _imagePath == null ? 'Pick Image' : 'Change Image',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_imagePath != null) ...[
                    SizedBox(height: 10),
                    Image.file(
                      File(_imagePath!), // Show the user-uploaded image
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ],
                  SizedBox(height: 10),
                  // Add or Update Service Button
                  GestureDetector(
                    onTap: _addOrUpdateService,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _editingIndex != null ? 'Save Changes' : 'Add Service',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
