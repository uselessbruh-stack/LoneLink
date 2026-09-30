/// LONE LINK — Drift Database Definition
///
/// Central database class that ties together all tables and
/// generates the type-safe query API.
///
/// Run `dart run build_runner build` to generate the .g.dart file.

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:lone_link/core/constants/app_constants.dart';
import 'package:lone_link/storage/database/tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  LocalIdentities,
  Peers,
  Conversations,
  Messages,
  MessageEnvelopes,
  ProcessedMessageIds,
  Acknowledgements,
  Routes,
  BridgeCandidates,
  SyncStates,
])
class LoneLinkDatabase extends _$LoneLinkDatabase {
  LoneLinkDatabase() : super(_openConnection());

  /// Constructor for testing with an in-memory database.
  LoneLinkDatabase.forTesting(super.e);

  @override
  int get schemaVersion => kDatabaseVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations go here.
          // Example:
          // if (from < 2) {
          //   await m.addColumn(messages, messages.newColumn);
          // }
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, kDatabaseFileName));
    return NativeDatabase.createInBackground(file);
  });
}
