class CamsPlaybackCapabilities {
  final bool supportsImmediateManualQueueTakeover;

  const CamsPlaybackCapabilities({
    this.supportsImmediateManualQueueTakeover = false,
  });
}

abstract class CamsPlaybackCapabilityProvider {
  const CamsPlaybackCapabilityProvider();

  CamsPlaybackCapabilities get current;
}

class StaticCamsPlaybackCapabilityProvider
    extends CamsPlaybackCapabilityProvider {
  final CamsPlaybackCapabilities _current;

  const StaticCamsPlaybackCapabilityProvider([
    this._current = const CamsPlaybackCapabilities(),
  ]);

  @override
  CamsPlaybackCapabilities get current => _current;
}
