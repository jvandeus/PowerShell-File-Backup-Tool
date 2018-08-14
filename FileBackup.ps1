param([string]$FileLocation="",[string]$BackupLocation="")

Function Get-FileName($initialDirectory)
{  
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
	Out-Null

	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.InitialDirectory = $initialDirectory
    $OpenFileDialog.Title = "Select a file to backup"
	$OpenFileDialog.Filter = "All files (*.*)| *.*"

	$result = $OpenFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true })) | Out-Null
	if ([string]::IsNullOrEmpty($OpenFileDialog.FileName)) {
		Write-Host "Invalid File location: '" $OpenFileDialog.FileName "' Exiting now."
	    exit
	}
    $OpenFileDialog.FileName
}

Function Get-FolderName($initialDirectory)
{
	Add-Type -AssemblyName System.Windows.Forms
	$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
	$FolderBrowser.Description = 'Select the folder to store the Backups'
	$result = $FolderBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true })) | Out-Null
	if ([string]::IsNullOrEmpty($FolderBrowser.SelectedPath)) {
		Write-Host "Invalid Folder location: '" $FolderBrowser.SelectedPath "' Exiting now."
	    exit
	}
	$FolderBrowser.SelectedPath
}

# check if the file location provided is a real path
if (![string]::IsNullOrEmpty($FileLocation) -and !(Test-Path -Path $FileLocation -PathType leaf)) {
	Write-Host "Invalid File location: '" $FileLocation "' Exiting now."
	exit
}
$FileLocation = Get-FileName -initialDirectory "c:fso"
Write-Host "File Location: " $FileLocation
$FilePath = [io.path]::GetDirectoryName($FileLocation)
Write-Host "File Path: " $FilePath
$FileName = [io.path]::GetFileName($FileLocation)
Write-Host "File Name: " $FileName

# check if the folder location provided is a real path
if (![string]::IsNullOrEmpty($BackupLocation) -and !(Test-Path -Path FileLocation)) {
	Write-Host "Invalid Backup Folder location: '$FileLocation' Exiting now."
	exit
}
$BackupLocation = Get-FolderName -initialDirectory "c:fso"
# default to a subfolder in the backup file's Directory
if ([string]::IsNullOrEmpty($BackupLocation) -Or !(Test-Path $BackupLocation)) {
	$BackupLocation = "$FilePath/Backups"
}
if (!(Test-Path $BackupLocation)) {
	New-Item -ItemType Directory  -Force -Path $BackupLocation
}

Write-Host "Backups will save to the following Folder location: '$BackupLocation'"

# normalize the end of the backup location to prepare for file paths.
$BackupLocation = $BackupLocation.TrimEnd("/"," ")

$IntervalInSeconds = 900

while (1) {
	Write-Host "`nBacking up file..."
	Copy-Item $FileLocation "$BackupLocation/$FileName.$(get-date -f MM-dd-yyyy_HH_mm_ss)" -Force
	Write-Host "Finished"
	
	while ((Get-ChildItem "$BackupLocation").Count -gt 10) {
	Get-ChildItem "$BackupLocation" | Sort CreationTime | Select -First 1 | Remove-Item
	}
	
	start-sleep -seconds $IntervalInSeconds
}
