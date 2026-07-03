import 'dart:async';
import 'dart:collection';

class _BackgroundTask {
  final Future<void> Function() task;
  final Function(Object)? onError;
  final Completer<void> completer;

  _BackgroundTask(this.task, this.onError, this.completer);
}

class BackgroundTaskQueue {
  static final BackgroundTaskQueue instance = BackgroundTaskQueue._internal();
  BackgroundTaskQueue._internal();

  final Queue<_BackgroundTask> _queue = Queue();
  bool _isProcessing = false;

  /// Default timeout for any background task is 10 seconds.
  /// If it takes longer, we assume failure (e.g., poor network) and rollback.
  static const Duration _taskTimeout = Duration(seconds: 10);

  /// Enqueues a task and returns a Future that completes when the task finishes (or fails).
  Future<void> enqueue<T>({
    required Future<T> Function() task,
    Function(Object)? onError,
  }) {
    final completer = Completer<void>();
    _queue.add(_BackgroundTask(task, onError, completer));
    _processQueue();
    return completer.future;
  }

  void _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      try {
        await item.task().timeout(_taskTimeout);
        item.completer.complete();
      } catch (e) {
        if (item.onError != null) {
          item.onError!(e);
        }
        item.completer.completeError(e);
      }
    }

    _isProcessing = false;
  }
}
