import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/models/user_data.dart';
import 'package:lote0115/providers/isar_provider.dart';
import 'package:lote0115/services/isar_service.dart';

final userDataProvider =
    StateNotifierProvider<UserDataNotifier, UserData?>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return UserDataNotifier(isarService);
});

class UserDataNotifier extends StateNotifier<UserData?> {
  final IsarService isarService;

  UserDataNotifier(this.isarService) : super(null) {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    await isarService.initializeUserData();
    state = await isarService.getUserData();
    // initializeTagsFromNotes();
  }

  // Future<void> initializeTagsFromNotes() async {
  //   if (state != null) {
  //     final notes = await isarService.getNotes();
  //     final List<String> tags = notes
  //         .expand((note) => note.tags ?? <String>[])
  //         .toSet()
  //         .toList()
  //         .reversed
  //         .toList();
  //     final newUserData = state!.copyWith(tags: tags);
  //     await updateUserData(newUserData);
  //   }
  // }

  Future<void> updateUserData(UserData newUserData) async {
    await isarService.saveUserData(newUserData);
    state = newUserData;
  }

  Future<void> _saveUserData() async {
    await isarService.saveUserData(state!);
  }

  Future<void> updateLanguages(List<String> languages) async {
    if (state != null) {
      final newUserData = state!.copyWith(languages: languages);
      await updateUserData(newUserData);
    }
  }

  Future<void> addTags(List<String> tags) async {
    if (state != null) {
      final oldTags = List<String>.from(state!.tags ?? []);
      for (var tag in tags) {
        if (oldTags.contains(tag)) {
          oldTags.remove(tag);
        }
      }
      final newTags = [...tags, ...oldTags];
      print('fucking newTags: $newTags');
      final newUserData = state!.copyWith(tags: newTags);
      print('fucking newUserData tags: ${newUserData.tags}');
      await updateUserData(newUserData);
    }
  }

  Future<void> removeTags(List<String> tags) async {
    if (state != null) {
      final newTags = List<String>.from(state!.tags ?? []);
      for (var tag in tags) {
        if (newTags.contains(tag)) {
          newTags.remove(tag);
        }
      }
      final newUserData = state!.copyWith(tags: newTags);
      await updateUserData(newUserData);
    }
  }

  Future<void> updateTags(List<String> tags) async {
    if (state != null) {
      print('tags: $tags');
      final newUserData = state!.copyWith(tags: tags);
      await updateUserData(newUserData);
    }
  }

  Future<void> login(String userId, String username, String? email,
      String? avatar, String? token) async {
    if (state != null) {
      final newUserData = state!.copyWith(
        userId: userId,
        username: username,
        email: email,
        avatar: avatar,
        token: token,
      );

      await updateUserData(newUserData);
    }
  }

  Future<void> logout() async {
    if (state != null) {
      final newUserData = state!.copyWith(
        userId: null,
        username: null,
        email: null,
        avatar: null,
        token: null,
        vipUntil: null,
      );

      await updateUserData(newUserData);
    }
  }

  Future<void> addCustomApi(CustomApi api) async {
    if (state == null) return;

    final customApis = List<CustomApi>.from(state!.customApis ?? []);
    customApis.add(api);

    state = state!.copyWith(customApis: customApis);
    await _saveUserData();
  }

  Future<void> updateCustomApi(CustomApi oldApi, CustomApi newApi) async {
    if (state == null) return;

    final customApis = List<CustomApi>.from(state!.customApis ?? []);
    final index = customApis.indexOf(oldApi);
    if (index != -1) {
      customApis[index] = newApi;
      state = state!.copyWith(customApis: customApis);
      await _saveUserData();
    }
  }

  Future<void> removeCustomApi(CustomApi api) async {
    if (state == null) return;

    final customApis = List<CustomApi>.from(state!.customApis ?? []);
    customApis.remove(api);

    state = state!.copyWith(customApis: customApis);
    await _saveUserData();
  }

  Future<void> selectApi(CustomApi? api) async {
    if (state == null) return;

    final customApis = List<CustomApi>.from(state!.customApis ?? []);
    for (var existingApi in customApis) {
      existingApi.isCurrent = existingApi == api;
    }

    state = state!.copyWith(customApis: customApis);
    await _saveUserData();
  }

  Future<void> validateApi(CustomApi api, bool isValid) async {
    if (state == null) return;

    final customApis = List<CustomApi>.from(state!.customApis ?? []);
    final index = customApis.indexOf(api);
    if (index != -1) {
      customApis[index].isValid = isValid;
      state = state!.copyWith(customApis: customApis);
      await _saveUserData();
    }
  }
}
