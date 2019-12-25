param(
    
    [Parameter(Mandatory)]
    [string]$ComputerName,
    
    [Parameter(Mandatory)]
    [string]$SccmSiteCode,

    [Parameter(Mandatory)]
    [string]$SccmSiteName,

    [Parameter(Mandatory)]
    [ValidatePattern('^EVAL$|^\w{5}-\w{5}-\w{5}-\w{5}-\w{5}$', Options = 'IgnoreCase')]
    [string]$SccmProductId,

    [Parameter(Mandatory)]
    [string]$SccmBinariesDirectory,

    [Parameter(Mandatory)]
    [string]$SccmPreReqsDirectory,

    [Parameter(Mandatory)]
    [string]$AdkDownloadPath,

    [Parameter(Mandatory)]
    [string]$WinPEDownloadPath,

    [Parameter(Mandatory)]
    [string]$SqlServerName
)

$sqlServer = Get-LabVM -Role SQLServer | Where-Object Name -eq $SqlServerName
$sccmServer = Get-LabVM -ComputerName $ComputerName
if (-not $sqlServer)
{
    Write-Error "The specified SQL Server '$SqlServerName' does not exist in the lab."
    return
}    

if ($sccmServer.OperatingSystem.Version -lt 10.0 -or $sqlServer.OperatingSystem.Version -lt 10.0)
{
    Write-Error "The SCCM role requires the SCCM server and the SQL Server to be Windows 2016 or higher."
    return
}

if ($SccmSiteCode -notmatch '^[A-Za-z0-9]{3}$')
{
    Write-Error 'The site code must have exactly three characters and it can contain only alphanumeric characters (A to Z or 0 to 9).'
    return
}

$script = Get-Command -Name $PSScriptRoot\Invoke-DownloadADK.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-DownloadADK.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-DownloadCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-DownloadCM.ps1 @param

$script = Get-Command -Name $PSScriptRoot\Invoke-InstallCM.ps1
$param = Sync-Parameter -Command $script -Parameters $PSBoundParameters
& $PSScriptRoot\Invoke-InstallCM.ps1 @param

Get-LabVM | ForEach-Object {
    Dismount-LabIsoImage -ComputerName $_.Name -SupressOutput
}