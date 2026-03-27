import 'package:flutter/material.dart';
import '../../domain/utils/format_util.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _useNFC = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSendMoney() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate network delay
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction sent successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        _recipientController.clear();
        _amountController.clear();
        _descriptionController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Method Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Connection Method',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                            Text(
                              _useNFC ? 'Using NFC' : 'Using Bluetooth',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useNFC,
                        onChanged: (value) {
                          setState(() {
                            _useNFC = value;
                          });
                        },
                        activeColor: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Recipient Address
                const Text(
                  'Recipient Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _recipientController,
                  decoration: InputDecoration(
                    hintText: 'Enter wallet address or ID',
                    prefixIcon: const Icon(Icons.wallet),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_2),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR Scanner coming soon')),
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a recipient address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Amount
                const Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Description (Optional)
                const Text(
                  'Description (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Add a note for this transaction',
                    maxLines: 3,
                  ),
                ),

                const SizedBox(height: 24),

                // Transaction Fee Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Fee',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            'Network Fee',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '\$0.50',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'FREE',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Total Amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total to Send',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      Text(
                        _amountController.text.isEmpty
                            ? '\$0.00'
                            : '\$${(double.parse(_amountController.text) + 0.50).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Send Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendMoney,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Send Money',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _recipientController.clear();
                            _amountController.clear();
                            _descriptionController.clear();
                          },
                    child: const Text('Clear'),
                  ),
                ),

                const SizedBox(height: 24),

                // Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'How it works:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Enter the recipient\'s wallet address or ID\n'
                        '2. Choose the amount you want to send\n'
                        '3. Add an optional description\n'
                        '4. Confirm and send\n'
                        '5. Transaction syncs when connection is available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
