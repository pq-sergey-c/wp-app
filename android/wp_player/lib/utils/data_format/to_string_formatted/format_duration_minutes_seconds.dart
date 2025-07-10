String _twoDigits(int n) => n.toString().padLeft(2, '0');

String _formatDurationNoHours(Duration? duration) {
  if (duration == null) return "--:--";

  final String minutes = _twoDigits(duration.inMinutes);
  final String seconds = _twoDigits(duration.inSeconds.remainder(60));
  return "$minutes:$seconds";
}

String _formatDurationWithHours(Duration? duration) {
  if (duration == null) return "--:--:--";

  final String hours = _twoDigits(duration.inHours);
  final String minutes = _twoDigits(duration.inMinutes.remainder(60));
  final String seconds = _twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}

String formatDuration(Duration? duration, {bool withHours = false}) {
  return withHours ? _formatDurationWithHours(duration) : _formatDurationNoHours(duration);
}
