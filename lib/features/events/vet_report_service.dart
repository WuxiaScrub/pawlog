import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/database.dart';
import '../../models/event_type.dart';

/// Builds a printable / shareable PDF of a cat's care history, intended for
/// sharing with a vet. The events passed in are already filtered (by date
/// range and type) by the caller — this class only lays them out.
class VetReportService {
  const VetReportService();

  /// Generates the PDF bytes for [events] belonging to [cat].
  ///
  /// [rangeLabel] is a human-readable description of the date window (e.g.
  /// "Last 90 days" or "Mar 1 – Apr 15, 2026") shown in the header.
  /// [includeNotes] renders each event's free-text notes; [includeDetails]
  /// renders captured metadata (hairball present, product name, etc.);
  /// [includePhotos] embeds any photo attached to an event.
  Future<Uint8List> build({
    required Cat cat,
    required List<Event> events,
    required String rangeLabel,
    bool includeNotes = true,
    bool includeDetails = true,
    bool includePhotos = false,
  }) async {
    final doc = pw.Document(
      title: 'PawLog vet report — ${cat.name}',
      author: 'PawLog',
    );

    // Newest first, matching the on-screen history ordering.
    final sorted = [...events]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    final counts = <CatEventType, int>{};
    for (final e in sorted) {
      final type = CatEventTypeX.fromStorageKey(e.eventType);
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final generatedAt = DateFormat.yMMMd().add_jm().format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 48),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  '${cat.name} — care history',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'PawLog is a care log, not a substitute for veterinary care.   '
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ),
        build: (context) => [
          _buildTitle(cat, rangeLabel, generatedAt),
          pw.SizedBox(height: 16),
          _buildProfile(cat),
          pw.SizedBox(height: 16),
          if (counts.isNotEmpty) ...[
            _buildSummary(counts),
            pw.SizedBox(height: 20),
          ],
          _buildTimelineHeading(sorted.length),
          pw.SizedBox(height: 8),
          if (sorted.isEmpty)
            pw.Text(
              'No events recorded in this period.',
              style: const pw.TextStyle(color: PdfColors.grey600),
            )
          else
            _buildTimeline(
              sorted,
              includeNotes: includeNotes,
              includeDetails: includeDetails,
              includePhotos: includePhotos,
            ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildTitle(Cat cat, String rangeLabel, String generatedAt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Care History',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          cat.name,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal800,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Period: $rangeLabel',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.Text(
          'Generated $generatedAt by PawLog',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
        ),
      ],
    );
  }

  pw.Widget _buildProfile(Cat cat) {
    final rows = <List<String>>[];
    if (cat.breed != null && cat.breed!.isNotEmpty) {
      rows.add(['Breed', cat.breed!]);
    }
    if (cat.dateOfBirth != null) {
      final dob = cat.dateOfBirth!;
      final age = _ageString(dob);
      rows.add([
        'Date of birth',
        '${DateFormat.yMMMd().format(dob)}${age != null ? '  ($age)' : ''}',
      ]);
    }
    if (cat.weightKg != null) {
      rows.add(['Weight', '${cat.weightKg!.toStringAsFixed(2)} kg']);
    }

    if (rows.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final row in rows)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 90,
                    child: pw.Text(
                      row[0],
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(row[1],
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(Map<CatEventType, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in entries)
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  '${entry.key.label}: ${entry.value}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTimelineHeading(int count) {
    return pw.Text(
      'Timeline ($count ${count == 1 ? 'event' : 'events'})',
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    );
  }

  pw.Widget _buildTimeline(
    List<Event> events, {
    required bool includeNotes,
    required bool includeDetails,
    required bool includePhotos,
  }) {
    String? lastDay;
    final children = <pw.Widget>[];

    for (final event in events) {
      final day = DateFormat.yMMMEd().format(event.loggedAt);
      if (day != lastDay) {
        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
            child: pw.Text(
              day,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
              ),
            ),
          ),
        );
        lastDay = day;
      }
      children.add(_buildEventRow(
        event,
        includeNotes: includeNotes,
        includeDetails: includeDetails,
        includePhotos: includePhotos,
      ));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _buildEventRow(
    Event event, {
    required bool includeNotes,
    required bool includeDetails,
    required bool includePhotos,
  }) {
    final type = CatEventTypeX.fromStorageKey(event.eventType);
    final time = DateFormat.jm().format(event.loggedAt);

    final detailLines = <String>[];
    if (includeNotes &&
        event.notes != null &&
        event.notes!.trim().isNotEmpty) {
      detailLines.add(event.notes!.trim());
    }
    if (includeDetails) {
      detailLines.addAll(_readableMetadata(event.metadataJson));
    }

    final photoBytes =
        includePhotos ? _loadPhotoBytes(_photoPath(event.metadataJson)) : null;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.only(left: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.grey300, width: 1.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 55,
                child: pw.Text(
                  time,
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  type.label,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          for (final line in detailLines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 55, top: 1),
              child: pw.Text(
                line,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
              ),
            ),
          if (photoBytes != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 55, top: 4),
              child: pw.ClipRRect(
                horizontalRadius: 4,
                verticalRadius: 4,
                child: pw.Image(
                  pw.MemoryImage(photoBytes),
                  width: 120,
                  height: 120,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Flattens the event metadata JSON into human-readable "Key: value" lines,
  /// skipping internal keys (like the attached photo path) that don't belong
  /// in a vet report.
  List<String> _readableMetadata(String? metadataJson) {
    if (metadataJson == null || metadataJson.isEmpty) return const [];
    Map<String, dynamic> map;
    try {
      map = jsonDecode(metadataJson) as Map<String, dynamic>;
    } catch (_) {
      return const [];
    }
    const skip = {'photo_path'};
    final lines = <String>[];
    for (final entry in map.entries) {
      if (skip.contains(entry.key)) continue;
      final value = entry.value;
      if (value == null || value.toString().isEmpty) continue;
      final raw = entry.key.replaceAll('_', ' ');
      final key = raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
      lines.add('$key: $value');
    }
    return lines;
  }

  /// Extracts the stored photo path (native file path or base64 data URL)
  /// from an event's metadata, or null if there's no attachment.
  String? _photoPath(String? metadataJson) {
    if (metadataJson == null || metadataJson.isEmpty) return null;
    try {
      final map = jsonDecode(metadataJson) as Map<String, dynamic>;
      return map['photo_path'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Loads raw image bytes for a stored photo [path]. Handles both base64
  /// data URLs (web) and native file paths; returns null when the file is
  /// missing or can't be decoded. Mirrors [resolveLocalPhoto].
  Uint8List? _loadPhotoBytes(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('data:')) {
      try {
        return base64Decode(path.substring(path.indexOf(',') + 1));
      } catch (_) {
        return null;
      }
    }
    if (kIsWeb) return null;
    try {
      final file = File(path);
      return file.existsSync() ? file.readAsBytesSync() : null;
    } catch (_) {
      return null;
    }
  }

  String? _ageString(DateTime dob) {
    final now = DateTime.now();
    var months = (now.year - dob.year) * 12 + (now.month - dob.month);
    if (now.day < dob.day) months -= 1;
    if (months < 0) return null;
    final years = months ~/ 12;
    final remMonths = months % 12;
    if (years == 0) return '$remMonths mo';
    if (remMonths == 0) return '$years yr';
    return '$years yr $remMonths mo';
  }
}
