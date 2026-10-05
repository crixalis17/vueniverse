import 'package:flutter/material.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/data/sources/ultrahuman_client.dart';
import 'package:vueniverse/domain/models/collection_history.dart';
import 'package:vueniverse/domain/models/collection_snapshot.dart';

class UltrahumanImportScreen extends StatefulWidget {
  const UltrahumanImportScreen({super.key});
  @override
  State<UltrahumanImportScreen> createState() => _UltrahumanImportScreenState();
}

class _UltrahumanImportScreenState extends State<UltrahumanImportScreen> {
  final _token = TextEditingController();
  final _endDate = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  int _days = 7;
  bool _ownerConfirmed = false;
  String? _message;
  @override
  void dispose() {
    _token.clear();
    _token.dispose();
    _endDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = VueniverseScope.of(context);
    final busy = state.sourceOperationInProgress;
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Ultrahuman')),
      bottomNavigationBar: _message == null
          ? null
          : SafeArea(
              child: Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _message!,
                    key: const ValueKey('ultrahuman-import-message'),
                  ),
                ),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Import your own health timeline',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'The app contacts Ultrahuman directly. Heart rate and supported sleep stages are saved in your encrypted Live store, not sent to a hosted model. Your API key is used only for this import and is not saved.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _token,
            enabled: !busy,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Personal API key',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _days,
            decoration: const InputDecoration(labelText: 'Import period'),
            items: [
              for (final days in [1, 7, 14])
                DropdownMenuItem(
                  value: days,
                  child: Text(
                    days == 1 ? '1 provider day' : '$days provider days',
                  ),
                ),
            ],
            onChanged: busy ? null : (value) => setState(() => _days = value!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _endDate,
            enabled: !busy,
            keyboardType: TextInputType.datetime,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Last provider date (YYYY-MM-DD)',
              helperText:
                  'Suggested from this phone. Confirm the date in Ultrahuman.',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'These are requested Ultrahuman daily dates, ending on the date above. They are not a historical travel timezone. Adjust the last date if Ultrahuman and this phone show different dates.',
          ),
          CheckboxListTile(
            value: _ownerConfirmed,
            contentPadding: EdgeInsets.zero,
            onChanged: busy
                ? null
                : (value) => setState(() => _ownerConfirmed = value ?? false),
            title: const Text(
              'This key belongs to me and this Live store contains only my data.',
            ),
          ),
          const Text(
            'HRV and steps are not imported yet. Ultrahuman supplies the latest timezone, not a historical travel timezone; tell the app about travel in check-ins. No calls, meetings or other events will be invented.',
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy || !_ownerConfirmed
                ? null
                : () async {
                    final token = _token.text.trim();
                    if (token.isEmpty) {
                      setState(() => _message = 'Enter your personal API key.');
                      return;
                    }
                    final endDate = _endDate.text.trim();
                    try {
                      validateUltrahumanDate(endDate);
                    } on UltrahumanException {
                      setState(
                        () => _message =
                            'Enter a valid last provider date as YYYY-MM-DD.',
                      );
                      return;
                    }
                    // Clear the text controller immediately; only the active call holds it.
                    _token.clear();
                    final ok = await state.importUltrahuman(
                      token,
                      _days,
                      endDate,
                    );
                    if (!mounted) return;
                    setState(
                      () => _message =
                          state.sourceOperationMessage ??
                          (ok
                              ? 'Import complete. Review your measurements and collection history in Sources.'
                              : 'Import did not complete. Check Sources before retrying.'),
                    );
                  },
            child: Text(busy ? 'Importing…' : 'Import to this device'),
          ),
        ],
      ),
    );
  }
}

class CollectionHistoryScreen extends StatefulWidget {
  const CollectionHistoryScreen({super.key});
  @override
  State<CollectionHistoryScreen> createState() =>
      _CollectionHistoryScreenState();
}

class _CollectionHistoryScreenState extends State<CollectionHistoryScreen> {
  CollectionSnapshot? _snapshot;
  final _receipts = <CollectionReceipt>[];
  bool _busy = false;
  String? _error;
  bool _initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load(reset: true);
    }
  }

  Future<void> _load({required bool reset}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await VueniverseScope.of(
        context,
      ).loadCollectionHistory(reset ? null : _snapshot?.history.nextCursor);
      if (!mounted) return;
      setState(() {
        _snapshot = data;
        if (reset) _receipts.clear();
        _receipts.addAll(data.history.receipts);
      });
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'Collection history could not load. Your stored data has not been changed.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _time(DateTime value) =>
      value.toLocal().toIso8601String().substring(0, 16).replaceAll('T', ' ');

  String _count(int? value) => value?.toString() ?? 'unknown';

  String _receiptDetails(CollectionReceipt receipt) {
    final lines = <String>[_time(receipt.recordedAtUtc)];
    if (receipt.kind == 'deletion') {
      lines.add('${_count(receipt.recordsDeleted)} deleted');
    } else {
      lines.add(
        '${_count(receipt.recordsSeen)} seen · ${_count(receipt.recordsAccepted)} accepted · ${_count(receipt.recordsRejected)} rejected',
      );
      if (receipt.receiptSchema != null ||
          receipt.recordsInserted != null ||
          receipt.recordsChanged != null ||
          receipt.recordsDuplicate != null) {
        lines.add(
          '${_count(receipt.recordsInserted)} new · ${_count(receipt.recordsChanged)} updated · ${_count(receipt.recordsDuplicate)} repeats',
        );
      }
    }
    if (receipt.requestedLocalDate != null) {
      lines.add(
        'API day ${receipt.requestedLocalDate} · ${receipt.reportedTimezone ?? 'zone unavailable'}',
      );
    }
    if (receipt.rejectionReasons.isNotEmpty) {
      lines.add(
        receipt.rejectionReasons.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', '),
      );
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Collection history')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'What this device has collected',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'This is an import ledger, not a health finding. Counts show saved records, not continuous coverage. Accepted imports may include repeats. Values, journal text and API keys are not shown here.',
        ),
        if (_snapshot case final snapshot?) ...[
          const SizedBox(height: 16),
          Text(
            '${snapshot.coverage.storeKind.name.toUpperCase()} · ${snapshot.coverage.retainedRecords} retained records',
          ),
          if (snapshot.coverage.groups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No health or context records saved yet. Connect Ultrahuman or add a check-in.',
              ),
            ),
          for (final group in snapshot.coverage.groups)
            Card(
              child: ListTile(
                title: Text(
                  '${group.sourceConnectionId} · ${group.recordType}',
                ),
                subtitle: Text(
                  '${group.count} retained\n${_time(group.firstObservedAtUtc)} → ${_time(group.lastObservedAtUtc)}',
                ),
                isThreeLine: true,
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Recent collection activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          for (final receipt in _receipts)
            Card(
              child: ListTile(
                leading: Icon(
                  receipt.kind == 'deletion'
                      ? Icons.delete_outline
                      : receipt.hasError
                      ? Icons.warning_amber
                      : Icons.download_done,
                ),
                title: Text(
                  '${receipt.sourceConnectionId ?? 'Local store'} · ${receipt.status}',
                ),
                subtitle: Text(_receiptDetails(receipt)),
              ),
            ),
          if (snapshot.history.nextCursor != null)
            OutlinedButton(
              onPressed: _busy ? null : () => _load(reset: false),
              child: const Text('Load older activity'),
            ),
        ],
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null) Text(_error!),
        OutlinedButton(
          onPressed: _busy ? null : () => _load(reset: true),
          child: const Text('Refresh collection history'),
        ),
      ],
    ),
  );
}
