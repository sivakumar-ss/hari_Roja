import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/groq_service.dart';
import '../../services/insforge_service.dart';
import '../../widgets/ui.dart';

class _ChatMsg {
  final String role; // user | assistant | error
  final String content;
  _ChatMsg(this.role, this.content);
  bool get isUser => role == 'user';
}

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});
  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _msgs = [];
  bool _sending = false;
  String? _sessionId;
  String? _lastUserMessage;

  static const _suggestions = [
    'How much did I spend this month?',
    'Am I saving enough for emergencies?',
    'How can I pay off my loans faster?',
    'Suggest a plan to reach my goals',
  ];

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _initSession() async {
    try {
      final uid = InsforgeService.client.auth.currentUser?.id;
      if (uid == null) return;
      final repo = ref.read(financeRepositoryProvider);
      final sessions = await repo.listSessions(uid);
      if (sessions.isNotEmpty) {
        _sessionId = sessions.first.id;
        final msgs = await repo.listMessages(_sessionId!);
        if (!mounted) return;
        setState(() {
          for (final m in msgs) {
            if (m.role == 'user' || m.role == 'assistant') _msgs.add(_ChatMsg(m.role, m.content));
          }
        });
        _scrollToEnd();
      } else {
        final s = await repo.createSession(uid, title: 'Chat');
        _sessionId = s.id;
      }
    } catch (_) {
      // Chat still works even when the history cannot be loaded.
    }
  }

  Future<void> _newChat() async {
    setState(() {
      _msgs.clear();
      _sessionId = null;
      _lastUserMessage = null;
    });
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final s = await ref.read(financeRepositoryProvider).createSession(uid, title: 'Chat');
      _sessionId = s.id;
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _buildContext() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return {};
    final repo = ref.read(financeRepositoryProvider);
    final profile = await repo.getProfile(uid);
    final incomes = await repo.listIncome(uid);
    final expenses = await repo.listExpenses(uid);
    final savings = await repo.listSavings(uid);
    final loans = await repo.listLoans(uid);
    final investments = await repo.listInvestments(uid);
    final goals = await repo.listGoals(uid);
    final score = await repo.latestScore(uid);
    final risk = await repo.latestRisk(uid);
    final now = DateTime.now();
    final mi = incomes.where((e) => e.entryDate.year == now.year && e.entryDate.month == now.month).fold<double>(0, (s, e) => s + e.amount);
    final me = expenses.where((e) => e.entryDate.year == now.year && e.entryDate.month == now.month).fold<double>(0, (s, e) => s + e.amount);
    return {
      'profile': {
        'name': profile?.fullName,
        'age': profile?.age,
        'occupation': profile?.occupation,
        'cityTier': profile?.cityTier,
        'monthlyIncome': profile?.monthlyIncome,
      },
      'thisMonth': {'income': mi, 'expense': me, 'surplus': mi - me},
      'totalSavings': savings.fold<double>(0, (s, e) => s + e.amount),
      'loans': loans.map((l) => {'name': l.name, 'outstanding': l.outstanding, 'emi': l.emi, 'rate': l.interestRate}).toList(),
      'totalInvestments': investments.fold<double>(0, (s, i) => s + i.amount),
      'goals': goals.map((g) => {'name': g.name, 'target': g.targetAmount, 'current': g.currentAmount, 'progressPct': (g.progress * 100).round()}).toList(),
      'healthScore': score?.overallScore,
      'riskLevel': risk?.riskLevel,
    };
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
    });
  }

  Future<void> _persist(String role, String content) async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null || _sessionId == null) return;
    try {
      await ref.read(financeRepositoryProvider).addMessage(
            ChatMessage(sessionId: _sessionId!, userId: uid, role: role, content: content, createdAt: DateTime.now()),
          );
    } catch (_) {}
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _msgs.add(_ChatMsg('user', text));
      _lastUserMessage = text;
      _sending = true;
    });
    _ctrl.clear();
    _scrollToEnd();
    await _persist('user', text);

    try {
      final ctx = await _buildContext();
      final history = _msgs
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .toList()
          .reversed
          .skip(1)
          .take(8)
          .toList()
          .reversed
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      final reply = await GroqService.chat(message: text, history: history, context: ctx);
      if (!mounted) return;
      setState(() => _msgs.add(_ChatMsg('assistant', reply)));
      await _persist('assistant', reply);
    } catch (e) {
      if (!mounted) return;
      setState(() => _msgs.add(_ChatMsg('error', e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: gradientAppBar('AI Advisor', automaticallyImplyLeading: false, actions: [
        IconButton(tooltip: 'New chat', onPressed: _sending ? null : _newChat, icon: const Icon(Icons.add_comment_outlined)),
      ]),
      body: Column(
        children: [
          Expanded(child: _msgs.isEmpty && !_sending ? _welcome() : _conversation()),
          if (_sending) _typing(),
          _composer(),
        ],
      ),
    );
  }

  Widget _welcome() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(gradient: AppGradients.brand, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 18),
        const Text("Hi, I'm Fin",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.4)),
        const SizedBox(height: 6),
        const Text('I can see your income, spending, loans and goals.\nAsk me anything about them.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 26),
        ..._suggestions.map((s) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _suggestion(s))),
      ],
    );
  }

  Widget _suggestion(String text) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _send(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 17, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMuted),
        ]),
      ),
    );
  }

  Widget _conversation() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _msgs.length,
      itemBuilder: (_, i) => _bubble(_msgs[i]),
    );
  }

  Widget _bubble(_ChatMsg m) {
    if (m.role == 'error') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.error_outline_rounded, size: 17, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(child: Text(m.content, style: const TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w600))),
              ]),
              if (_lastUserMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 25),
                  child: GestureDetector(
                    onTap: () => _send(_lastUserMessage),
                    child: const Text('Tap to retry',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary, decoration: TextDecoration.underline)),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (m.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
          decoration: const BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(m.content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(gradient: AppGradients.brand, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [BoxShadow(color: Color(0x0F111827), blurRadius: 16, offset: Offset(0, 6))],
              ),
              child: Text(m.content, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typing() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(gradient: AppGradients.brand, shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 10),
        const Text('Fin is thinking...', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x14111827), blurRadius: 20, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Ask about your finances...',
                      prefixIcon: Icon(Icons.chat_bubble_outline_rounded, size: 19),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : () => _send(),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _sending ? null : AppGradients.brand,
                      color: _sending ? AppColors.divider : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _sending ? null : AppShadows.floating,
                    ),
                    child: Icon(Icons.send_rounded, color: _sending ? AppColors.textMuted : Colors.white, size: 21),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Informational only. Not licensed financial advice.',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
