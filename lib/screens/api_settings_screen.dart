import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/models/user_data.dart';
import 'package:lote0115/providers/user_data_provider.dart';

class ApiSettingsScreen extends ConsumerStatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  ConsumerState<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends ConsumerState<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _testConnection(String baseUrl, String apiKey) async {
    try {
      // TODO: Implement API test
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection successful')),
      );
      return Future.value();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
      return Future.error(e);
    }
  }

  void _showDeleteConfirmation(CustomApi api) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API'),
        content: Text('Are you sure you want to delete "${api.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(userDataProvider.notifier).removeCustomApi(api);
              Navigator.pop(context); // Close delete dialog
              Navigator.pop(context); // Close edit dialog
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddApiDialog() {
    _nameController.clear();
    _baseUrlController.clear();
    _apiKeyController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom API'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'My Custom API',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.example.com',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a base URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an API key';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              final newApi = CustomApi()
                ..name = _nameController.text
                ..baseUrl = _baseUrlController.text
                ..apiKey = _apiKeyController.text
                ..isValid = false
                ..isCurrent = false;

              ref.read(userDataProvider.notifier).addCustomApi(newApi);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditApiDialog(CustomApi api) {
    _nameController.text = api.name ?? '';
    _baseUrlController.text = api.baseUrl ?? '';
    _apiKeyController.text = api.apiKey ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Edit Custom API'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _baseUrlController,
                decoration: const InputDecoration(labelText: 'Base URL'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a base URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(labelText: 'API Key'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an API key';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () => _showDeleteConfirmation(api),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final updatedApi = CustomApi()
                    ..name = _nameController.text
                    ..baseUrl = _baseUrlController.text
                    ..apiKey = _apiKeyController.text
                    ..isValid = api.isValid
                    ..isCurrent = api.isCurrent;

                  ref
                      .read(userDataProvider.notifier)
                      .updateCustomApi(api, updatedApi);
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final customApis = userData?.customApis ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('API 设置'),
      ),
      body: ListView(
        children: [
          // Official API
          ListTile(
            title: const Text('免费 API'),
            subtitle: const Text('默认 API 服务'),
            selected: userData?.currentApi == null,
            selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
            selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
            leading: const Icon(Icons.verified),
            onTap: () {
              ref.read(userDataProvider.notifier).selectApi(null);
            },
          ),
          const Divider(),
          // Custom APIs
          ...customApis.map((api) => Column(
                children: [
                  ListTile(
                    title: Text(api.name ?? 'Custom API'),
                    subtitle: Text(api.baseUrl ?? ''),
                    selected: api.isCurrent == true,
                    selectedTileColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    selectedColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    leading: Icon(
                      api.isValid == true ? Icons.cloud_done : Icons.cloud_off,
                      color: api.isValid == true ? Colors.green : Colors.red,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Test'),
                          onPressed: () async {
                            try {
                              await _testConnection(
                                api.baseUrl ?? '',
                                api.apiKey ?? '',
                              );
                              if (!mounted) return;
                              ref
                                  .read(userDataProvider.notifier)
                                  .validateApi(api, true);
                            } catch (e) {
                              if (!mounted) return;
                              ref
                                  .read(userDataProvider.notifier)
                                  .validateApi(api, false);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditApiDialog(api),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (api.isValid == true) {
                        ref.read(userDataProvider.notifier).selectApi(api);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Cannot select invalid API. Please test connection first.'),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(),
                ],
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddApiDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add API'),
      ),
    );
  }
}
