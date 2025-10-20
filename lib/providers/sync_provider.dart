import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService();

  bool get isSyncing => _syncService.isSyncing;
  DateTime? get lastSyncTime => _syncService.lastSyncTime;

  Future<void> syncAll() async {
    try {
      await _syncService.syncAll();
      notifyListeners();
    } catch (e) {
      print('Error en sincronización: $e');
      rethrow;
    }
  }

  Future<bool> checkConnectivity() async {
    return await _syncService.checkConnectivity();
  }
}






