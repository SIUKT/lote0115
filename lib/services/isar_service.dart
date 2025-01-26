import 'package:isar/isar.dart';
import 'package:lote0115/models/note.dart';
import 'package:lote0115/models/user_data.dart';

class IsarService {
  late final Isar _isar;

  IsarService(this._isar);

  // Note operations
  Future<void> saveNote(Note note) => _isar.writeTxn(() async {
        await _isar.notes.put(note);
      });

  Future<List<Note>> getNotes() => _isar.notes.where().findAll();

  // UserState operations
  Future<UserData?> getUserData() async {
    return await _isar.userDatas.where().findFirst();
  }

  Future<void> saveUserData(UserData userData) => _isar.writeTxn(() async {
        await _isar.userDatas.put(userData);
        print('fffff userData: ${userData.tags}');
      });

  Future<void> initializeUserData() async {
    final existingState = await getUserData();
    if (existingState == null) {
      final newState = UserData();
      await saveUserData(newState);
    }
  }

  Future<void> deleteNote(Note note) async {
    await _isar.writeTxn(() async {
      await _isar.notes.delete(note.id);
    });
  }
}
