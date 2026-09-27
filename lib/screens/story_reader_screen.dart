import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/books.dart';
import '../content/characters.dart';
import '../core/music_route.dart';
import '../core/routes.dart';
import '../core/sound.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../premium/premium_service.dart';
import '../state/app_state.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/scene_view.dart';
import 'reward_screen.dart';

/// Picture-book reader with "Read to me" narration (English or Spanish),
/// word highlighting and tap-a-word pronunciation.
class StoryReaderScreen extends StatefulWidget {
  const StoryReaderScreen({super.key, required this.book});
  final Book book;

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _Word {
  _Word(this.text, this.start, this.end);
  final String text;
  final int start;
  final int end;
}

class _StoryReaderScreenState extends State<StoryReaderScreen> with MusicAware {
  /// -1 = cover.
  int _page = -1;
  bool _readToMe = false;
  late bool _spanish = context.read<AppState>().settings.readAloudSpanish;
  int _highlight = -1;
  int _session = 0;
  bool _finished = false;

  @override
  bool get wantsMusic => false;

  SpeechService get _speech => context.read<SpeechService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _readTitle());
  }

  @override
  void dispose() {
    _session++;
    super.dispose();
  }

  String get _lang => _spanish ? SpeechService.spanish : _speech.englishLocale;

  void _readTitle() {
    if (!mounted) return;
    _speech.sayNow(widget.book.titleIn(_spanish), language: _lang);
  }

  List<_Word> _words(String text) {
    final result = <_Word>[];
    final re = RegExp(r'\S+');
    for (final m in re.allMatches(text)) {
      result.add(_Word(m.group(0)!, m.start, m.end));
    }
    return result;
  }

  Future<void> _readPage() async {
    if (_page < 0 || _page >= widget.book.pages.length) return;
    final session = ++_session;
    final text = widget.book.pages[_page].text(_spanish);
    final words = _words(text);
    setState(() => _highlight = -1);
    final started = DateTime.now();
    await _speech.say(
      text,
      language: _lang,
      onProgress: (_, start, end) {
        if (!mounted || session != _session) return;
        final i = words.indexWhere((w) => start >= w.start && start < w.end);
        if (i >= 0 && i != _highlight) setState(() => _highlight = i);
      },
    );
    if (!mounted || session != _session) return;
    setState(() => _highlight = -1);
    if (_readToMe) {
      // Give every page enough time to look at, even with the voice off.
      final minimum = Duration(milliseconds: 1500 + text.length * 45);
      final spent = DateTime.now().difference(started);
      await Future<void>.delayed(spent < minimum ? minimum - spent : const Duration(milliseconds: 900));
      if (!mounted || session != _session) return;
      _go(1);
    }
  }

  void _go(int delta) {
    final next = _page + delta;
    if (next < -1) return;
    if (next >= widget.book.pages.length) {
      _finish();
      return;
    }
    context.read<SoundService>().play(Sfx.page);
    _session++;
    _speech.stop();
    setState(() {
      _page = next;
      _highlight = -1;
    });
    if (_page >= 0 && _readToMe) {
      _readPage();
    } else if (_page == -1) {
      _readTitle();
    }
  }

  void _start(bool readToMe) {
    setState(() => _readToMe = readToMe);
    _go(1);
    if (!readToMe) {
      // Read-myself still says the first page once when tapped (speaker button).
      _speech.stop();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _session++;
    _speech.stop();
    final reward = context.read<AppState>().recordBook(widget.book, premium: context.read<PremiumService>().isPremium);
    context.read<SoundService>().play(Sfx.win);
    replaceScreen(
      context,
      RewardScreen(
        reward: reward,
        host: CharacterId.luna,
        message: _spanish ? '¡El fin!' : 'The End!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return Scaffold(
      backgroundColor: book.color.pastel,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  RoundButton(
                    icon: Icons.close_rounded,
                    size: 48,
                    semanticLabel: 'Close',
                    onTap: () {
                      _session++;
                      _speech.stop();
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      book.titleIn(_spanish),
                      overflow: TextOverflow.ellipsis,
                      style: KidText.display(22, color: book.color.darken(0.1)),
                    ),
                  ),
                  _LangToggle(
                    spanish: _spanish,
                    color: book.color,
                    onChanged: (v) {
                      _session++;
                      _speech.stop();
                      setState(() => _spanish = v);
                      if (_page >= 0 && _readToMe) {
                        _readPage();
                      } else if (_page == -1) {
                        _readTitle();
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  if (_page >= 0)
                    _ReadToMeToggle(
                      on: _readToMe,
                      color: book.color,
                      onChanged: (v) {
                        setState(() => _readToMe = v);
                        if (v) {
                          _readPage();
                        } else {
                          _session++;
                          _speech.stop();
                        }
                      },
                    ),
                ],
              ),
            ),
            Expanded(child: _page < 0 ? _cover() : _pageView()),
          ],
        ),
      ),
    );
  }

  Widget _cover() {
    final book = widget.book;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SceneView(scene: book.cover),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  book.titleIn(_spanish),
                  textAlign: TextAlign.center,
                  style: KidText.display(32, color: book.color.darken(0.15)),
                ),
                const SizedBox(height: 4),
                Text(
                  _spanish ? 'Un libro de Kids Learning Universe' : 'A Kids Learning Universe book',
                  textAlign: TextAlign.center,
                  style: KidText.body(14, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 18),
                BubblyButton.label(
                  label: _spanish ? 'Léemelo' : 'Read to me',
                  emoji: '🔊',
                  color: book.color,
                  width: 240,
                  onTap: () => _start(true),
                ),
                const SizedBox(height: 12),
                BubblyButton.label(
                  label: _spanish ? 'Leo yo' : 'Read myself',
                  emoji: '📖',
                  color: AppColors.adventure,
                  width: 240,
                  onTap: () => _start(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageView() {
    final book = widget.book;
    final page = book.pages[_page];
    final words = _words(page.text(_spanish));
    final longText = page.text(_spanish).length > 90;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: ClipRRect(
                key: ValueKey(_page),
                borderRadius: BorderRadius.circular(28),
                child: SceneView(scene: page.scene),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runSpacing: 4,
                          children: [
                            for (final (i, w) in words.indexed)
                              GestureDetector(
                                onTap: () {
                                  _session++;
                                  final clean = w.text.replaceAll(RegExp(r"[^\p{L}\p{N}'’-]", unicode: true), '');
                                  _speech.sayNow(clean, language: _lang);
                                  setState(() => _highlight = i);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: i == _highlight ? AppColors.star.withValues(alpha: 0.55) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(w.text, style: KidText.reading(longText ? 22 : 28, weight: FontWeight.w400)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    RoundButton(icon: Icons.arrow_back_rounded, onTap: () => _go(-1), color: Colors.white, semanticLabel: 'Previous page'),
                    const SizedBox(width: 10),
                    RoundButton(
                      icon: Icons.volume_up_rounded,
                      onTap: _readPage,
                      color: book.color,
                      iconColor: Colors.white,
                      semanticLabel: 'Read this page',
                    ),
                    Expanded(
                      child: Text(
                        '${_page + 1} / ${book.pages.length}',
                        textAlign: TextAlign.center,
                        style: KidText.display(18, color: AppColors.inkSoft),
                      ),
                    ),
                    BubblyButton(
                      onTap: () => _go(1),
                      color: AppColors.success,
                      depth: 5,
                      radius: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      semanticLabel: 'Next page',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _page == book.pages.length - 1 ? (_spanish ? 'Fin' : 'The End') : (_spanish ? 'Sigue' : 'Next'),
                            style: KidText.display(20, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle({required this.spanish, required this.color, required this.onChanged});
  final bool spanish;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(String label, bool value) => GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: spanish == value ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label, style: KidText.display(15, color: spanish == value ? Colors.white : color)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [option('English', false), option('Español', true)]),
    );
  }
}

class _ReadToMeToggle extends StatelessWidget {
  const _ReadToMeToggle({required this.on, required this.color, required this.onChanged});
  final bool on;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? color : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(on ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded, color: on ? Colors.white : color, size: 20),
            const SizedBox(width: 6),
            Text('Read to me', style: KidText.display(15, color: on ? Colors.white : color)),
          ],
        ),
      ),
    );
  }
}
