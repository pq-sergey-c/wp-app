#define BuildFolder "..\build\windows\x64\runner\Release"
#define AppVersion GetVersionNumbersString(BuildFolder + "\Wavepaths.exe")

[Setup]
AppId={{BD7AD8A9-1F0F-45C4-BBB2-A4F9DD15075A}
AppName=Wavepaths
AppVersion={#AppVersion}
AppPublisher=Wavepaths
AppPublisherURL=https://www.wavepaths.com/

WizardStyle=modern
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

DefaultDirName={autopf}\Wavepaths

DisableProgramGroupPage=no
AllowNoIcons=yes
DefaultGroupName=Wavepaths

UninstallDisplayIcon={app}\Wavepaths.exe
SetupIconFile=runner\resources\app_icon.ico

OutputDir=..\build\windows\installer
OutputBaseFilename=WavepathsInstaller_v.{#AppVersion}

PrivilegesRequired=lowest

[UninstallDelete]
; In case of absence of %TEMP env var - would try to delete from {tmp} which is relatively safe fallback
Type: filesandordirs; Name: "{%TEMP|{tmp}}\Wavepaths"


[Files]
Source:  "{#BuildFolder}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Wavepaths"; Filename: "{app}\Wavepaths.exe"
Name: "{autodesktop}\Wavepaths"; Filename: "{app}\Wavepaths.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Run]
Filename: "{app}\Wavepaths.exe"; Description: "Launch Wavepaths"; Flags: nowait postinstall skipifsilent

[Registry]
; Register custom URI scheme wavepaths2://
Root: HKCU; Subkey: "Software\Classes\wavepaths2"; Flags: uninsdeletekey; ValueType: string; ValueName: ""; ValueData: "URL:Open in Wavepaths"
Root: HKCU; Subkey: "Software\Classes\wavepaths2"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\wavepaths2\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\Wavepaths.exe,0"""
Root: HKCU; Subkey: "Software\Classes\wavepaths2\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Wavepaths.exe"" ""%1"""
