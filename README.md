# Getting Started

This project is a Flutter application.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/).

# Strange behaviors / notes

Note that:

1. Server uses old websocket version
2. More modern android audio backend (AAudio) works incorrectly with current native code - use OpenSLES
3. The backend API occasionally returns numerical values as either `int` or `double` inconsistently. To handle this, parse incoming numerical data from API responses as `num`. Subsequently, cast to the required type using `.toInt()` or `.toDouble()`
4. Note usage of `isJsonListOfDicts` and `isJsonListOfDictsOrNull`

# Windows

To setup Windows read [windows_setup.md](doc/setup/windows.md)
To build and make installer for Windows read [windows_build.md](doc/building/windows.md)
