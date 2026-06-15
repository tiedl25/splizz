import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:powersync/powersync.dart';
import 'package:splizz/data/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
final log = Logger('powersync-supabase');

/// Postgres Response codes that we cannot recover from by retrying.
final List<RegExp> fatalResponseCodes = [
  // Class 22 — Data Exception
  // Examples include data type mismatch.
  RegExp(r'^22...$'),
  // Class 23 — Integrity Constraint Violation.
  // Examples include NOT NULL, FOREIGN KEY and UNIQUE violations.
  RegExp(r'^23...$'),
  // INSUFFICIENT PRIVILEGE - typically a row-level security violation
  RegExp(r'^42501$'),
];

class BackendConnector extends PowerSyncBackendConnector {
  Future<void>? _refreshFuture;

  BackendConnector();
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    await _refreshFuture;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return null;
    }

    final token = session.accessToken;
    final userId = session.user.id;
    final expiresAt = session.expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 3600);

    await dotenv.load(fileName: 'keys.env');

    return PowerSyncCredentials(
      endpoint: AppConfig.isDebug ? dotenv.get('POWERSYNC_DEBUG_URL') : dotenv.get('POWERSYNC_URL'),
      token: token,
      userId: userId,
      expiresAt: expiresAt,
    );
  }

  @override
  void invalidateCredentials() {
    // Trigger a session refresh if auth fails on PowerSync.
    // Generally, sessions should be refreshed automatically by Supabase.
    // However, in some cases it can be a while before the session refresh is
    // retried. We attempt to trigger the refresh as soon as we get an auth
    // failure on PowerSync.
    //
    // This could happen if the device was offline for a while and the session
    // expired, and nothing else attempt to use the session it in the meantime.
    //
    // Timeout the refresh call to avoid waiting for long retries,
    // and ignore any errors. Errors will surface as expired tokens.
    _refreshFuture = Supabase.instance.client.auth
        .refreshSession()
        .timeout(const Duration(seconds: 5))
        .then((response) => null, onError: (error) => null);
  }

  Future<SupabaseClient> getSupabaseClient(PowerSyncDatabase database) async {
    await dotenv.load(fileName: 'keys.env');

    final supabase = SupabaseClient(
      AppConfig.isDebug ? dotenv.get('DEBUG_SUPABASE_URL') : dotenv.get('SUPABASE_URL'),
      AppConfig.isDebug ? dotenv.get('DEBUG_SUPABASE_ANON_KEY') : dotenv.get('SUPABASE_ANON_KEY'),
    );

    return supabase;
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    final supabase = Supabase.instance.client;
    CrudEntry? lastOp;

    try {
      // The data that needs to be changed in the remote db
      for (var op in transaction.crud) {
        lastOp = op;

        final table = op.table;
        final id = op.id;
        final data = op.opData ?? {};

        switch (op.op) {
          case UpdateType.put:
            await supabase
                .from(table)
                .insert({...data, 'id': id});
            break;
          case UpdateType.patch:
            await supabase
              .from(table)
              .update(data)
              .eq('id', id);
            break;
          case UpdateType.delete:
            await supabase
              .from(table)
              .delete()
              .eq('id', id);
            break;
        }
      }

      // Completes the transaction and moves onto the next one
      await transaction.complete();
    } on PostgrestException catch (e) {
      if (e.code != null &&
          fatalResponseCodes.any((re) => re.hasMatch(e.code!))) {
        /// Instead of blocking the queue with these errors,
        /// discard the (rest of the) transaction.
        ///
        /// Note that these errors typically indicate a bug in the application.
        /// If protecting against data loss is important, save the failing records
        /// elsewhere instead of discarding, and/or notify the user.
        log.severe('Data upload error - discarding $lastOp', e);
        await transaction.complete();
      } else {
        // Error may be retryable - e.g. network error or temporary server error.
        // Throwing an error here causes this call to be retried after a delay.
        rethrow;
      }
    }
  }
}