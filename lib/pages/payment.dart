import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MpesaPaymentPage extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const MpesaPaymentPage({
    super.key,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<MpesaPaymentPage> createState() => _MpesaPaymentPageState();
}

class _MpesaPaymentPageState extends State<MpesaPaymentPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitPayment() async {
    final rawPhone = _phoneController.text.trim();

    if (!RegExp(r'^07\d{8}$').hasMatch(rawPhone)) {
      setState(() {
        _errorMessage = 'Enter a valid Safaricom number starting with 07...';
      });
      return;
    }

    final phone = '254' + rawPhone.substring(1); // Convert 07... → 2547...

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://lumendeotv-project-backend.onrender.com/api/mpesa/stkpush'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "amount": 1,
          "account_ref": "TEST123",
          "desc": "Test payment",
          "phone": phone,
        }),
      );

      final data = jsonDecode(response.body);
      print('STK Push Response: $data');

      if (response.statusCode == 200 && data['status'] == 'success') {
        final checkoutRequestId = data['data']['CheckoutRequestID'];
        _pollPaymentStatus(checkoutRequestId);
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Payment initiation failed.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    }
  }

  Future<void> _pollPaymentStatus(String checkoutRequestId) async {
    const maxTries = 10;
    const waitTime = Duration(seconds: 5);

    for (int i = 0; i < maxTries; i++) {
      try {
        final response = await http.get(
          Uri.parse('https://lumendeotv-project-backend.onrender.com/api/mpesa/payment-status/$checkoutRequestId'),
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          print('Polling result: $result');

          if (result['status'] == 'completed') {
            widget.onSuccess();
            return;
          } else if (result['status'] == 'failed') {
            setState(() {
              _errorMessage = 'Payment failed: ${result['message'] ?? "Try again."}';
              _isLoading = false;
            });
            return;
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Status check error: $e';
        });
        break;
      }

      await Future.delayed(waitTime);
    }

    setState(() {
      _errorMessage = 'Payment confirmation timed out.';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFFFD700);
    const darkColor = Colors.black;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/plainlumendeobackground.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: darkColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unlock Full Video',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: goldColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter your M-Pesa phone number to pay and unlock.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: const TextStyle(color: goldColor),
                        hintText: 'e.g. 0712345678',
                        hintStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: goldColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: goldColor, width: 2),
                        ),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: widget.onCancel,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: _isLoading ? null : _submitPayment,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text('Pay'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
