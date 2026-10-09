import 'package:flutter/material.dart';
import '../../main.dart' show CrmData;
import '../../core/theme/app_theme.dart';
import 'assistant_engine.dart';
import 'gemini_service.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key, required this.data});
  final CrmData data;

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(
      text: 'مرحبًا! أنا مساعدك الذكي 🤖\n'
          'اسألني عن:\n'
          '• كم عميل عندي؟\n'
          '• من أفضل مندوب؟\n'
          '• ما الفرص المفتوحة؟\n'
          '• ماذا أفعل اليوم؟',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
    });
    _controller.clear();

    // 1. جرّب Rules أولاً (فوري، بدون إنترنت)
    final localAnswer = AssistantEngine.ask(text, widget.data);

    // 2. إذا كان الرد "لم أفهم" → جرّب Gemini
    if (localAnswer.category == 'عام' || localAnswer.category == null) {
      // أضف رسالة "جاري التفكير"
      setState(() {
        _messages.add(_Message(
          text: 'جاري التفكير... 🤔',
          isUser: false,
        ));
      });
      _scrollToBottom();

      // استدعِ Gemini
      GeminiService.ask(text, widget.data).then((geminiAnswer) {
        if (!mounted) return;
        setState(() {
          // احذف "جاري التفكير"
          if (_messages.isNotEmpty &&
              _messages.last.text == 'جاري التفكير... 🤔') {
            _messages.removeLast();
          }
          // أضف الإجابة
          final finalText = geminiAnswer ??
              localAnswer.text; // إن فشل Gemini، اعرض Rules
          _messages.add(_Message(text: finalText, isUser: false));
        });
        _scrollToBottom();
      });
    } else {
      // Rules فهمت السؤال → اعرض مباشرة
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _messages.add(_Message(text: localAnswer.text, isUser: false));
        });
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('المساعد الذكي 🤖'),
          backgroundColor: AppTheme.primaryTeal,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(14),
                itemCount: _messages.length,
                itemBuilder: (context, i) => _bubble(_messages[i]),
              ),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_Message m) {
    return Align(
      alignment: m.isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: m.isUser ? AppTheme.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: m.isUser ? null : Border.all(color: Colors.black12),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            color: m.isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'اكتب سؤالك...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppTheme.primaryTeal,
              radius: 22,
              child: IconButton(
                onPressed: _send,
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  const _Message({required this.text, required this.isUser});
}
