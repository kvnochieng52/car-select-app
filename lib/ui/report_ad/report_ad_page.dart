import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_appartment_live/models/configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportAdDialog extends StatefulWidget {
  final Map<String, dynamic> propertyDetails;

  const ReportAdDialog({Key? key, required this.propertyDetails})
      : super(key: key);

  @override
  _ReportAdDialogState createState() => _ReportAdDialogState();
}

class _ReportAdDialogState extends State<ReportAdDialog> {
  String? _selectedReason;
  String _description = '';
  bool _isSubmitting = false; // Add a flag for submission state

  final List<String> _reportReasons = [
    'This is Illegal/Fraudulent',
    'The Ad is spam',
    'The Price is wrong',
    'User is unreachable',
    'Other',
  ];

  void _submitReport() async {
    // Validate input
    if (_selectedReason == null || _description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a reason and provide a description.'),
        ),
      );
      return;
    }

    // Set submitting state
    setState(() {
      _isSubmitting = true;
    });

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    // Prepare data for submission
    final reportData = {
      'propertyID': widget.propertyDetails['id'],
      'reason': _selectedReason,
      'description': _description,
      'user_id': user['id']
    };

    // Submit the report to API
    final response = await http.post(
      Uri.parse('${Configuration.API_URL}property/report'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(reportData),
    );

    // Reset submitting state
    setState(() {
      _isSubmitting = false;
    });

    // Handle the response from the API
    if (response.statusCode == 200) {
      // Display confirmation dialog after submitting
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Report Submitted'),
          content: Text(
              'Thank you, we have received your report. We shall Review and action.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
                Navigator.of(context).pop(); // Close the report dialog
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Handle error response
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report. Please try again later.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Report Ad: ${widget.propertyDetails['property_title']}',
        style: TextStyle(fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Report Reason'),
              value: _selectedReason,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedReason = newValue;
                });
              },
              items: _reportReasons.map((String reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Please describe your issue',
                border: OutlineInputBorder(),
              ),
            ),
            if (_isSubmitting) // Show loading message
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 8),
                    Text('Submitting...'),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitReport,
          child: Text('Submit'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
