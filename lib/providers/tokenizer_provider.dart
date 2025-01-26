import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tokenizer/tokenizer_service.dart';
import '../services/tokenizer/local_tokenizer_service.dart';

final tokenizerProvider = Provider<TokenizerService>((ref) {
  return LocalTokenizerService();
});
