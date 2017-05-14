﻿#Version 1.00.00 @KieranWalsh May 2017
# Computer Talk LTD

$OffComputers = @()
$CheckFail = @()
$Patched = @()
$Unpatched = @()

$log = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "WannaCry patch state for $($ENV:USERDOMAIN).csv"

$Patches = @('KB3205409', 'KB3210720', 'KB3210721', 'KB3212646', 'KB3213986', 'KB4012212', 'KB4012213', 'KB4012214', 'KB4012215', 'KB4012216', 'KB4012217', 'KB4012218', 'KB4012598', 'KB4012606', 'KB4013198', 'KB4013389', 'KB4013429', 'KB4015217', 'KB4015438', 'KB4015546', 'KB4015549', 'KB4015552', 'KB4016635', 'KB4019263', 'KB4019264', 'KB4019472')

$WindowsComputers = (Get-ADComputer -Filter {
    OperatingSystem -Like 'Windows*'
}).Name|
Sort-Object

"WannaCry patch status $(Get-Date -Format 'yyyy-MM-dd HH:mm')" |Out-File -FilePath $log

$ComputerCount = $WindowsComputers.count
"There are $ComputerCount computers to check"
$loop = 0
foreach($Computer in $WindowsComputers)
{
  $ThisComputerPatches = @()
  $loop ++
  "$loop of $ComputerCount `t$Computer"
  try
  {
    $null = Test-Connection -ComputerName $Computer -Count 1 -ErrorAction Stop
    try
    {
      $Hotfixes = Get-HotFix -ComputerName $Computer -ErrorAction Stop

      $Patches | ForEach-Object -Process {
        if($Hotfixes.HotFixID -contains $_)
        {
          $ThisComputerPatches += $_
        }
      }
    }
    catch
    {
      $CheckFail += $Computer
      "***`t$Computer `tUnable to gather hotfix information" |Out-File -FilePath $log -Append
    }
    If($ThisComputerPatches)
    {
      "$Computer is patched with $($ThisComputerPatches -join (','))" |Out-File -FilePath $log -Append
      $Patched += $Computer
    }
    Else
    {
      $Unpatched += $Computer
      "*****`t$Computer IS UNPATCHED! *****" |Out-File -FilePath $log -Append
    }
  }
  catch
  {
    $OffComputers += $Computer
    "****`t$Computer `tUnable to connect." |Out-File -FilePath $log -Append
  }
}

'Unpatched:' |Out-File -FilePath $log -Append
$Unpatched -join (', ')  |Out-File -FilePath $log -Append
'' |Out-File -FilePath $log -Append
'Patched:' |Out-File -FilePath $log -Append
$Patched -join (', ') |Out-File -FilePath $log -Append
'' |Out-File -FilePath $log -Append
'Off/Untested:'|Out-File -FilePath $log -Append
($OffComputers + $CheckFail | Sort-Object)-join (', ')|Out-File -FilePath $log -Append

"Of the $($WindowsComputers.count) windows computers in active directory, $($OffComputers.count) were off, $($CheckFail.count) couldn't be checked, $($Unpatched.count) were unpatched and $($Patched.count) were successfully patched."
'Full details in the log file.'

try
{
  Start-Process -FilePath notepad++ -ArgumentList $log
}
catch
{
  Start-Process -FilePath notepad.exe -ArgumentList $log
}