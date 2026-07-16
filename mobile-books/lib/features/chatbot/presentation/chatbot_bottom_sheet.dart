import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/theme/app_icons.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:dio/dio.dart';

enum ChatState {
  greeting,
  businessSize,
  currentTool,
  featureInterest,
  keyNeed,
  recommendation,
  endSuccess,
  endNoThanks
}

class ChatMessage {
  final String text;
  final bool isBot;

  ChatMessage(this.text, {required this.isBot});
}

class ChatbotBottomSheet extends ConsumerStatefulWidget {
  const ChatbotBottomSheet({super.key});

  @override
  ConsumerState<ChatbotBottomSheet> createState() => _ChatbotBottomSheetState();
}

class _ChatbotBottomSheetState extends ConsumerState<ChatbotBottomSheet> {
  final List<ChatMessage> _messages = [];
  ChatState _currentState = ChatState.greeting;
  bool _isTyping = false;
  bool _isSubmitting = false;

  // Answers tracker
  String _businessSize = '';
  String _currentTool = '';
  String _featureInterest = '';
  String _keyNeed = '';
  String _recommendedPlan = '';

  final TextEditingController _emailController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addBotMessage("Hi! I'm here to help you find the right plan for your business. Mind answering a couple quick questions?");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _isTyping = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text, isBot: true));
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text, isBot: false));
    });
    _scrollToBottom();
  }

  void _handleGreeting(bool accept) {
    if (accept) {
      _addUserMessage("Sure, let's do it!");
      setState(() {
        _currentState = ChatState.businessSize;
      });
      _addBotMessage("How many people will use Eazzio Books?");
    } else {
      _addUserMessage("No thanks");
      setState(() {
        _currentState = ChatState.endNoThanks;
      });
      _addBotMessage("No problem! Feel free to browse around. I'll be here if you need me.");
    }
  }

  void _handleBusinessSize(String size) {
    _addUserMessage(size);
    _businessSize = size;
    setState(() {
      _currentState = ChatState.currentTool;
    });
    _addBotMessage("Are you currently using another accounting tool?");
  }

  void _handleCurrentTool(String tool) {
    _addUserMessage(tool);
    _currentTool = tool;
    setState(() {
      _currentState = ChatState.featureInterest;
    });
    _addBotMessage("Which Eazzio Books feature sounds most exciting to you?");
  }

  void _handleFeatureInterest(String feature) {
    _addUserMessage(feature);
    _featureInterest = feature;
    setState(() {
      _currentState = ChatState.keyNeed;
    });
    _addBotMessage("Got it! And what matters most to you right now?");
  }

  void _handleKeyNeed(String need) {
    _addUserMessage(need);
    _keyNeed = need;

    // Calculation mapping matching the web logic exactly
    String recommended = 'Standard Premium';
    String reason = "it includes all the core features you need to manage your finances effectively.";

    if (need == 'Basic invoicing' && _businessSize == 'Just me') {
      recommended = 'Free';
      reason = "it has everything you need to send your first invoice without any cost.";
    } else if (need == 'Cash flow forecasting' || need == 'Inventory & purchases') {
      recommended = 'Standard Premium';
      reason = "it includes advanced forecasting and inventory tracking that Zoho Books doesn't have.";
    } else if (need == 'Team & reporting features' || _businessSize == '6+ people') {
      recommended = 'Professional';
      reason = "it's built for teams with custom roles, advanced reporting, and full audit logs.";
    }

    _recommendedPlan = recommended;

    setState(() {
      _currentState = ChatState.recommendation;
    });

    _addBotMessage("Based on what you told me, the **$recommended** plan is your best bet because $reason");
    Future.delayed(const Duration(milliseconds: 1400), () {
      _addBotMessage("Want us to send you a quick guide by email?");
    });
  }

  Future<void> _submitLead(String? email) async {
    if (email != null && (email.isEmpty || !email.contains('@'))) return;

    setState(() {
      _isSubmitting = true;
    });

    if (email != null) {
      _addUserMessage("Send it to $email");
    } else {
      _addUserMessage("No thanks, just show me the plan");
    }

    try {
      final client = ref.read(networkClientProvider);
      final payload = {
        'businessSize': _businessSize,
        'currentTool': _currentTool,
        'featureInterest': _featureInterest,
        'keyNeed': _keyNeed,
        'recommendedPlan': _recommendedPlan,
        'email': email,
      };

      await client.post('/leads', data: payload);

      setState(() {
        _currentState = ChatState.endSuccess;
      });
      _addBotMessage(email != null
          ? "Thanks! We've sent the guide. You can check out the plan details or start a free trial now."
          : "No problem! You can check out the plan details below.");
    } on DioException catch (e) {
      // Graceful error state for rate limiting (429) or other API issues
      String errorMsg = "Oops, something went wrong saving your email, but you can still check out the plans!";
      if (e.response?.statusCode == 429) {
        errorMsg = "Rate limit reached. Please try again in 15 minutes.";
      }
      setState(() {
        _currentState = ChatState.endSuccess;
      });
      _addBotMessage(errorMsg);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          // Header Drag Bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Sheet Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(AppIcons.support_agent, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Plan Finder Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(AppIcons.cancel, size: 20),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Conversation View
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingBubble();
                }
                return _buildChatBubble(_messages[index], isDark);
              },
            ),
          ),

          const Divider(height: 1),
          
          // Controls / Options View
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildControls(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, bool isDark) {
    return Align(
      alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isBot
              ? (isDark ? Colors.grey.shade800 : Colors.grey.shade100)
              : AppColors.primaryBlue,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: msg.isBot ? Radius.zero : const Radius.circular(14),
            bottomRight: msg.isBot ? const Radius.circular(14) : Radius.zero,
          ),
        ),
        child: Text(
          msg.text.replaceAll('**', ''),
          style: TextStyle(
            fontSize: 13,
            color: msg.isBot
                ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: const Text('...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildControls(bool isDark) {
    if (_isSubmitting) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_currentState) {
      case ChatState.greeting:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleGreeting(false),
                child: const Text('No thanks'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _handleGreeting(true),
                child: const Text("Sure, let's do it!"),
              ),
            ),
          ],
        );

      case ChatState.businessSize:
        return _buildOptionButtons([
          'Just me',
          '2-5 people',
          '6+ people',
        ], _handleBusinessSize);

      case ChatState.currentTool:
        return _buildOptionButtons([
          'Excel',
          'Tally',
          'Zoho Books',
          'Other',
          'None',
        ], _handleCurrentTool);

      case ChatState.featureInterest:
        return _buildOptionButtons([
          'Invoicing',
          'Expense Tracking',
          'Inventory Management',
          'Financial Reports',
        ], _handleFeatureInterest);

      case ChatState.keyNeed:
        return _buildOptionButtons([
          'Basic invoicing',
          'Cash flow forecasting',
          'Inventory & purchases',
          'Team & reporting features',
        ], _handleKeyNeed);

      case ChatState.recommendation:
        return Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _submitLead(null),
                    child: const Text('Skip email'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _submitLead(_emailController.text),
                    child: const Text('Send Guide'),
                  ),
                ),
              ],
            ),
          ],
        );

      case ChatState.endSuccess:
      case ChatState.endNoThanks:
        return SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context, _recommendedPlan.toLowerCase());
            },
            child: Text(
              _currentState == ChatState.endNoThanks
                  ? 'Explore Pricing'
                  : 'View Recommended Plan Details',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
    }
  }

  Widget _buildOptionButtons(List<String> options, Function(String) callback) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        return ActionChip(
          label: Text(opt, style: const TextStyle(fontSize: 12)),
          onPressed: () => callback(opt),
        );
      }).toList(),
    );
  }
}
