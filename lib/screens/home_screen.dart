import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:math';
import 'package:lote0115/models/note.dart';
import 'package:lote0115/providers/note_provider.dart';
import 'package:lote0115/providers/user_data_provider.dart';
import 'package:lote0115/screens/note_details_screen.dart';
import 'package:lote0115/screens/primary_details_screen.dart';
import 'package:lote0115/screens/settings_screen.dart';
import 'package:lote0115/widgets/note_input_sheet.dart';
import 'package:lote0115/widgets/note_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String selectedTag = 'All';
  bool _isSearching = false;
  final _searchController = TextEditingController();
  List<String> _languages = [];
  String _searchQuery = '';
  int _currentLanguagePage = 0;

  Future<void> _saveCurrentPage(int currentPage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentPage', currentPage);
  }

  Future<void> _loadCurrentPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentLanguagePage = prefs.getInt('currentPage') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentPage();
  }

  List<String> getItemLanguages(String primaryLanguage) {
    if (_languages.length <= 5) {
      final result = List<String>.from(_languages);
      return result;
    }
    List<String> newLanguages = List<String>.from(_languages);
    newLanguages.remove(primaryLanguage);

    final startIndex = _currentLanguagePage * 4;

    if (startIndex >= newLanguages.length) {
      // Reset to first page if somehow we're out of bounds
      _currentLanguagePage = 0;
      return newLanguages.sublist(0, 4)..insert(0, primaryLanguage);
    }
    // Take up to 5 languages from current position, or whatever remains
    return newLanguages.sublist(
        startIndex,
        (startIndex + 4) > newLanguages.length
            ? newLanguages.length
            : startIndex + 4)
      ..insert(0, primaryLanguage);
  }

  // List<String> get _currentLanguages {
  //   List<String> languages = List<String>.from(_languages);
  //   if (languages.length <= 5) {
  //     return languages;
  //   }
  //   final startIndex = _currentLanguagePage * 5;

  //   if (startIndex >= languages.length) {
  //     // Reset to first page if somehow we're out of bounds
  //     _currentLanguagePage = 0;
  //     return languages.sublist(0, 5);
  //   }
  //   // Take up to 5 languages from current position, or whatever remains
  //   return languages.sublist(
  //       startIndex,
  //       (startIndex + 5) > languages.length
  //           ? languages.length
  //           : startIndex + 5);
  // }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Note> _filterNotes(List<Note> notes) {
    if (_searchQuery.isEmpty && selectedTag == 'All') {
      return notes;
    }

    final filteredNotes = notes.where((note) {
      bool matchesTag = selectedTag == 'All' ||
          (note.tags != null ? note.tags!.contains(selectedTag) : false);

      if (_searchQuery.isEmpty) {
        return matchesTag;
      }

      String searchLower = _searchQuery.toLowerCase();
      bool matchesContent = note.variants?.any((variant) {
            return variant.content?.toLowerCase().contains(searchLower) ??
                false;
          }) ??
          false;
      bool matchesContext =
          note.context?.toLowerCase().contains(searchLower) ?? false;
      bool matchesTags =
          note.tags?.any((tag) => tag.toLowerCase().contains(searchLower)) ??
              false;

      bool matchesQnA = note.variants?.any((variant) {
            return variant.qnas?.any((qna) {
                  return (qna.question?.toLowerCase().contains(searchLower) ??
                          false) ||
                      (qna.answer?.toLowerCase().contains(searchLower) ??
                          false);
                }) ??
                false;
          }) ??
          false;

      return matchesTag &&
          (matchesContent || matchesContext || matchesTags || matchesQnA);
    }).toList();

    return filteredNotes;
  }

  void _openRandomNote(List<Note> notes) {
    if (notes.isEmpty) return;

    // Collect all variants except the primary one from each note
    List<(Note, NoteVariant)> allVariants = [];
    for (var note in notes) {
      if (note.variants != null) {
        for (var variant in note.variants!) {
          if (!(variant.isPrimary == true)) {
            allVariants.add((note, variant));
          }
        }
      }
    }

    if (allVariants.isEmpty) return;

    // Get a random variant
    final random = Random();
    final randomPair = allVariants[random.nextInt(allVariants.length)];

    Widget destination = NoteDetailsScreen(
      note: randomPair.$1,
      language: randomPair.$2.language,
    );

    // Navigate to note details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => destination,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);

    final notes = ref.watch(noteProvider);
    final allTags = ['All', ...userData?.tags ?? []];
    _languages = List.unmodifiable(userData?.languages ?? []);
    final filteredNotes = _filterNotes(notes);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                ),
                style: Theme.of(context).textTheme.titleLarge,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('lote',
                style: TextStyle(
                    // fontSize: 24,
                    // fontWeight: FontWeight.bold,
                    )),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          if (_languages.length > 5)
            IconButton(
              icon: const Icon(Icons.switch_access_shortcut_outlined),
              onPressed: () {
                setState(() {
                  final totalPages = ((_languages.length - 1) / 4).ceil();
                  _currentLanguagePage =
                      (_currentLanguagePage + 1) % totalPages;
                  _saveCurrentPage(_currentLanguagePage);
                });
              },
            ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.star_border_outlined),
              onPressed: () {
                final notes = ref.read(noteProvider);
                _openRandomNote(notes);
              },
            ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.person_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            builder: (context) => const NoteInputSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          Container(
            height: 48,
            // margin: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allTags.length,
              itemBuilder: (context, index) {
                final tag = allTags[index];
                final isSelected = selectedTag == tag;
                // 计算当前tag的notes的数量
                final notes = filteredNotes;
                final tagNotes =
                    notes.where((note) => note.tags?.contains(tag) ?? false);
                final count = tag == 'All' ? notes.length : tagNotes.length;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      FilterChip(
                        side: BorderSide.none,
                        showCheckmark: false,
                        label: Text(
                          tag.length > 4 ? '${tag.substring(0, 4)}...' : tag,
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedTag = tag;
                            });
                          }
                        },
                      ),
                      if (isSelected)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final note = filteredNotes[index];

                final languages = getItemLanguages(note.primaryLanguage);
                if (languages.contains(note.primaryLanguage)) {
                  languages.removeWhere(
                      (language) => language == note.primaryLanguage);
                  languages.insert(0, note.primaryLanguage);
                } else if (languages.contains('')) {
                  languages.removeWhere((l) => l == '');
                  languages.insert(0, note.primaryLanguage);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SlidableAutoTriggerItem(
                    note: note,
                    child: NoteItem(
                      note: note,
                      languages: languages,
                      searchQuery: _searchQuery,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// consumer widget
class SlidableAutoTriggerItem extends ConsumerStatefulWidget {
  final Widget child;
  final Note note;

  const SlidableAutoTriggerItem({
    super.key,
    required this.child,
    required this.note,
  });

  @override
  ConsumerState<SlidableAutoTriggerItem> createState() =>
      _SlidableAutoTriggerItemState();
}

class _SlidableAutoTriggerItemState
    extends ConsumerState<SlidableAutoTriggerItem>
    with SingleTickerProviderStateMixin {
  bool _hasTriggered = false;
  bool _hasHapticFeedback = false;
  late final SlidableController _controller;
  final double _extentRatio = 0.15;
  double _lastProgress = 0;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    _controller = SlidableController(this);
    _controller.animation.addListener(_checkProgress);
  }

  @override
  void dispose() {
    _controller.animation.removeListener(_checkProgress);
    _controller.dispose();
    super.dispose();
  }

  void _checkProgress() {
    final progress = _controller.animation.value;

    // 开始滑动
    if (!_isSliding && progress.abs() > 0) {
      _isSliding = true;
    }

    // 只在首次超过阈值时触发haptic
    if (progress.abs() >= _extentRatio &&
        _lastProgress.abs() < _extentRatio &&
        !_hasTriggered) {
      _hasHapticFeedback = true;
      HapticFeedback.mediumImpact();
    }

    // 检测滑动结束
    if (_isSliding && progress.abs() == 0) {
      _isSliding = false;
      _hasHapticFeedback = false;
    }

    // 如果滑动停止但没有完全展开，自动回弹
    if (_isSliding &&
        progress == _lastProgress &&
        progress.abs() > 0 &&
        progress.abs() < _extentRatio * 1.2) {
      _controller.close();
    }

    _lastProgress = progress;
  }

  Future<void> _closeWithAnimation() async {
    _controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.note.id),
      controller: _controller,
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: _extentRatio,
        openThreshold: _extentRatio * 1.2,
        dismissible: DismissiblePane(
          onDismissed: () {},
          closeOnCancel: true,
          dismissThreshold: _extentRatio,
          confirmDismiss: () async {
            if (!_hasTriggered) {
              setState(() => _hasTriggered = true);
              await _closeWithAnimation();
              if (!mounted) return false;

              final BuildContext currentContext = context;
              await showModalBottomSheet(
                context: currentContext,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                builder: (context) => NoteInputSheet(note: widget.note),
              );

              if (!mounted) return false;
              setState(() {
                _hasTriggered = false;
                _hasHapticFeedback = false;
              });
            }
            return false;
          },
        ),
        children: [
          CustomSlidableAction(
            onPressed: (_) {},
            autoClose: true,
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Colors.white,
            child: const Text(
              '编辑',
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: _extentRatio,
        openThreshold: _extentRatio * 1.2,
        dismissible: DismissiblePane(
          onDismissed: () {},
          closeOnCancel: true,
          dismissThreshold: _extentRatio,
          confirmDismiss: () async {
            if (!_hasTriggered) {
              setState(() => _hasTriggered = true);
              await _closeWithAnimation();
              if (!mounted) return false;

              final BuildContext currentContext = context;
              bool? confirm = await showDialog<bool>(
                context: currentContext,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('确认删除'),
                    content: const Text('你确定要删除该笔记吗？'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('删除'),
                      ),
                    ],
                  );
                },
              );

              if (!mounted) return false;

              if (confirm ?? false) {
                ref.read(noteProvider.notifier).deleteNote(widget.note);
                if (!mounted) return false;
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(content: Text('笔记已删除')),
                );
              }
              setState(() {
                _hasTriggered = false;
                _hasHapticFeedback = false;
              });
            }
            return false;
          },
        ),
        children: [
          CustomSlidableAction(
            onPressed: (_) {},
            autoClose: true,
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}

              // if (widget.note.language == widget.note.primaryLanguage) {
              //   await Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) =>
              //           PrimaryDetailsScreen(note: widget.note),
              //     ),
              //   );
              // } else {
              //   await Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => NoteDetailsScreen(note: widget.note),
              //     ),
              //   );
              // }