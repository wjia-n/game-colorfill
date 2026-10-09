import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/artisan.dart';
import '../theme/fill_themes.dart';

/// Pro screen: Free-vs-Pro comparison, real Play Billing purchases,
/// tip jar, restore. Graceful when the store isn't configured yet.
class ProScreen extends StatefulWidget {
  final FillAudio audio;
  final FillSettings settings;
  const ProScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  final StoreService _store = StoreService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _store.init();
    _store.proPurchased.addListener(_onProPurchased);
    _store.lastThanks.addListener(_onThanks);
    if (mounted) setState(() => _loading = false);
  }

  void _onProPurchased() {
    if (_store.proPurchased.value) {
      widget.settings.setPro(true);
      widget.audio.levelWin();
    }
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      _store.lastThanks.value = null;
    }
  }

  @override
  void dispose() {
    _store.proPurchased.removeListener(_onProPurchased);
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    super.dispose();
  }

  FillThemeDef get _theme => FillThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme);

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final s = widget.settings;
    return ListenableBuilder(
      listenable: s,
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.text),
          title: Text('Color Fill PRO',
              style: Artisan.heading(20, theme: theme)),
        ),
        extendBodyBehindAppBar: true,
        body: TableBackdrop(
          theme: theme,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                Center(
                  child: Text('💎',
                      style: const TextStyle(fontSize: 54)),
                ),
                const SizedBox(height: 8),
                Text(
                  s.isPro
                      ? 'You are PRO. Enjoy every tile!'
                      : 'Unlock the full paintbox.',
                  style: Artisan.heading(18, theme: theme),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _comparisonTable(theme),
                const SizedBox(height: 20),
                if (_loading)
                  Center(
                      child: CircularProgressIndicator(
                          color: theme.accent)),
                if (!_loading && !s.isPro) _buySection(theme),
                if (!_loading && s.isPro)
                  Center(
                    child: ProBadge(theme: theme),
                  ),
                const SizedBox(height: 24),
                Text('TIP JAR ☕',
                    style: Artisan.label(12, theme: theme),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Color Fill is made by one indie maker. Tips keep the paints flowing — totally optional!',
                  style: Artisan.body(13, theme: theme),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (_loading)
                  Center(
                      child: CircularProgressIndicator(
                          color: theme.accent)),
                if (!_loading) _tipJar(theme),
                const SizedBox(height: 16),
                Center(
                  child: ValueListenableBuilder<String?>(
                    valueListenable: _store.purchaseError,
                    builder: (_, err, __) => Column(
                      children: [
                        if (err != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 10),
                            child: Text(err,
                                style: TextStyle(
                                    color: const Color(0xFFFF8A8A),
                                    fontSize: 13)),
                          ),
                        TextButton(
                          onPressed: () {
                            widget.audio.click();
                            _store.restore();
                          },
                          child: Text(
                            'Restore purchases',
                            style: TextStyle(
                              color: theme.accent,
                              fontWeight: FontWeight.w700,
                              decoration:
                                  TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _comparisonTable(FillThemeDef theme) {
    const rows = [
      ['Campaign levels', '20', '20'],
      ['Daily challenge', '✅', '✅'],
      ['Quick play', '✅', '✅'],
      ['Table themes', '4', '12 + custom'],
      ['Tile styles', '4', '8'],
      ['Custom theme creator', '🔒', '✅'],
      ['Hard difficulty', '🔒', '✅'],
      ['Hints per board', '3', '3'],
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(
            color: theme.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: 76,
                  child: Text('FREE',
                      style: Artisan.label(12, theme: theme),
                      textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 76,
                  child: Text('PRO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                        color: theme.accent,
                      ),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          for (int i = 0; i < rows.length; i++)
            Container(
              color: i.isOdd
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(left: 14),
                      child: Text(rows[i][0],
                          style:
                              Artisan.body(13, theme: theme)),
                    ),
                  ),
                  SizedBox(
                    width: 76,
                    child: Text(rows[i][1],
                        style:
                            Artisan.body(13, theme: theme),
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 76,
                    child: Text(rows[i][2],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.accent,
                        ),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buySection(FillThemeDef theme) {
    if (!_store.storeReady) {
      // Honest pre-launch state: never a fake buy button.
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withValues(alpha: 0.28),
          border: Border.all(
              color: theme.accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          _store.error ??
              'Pro unlocks will be available after the store setup.',
          style: Artisan.body(13, theme: theme),
          textAlign: TextAlign.center,
        ),
      );
    }
    final pro = _store.proProduct;
    return Column(
      children: [
        if (pro != null)
          FillButton(
            label: 'Go PRO — ${pro.price}',
            emoji: '💎',
            onTap: () {
              widget.audio.click();
              _store.buyPro();
            },
            theme: theme,
          ),
        const SizedBox(height: 8),
        Text(
          'One-time purchase. Yours forever, on every device.',
          style: Artisan.body(12, theme: theme),
          textAlign: TextAlign.center,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _store.purchaseInProgress,
          builder: (_, busy, __) => busy
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: CircularProgressIndicator(
                      color: theme.accent),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _tipJar(FillThemeDef theme) {
    if (!_store.storeReady) {
      return Text(
        'The tip jar opens after the store setup.',
        style: Artisan.body(12, theme: theme),
        textAlign: TextAlign.center,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tipButton(theme, _store.coffeeProduct, '☕', 'Coffee'),
        const SizedBox(width: 14),
        _tipButton(
            theme, _store.chocolateProduct, '🍫', 'Chocolate'),
      ],
    );
  }

  Widget _tipButton(FillThemeDef theme, ProductDetails? product,
      String emoji, String label) {
    if (product == null) return const SizedBox.shrink();
    return FillButton(
      label: '$label ${product.price}',
      emoji: emoji,
      small: true,
      primary: false,
      onTap: () {
        widget.audio.click();
        _store.buyTip(product);
      },
      theme: theme,
    );
  }
}
