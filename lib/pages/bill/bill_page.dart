import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class BillPage extends StatefulWidget {
  const BillPage({super.key});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  final _companyCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _submitting = false;
  Map<String, dynamic>? _billData;

  @override
  void initState() {
    super.initState();
    _fetchBill();
  }

  Future<void> _fetchBill() async {
    try {
      final resp = await ApiClient().get('/api/orders/current');
      final orderId = resp.data['id'];
      final bill = await ApiClient().get('/api/orders/$orderId/bill');
      setState(() => _billData = bill.data as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> _submitInvoice() async {
    if (_companyCtrl.text.trim().isEmpty || _taxCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写所有发票信息'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _submitting = true);
    try {
      final resp = await ApiClient().get('/api/orders/current');
      await ApiClient().put('/api/orders/${resp.data['id']}/invoice', data: {
        'company_name': _companyCtrl.text.trim(),
        'tax_id': _taxCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发票信息已保存'), backgroundColor: Colors.green));
        _companyCtrl.clear(); _taxCtrl.clear(); _emailCtrl.clear();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _taxCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_billData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bill = _billData!;
    final roomRate = (bill['room_rate'] as num?)?.toInt() ?? 0;
    final grandTotal = (bill['grand_total'] as num?)?.toInt() ?? 0;
    final consumptions = (bill['consumptions'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('📊 挂房账'), backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1677FF), Color(0xFF0050B3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF1677FF).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('账单实时总计', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('¥${(grandTotal / 100).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.21), borderRadius: BorderRadius.circular(12)),
                    child: Text('📊 共 ${consumptions.length} 笔消费', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 10),
                const Divider(color: Color(0x33FFFFFF), height: 1),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('信用预授权剩余押金比例', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '${((300000 - grandTotal) / 300000 * 100).clamp(0, 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ]),
                  Text(
                    '可用额度: ¥${((300000 - grandTotal) / 100).toStringAsFixed(0)} / ¥3,000',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('消费明细', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildRow('房费', '¥${(roomRate / 100).toStringAsFixed(0)}', isMain: true),
          ...consumptions.map((c) => _buildRow(c['item_name'] ?? '', '¥${((c['amount'] as num?)?.toInt() ?? 0) ~/ 100}')),
          const Divider(),
          _buildRow('合计', '¥${(grandTotal / 100).toStringAsFixed(0)}', isTotal: true),
          const SizedBox(height: 24),
          const Text('📄 电子发票预登记', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...[('公司抬头', '请输入公司全称'), ('企业税号', '请输入税号'), ('接收邮箱', '请输入邮箱')].map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(controller: e.$1 == '公司抬头' ? _companyCtrl : e.$1 == '企业税号' ? _taxCtrl : _emailCtrl,
              decoration: InputDecoration(labelText: e.$1, hintText: e.$2, border: const OutlineInputBorder())),
          )),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 44, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white),
            onPressed: _submitting ? null : _submitInvoice,
            child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('保存发票预登记信息'),
          )),
        ],
      ),
    );
  }

  Widget _buildRow(String item, String amount, {bool isMain = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(item, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isMain ? 14 : 13))),
        Text(amount, style: TextStyle(fontWeight: FontWeight.w600, color: isTotal ? Colors.red : const Color(0xFF262626), fontSize: isTotal ? 20 : 14)),
      ]),
    );
  }
}
