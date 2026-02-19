import 'package:cams_store_manager/features/hub_management/domain/entities/hub_entity.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/hub_sensor_entity.dart';
import 'package:cams_store_manager/features/space_control/domain/entities/space.dart';

/// Toggle this flag to switch between the two UI states for easy testing:
///   - true  → Space has a fully-configured HubEntity (online, speaker, sensors)
///   - false → Space has no hub (currentHub == null)
bool mockHasHub = true;

/// Mock repository for the Devices (hub_management) tab.
/// Replace [getCurrentSpaceDevice] with a real repository call once the API
/// is ready.
class MockHubRepository {
  MockHubRepository._();

  // ── Sensor fixtures ────────────────────────────────────────────────────────

  static const _sensors = [
    HubSensorEntity(
      id: 'sensor-001',
      name: 'Nhiệt độ',
      type: 'temperature',
      unit: '°C',
      currentValue: 24.5,
    ),
    HubSensorEntity(
      id: 'sensor-002',
      name: 'Lượng khách',
      type: 'crowd',
      unit: ' người',
      currentValue: 12,
    ),
  ];

  // ── Hub fixture ────────────────────────────────────────────────────────────

  static const _hub = HubEntity(
    id: 'hub-001',
    macAddress: 'AA:BB:CC:DD:EE:01',
    isOnline: true,
    wifiSignalStrength: 'Mạnh',
    connectedSpeakerName: 'Marshall Stanmore',
    currentVolume: 65,
    sensors: _sensors,
  );

  // ── Space fixture (hub installed) ─────────────────────────────────────────

  static const _spaceWithHub = Space(
    id: 'space-001',
    name: 'Sảnh Chính',
    status: 'Online',
    currentMood: 'Sáng tạo',
    assignedHubId: 'hub-001',
    storeId: 'store-001',
    currentHub: _hub,
  );

  // ── Space fixture (no hub) ────────────────────────────────────────────────

  static const _spaceWithoutHub = Space(
    id: 'space-001',
    name: 'Sảnh Chính',
    status: 'Online',
    currentMood: 'Sáng tạo',
    assignedHubId: '',
    storeId: 'store-001',
    currentHub: null,
  );

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the [Space] entity for the currently active space,
  /// with [Space.currentHub] populated (or null) based on [mockHasHub].
  static Space getCurrentSpaceDevice() {
    return mockHasHub ? _spaceWithHub : _spaceWithoutHub;
  }
}
