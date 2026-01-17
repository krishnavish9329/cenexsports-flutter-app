# How to Enable Developer Mode on Windows (Fix Symlink Support)

## Method 1: Through Settings (Recommended)

1. Press `Windows + I` to open Settings
2. Go to **Privacy & Security** → **For developers**
3. Turn ON **Developer Mode**
4. If prompted, click **Yes** to confirm
5. Restart your computer (recommended)

## Method 2: Through PowerShell (Run as Administrator)

Open PowerShell as Administrator and run:

```powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord
```

Then restart your computer.

## Method 3: Quick Settings Link

Run this command in PowerShell (it will open Settings directly):

```powershell
start ms-settings:developers
```

Then toggle **Developer Mode** ON.

## After Enabling Developer Mode

1. Restart your computer
2. The symlink warning should disappear
3. You can now build Flutter apps for Windows desktop

## Note

- This is only needed for **Windows desktop builds**
- **Android builds** don't require Developer Mode
- The warning appears but doesn't always block the build
