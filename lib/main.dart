import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:lote0115/models/note.dart';
import 'package:lote0115/models/user_data.dart';
import 'package:lote0115/providers/isar_provider.dart';
import 'package:lote0115/providers/shared_prefs_provider.dart';
import 'package:lote0115/providers/user_data_provider.dart';
import 'package:lote0115/screens/home_screen.dart';
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
    final userState = ref.watch(userDataProvider);

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
      home: userState == null
          ? const Center(child: CircularProgressIndicator())
          : const HomeScreen(),
    );
  }
}
