import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/models/note.dart';
import 'package:lote0115/providers/note_provider.dart';
import 'package:lote0115/widgets/scramble_text.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _pageController = PageController();
  final Map<int, ScrollController> _scrollControllers = {};
  List<(Note, NoteVariant)> _gameVariants = [];
  List<bool> _completedQuestions = [];
  double _progressValue = 0.0;
  String? _selectedLanguage;
  Set<String> _availableLanguages = {};

  Drag? _drag;
  ScrollController? _activeScrollController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    // _drag?.dispose();
    super.dispose();
  }

  ScrollController _getScrollController(int index) {
    if (!_scrollControllers.containsKey(index)) {
      _scrollControllers[index] = ScrollController();
    }
    return _scrollControllers[index]!;
  }

  void _handleDragStart(DragStartDetails details) {
    final currentScrollController = _getScrollController(_currentPageIndex);

    if (currentScrollController.hasClients &&
        currentScrollController.position.context.storageContext != null) {
      final RenderBox renderBox = currentScrollController
          .position.context.storageContext
          .findRenderObject() as RenderBox;
      if (renderBox.paintBounds
          .shift(renderBox.localToGlobal(Offset.zero))
          .contains(details.globalPosition)) {
        _activeScrollController = currentScrollController;
        _drag = _activeScrollController!.position.drag(details, _disposeDrag);
        return;
      }
    }
    _activeScrollController = _pageController;
    _drag = _pageController.position.drag(details, _disposeDrag);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final currentScrollController = _getScrollController(_currentPageIndex);

    if (_activeScrollController == currentScrollController) {
      // 如果在内容顶部继续向下拖动，切换到页面控制器
      if (details.primaryDelta! > 0 &&
          _activeScrollController!.position.pixels ==
              _activeScrollController!.position.minScrollExtent) {
        _activeScrollController = _pageController;
        _drag?.cancel();
        _drag = _pageController.position.drag(
            DragStartDetails(
                globalPosition: details.globalPosition,
                localPosition: details.localPosition),
            _disposeDrag);
      }
      // 如果在内容底部继续向上拖动，切换到页面控制器
      else if (details.primaryDelta! < 0 &&
          _activeScrollController!.position.pixels ==
              _activeScrollController!.position.maxScrollExtent) {
        _activeScrollController = _pageController;
        _drag?.cancel();
        _drag = _pageController.position.drag(
            DragStartDetails(
                globalPosition: details.globalPosition,
                localPosition: details.localPosition),
            _disposeDrag);
      }
    }
    _drag?.update(details);
  }

  void _handleDragEnd(DragEndDetails details) {
    _drag?.end(details);
  }

  void _handleDragCancel() {
    _drag?.cancel();
  }

  void _disposeDrag() {
    _drag = null;
  }

  void _updateAvailableLanguages(List<Note> notes) {
    Set<String> languages = {};
    for (var note in notes) {
      if (note.variants != null) {
        for (var variant in note.variants!) {
          if (variant.language != null &&
              variant.content != null &&
              variant.content != note.primaryContent) {
            languages.add(variant.language!);
          }
        }
      }
    }
    _availableLanguages = languages;
  }

  void _initializeGame() {
    final notes = ref.read(noteProvider);
    _updateAvailableLanguages(notes);
    List<(Note, NoteVariant)> allVariants = [];

    for (var note in notes) {
      if (note.variants != null) {
        for (var variant in note.variants!) {
          if (variant.content != null &&
              variant.language != null &&
              variant.content != note.primaryContent &&
              (_selectedLanguage == null ||
                  variant.language == _selectedLanguage)) {
            allVariants.add((note, variant));
          }
        }
      }
    }

    if (allVariants.isNotEmpty) {
      allVariants.shuffle();
      setState(() {
        _gameVariants = allVariants.take(5).toList();
        _completedQuestions = List.filled(_gameVariants.length, false);
        _progressValue = 1 / _gameVariants.length;
      });
    } else {
      setState(() {
        _gameVariants = [];
        _completedQuestions = [];
        _progressValue = 0.0;
      });
    }
  }

  void _onQuestionCompleted(int index, bool isCorrect) {
    setState(() {
      _completedQuestions[index] = isCorrect;
    });
  }

  void _startNewGame() {
    setState(() {
      _progressValue = 0.0;
    });
    _pageController
        .animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )
        .then((_) {
      _initializeGame();
    });
  }

  void _jumpToFirstIncomplete() {
    final index = _completedQuestions.indexOf(false);
    if (index != -1) {
      setState(() {
        _progressValue = (index + 1) / _gameVariants.length;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateProgress(int page) {
    if (_gameVariants.isEmpty) return;

    setState(() {
      if (page >= _gameVariants.length) {
        _progressValue = 1.0;
      } else {
        _progressValue = (page + 1) / _gameVariants.length;
      }
    });
  }

  void _showLanguageFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择语言'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('所有语言'),
              selected: _selectedLanguage == null,
              onTap: () {
                setState(() => _selectedLanguage = null);
                Navigator.pop(context);
                _startNewGame();
              },
            ),
            const Divider(),
            ..._availableLanguages.map((lang) => ListTile(
                  title: Text(lang),
                  selected: _selectedLanguage == lang,
                  onTap: () {
                    setState(() => _selectedLanguage = lang);
                    Navigator.pop(context);
                    _startNewGame();
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(noteProvider, (previous, next) {
      if (previous != next) {
        _initializeGame();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageFilter,
          ),
        ],
        bottom: _gameVariants.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progressValue,
                  minHeight: 2,
                ),
              ),
      ),
      body: _gameVariants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedLanguage == null
                        ? 'No variants available for game'
                        : 'No variants available for $_selectedLanguage',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeGame,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RawGestureDetector(
              gestures: {
                VerticalDragGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                        VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer(),
                  (VerticalDragGestureRecognizer instance) {
                    instance
                      ..onStart = _handleDragStart
                      ..onUpdate = _handleDragUpdate
                      ..onEnd = _handleDragEnd
                      ..onCancel = _handleDragCancel;
                  },
                ),
              },
              behavior: HitTestBehavior.opaque,
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                onPageChanged: (index) {
                  _currentPageIndex = index;
                  _updateProgress(index);
                },
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _gameVariants.length + 1,
                itemBuilder: (context, index) {
                  if (index == _gameVariants.length) {
                    final allCompleted = !_completedQuestions.contains(false);
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            allCompleted
                                ? 'Congratulations! All questions completed!'
                                : 'You still have some questions to complete',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          if (allCompleted)
                            ElevatedButton(
                              onPressed: _startNewGame,
                              child: const Text('Start New Game'),
                            )
                          else
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: _jumpToFirstIncomplete,
                                  child: const Text('Continue Game'),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _startNewGame,
                                  child: const Text('Give Up & Start New Game'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }

                  final (note, variant) = _gameVariants[index];
                  final scrollController = _getScrollController(index);

                  return SingleChildScrollView(
                      controller: scrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade50,
                                    Colors.blue.shade100.withValues(alpha: 0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.shade100,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.translate_rounded,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      note.primaryContent,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue.shade900,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: variant.content!
                                .split(RegExp(r'\n{2,}|\n'))
                                .map(
                                  (paragraph) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: paragraph
                                        .split(RegExp(r'(?<=[.!?。！？])\s*'))
                                        .where((sentence) =>
                                            sentence.trim().isNotEmpty)
                                        .map(
                                          (sentence) => Padding(
                                            padding: const EdgeInsets.all(0.0),
                                            child: ScrambleText(
                                              sentence: sentence,
                                              translation: note.primaryContent,
                                              language: variant.language!,
                                              onCheckResult: (isCorrect) =>
                                                  _onQuestionCompleted(
                                                      index, isCorrect),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ));
                },
              ),
            ),
    );
  }
}
