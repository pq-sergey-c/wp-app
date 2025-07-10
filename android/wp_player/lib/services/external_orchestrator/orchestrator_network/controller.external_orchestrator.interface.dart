abstract class IExternalOrchestratorController {
  void start();
  void dispose();

  Future<void> startSessionEarly();
  void broadcastUserAdvanceFromPrelude();

  void pause();
  void resume();
}
