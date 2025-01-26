import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/providers/user_data_provider.dart';
import 'package:lote0115/screens/language_selection_screen.dart';
import 'package:lote0115/screens/api_settings_screen.dart';
import 'package:lote0115/widgets/data_transfer_dialog.dart';
import 'package:lote0115/providers/data_transfer_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          if (userState?.userId == null) ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('登录'),
              onTap: () {
                // TODO: Implement login with Supabase
              },
            ),
          ] else ...[
            ListTile(
              leading: CircleAvatar(
                backgroundImage: userState?.avatar != null
                    ? NetworkImage(userState!.avatar!)
                    : null,
                child:
                    userState?.avatar == null ? const Icon(Icons.person) : null,
              ),
              title: Text(userState?.username ?? 'User'),
              subtitle: Text(userState?.email ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  ref.read(userDataProvider.notifier).logout();
                },
              ),
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('选择语言'),
            subtitle: Text(
              userState?.languages.map((e) => e.toUpperCase()).join(', ') ??
                  'No languages selected',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguageSelectionScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('导出/导入数据'),
            subtitle: const Text('导出/导入所有数据为json/csv/txt文件'),
            leading: const Icon(Icons.import_export),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Consumer(
                  builder: (context, ref, child) {
                    final dataTransferService =
                        ref.watch(dataTransferServiceProvider);
                    return DataTransferDialog(
                      dataTransferService: dataTransferService,
                    );
                  },
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('API 设置'),
            subtitle: Text(
              ref.watch(userDataProvider)?.currentApi?.name ??
                  '免费 API 余额：${userState?.usageCount ?? 0}/${userState?.usageLimit ?? 10}',
            ),
            leading: const Icon(Icons.api),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApiSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
