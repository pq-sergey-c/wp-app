abstract class IExternalOrchestrator {
  Future<void> start();
  Future<void> dispose();

  Future<void> startSessionEarly();
  void broadcastUserAdvanceFromPrelude();

  void pause();
  void resume();
}
