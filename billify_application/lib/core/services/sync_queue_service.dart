import 'dart:convert';
import 'package:billify/core/services/local_storage_service.dart';
import 'package:billify/core/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

enum SyncStatus { pending, syncing, completed, failed }

/// Represents an offline mutation or background synchronization task
class SyncTask {
  final String id;
  final String action;
  final String businessId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final int maxAttempts;
  final SyncStatus status;
  final String? lastError;

  SyncTask({
    String? id,
    required this.action,
    required this.businessId,
    required this.payload,
    DateTime? createdAt,
    this.attempts = 0,
    this.maxAttempts = 5,
    this.status = SyncStatus.pending,
    this.lastError,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isMaxRetriesExceeded => attempts >= maxAttempts;

  SyncTask copyWith({
    String? id,
    String? action,
    String? businessId,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? attempts,
    int? maxAttempts,
    SyncStatus? status,
    String? lastError,
  }) {
    return SyncTask(
      id: id ?? this.id,
      action: action ?? this.action,
      businessId: businessId ?? this.businessId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }

  factory SyncTask.fromJson(Map<String, dynamic> json) {
    return SyncTask(
      id: json['id'] as String,
      action: json['action'] as String,
      businessId: json['business_id']?.toString() ?? '',
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      maxAttempts: (json['max_attempts'] as num?)?.toInt() ?? 5,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncStatus.pending,
      ),
      lastError: json['last_error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'business_id': businessId,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'attempts': attempts,
      'max_attempts': maxAttempts,
      'status': status.name,
      'last_error': lastError,
    };
  }
}

/// Offline-first Persistent Synchronization Queue for scalable background data sync.
class SyncQueueService {
  final LocalStorageService _storage;
  static const String _queueStorageKey = 'offline_sync_queue';

  SyncQueueService(this._storage);

  /// Enqueue a mutation task for offline sync
  Future<SyncTask> enqueue({
    required String action,
    required String businessId,
    required Map<String, dynamic> payload,
    int maxAttempts = 5,
  }) async {
    final task = SyncTask(
      action: action,
      businessId: businessId,
      payload: payload,
      maxAttempts: maxAttempts,
    );

    final tasks = _loadTasks();
    tasks.add(task);
    await _saveTasks(tasks);

    AppLogger.info(
      'Enqueued offline sync task: ${task.action} (id: ${task.id})',
      tag: 'SyncQueueService',
    );
    return task;
  }

  /// Get pending synchronization tasks for a specific business or all
  List<SyncTask> getPendingTasks({String? businessId}) {
    final tasks = _loadTasks();
    return tasks.where((t) {
      final matchesBiz = businessId == null || t.businessId == businessId;
      final isPending = t.status == SyncStatus.pending || t.status == SyncStatus.failed;
      return matchesBiz && isPending && !t.isMaxRetriesExceeded;
    }).toList();
  }

  /// Mark task as successfully synced
  Future<void> markTaskSuccess(String taskId) async {
    final tasks = _loadTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(
        status: SyncStatus.completed,
        lastError: null,
      );
      await _saveTasks(tasks);
      AppLogger.info('Sync task completed: $taskId', tag: 'SyncQueueService');
    }
  }

  /// Mark task as failed with an error message
  Future<void> markTaskFailed(String taskId, String errorMessage) async {
    final tasks = _loadTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final current = tasks[index];
      final newAttempts = current.attempts + 1;
      tasks[index] = current.copyWith(
        attempts: newAttempts,
        status: newAttempts >= current.maxAttempts ? SyncStatus.failed : SyncStatus.pending,
        lastError: errorMessage,
      );
      await _saveTasks(tasks);
      AppLogger.warning(
        'Sync task failed (attempt $newAttempts/${current.maxAttempts}): $taskId ($errorMessage)',
        tag: 'SyncQueueService',
      );
    }
  }

  /// Process the entire queue with a caller-supplied executor
  Future<int> processQueue(
    Future<bool> Function(SyncTask task) executor, {
    String? businessId,
  }) async {
    final pending = getPendingTasks(businessId: businessId);
    if (pending.isEmpty) return 0;

    int syncedCount = 0;
    for (final task in pending) {
      try {
        final success = await executor(task);
        if (success) {
          await markTaskSuccess(task.id);
          syncedCount++;
        } else {
          await markTaskFailed(task.id, 'Executor returned false');
        }
      } catch (e) {
        await markTaskFailed(task.id, e.toString());
      }
    }

    await clearCompletedTasks();
    return syncedCount;
  }

  /// Clear successfully completed tasks to keep memory and storage footprint minimal
  Future<void> clearCompletedTasks() async {
    final tasks = _loadTasks();
    tasks.removeWhere((t) => t.status == SyncStatus.completed);
    await _saveTasks(tasks);
  }

  /// Get count of pending tasks
  int pendingCount({String? businessId}) {
    return getPendingTasks(businessId: businessId).length;
  }

  List<SyncTask> _loadTasks() {
    final list = _storage.getJsonList(_queueStorageKey);
    if (list == null) return [];
    return list.map((json) => SyncTask.fromJson(json)).toList();
  }

  Future<bool> _saveTasks(List<SyncTask> tasks) async {
    final jsonList = tasks.map((t) => t.toJson()).toList();
    return await _storage.setJsonList(_queueStorageKey, jsonList);
  }
}
