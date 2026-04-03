import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import '../../core/exceptions/app_exception.dart';

class NfcRecipient {
  final String userId;
  final String username;

  NfcRecipient({required this.userId, required this.username});
}

class PayMeshNfcService {
  static final PayMeshNfcService _instance = PayMeshNfcService._internal();
  factory PayMeshNfcService() => _instance;
  PayMeshNfcService._internal();

  static const String _mimeType = 'application/vnd.paymesh';

  Future<bool> isNfcAvailable() async {
    final availability = await NfcManager.instance.checkAvailability();
    return availability == NfcAvailability.enabled;
  }

  /// Build a MIME-type NDEF record manually (TypeNameFormat.media).
  static NdefRecord _createMimeRecord(String mimeType, Uint8List payload) {
    return NdefRecord(
      typeNameFormat: TypeNameFormat.media,
      type: Uint8List.fromList(utf8.encode(mimeType)),
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  /// Write this user's identity to an NFC tag / nearby device.
  Future<void> writeUserId({
    required String userId,
    required String username,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final available = await isNfcAvailable();
      if (!available) {
        onError('NFC is not available on this device');
        return;
      }

      final payloadBytes = Uint8List.fromList(
        utf8.encode(jsonEncode({'userId': userId, 'username': username, 'type': 'paymesh_id'})),
      );

      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            bool writable = false;
            Future<void> Function(NdefMessage)? writeFunc;

            if (Platform.isAndroid) {
              final ndef = NdefAndroid.from(tag);
              if (ndef == null) {
                await NfcManager.instance.stopSession(errorMessageIos: 'Tag not NDEF compatible');
                onError('NFC tag is not compatible');
                return;
              }
              if (!ndef.isWritable) {
                await NfcManager.instance.stopSession(errorMessageIos: 'Tag is read-only');
                onError('NFC tag is read-only');
                return;
              }
              writable = true;
              writeFunc = ndef.writeNdefMessage;
            } else if (Platform.isIOS) {
              final ndef = NdefIos.from(tag);
              if (ndef == null) {
                await NfcManager.instance.stopSession(errorMessageIos: 'Tag not NDEF compatible');
                onError('NFC tag is not compatible');
                return;
              }
              if (ndef.status != NdefStatusIos.readWrite) {
                await NfcManager.instance.stopSession(errorMessageIos: 'Tag is read-only');
                onError('NFC tag is read-only');
                return;
              }
              writable = true;
              writeFunc = ndef.writeNdef;
            }

            if (!writable || writeFunc == null) {
              await NfcManager.instance.stopSession(errorMessageIos: 'Unsupported platform');
              onError('NFC write not supported on this platform');
              return;
            }

            final message = NdefMessage(
              records: [_createMimeRecord(_mimeType, payloadBytes)],
            );

            await writeFunc(message);
            await NfcManager.instance.stopSession();
            onSuccess();
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessageIos: e.toString());
            onError('Write failed: $e');
          }
        },
      );
    } catch (e) {
      throw GenericException('NFC write failed: $e');
    }
  }

  /// Read a PayMesh identity from an NFC tag.
  Future<void> readRecipientId({
    required Function(NfcRecipient) onRecipientFound,
    required Function(String) onError,
  }) async {
    try {
      final available = await isNfcAvailable();
      if (!available) {
        onError('NFC is not available on this device');
        return;
      }

      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            NdefMessage? message;

            if (Platform.isAndroid) {
              final ndef = NdefAndroid.from(tag);
              message = ndef?.cachedNdefMessage ?? await ndef?.getNdefMessage();
            } else if (Platform.isIOS) {
              final ndef = NdefIos.from(tag);
              message = ndef?.cachedNdefMessage ?? await ndef?.readNdef();
            }

            if (message == null || message.records.isEmpty) {
              await NfcManager.instance.stopSession(errorMessageIos: 'No data found');
              onError('No PayMesh data found on this tag');
              return;
            }

            String? decoded;
            for (final record in message.records) {
              // MIME record
              if (record.typeNameFormat == TypeNameFormat.media) {
                decoded = utf8.decode(record.payload);
                break;
              }
              // RTD Text record (well-known)
              if (record.typeNameFormat == TypeNameFormat.wellKnown) {
                final payload = record.payload;
                if (payload.length > 3) {
                  final langLen = payload[0] & 0x3F;
                  decoded = utf8.decode(payload.sublist(1 + langLen));
                  break;
                }
              }
            }

            if (decoded == null) {
              await NfcManager.instance.stopSession(errorMessageIos: 'Unrecognised format');
              onError('Tag does not contain PayMesh data');
              return;
            }

            final data = jsonDecode(decoded) as Map<String, dynamic>;
            if (data['type'] != 'paymesh_id') {
              await NfcManager.instance.stopSession(errorMessageIos: 'Not a PayMesh tag');
              onError('This is not a PayMesh payment tag');
              return;
            }

            final recipient = NfcRecipient(
              userId: data['userId'] as String,
              username: data['username'] as String? ?? 'Unknown',
            );

            await NfcManager.instance.stopSession();
            onRecipientFound(recipient);
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessageIos: e.toString());
            onError('Read failed: $e');
          }
        },
      );
    } catch (e) {
      throw GenericException('NFC read failed: $e');
    }
  }

  Future<void> stopSession() async {
    await NfcManager.instance.stopSession();
  }
}