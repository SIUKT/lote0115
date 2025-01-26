import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_transfer_service.dart';
import 'isar_provider.dart';

final dataTransferServiceProvider = Provider<DataTransferService>((ref) {
  final isar = ref.watch(isarProvider);
  return DataTransferService(isar);
});
