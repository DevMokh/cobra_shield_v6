import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../services/inbox.dart';
import '../services/message_analyzer.dart';
import '../services/settings_store.dart';
import '../services/strings.dart';
import 'history_screen.dart';
import 'home_dashboard.dart';
import 'message_scan_screen.dart';
import 'tools_screen.dart';
import 'train_screen.dart';
import 'url_scan_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  String _lastClip = '';

  // ملاحظة: الفهارس هنا مستخدمة في HomeDashboard.onNavigate (0 رابط، 1 رسالة،
  // 2 تدرّب، 3 أدوات، 4 السجل) وهي نفس ترتيب _pages بعد شاشة الرئيسية.
  List<Widget> get _pages => <Widget>[
        HomeDashboard(onNavigate: (i) => setState(() => _index = i + 1)),
        const UrlScanScreen(),
        const MessageScanScreen(),
        const TrainScreen(),
        const ToolsScreen(),
        const HistoryScreen(),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Inbox.shared.addListener(_onShared);
    Inbox.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkClipboard());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Inbox.shared.removeListener(_onShared);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  /// نص جاي من "مشاركة" أو تحديد نص: رابط واحد -> فحص رابط، غير كده -> فحص رسالة
  void _onShared() {
    final inc = Inbox.shared.value;
    if (inc == null) return;
    final text = inc.text;
    final links = MessageAnalyzer.extractLinks(text);
    final singleLink = links.length == 1 && (text.length - links.first.length) < 12;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (singleLink) {
        setState(() => _index = 1);
        Inbox.toUrl.value = Incoming(links.first);
      } else {
        setState(() => _index = 2);
        Inbox.toMessage.value = Incoming(text);
      }
    });
  }

  Future<void> _checkClipboard() async {
    if (!SettingsStore.instance.clipWatch) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    try {
      final d = await Clipboard.getData(Clipboard.kTextPlain);
      final t = d?.text?.trim();
      if (t == null || t.isEmpty || t == _lastClip) return;
      _lastClip = t;
      final links = MessageAnalyzer.extractLinks(t);
      if (links.isEmpty || !mounted) return;
      final first = links.first;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: const Text('في رابط منسوخ. تحب تفحصه؟'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'افحص',
          textColor: C.emerald,
          onPressed: () {
            setState(() => _index = 1);
            Inbox.toUrl.value = Incoming(first);
          },
        ),
      ));
    } catch (_) {
      // أندرويد منع قراءة الحافظة الآن: نتجاهل
    }
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لـ SettingsStore هنا يخلي الشاشة كلها (وشاشاتها الفرعية) تعيد
    // البناء لما لغة الواجهة تتغيّر من تاب الأدوات.
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(index: _index, children: _pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: <NavigationDestination>[
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: tr(S.navHome),
              ),
              NavigationDestination(
                icon: const Icon(Icons.link_rounded),
                selectedIcon: const Icon(Icons.link_rounded),
                label: tr(S.navLink),
              ),
              NavigationDestination(
                icon: const Icon(Icons.mark_email_unread_outlined),
                selectedIcon: const Icon(Icons.mark_email_unread_rounded),
                label: tr(S.navMessage),
              ),
              NavigationDestination(
                icon: const Icon(Icons.sports_esports_outlined),
                selectedIcon: const Icon(Icons.sports_esports_rounded),
                label: tr(S.navTrain),
              ),
              NavigationDestination(
                icon: const Icon(Icons.build_circle_outlined),
                selectedIcon: const Icon(Icons.build_circle_rounded),
                label: tr(S.navTools),
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_rounded),
                selectedIcon: const Icon(Icons.history_rounded),
                label: tr(S.navHistory),
              ),
            ],
          ),
        );
      },
    );
  }
}
