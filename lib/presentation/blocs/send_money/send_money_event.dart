part of 'send_money_bloc.dart';

sealed class SendMoneyEvent {}

class RecipientQrScanned extends SendMoneyEvent {
  final String userId;
  final String? username;
  RecipientQrScanned({required this.userId, this.username});
}

class RecipientFromDeviceSelected extends SendMoneyEvent {
  final PayMeshDevice device;
  RecipientFromDeviceSelected(this.device);
}

class RecipientCleared extends SendMoneyEvent {}

class AdvertisingToggled extends SendMoneyEvent {
  final bool start;
  AdvertisingToggled(this.start);
}

class BleScanStarted extends SendMoneyEvent {}

class SendMoneySubmitted extends SendMoneyEvent {
  final double amount;
  SendMoneySubmitted(this.amount);
}

class SendMoneyReset extends SendMoneyEvent {}

// Internal events — dispatched by the BLoC itself from the BLE stream
class _BleDevicesUpdated extends SendMoneyEvent {
  final List<PayMeshDevice> devices;
  _BleDevicesUpdated(this.devices);
}

class _BleScanCompleted extends SendMoneyEvent {}
