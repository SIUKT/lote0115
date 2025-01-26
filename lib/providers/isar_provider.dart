import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:lote0115/services/isar_service.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar instance must be initialized first');
});

final isarServiceProvider = Provider<IsarService>((ref) {
  final isar = ref.watch(isarProvider);
  return IsarService(isar);
});
