import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:lote0115/models/note.dart';
import 'package:path_provider/path_provider.dart';

enum ExportFormat {
  json,
  csv,
  txt,
}

class DataTransferService {
  final Isar isar;

  DataTransferService(this.isar);

  Future<String?> exportData(ExportFormat format) async {
    try {
      final notes = await isar.notes.where().findAll();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      String fileName;
      String content;

      switch (format) {
        case ExportFormat.json:
          fileName = 'notes_$timestamp.json';
          content = jsonEncode(notes.map((note) => note.toJson()).toList());
          break;
        case ExportFormat.csv:
          fileName = 'notes_$timestamp.csv';
          final csvData = notes.map((note) => note.toCsvRow()).toList();
          content = const ListToCsvConverter().convert(csvData);
          break;
        case ExportFormat.txt:
          fileName = 'notes_$timestamp.txt';
          content = notes.map((note) => note.toString()).join('\n\n');
          break;
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      debugPrint('Error exporting data: $e');
      return null;
    }
  }

  Future<bool> importData(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final extension = filePath.split('.').last.toLowerCase();

      List<Map<String, dynamic>> data;
      switch (extension) {
        case 'json':
          data = List<Map<String, dynamic>>.from(jsonDecode(content));
          break;
        case 'csv':
          final csvTable = const CsvToListConverter().convert(content);
          // Assuming first row is headers
          final headers = csvTable[0].cast<String>();
          data = csvTable.skip(1).map((row) {
            Map<String, dynamic> item = {};
            for (var i = 0; i < headers.length; i++) {
              item[headers[i]] = row[i];
            }
            return item;
          }).toList();
          break;
        case 'txt':
          // Split by double newline to separate entries
          final entries = content.split('\n\n');
          data = entries.map((entry) => {'content': entry.trim()}).toList();
          break;
        default:
          throw Exception('Unsupported file format');
      }

      await isar.writeTxn(() async {
        // Clear existing data
        await isar.notes.clear();
        // Import new data
        for (var item in data) {
          final note = Note()
            ..cloudId = item['cloudId'] as String?
            ..createdAt = DateTime.tryParse(item['createdAt'] as String? ?? '') ?? DateTime.now()
            ..updatedAt = DateTime.tryParse(item['updatedAt'] as String? ?? '') ?? DateTime.now()
            ..context = item['context'] as String?
            ..tags = (item['tags'] as List<dynamic>?)?.cast<String>()
            ..variants = (item['variants'] as List<dynamic>?)?.map((v) {
              final variant = NoteVariant()
                ..language = v['language'] as String
                ..isPrimary = v['isPrimary'] as bool
                ..isCurrent = v['isCurrent'] as bool
                ..content = v['content'] as String
                ..audioUrl = v['audioUrl'] as String?
                ..explaination = v['explaination'] as String?
                ..reviewCount = v['reviewCount'] as int
                ..lastReviewAt = DateTime.tryParse(v['lastReviewAt'] as String? ?? '')
                ..createdAt = DateTime.tryParse(v['createdAt'] as String? ?? '') ?? DateTime.now()
                ..editedAt = DateTime.tryParse(v['editedAt'] as String? ?? '');
              return variant;
            }).toList();
          await isar.notes.put(note);
        }
      });

      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }

  Future<String?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv', 'txt'],
    );

    if (result != null) {
      return result.files.single.path;
    }
    return null;
  }

  Future<String?> pickExportLocation(String fileName) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: fileName,
    );

    return outputFile;
  }
}
