import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class BillDetailPage extends StatefulWidget {
  final String orderId;

  const BillDetailPage({super.key, required this.orderId});

  @override
  State<BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage> {
  final _companyCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _submitting = false;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _billData;

  @override
  void initState() {
    super.initState();
    _fetchBill();
  }

  Future<void> _fetchBill() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final bill = await ApiClient().get('/api/orders/${widget.orderId}/bill');
      setState(() { _billData = bill.data as Map<String, dynamic>; _loading = false; });
    } catch (_) {
      setState(() { _error = '加载账单失败，请稍后重试'; _loading = false; });
    }
  }

  Future<void> _submitInvoice() async {
    if (_companyCtrl.text.trim().isEmpty || _taxCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写所有发票信息'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiClient().put('/api/orders/${widget.orderId}/invoice', data: {
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

  // ── Colors ──
  static const _bg = Color(0xFF0a0a1e);
  static const _card = Color(0xFF1f2937);
  static const _blue = Color(0xFF2563eb);
  static const _muted = Color(0xFF9ca3af);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: _blue)));
    }
    if (_error != null || _billData == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(child: Text(_error ?? '加载失败', style: const TextStyle(color: _muted))),
      );
    }

    final bill = _billData!;
    final roomRate = (bill['room_rate'] as num?)?.toInt() ?? 0;
    final grandTotal = (bill['grand_total'] as num?)?.toInt() ?? 0;
    final consumptions = (bill['consumptions'] as List?) ?? [];

    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF111128), Color(0xFF0a0a1e)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ── Back + Title ──
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.chevron_left, color: _muted, size: 28),
                  ),
                  const Expanded(
                    child: Text('我的账单', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
              const SizedBox(height: 24),

              // ── Bill Summary Card ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('当前账单 (待支付)', style: TextStyle(fontSize: 14, color: _muted)),
                    const SizedBox(height: 8),
                    Text('¥${(grandTotal / 100).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('共 ${consumptions.length} 笔消费', style: const TextStyle(fontSize: 12, color: _muted)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {},
                              child: const Text('去支付', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF374151)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _submitting ? null : _submitInvoice,
                              child: _submitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('发票', style: TextStyle(fontSize: 14, color: _muted)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 消费明细 ──
              const Text('消费明细', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 12),

              // Room rate
              _buildExpenseItem(Icons.hotel, '客房费用', '房间住宿', _blue, roomRate),

              // Consumptions
              ...consumptions.map((c) {
                final amount = ((c['amount'] as num?)?.toInt() ?? 0);
                final name = c['item_name'] ?? '';
                final (icon, color) = _getConsumptionStyle(name);
                return _buildExpenseItem(icon, name, name, color, amount);
              }),

              const SizedBox(height: 20),

              // ── Invoice Form ──
              const Text('电子发票预登记', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 12),
              _buildInput(_companyCtrl, '公司抬头'),
              const SizedBox(height: 10),
              _buildInput(_taxCtrl, '企业税号'),
              const SizedBox(height: 10),
              _buildInput(_emailCtrl, '接收邮箱'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitting ? null : _submitInvoice,
                  child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('保存发票预登记信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(IconData icon, String title, String subtitle, Color color, int amountFen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                if (subtitle != title) Text(subtitle, style: const TextStyle(fontSize: 11, color: _muted)),
              ],
            ),
          ),
          Text('¥${(amountFen / 100).toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: _muted),
        filled: true, fillColor: _card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF374151))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF374151))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  (IconData, Color) _getConsumptionStyle(String name) {
    if (name.contains('餐') || name.contains('送餐')) return (Icons.restaurant_outlined, const Color(0xFFfb923c));
    if (name.contains('洗衣')) return (Icons.checkroom_outlined, const Color(0xFFc084fc));
    if (name.contains('迷你') || name.contains('吧')) return (Icons.local_bar_outlined, const Color(0xFFf87171));
    if (name.contains('清洁')) return (Icons.cleaning_services_outlined, const Color(0xFF4ade80));
    if (name.contains('维修') || name.contains('修')) return (Icons.build_outlined, const Color(0xFF9ca3af));
    return (Icons.receipt_long_outlined, const Color(0xFF60a5fa));
  }
}
