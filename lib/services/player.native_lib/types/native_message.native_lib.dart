/// **Note**: Changing this values require change in native wrapper also
enum WpNativeMessageType {
  dataRequest(1),
  cancelFetchRequest(2);

  final int value;
  const WpNativeMessageType(this.value);

  static WpNativeMessageType fromInt(final int value) {
    return WpNativeMessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid NativeMessageType value: $value'),
    );
  }
}

abstract class WpNativeMessage {}

// WpNativeMessageType.dataRequest;
class WpDataRequest implements WpNativeMessage {
  final int id;
  final String url;
  final DateTime scheduledTime;

  WpDataRequest(this.id, this.url, this.scheduledTime);
}

// WpNativeMessageType.cancelFetchRequest;
class WpDataCancelRequest implements WpNativeMessage {
  final int id;

  WpDataCancelRequest(this.id);
}
