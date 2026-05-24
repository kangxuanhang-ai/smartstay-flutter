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

  Future<void> _submitInvoice() async {
    setState(() => _submitting = true);
    try {
      await ApiClient().put('/api/orders/current/invoice', data: {
        'company_name': _companyCtrl.text.trim(),
        'tax_id': _taxCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发票信息已保存'), backgroundColor: Colors.green),
        );
        _companyCtrl.clear();
        _taxCtrl.clear();
        _emailCtrl.clear();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请检查订单状态'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📊 挂房账'), backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1677FF), borderRadius: BorderRadius.circular(10)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('押金剩余比例', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('82%', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ]),
                Text('💰 ¥2,460 / ¥3,000', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('消费明细', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildRow('房费 ¥300 × 2天', '房费', '¥600'),
          _buildRow('小冰箱·可乐', 'minibar', '¥8'),
          _buildRow('中餐厅·红烧肉套餐', 'restaurant', '¥128'),
          const Divider(),
          _buildRow('合计', '', '¥736', isTotal: true),
          const SizedBox(height: 24),
          const Text('📄 电子发票预登记', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: _companyCtrl, decoration: const InputDecoration(labelText: '公司抬头', hintText: '请输入公司全称', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _taxCtrl, decoration: const InputDecoration(labelText: '企业税号', hintText: '请输入税号', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: '接收邮箱', hintText: '请输入邮箱', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 44, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), foregroundColor: Colors.white),
            onPressed: _submitting ? null : _submitInvoice,
            child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('保存发票预登记信息'),
          )),
        ],
      ),
    );
  }

  Widget _buildRow(String item, String category, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(flex: 3, child: Text(item, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal))),
        Expanded(flex: 2, child: Text(category, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Text(amount, style: TextStyle(fontWeight: FontWeight.w600, color: isTotal ? Colors.red : const Color(0xFF262626), fontSize: isTotal ? 20 : 14)),
      ]),
    );
  }
}
