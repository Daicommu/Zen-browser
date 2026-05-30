import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:math' as math;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const ZenBrowserApp());
}

class Shortcut {
  final String title;
  final String url;
  final String emoji;
  Shortcut({required this.title, required this.url, required this.emoji});
}

class ZenBrowserApp extends StatelessWidget {
  const ZenBrowserApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zen Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          surface: Color(0xFF0A0A0F),
        ),
      ),
      home: const BrowserHome(),
    );
  }
}

class BrowserHome extends StatefulWidget {
  const BrowserHome({super.key});
  @override
  State<BrowserHome> createState() => _BrowserHomeState();
}

class _BrowserHomeState extends State<BrowserHome>
    with TickerProviderStateMixin {
  WebViewController? _controller;
  bool _isLoading = false;
  bool _showWebView = false;
  bool _orbExpanded = false;
  double _loadProgress = 0.0;
  String _currentUrl = '';

  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  late AnimationController _orbAnimController;
  late AnimationController _loadingAnimController;
  late AnimationController _pageEntryController;
  late Animation<double> _orbExpansion;
  late Animation<double> _shadowRise;
  late Animation<double> _shadowFall;
  late Animation<double> _pageEntry;

  List<Shortcut> shortcuts = [
    Shortcut(title: 'Google', url: 'https://google.com', emoji: '🔍'),
    Shortcut(title: 'YouTube', url: 'https://youtube.com', emoji: '▶️'),
    Shortcut(title: 'Wikipedia', url: 'https://wikipedia.org', emoji: '📖'),
  ];

  @override
  void initState() {
    super.initState();

    _orbAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pageEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _orbExpansion = CurvedAnimation(
      parent: _orbAnimController,
      curve: Curves.easeInOutCubic,
    );

    _shadowRise = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _loadingAnimController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _shadowFall = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _loadingAnimController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _pageEntry = CurvedAnimation(
      parent: _pageEntryController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _orbAnimController.dispose();
    _loadingAnimController.dispose();
    _pageEntryController.dispose();
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _toggleOrb() {
    setState(() => _orbExpanded = !_orbExpanded);
    if (_orbExpanded) {
      _orbAnimController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _urlFocusNode.requestFocus();
      });
    } else {
      _orbAnimController.reverse();
      _urlFocusNode.unfocus();
    }
  }

  void _navigate(String url) {
    String finalUrl = url.trim();
    if (finalUrl.isEmpty) return;

    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      if (finalUrl.contains('.') && !finalUrl.contains(' ')) {
        finalUrl = 'https://$finalUrl';
      } else {
        finalUrl =
            'https://www.google.com/search?q=${Uri.encodeComponent(finalUrl)}';
      }
    }

    _toggleOrb();
    _loadUrl(finalUrl);
  }

  void _loadUrl(String url) {
    setState(() {
      _currentUrl = url;
      _isLoading = true;
      _loadProgress = 0.0;
    });

    _loadingAnimController.forward(from: 0.0);

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) {
          setState(() => _loadProgress = progress / 100.0);
        },
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) {
          setState(() => _isLoading = false);
          _loadingAnimController.animateTo(1.0,
              duration: const Duration(milliseconds: 400));
        },
      ))
      ..loadRequest(Uri.parse(url));

    setState(() {
      _controller = controller;
      _showWebView = true;
    });

    _pageEntryController.forward(from: 0.0);
  }

  void _showAddShortcutDialog() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final emojiCtrl = TextEditingController(text: '🌐');

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('افزودن میانبر',
            style: TextStyle(color: Colors.white, fontFamily: 'serif')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(emojiCtrl, 'ایموجی'),
            const SizedBox(height: 12),
            _dialogField(titleCtrl, 'عنوان'),
            const SizedBox(height: 12),
            _dialogField(urlCtrl, 'آدرس (URL)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('لغو', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                setState(() {
                  shortcuts.add(Shortcut(
                    title: titleCtrl.text,
                    url: urlCtrl.text.startsWith('http')
                        ? urlCtrl.text
                        : 'https://${urlCtrl.text}',
                    emoji: emojiCtrl.text.isEmpty ? '🌐' : emojiCtrl.text,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF0D0D1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // ── Home Screen ──────────────────────────────────────────
          if (!_showWebView) _buildHomeScreen(size),

          // ── WebView ──────────────────────────────────────────────
          if (_showWebView)
            AnimatedBuilder(
              animation: _pageEntry,
              builder: (_, __) => Opacity(
                opacity: _pageEntry.value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - _pageEntry.value)),
                  child: SizedBox.expand(
                    child: WebViewWidget(controller: _controller!),
                  ),
                ),
              ),
            ),

          // ── Loading Shadow Effect ─────────────────────────────────
          if (_isLoading)
            AnimatedBuilder(
              animation: _loadingAnimController,
              builder: (_, __) {
                double shadowOpacity;
                if (_loadingAnimController.value <= 0.5) {
                  shadowOpacity = _shadowRise.value * 0.85;
                } else {
                  shadowOpacity = _shadowFall.value * 0.85;
                }
                double shadowHeight =
                    size.height * 0.18 * math.min(1, shadowOpacity * 1.5);

                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: shadowHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF6C63FF).withOpacity(shadowOpacity),
                          const Color(0xFF0A0A0F).withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // ── Progress Bar ─────────────────────────────────────────
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadProgress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
                minHeight: 2,
              ),
            ),

          // ── Floating Orb ──────────────────────────────────────────
          _buildFloatingOrb(size),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(Size size) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 48),
          // Title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFB06EFF)],
            ).createShader(bounds),
            child: const Text(
              'ZEN',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 16,
              ),
            ),
          ),
          const Text(
            'مرورگر آرامش',
            style: TextStyle(
              color: Color(0xFF555577),
              fontSize: 13,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 56),

          // Shortcuts Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('میانبرها',
                        style: TextStyle(
                            color: Color(0xFF888899),
                            fontSize: 12,
                            letterSpacing: 2)),
                    GestureDetector(
                      onTap: _showAddShortcutDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  const Color(0xFF6C63FF).withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add,
                                size: 13, color: Color(0xFF6C63FF)),
                            SizedBox(width: 4),
                            Text('افزودن',
                                style: TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: shortcuts.length,
                  itemBuilder: (_, i) => _buildShortcutTile(shortcuts[i]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutTile(Shortcut s) {
    return GestureDetector(
      onTap: () => _loadUrl(s.url),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.12),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(s.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.title,
            style: const TextStyle(color: Color(0xFF888899), fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingOrb(Size size) {
    return AnimatedBuilder(
      animation: _orbExpansion,
      builder: (context, _) {
        final expanded = _orbExpansion.value;
        final orbSize = 52.0 + (size.width - 52 - 32) * expanded;
        final orbHeight = 52.0 + 8 * expanded;
        final bottomPad = 32.0 - 12 * expanded;

        return Positioned(
          bottom: bottomPad,
          left: 16 + (0) * expanded,
          right: 16,
          child: Center(
            child: GestureDetector(
              onTap: _orbExpanded ? null : _toggleOrb,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                width: orbSize,
                height: orbHeight + 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D1A),
                  borderRadius: BorderRadius.circular(
                      52 - 36 * expanded),
                  border: Border.all(
                    color: const Color(0xFF6C63FF)
                        .withOpacity(0.3 + 0.2 * expanded),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF)
                          .withOpacity(0.25 + 0.15 * expanded),
                      blurRadius: 24 + 12 * expanded,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(52 - 36 * expanded),
                  child: expanded > 0.1
                      ? _buildExpandedOrb(expanded)
                      : _buildCollapsedOrb(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedOrb() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.language_rounded,
              color: Color(0xFF6C63FF), size: 22),
          const SizedBox(width: 6),
          Text(
            _showWebView ? _trimUrl(_currentUrl) : 'جستجو کن...',
            style: const TextStyle(
              color: Color(0xFF888899),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedOrb(double expanded) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (_showWebView)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showWebView = false;
                  _pageEntryController.reset();
                });
                _toggleOrb();
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.home_rounded,
                    color: Color(0xFF6C63FF), size: 20),
              ),
            ),
          Expanded(
            child: TextField(
              controller: _urlController,
              focusNode: _urlFocusNode,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                hintText: 'آدرس یا جستجو...',
                hintStyle:
                    TextStyle(color: Color(0xFF555577), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (v) {
                _navigate(v);
                _urlController.clear();
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              _navigate(_urlController.text);
              _urlController.clear();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Color(0xFF6C63FF), size: 18),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _toggleOrb,
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child:
                  Icon(Icons.close, color: Color(0xFF555577), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _trimUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url.length > 24 ? '${url.substring(0, 24)}...' : url;
    }
  }
}
