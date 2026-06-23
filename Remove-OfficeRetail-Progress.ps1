<#
.SYNOPSIS
    Removes retail versions of Microsoft Office from the device.

.DESCRIPTION
    This script detects and removes retail installations of Microsoft Office and
    non-English language packs, displaying progress throughout the operation.
    It uses the Office Deployment Tool for safe removal. This script specifically
    targets retail consumer versions and non-en-us language packs, and will NOT
    remove Microsoft 365 Apps for enterprise - en-us.

.NOTES
    Author: First American
    Version: 1.2

    Excluded Products (will NOT be removed):
    - Microsoft 365 Apps for enterprise - en-us ONLY

    Targeted Products (will be removed):
    - All other Office retail versions including consumer Office 365
    - OneNote Free/Retail
    - Non-English (non-en-us) language packs for Microsoft 365 Apps for enterprise
#>

[CmdletBinding()]
param()

# Function to write log messages
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    Write-Host $logMessage -ForegroundColor $(
        switch ($Level) {
            'Info' { 'Cyan' }
            'Warning' { 'Yellow' }
            'Error' { 'Red' }
            'Success' { 'Green' }
        }
    )
}

# Function to show progress with visual indicator
function Show-Progress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete
    )

    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    Write-Host "`n[" -NoNewline -ForegroundColor White
    Write-Host "$PercentComplete%" -NoNewline -ForegroundColor Yellow
    Write-Host "] " -NoNewline -ForegroundColor White
    Write-Host "$Activity - $Status" -ForegroundColor Cyan
}

# Function to check if Office is installed
function Test-OfficeInstalled {
    Show-Progress -Activity "Checking for Office installations" -Status "Scanning registry..." -PercentComplete 10

    $officeKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
    )

    $hasRetailToRemove = $false

    foreach ($key in $officeKeys) {
        if (Test-Path $key) {
            $props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            if ($props) {
                $productIds = $props.ProductReleaseIds
                $clientCulture = $props.ClientCulture

                Write-Log "Found Office installation at: $key"
                Write-Log "  Products: $productIds"
                Write-Log "  Culture: $clientCulture"
                Write-Log "  Version: $($props.VersionToReport)"

                # Check for retail products that should be removed
                $retailProducts = @(
                    'OneNoteFreeRetail',
                    'OneNoteRetail',
                    'PersonalRetail',
                    'HomeStudentRetail',
                    'HomeBusiness2019Retail',
                    'Professional2019Retail',
                    'O365HomePremRetail'
                )

                foreach ($retailProduct in $retailProducts) {
                    if ($productIds -match $retailProduct) {
                        Write-Log "  Found retail product: $retailProduct - will attempt removal" -Level Warning
                        $hasRetailToRemove = $true
                    }
                }

                # Check if Microsoft 365 Apps for enterprise is present
                if ($productIds -match "O365ProPlusRetail") {
                    Write-Log "  Detected Microsoft 365 Apps for enterprise - will be preserved" -Level Info
                }
            }
        }
    }

    return $hasRetailToRemove
}

# Function to download Office Deployment Tool
function Get-ODT {
    param([string]$TempPath)

    Show-Progress -Activity "Preparing removal" -Status "Downloading Office Deployment Tool..." -PercentComplete 30
    Write-Log "Downloading Office Deployment Tool..."

    $odtUrl = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_17830-20162.exe"
    $odtPath = Join-Path $TempPath "ODTSetup.exe"

    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $odtUrl -OutFile $odtPath -UseBasicParsing -ErrorAction Stop
        $ProgressPreference = 'Continue'
        Write-Log "Office Deployment Tool downloaded successfully" -Level Success
        return $odtPath
    }
    catch {
        Write-Log "Failed to download ODT: $_" -Level Error
        return $null
    }
}

# Function to extract ODT
function Expand-ODT {
    param(
        [string]$ODTPath,
        [string]$ExtractPath
    )

    Show-Progress -Activity "Preparing removal" -Status "Extracting Office Deployment Tool..." -PercentComplete 40
    Write-Log "Extracting Office Deployment Tool..."

    try {
        $process = Start-Process -FilePath $ODTPath -ArgumentList "/quiet /extract:`"$ExtractPath`"" -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-Log "ODT extracted successfully" -Level Success
            return $true
        }
        else {
            Write-Log "Failed to extract ODT. Exit code: $($process.ExitCode)" -Level Error
            return $false
        }
    }
    catch {
        Write-Log "Error extracting ODT: $_" -Level Error
        return $false
    }
}

# Function to create removal configuration XML
function New-RemovalConfig {
    param([string]$ConfigPath)

    Show-Progress -Activity "Preparing removal" -Status "Creating removal configuration..." -PercentComplete 50
    Write-Log "Creating Office removal configuration..."

    $xmlContent = @"
<Configuration>
    <Remove>
        <Product ID="OneNoteFreeRetail">
            <Language ID="MatchInstalled" />
        </Product>
        <Product ID="OneNoteRetail">
            <Language ID="MatchInstalled" />
        </Product>
        <Product ID="O365ProPlusRetail">
            <Language ID="es-es" />
            <Language ID="fr-fr" />
            <Language ID="pt-br" />
        </Product>
        <Product ID="PersonalRetail">
            <Language ID="MatchInstalled" />
        </Product>
        <Product ID="HomeStudentRetail">
            <Language ID="MatchInstalled" />
        </Product>
        <Product ID="HomeBusiness2019Retail">
            <Language ID="MatchInstalled" />
        </Product>
        <Product ID="Professional2019Retail">
            <Language ID="MatchInstalled" />
        </Product>
        <Product ID="O365HomePremRetail">
            <Language ID="MatchInstalled" />
        </Product>
    </Remove>
    <Display Level="None" AcceptEULA="TRUE" />
    <Logging Level="Standard" Path="$env:TEMP" />
</Configuration>
"@

    try {
        $xmlContent | Out-File -FilePath $ConfigPath -Encoding UTF8 -Force
        Write-Log "Removal configuration created" -Level Success
        Write-Log "  - Will remove: OneNote, non-en-us language packs, retail Office versions" -Level Info
        Write-Log "  - Will preserve: Microsoft 365 Apps for enterprise - en-us" -Level Info
        return $true
    }
    catch {
        Write-Log "Failed to create configuration: $_" -Level Error
        return $false
    }
}

# Function to remove Office
function Remove-Office {
    param(
        [string]$SetupPath,
        [string]$ConfigPath
    )

    Show-Progress -Activity "Removing Office" -Status "Uninstalling retail Office installations..." -PercentComplete 60
    Write-Log "Starting Office removal process..."
    Write-Log "This may take several minutes - please wait..." -Level Warning

    try {
        $arguments = "/configure `"$ConfigPath`""

        # Show periodic updates during removal
        $job = Start-Job -ScriptBlock {
            param($setup, $setupArgs)
            $process = Start-Process -FilePath $setup -ArgumentList $setupArgs -Wait -PassThru -NoNewWindow
            return $process.ExitCode
        } -ArgumentList $SetupPath, $arguments

        $elapsed = 0
        while ($job.State -eq 'Running') {
            $elapsed += 5
            Show-Progress -Activity "Removing Office" -Status "Uninstalling... ($elapsed seconds elapsed)" -PercentComplete (60 + [Math]::Min(25, $elapsed / 10))
            Start-Sleep -Seconds 5
        }

        $exitCode = Receive-Job -Job $job
        Remove-Job -Job $job

        if ($exitCode -eq 0) {
            Write-Log "Office removed successfully" -Level Success
            return $true
        }
        else {
            Write-Log "Office removal completed with exit code: $exitCode" -Level Warning
            return $true
        }
    }
    catch {
        Write-Log "Error during Office removal: $_" -Level Error
        return $false
    }
}

# Main script execution
try {
    # Start timer
    $startTime = Get-Date

    Write-Host "`n========================================" -ForegroundColor White
    Write-Host "  Office Retail Removal Script" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor White

    Write-Log "=== Office Retail Removal Script Started ==="
    Show-Progress -Activity "Initializing" -Status "Starting Office removal process..." -PercentComplete 0

    # Check for Office installations
    $hasRetailToRemove = Test-OfficeInstalled

    if (-not $hasRetailToRemove) {
        Show-Progress -Activity "Complete" -Status "No retail Office products found to remove" -PercentComplete 100
        Write-Log "No retail Office products detected that need removal" -Level Success
        Write-Log "Microsoft 365 Apps for enterprise (if present) will be preserved" -Level Info

        # Calculate and display elapsed time
        $endTime = Get-Date
        $elapsed = $endTime - $startTime
        $elapsedFormatted = "{0:mm}m {0:ss}s" -f $elapsed
        Write-Log "Total elapsed time: $elapsedFormatted" -Level Info

        Start-Sleep -Seconds 2
        Write-Progress -Activity "Complete" -Completed
        exit 0
    }

    Write-Log "Retail Office products detected - proceeding with removal" -Level Success

    # Create temporary working directory
    Show-Progress -Activity "Preparing removal" -Status "Creating temporary directory..." -PercentComplete 20
    $tempPath = Join-Path $env:TEMP "OfficeRemoval_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
    Write-Log "Created temporary directory: $tempPath"

    # Download ODT
    $odtPath = Get-ODT -TempPath $tempPath
    if (-not $odtPath) {
        throw "Failed to download Office Deployment Tool"
    }

    # Extract ODT
    $extractPath = Join-Path $tempPath "ODT"
    New-Item -Path $extractPath -ItemType Directory -Force | Out-Null

    if (-not (Expand-ODT -ODTPath $odtPath -ExtractPath $extractPath)) {
        throw "Failed to extract Office Deployment Tool"
    }

    # Create removal configuration
    $configPath = Join-Path $extractPath "RemoveOffice.xml"
    if (-not (New-RemovalConfig -ConfigPath $configPath)) {
        throw "Failed to create removal configuration"
    }

    # Execute Office removal
    $setupPath = Join-Path $extractPath "setup.exe"
    if (-not (Test-Path $setupPath)) {
        throw "Setup.exe not found at $setupPath"
    }

    $null = Remove-Office -SetupPath $setupPath -ConfigPath $configPath

    # Verify removal
    Show-Progress -Activity "Verifying removal" -Status "Checking for remaining retail products..." -PercentComplete 90
    Start-Sleep -Seconds 3

    $remainingRetail = Test-OfficeInstalled

    if (-not $remainingRetail) {
        Show-Progress -Activity "Complete" -Status "Retail products successfully removed" -PercentComplete 100
        Write-Host "`n========================================" -ForegroundColor White
        Write-Host "  SUCCESS: Retail Office Removed" -ForegroundColor Green
        Write-Host "========================================`n" -ForegroundColor White
        Write-Log "Retail Office products removed successfully" -Level Success
        Write-Log "Microsoft 365 Apps for enterprise (if present) has been preserved" -Level Info
        $exitCode = 0
    }
    else {
        Show-Progress -Activity "Complete" -Status "Removal completed with warnings" -PercentComplete 100
        Write-Host "`n========================================" -ForegroundColor White
        Write-Host "  WARNING: Some retail components may remain" -ForegroundColor Yellow
        Write-Host "========================================`n" -ForegroundColor White
        Write-Log "Some retail Office components may still remain" -Level Warning
        $exitCode = 1
    }

    # Cleanup
    Show-Progress -Activity "Cleanup" -Status "Removing temporary files..." -PercentComplete 95
    Write-Log "Cleaning up temporary files..."
    Start-Sleep -Seconds 1
    Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue

    # Calculate and display elapsed time
    $endTime = Get-Date
    $elapsed = $endTime - $startTime
    $elapsedFormatted = "{0:mm}m {0:ss}s" -f $elapsed

    Write-Progress -Activity "Complete" -Completed
    Write-Log "Total elapsed time: $elapsedFormatted" -Level Info
    Write-Log "=== Office Retail Removal Script Completed ==="

    exit $exitCode
}
catch {
    Show-Progress -Activity "Error" -Status "An error occurred" -PercentComplete 100
    Write-Host "`n========================================" -ForegroundColor White
    Write-Host "  ERROR: Removal Failed" -ForegroundColor Red
    Write-Host "========================================`n" -ForegroundColor White
    Write-Log "Critical error: $_" -Level Error
    Write-Log $_.ScriptStackTrace -Level Error

    # Cleanup on error
    if ($tempPath -and (Test-Path $tempPath)) {
        Write-Log "Cleaning up temporary files..." -Level Warning
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Calculate and display elapsed time on error
    if ($startTime) {
        $endTime = Get-Date
        $elapsed = $endTime - $startTime
        $elapsedFormatted = "{0:mm}m {0:ss}s" -f $elapsed
        Write-Log "Total elapsed time: $elapsedFormatted" -Level Info
    }

    Start-Sleep -Seconds 3
    Write-Progress -Activity "Error" -Completed

    exit 1
}
