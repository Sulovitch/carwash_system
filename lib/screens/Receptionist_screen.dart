import 'package:app/screens/CarInput_screen.dart';
import 'package:flutter/material.dart';
import 'Reservation_screen.dart';
import 'dart:convert'; // Required for JSON encoding/decoding
import 'package:http/http.dart' as http;

class ReceptionistScreen extends StatefulWidget {
  static const String routeName = 'receptionist_screen';
  final Map<String, dynamic> receptionist;
  final Map<String, dynamic> carWashInfo;

  const ReceptionistScreen({
    Key? key,
    required this.receptionist,
    required this.carWashInfo,
  }) : super(key: key);

  @override
  _ReceptionistScreenState createState() => _ReceptionistScreenState();
}

class _ReceptionistScreenState extends State<ReceptionistScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> carWashData;
  late TabController _tabController;

  List<Map<String, dynamic>> filteredReservations = [];
  bool isLoadingReservations = true;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  Map<String, dynamic>? _selectedCar;

  @override
  void initState() {
    super.initState();

    print('Receptionist Data: ${widget.receptionist}');
    print('Car Wash Info: ${widget.carWashInfo}');

    _tabController = TabController(length: 3, vsync: this);

    fetchReservations(widget.carWashInfo['carWashId']?.toString() ?? '');
  }

  Future<void> _updateReservationStatus(
      int reservationId, String status) async {
    const String url =
        'http://10.0.2.2/myapp/api/update_reservation_status.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'reservation_id': reservationId.toString(),
          'status': status,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            // Update the local filteredReservations list
            final index = filteredReservations.indexWhere(
              (res) => res['reservation_id'] == reservationId,
            );
            if (index != -1) {
              filteredReservations[index]['status'] = status;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reservation status updated to $status.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(data['message'] ?? 'Failed to update status.')),
          );
        }
      } else {
        throw Exception('Failed to update reservation status.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> fetchReservations(String carWashId) async {
    if (carWashId.isEmpty) {
      print('Error: carWashId is empty.');
      return; // Exit early if carWashId is not provided
    }

    const String url = 'http://10.0.2.2/myapp/api/fetch_reservations.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'car_wash_id': carWashId},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success']) {
          setState(() {
            filteredReservations = (data['reservations'] as List<dynamic>)
                .map((item) => item as Map<String, dynamic>)
                .toList();
            isLoadingReservations = false;
          });
        } else {
          print('Error: ${data['message']}');
          setState(() {
            isLoadingReservations = false;
          });
        }
      } else {
        print('Error fetching reservations: ${response.statusCode}');
        setState(() {
          isLoadingReservations = false;
        });
      }
    } catch (e) {
      print('Error fetching reservations: $e');
      setState(() {
        isLoadingReservations = false;
      });
    }
  }

  void fetchCarWashInfo(String carWashId) {
    // Fetch the car wash details based on the carWashId
    // For now, assume we have a static list or dummy data
    if (carWashId == '101') {
      carWashData = {
        'name': 'Sparkle Car Wash',
        'location': '123 Main Street, City',
      };
    } else {
      carWashData = {
        'name': 'Unknown Car Wash',
        'location': 'Not Available',
      };
    }

    // Update UI after fetching
    setState(() {});
  }

  Widget _buildReservationsTab() {
    if (isLoadingReservations) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.blueAccent,
        ),
      );
    }

    if (filteredReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No reservations available for this car wash.',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredReservations.length,
      itemBuilder: (context, index) {
        final reservation = filteredReservations[index];
        final isCanceled = reservation['status'] == 'Canceled';

        // Determine the name and phone to display
        final String userName =
            reservation['user_name'] ?? _nameController.text;
        final String userPhone =
            reservation['user_phone'] ?? _phoneController.text;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reservation Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      reservation['service_name'] ?? 'Unknown Service',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: reservation['status'] == 'Approved'
                            ? Colors.green[50]
                            : reservation['status'] == 'Rejected'
                                ? Colors.red[50]
                                : reservation['status'] == 'Canceled'
                                    ? Colors.grey[200]
                                    : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reservation['status'],
                        style: TextStyle(
                          color: reservation['status'] == 'Approved'
                              ? Colors.green[800]
                              : reservation['status'] == 'Rejected'
                                  ? Colors.red[800]
                                  : reservation['status'] == 'Canceled'
                                      ? Colors.grey[600]
                                      : Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Reservation Details
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'User: $userName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phone: $userPhone',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Car: ${reservation['car_make']} ${reservation['car_model']} (${reservation['car_year']})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Date: ${reservation['date']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Time: ${reservation['time']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: isCanceled
                          ? null
                          : () {
                              _updateReservationStatus(
                                reservation['reservation_id'],
                                'Approved',
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCanceled
                            ? Colors.grey
                            : const Color.fromARGB(
                                255, 0, 110, 4), // Vibrant green
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isCanceled
                          ? null
                          : () {
                              _updateReservationStatus(
                                reservation['reservation_id'],
                                'Rejected',
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCanceled
                            ? Colors.grey
                            : const Color.fromARGB(
                                255, 114, 8, 0), // Vibrant red
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceptionistDetailsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture or Placeholder
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  'Name: ${widget.receptionist['name'] ?? 'No Name Available'}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Receptionist Role
                Text(
                  'Receptionist',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Divider(height: 40, thickness: 1, color: Colors.grey),

                // Email Section
                _buildDetailRow(
                  icon: Icons.email,
                  label: 'Email',
                  value:
                      'Email: ${widget.receptionist['email'] ?? 'No Email Available'}',
                ),

                const Divider(height: 20, thickness: 1, color: Colors.grey),

                // Phone Section
                _buildDetailRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value:
                      'Phone: ${widget.receptionist['phone'] ?? 'No Phone Available'}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 30,
            color: Colors.blueAccent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMakeReservationTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Fields in Cards
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Add/Edit Car Button
          ElevatedButton.icon(
            onPressed: () async {
              final carDetails = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarInputScreen(userId: '1'),
                ),
              );

              if (carDetails != null) {
                setState(() {
                  _selectedCar = carDetails as Map<String, dynamic>;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color.fromARGB(255, 55, 1, 117), // Match Select Date
              foregroundColor: Colors.white, // Button text color
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              _selectedCar == null ? Icons.add : Icons.edit,
            ),
            label: Text(
              _selectedCar == null ? 'Add Car' : 'Edit Car',
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // Display Car Details
          if (_selectedCar != null)
            Card(
              elevation: 6,
              margin: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 40,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Make: ${_selectedCar!['make']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Model: ${_selectedCar!['model']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Year: ${_selectedCar!['year']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Plate: ${_selectedCar!['plateNumbers'].join()} '
                            '${_selectedCar!['plateLetters'].join()}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Spacer
          const Spacer(),

          // Next Button
          ElevatedButton(
            onPressed: () {
              final userName = _nameController.text.isNotEmpty
                  ? _nameController.text
                  : widget.receptionist['name'] ?? 'Unknown Receptionist';

              final userPhone = _phoneController.text.isNotEmpty
                  ? _phoneController.text
                  : widget.receptionist['phone'] ?? 'No Phone';

              if (userName.isEmpty || _selectedCar == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please complete all fields and add a car.'),
                  ),
                );
              } else {
                Navigator.pushNamed(
                  context,
                  ReservationScreen.screenRoute,
                  arguments: {
                    'carWashName':
                        widget.carWashInfo['name'], // Pass car wash name
                    'carWashId':
                        widget.carWashInfo['carWashId'], // Pass car wash ID
                    'car': _selectedCar, // Pass the selected car details
                    'userId': '1', // Pass user ID explicitly (for receptionist)
                    'name':
                        userName, // Use receptionist name if no input is provided
                    'phone':
                        userPhone, // Use receptionist phone if no input is provided
                    'userType': 'receptionist', // Indicate the user type
                  },
                ).then((result) {
                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      filteredReservations.insert(
                          0, result); // Insert at the top of the list
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reservation added successfully!'),
                      ),
                    );
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // Match Select Date
              foregroundColor: Colors.white, // Button text color
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Next',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarWashInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Car Wash: ${widget.carWashInfo['name']}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Location: ${widget.carWashInfo['location']}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reservations'),
            Tab(text: 'Make a Reservation'),
            Tab(text: 'Details'),
          ],
        ),
        title: Text('Receptionist Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pop(); // Call the logout function
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCarWashInfo(), // Display car wash information
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReservationsTab(),
                _buildMakeReservationTab(),
                _buildReceptionistDetailsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
