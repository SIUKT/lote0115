import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/providers/language_provider.dart';
import 'package:lote0115/providers/user_data_provider.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languages = ref.watch(languagesProvider);
    final userData = ref.watch(userDataProvider);
    final selectedLanguages = userData?.languages ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择语言'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final language = languages[index];
          final isSelected = selectedLanguages.contains(language.code);
          final order = selectedLanguages.indexOf(language.code) + 1;

          return Material(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final newLanguages = List<String>.from(selectedLanguages);
                if (isSelected) {
                  newLanguages.remove(language.code);
                } else {
                  newLanguages.add(language.code);
                }
                ref
                    .read(userDataProvider.notifier)
                    .updateLanguages(newLanguages);
              },
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          language.nativeName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          language.zhName,
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 5,
                      left: 10,
                      child: Text(
                        '$order',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
