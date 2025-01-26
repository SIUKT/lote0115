import 'package:isar/isar.dart';

part 'user_data.g.dart';

@collection
class UserData {
  Id id = Isar.autoIncrement;

  String? userId;
  String? username;
  String? email;
  String? avatar;
  String? token;
  List<String>? tags;
  List<CustomApi>? customApis;
  DateTime? vipUntil;

  int? usageLimit;
  int? usageCount;

  List<String> languages = const [];

  CustomApi? get currentApi {
    if (customApis == null || customApis!.isEmpty) return null;
    return customApis?.where((api) => api.isCurrent == true && api.isValid == true).firstOrNull;
  }

  UserData() {
    usageLimit = 10;
    usageCount = 0;
  }

  UserData copyWith({
    String? userId,
    String? username,
    String? email,
    String? avatar,
    String? token,
    List<String>? tags,
    int? usageLimit,
    int? usageCount,
    List<String>? languages,
    List<CustomApi>? customApis,
    DateTime? vipUntil,
  }) {
    return UserData()
      ..id = id
      ..userId = userId ?? this.userId
      ..username = username ?? this.username
      ..email = email ?? this.email
      ..avatar = avatar ?? this.avatar
      ..token = token ?? this.token
      ..usageLimit = usageLimit ?? this.usageLimit
      ..usageCount = usageCount ?? this.usageCount
      ..languages = languages ?? this.languages
      ..tags = tags ?? this.tags
      ..customApis = customApis ?? this.customApis
      ..vipUntil = vipUntil ?? this.vipUntil;
  }
}

@embedded
class CustomApi {
  String? name;
  String? baseUrl;
  String? apiKey;
  bool? isCurrent;
  bool? isValid;
}
