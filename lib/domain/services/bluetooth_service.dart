import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';
import '../../core/exceptions/app_exception.dart';

class PayMeshDevice {
  final String deviceId;   // BLE device id
  final String userId;     // PayMesh user UUID decoded from manufacturer data
  final String displayName;
  final int rssi;

  PayMeshDevice({
    required this.deviceId,
    required this.userId,
    required this.displayName,
    required this.rssi,
  });
}

class PayMeshBluetoothService {
  static final PayMeshBluetoothService _instance = PayMeshBluetoothService._internal();
  factory PayMeshBluetoothService() => _instance;
  PayMeshBluetoothService._internal();

  final _peripheral = FlutterBlePeripheral();
  StreamSubscription? _scanSubscription;
  bool _isAdvertising = false;

  // Manufacturer company ID — arbitrary fixed value for PayMesh
  static const int _companyId = 0x05FF;

  // Convert UUID string → 16 raw bytes
  static Uint8List _uuidToBytes(String uuid) {
    final hex = uuid.replaceAll('-', '');
    return Uint8List.fromList(
      List.generate(16, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)),
    );
  }

  // Convert 16 raw bytes → UUID string
  static String _bytesToUuid(List<int> bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Request all required BLE permissions at runtime.
  /// Returns true if all permissions are granted.
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 12+ (API 31+) needs BLUETOOTH_SCAN, BLUETOOTH_CONNECT, BLUETOOTH_ADVERTISE
      // Android < 12 needs ACCESS_FINE_LOCATION
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.locationWhenInUse,
      ].request();

      final allGranted = statuses.values.every(
        (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
      );
      return allGranted;
    }
    // iOS permissions are declared in Info.plist — no runtime request needed
    return true;
  }

  /// Start advertising this device as a PayMesh user.
  Future<void> startAdvertising({required String userId, required String username}) async {
    final granted = await requestPermissions();
    if (!granted) {
      throw BluetoothException('Bluetooth permissions denied. Please enable them in Settings.');
    }

    try {
      // flutter_ble_peripheral expects manufacturerId and manufacturerData separately.
      // manufacturerData must be only the payload bytes (NOT including the company ID).
      final userIdBytes = _uuidToBytes(userId);

      final truncName = 'PM-${username.length > 8 ? username.substring(0, 8) : username}';

      await _peripheral.start(
        advertiseData: AdvertiseData(
          serviceUuid: Constants.bleServiceUuid,
          manufacturerId: _companyId,   // company ID passed separately
          manufacturerData: userIdBytes, // 16 userId bytes only
          localName: truncName,
        ),
        advertiseSettings: AdvertiseSettings(
          advertiseMode: AdvertiseMode.advertiseModeBalanced,
          connectable: false,
          timeout: 0, // advertise indefinitely
        ),
      );
      _isAdvertising = true;
    } catch (e) {
      throw BluetoothException('Failed to start advertising: $e');
    }
  }

  Future<void> stopAdvertising() async {
    if (_isAdvertising) {
      await _peripheral.stop();
      _isAdvertising = false;
    }
  }

  bool get isAdvertising => _isAdvertising;

  /// Scan for nearby PayMesh devices.
  /// Returns a stream of discovered [PayMeshDevice]s.
  Stream<List<PayMeshDevice>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) {
    final controller = StreamController<List<PayMeshDevice>>.broadcast();
    final found = <String, PayMeshDevice>{}; // deduplicated by deviceId
    StreamSubscription? isScanningSubscription;

    void safeAdd(List<PayMeshDevice> devices) {
      if (!controller.isClosed) controller.add(devices);
    }

    void safeClose() {
      if (!controller.isClosed) {
        controller.add(found.values.toList());
        controller.close();
      }
    }

    _scanSubscription?.cancel();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        // Decode userId from manufacturer data (key = company ID, value = payload bytes)
        final mfMap = r.advertisementData.manufacturerData;
        if (!mfMap.containsKey(_companyId)) continue;

        final mfBytes = mfMap[_companyId]!;
        if (mfBytes.length < 16) continue;

        try {
          final userId = _bytesToUuid(mfBytes.sublist(0, 16));
          final displayName = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : 'PayMesh User';

          found[r.device.remoteId.str] = PayMeshDevice(
            deviceId: r.device.remoteId.str,
            userId: userId,
            displayName: displayName,
            rssi: r.rssi,
          );
          safeAdd(found.values.toList());
        } catch (_) {
          continue;
        }
      }
    });

    // Request permissions then start the scan
    requestPermissions().then((granted) {
      if (!granted) {
        safeClose();
        return;
      }

      // Wait a tick before listening to isScanning so the scan has time to start
      // (avoids the initial false emission closing the controller immediately)
      Future.microtask(() {
        bool scanStarted = false;
        isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
          if (scanning) {
            scanStarted = true;
          } else if (scanStarted) {
            isScanningSubscription?.cancel();
            safeClose();
          }
        });
      });

      FlutterBluePlus.startScan(
        withServices: [Guid(Constants.bleServiceUuid)],
        timeout: timeout,
      ).catchError((_) => safeClose());
    });

    // Safety timeout to always close the controller
    Future.delayed(timeout + const Duration(seconds: 2), safeClose);

    return controller.stream;
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  Future<bool> isBluetoothOn() async {
    return FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
  }
}