/// Defines the operational mode of the CAMS application.
enum AppMode {
  /// The app is run by a manager to remotely control spaces and music.
  /// Requires user authentication.
  remoteControl('Remote Control', 'remote_control'),

  /// The app is acting as a dedicated playback device for a specific space.
  /// Starts via pairing code, acts locally.
  playbackDevice('Playback Device', 'playback_device');

  const AppMode(this.label, this.value);

  /// Human-readable display label.
  final String label;

  /// Machine-friendly value.
  final String value;
}
