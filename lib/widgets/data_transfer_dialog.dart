import 'package:flutter/material.dart';
import '../services/data_transfer_service.dart';

class DataTransferDialog extends StatelessWidget {
  final DataTransferService dataTransferService;

  const DataTransferDialog({
    super.key,
    required this.dataTransferService,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import/Export Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose an action:'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _showImportDialog(context),
                child: const Text('Import'),
              ),
              ElevatedButton(
                onPressed: () => _showExportDialog(context),
                child: const Text('Export'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final filePath = await dataTransferService.pickFile();
    if (filePath == null) return;

    if (!context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Import'),
        content: const Text(
          'This will replace all existing data. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    final success = await dataTransferService.importData(filePath);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Data imported successfully' : 'Failed to import data',
        ),
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final format = await showDialog<ExportFormat>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExportFormat.values.map((format) {
            return ListTile(
              title: Text(format.name.toUpperCase()),
              onTap: () => Navigator.of(context).pop(format),
            );
          }).toList(),
        ),
      ),
    );

    if (format == null || !context.mounted) return;

    final filePath = await dataTransferService.exportData(format);
    if (!context.mounted) return;

    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported to: $filePath'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export data'),
        ),
      );
    }
  }
}
