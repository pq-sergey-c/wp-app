# Description

Main idea here, is that you firstly should build windows app with only flutter possibilities, namely: `flutter build ...`, and then use Inno Setup to make installer.

# Relevant resources

`inno_setup_scrip.iss` in **windows** folder

# Plan

1. Install [Inno Setup](https://jrsoftware.org/isdl.php)
2. Run `flutter build windows --release` in flutter project root
3. Run inno script

   1. from `Inno Setup Compiler`: open `.iss` script in `Inno Setup Compiler` and press run button

      Note: at time of writing it is `Compil32.exe`

   2. from CLI: `ISCC.exe inno_setup_script.iss`

      Note: you may alter both paths on need (just point to correct targets)

4. Find installer in `build/windows/installer/` folder.

# Notes

1. Paths in inno setup script are relative, so in case of refactoring you may consider, that it might be possible to break inno script.
2. Current setup is for x64 Windows.
3. If you don't update version of app, you might get that inno wouldn't update your installer - in this case (if you still don't want to update version, or already updated yet want to change something after initial installer building), just delete installer and re run Inno
