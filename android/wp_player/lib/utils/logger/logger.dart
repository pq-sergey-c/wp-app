import 'package:logger/logger.dart';

final logConsole = Logger(
  level: Level.all,
  printer: PrettyPrinter(
    methodCount: 1,
    errorMethodCount: 1,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTime,
  ),
);
