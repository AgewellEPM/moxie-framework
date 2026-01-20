; SimpleMoxieSwitcher Windows Installer Script
; Uses Inno Setup (free installer creator)
; Download from: https://jrsoftware.org/isinfo.php

[Setup]
AppName=SimpleMoxieSwitcher
AppVersion=1.0.0
AppPublisher=RollSEO LLC
AppPublisherURL=https://openmoxie.org
DefaultDirName={autopf}\SimpleMoxieSwitcher
DefaultGroupName=SimpleMoxieSwitcher
OutputBaseFilename=SimpleMoxieSwitcher-Setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
SetupIconFile=SimpleMoxieSwitcher\Assets\AppIcon.ico
UninstallDisplayIcon={app}\SimpleMoxieSwitcher.exe

; Require Windows 10 or later
MinVersion=10.0.19041

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Main application files
Source: "SimpleMoxieSwitcher\bin\Release\net8.0-windows10.0.19041.0\win-x64\publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\SimpleMoxieSwitcher"; Filename: "{app}\SimpleMoxieSwitcher.exe"; IconFilename: "{app}\Assets\AppIcon.ico"
Name: "{group}\Uninstall SimpleMoxieSwitcher"; Filename: "{uninstallexe}"
Name: "{autodesktop}\SimpleMoxieSwitcher"; Filename: "{app}\SimpleMoxieSwitcher.exe"; IconFilename: "{app}\Assets\AppIcon.ico"; Tasks: desktopicon

[Run]
; Check for .NET 8.0 Runtime
Filename: "https://dotnet.microsoft.com/download/dotnet/8.0"; Description: "Download .NET 8.0 Runtime (required)"; Flags: shellexec skipifdoesntexist postinstall skipifsilent

; Check for Docker Desktop
Filename: "https://www.docker.com/products/docker-desktop"; Description: "Download Docker Desktop (required)"; Flags: shellexec skipifdoesntexist postinstall skipifsilent

; Launch app after install
Filename: "{app}\SimpleMoxieSwitcher.exe"; Description: "{cm:LaunchProgram,SimpleMoxieSwitcher}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;

  // Check if .NET 8.0 is installed
  if not RegKeyExists(HKLM, 'SOFTWARE\dotnet\Setup\InstalledVersions\x64\sharedhost\8.0') then
  begin
    if MsgBox('.NET 8.0 Runtime is required but not installed. Do you want to download it now?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      ShellExec('open', 'https://dotnet.microsoft.com/download/dotnet/8.0', '', '', SW_SHOW, ewNoWait, ResultCode);
    end;
    Result := False;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = wpWelcome then
  begin
    // Show requirements message
    MsgBox('SimpleMoxieSwitcher requires:' + #13#10 +
           '• .NET 8.0 Runtime' + #13#10 +
           '• Docker Desktop' + #13#10 +
           '• Windows 10 (19041+) or Windows 11' + #13#10 + #13#10 +
           'The installer will guide you through any missing requirements.',
           mbInformation, MB_OK);
  end;
end;
