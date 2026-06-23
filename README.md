# Remove Office Retail Progress

A PowerShell script that safely removes retail versions of Microsoft Office and non-English language packs from Windows devices while preserving Microsoft 365 Apps for enterprise (en-us) installations.

## Overview

This script detects and removes retail installations of Microsoft Office, non-English language packs, and standalone OneNote installations, displaying detailed progress throughout the operation. It uses the official Office Deployment Tool (ODT) for safe removal and specifically targets consumer retail versions and non-en-us language packs while protecting the English enterprise deployment.

## Features

- **Selective Removal**: Only removes retail consumer Office versions and non-English language packs
- **Enterprise Protection**: Preserves Microsoft 365 Apps for enterprise - en-us
- **Language Pack Cleanup**: Removes es-es, fr-fr, pt-br language packs from enterprise Office
- **Visual Progress**: Real-time progress indicators and colored log output
- **Safe Execution**: Uses Microsoft's official Office Deployment Tool
- **Comprehensive Logging**: Timestamped logs with severity levels
- **Performance Tracking**: Displays total elapsed time for the operation
- **Automatic Cleanup**: Removes temporary files after execution
- **OneNote Removal**: Includes removal of standalone OneNote installations (all languages)

## What Gets Removed

The script will remove:
- All Office retail consumer versions (Personal, Home & Student, Home & Business, Professional, etc.)
- Consumer Office 365 installations (O365HomePremRetail)
- OneNote Free/Retail editions (all languages: en-us, es-es, fr-fr, pt-br)
- Non-English language packs from Microsoft 365 Apps for enterprise:
  - Spanish (es-es)
  - French (fr-fr)
  - Portuguese - Brazil (pt-br)

## What Is Protected

The script will **NOT** remove:
- Microsoft 365 Apps for enterprise - en-us ONLY

## Requirements

- Windows PowerShell 5.1 or later
- Administrative privileges
- Internet connection (to download Office Deployment Tool)

## Usage

### Basic Execution

Run the script with administrative privileges:

```powershell
.\Remove-OfficeRetail-Progress.ps1
```

### Intune Deployment

This script can be deployed as a remediation script or Win32 app through Microsoft Intune:

1. Package the script as a Win32 app using the IntuneWin App Utility
2. Set detection rule to check for retail Office installations
3. Configure as required or available based on your needs

## How It Works

1. **Detection Phase** (0-10%): Scans registry for Office installations and identifies retail products and non-English language packs
2. **Preparation Phase** (20-50%):
   - Creates temporary working directory
   - Downloads Office Deployment Tool from Microsoft
   - Extracts ODT components
   - Generates removal configuration XML targeting specific products and languages
3. **Removal Phase** (60-85%): Executes Office uninstallation with periodic progress updates
4. **Verification Phase** (90%): Confirms successful removal of retail products
5. **Cleanup Phase** (95-100%): Removes temporary files and displays total elapsed time

## Exit Codes

- `0`: Success - Office removed or not found
- `1`: Warning - Some components may remain or an error occurred

## Logging

The script provides:
- Color-coded console output (Info: Cyan, Warning: Yellow, Error: Red, Success: Green)
- Progress bars with percentage completion
- Timestamped log messages with severity levels
- Detailed product detection (shows what will be removed vs. preserved)
- Total elapsed time tracking
- ODT logs stored in `%TEMP%` directory

## Technical Details

### Registry Keys Checked

- `HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration`
- `HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration`

### Office Deployment Tool

The script downloads ODT version 17830-20162 from Microsoft's official download servers.

### Removal Configuration

Uses an XML configuration with:
- Targeted product removal (not `All="TRUE"`)
- Specific product IDs: OneNoteFreeRetail, OneNoteRetail, PersonalRetail, HomeStudentRetail, etc.
- Language-specific removal for O365ProPlusRetail (es-es, fr-fr, pt-br)
- Silent display level with automatic EULA acceptance
- Standard logging enabled

## Author

**First American**  
Version: 1.2

## Changelog

### Version 1.2
- Added removal of non-English language packs (es-es, fr-fr, pt-br) from Microsoft 365 Apps for enterprise
- Improved detection logic to identify specific retail products
- Added total elapsed time tracking
- Enhanced logging with detailed product detection
- Changed from `Remove All="TRUE"` to targeted product removal for better control

### Version 1.1
- Initial release with OneNote removal support

## License

This script is provided as-is for use within First American environments.

## Troubleshooting

### Script Reports Office Remains After Removal

Some Office components may persist due to:
- Locked files during removal
- Partial installations
- Registry remnants

**Solution**: Reboot the device and run the script again

### Download Failures

If ODT download fails:
- Verify internet connectivity
- Check firewall/proxy settings
- Ensure access to `download.microsoft.com`

### Access Denied Errors

**Solution**: Run PowerShell as Administrator

## Support

For issues or questions, contact your IT support team or refer to internal documentation.
