import 'package:uuid/uuid.dart';
import 'package:wp_player/services/client_id/client_id.service.interface.dart';

class ClientId implements IClientId {
  static final ClientId _instance = ClientId._internal();
  final String _clientId;

  factory ClientId() {
    return _instance;
  }

  ClientId._internal() : _clientId = const Uuid().v4();

  @override
  String get clientIdentifier => _clientId;
}
