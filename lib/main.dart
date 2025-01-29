import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:lote0115/models/note.dart';
import 'package:lote0115/models/user_data.dart';
import 'package:lote0115/providers/isar_provider.dart';
import 'package:lote0115/providers/shared_prefs_provider.dart';
import 'package:lote0115/screens/home_screen.dart';
import 'package:lote0115/screens/game_screen.dart';
import 'package:lote0115/widgets/note_input_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [NoteSchema, UserDataSchema],
    directory: dir.path,
  );
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'lote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff8acf00),
          // seedColor: Color(0xff4d6bfe),
          // brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: IndexedStack(
      //   index: _selectedIndex,
      //   children: const [
      //     HomeScreen(),
      //     GameScreen(),
      //   ],
      // ),
      body: const HomeScreen(),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        elevation: 0,
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) => const NoteInputSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // bottomNavigationBar: Container(
      //   // decoration: BoxDecoration(
      //   //   border: Border(
      //   //     top: BorderSide(
      //   //       color: Theme.of(context).dividerColor,
      //   //       width: 0.5,
      //   //     ),
      //   //   ),
      //   // ),
      //   child: BottomAppBar(
      //     height: 60,
      //     padding: EdgeInsets.zero,
      //     child: Row(
      //       mainAxisAlignment: MainAxisAlignment.spaceAround,
      //       children: [
      //         Expanded(
      //           child: GestureDetector(
      //             child: Icon(
      //               Icons.home,
      //               color: _selectedIndex == 0
      //                   ? Theme.of(context).colorScheme.primary
      //                   : Colors.grey,
      //             ),
      //             onTap: () => setState(() => _selectedIndex = 0),
      //           ),
      //         ),
      //         ElevatedButton(
      //           style: ElevatedButton.styleFrom(
      //             shape: const CircleBorder(),
      //             padding: const EdgeInsets.all(16),
      //             backgroundColor:
      //                 Theme.of(context).colorScheme.primaryContainer,
      //           ),
      //           onPressed: () {
      //             showModalBottomSheet(
      //               context: context,
      //               isScrollControlled: true,
      //               builder: (context) => const NoteInputSheet(),
      //             );
      //           },
      //           child: const Icon(
      //             Icons.add,
      //           ),
      //         ),
      //         Expanded(
      //           child: GestureDetector(
      //             child: Icon(
      //               Icons.games,
      //               color: _selectedIndex == 1
      //                   ? Theme.of(context).colorScheme.primary
      //                   : Colors.grey,
      //             ),
      //             onTap: () => setState(() => _selectedIndex = 1),
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }
}
