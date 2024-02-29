function UninstallTeams {
  [CmdletBinding(SupportsShouldProcess=$true)]
  param (
      [Parameter(Position=1, Mandatory=$true)]
      [String]
      $Path
  )

  Begin {
    $Installer = "$($Path)\Update.exe"

    Write-Information "Stopping Teams process.."
    Get-Process -ProcessName Teams -ErrorAction SilentlyContinue | Stop-Process -Force | Out-Null

  }

  Process {
    if ($PSCmdlet.ShouldProcess($Path, ("Removing teams from '{0}'" -f $Path))) {
      $Process = Start-Process -FilePath $Installer -ArgumentList "--uninstall /s" -PassThru -Wait -ErrorAction SilentlyContinue

      if ($Process.ExitCode -ne 0) {
        Write-Error "Uninstallation failed with exit code $($Process.ExitCode)"
      }

      Write-Information "Successfully removed Teams from $($Path)"

      Get-AppxPackage -Name MicrosoftTeams | Remove-AppxPackage
    }
  }
}

$TeamsPaths = @(
  "$($env:LOCALAPPDATA)\Microsoft\Teams"
)

$TeamsPaths | ForEach-Object {
  if (-not(Test-Path -Path $_)) {
    Write-Information "Older Teams installations not found."
  } else {
    UninstallTeams -Path $_
  }
}



$MachineWideInstaller = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Teams Machine-Wide Installer"}
if ($null -ne $MachineWideInstaller) {
  Write-Information "Removing MachineWide Installer.."
  $Uninstaller = $MachineWideInstaller.Uninstall()
  if ($Uninstaller.ReturnValue -eq 0) {
    Write-Information "Successfully removed Teams MachineWide Installer."
  } else {
    Write-Warning "Unable to remove Teams MachineWide Installer. ErrorCode: $($Uninstaller.ReturnValue)"
  }
} else {
  Write-Information "No MachineWide Installers found."
}