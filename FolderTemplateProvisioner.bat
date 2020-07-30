:: Name: ws-folder-template-provisioner
:: Version: 1.2
:: Date: 20200730
:: GitHub Repository: https://github.com/wandersick/ws-folder-template-provisioner
:: Description:
::   This Windows batch script provisions (copies) new folders with exact permissions and content
::   from a specified existing folder (template) based on the information (first name & last name)
::   inputted by a user via its command-line interface.
:: 
::   It solves a problem using 'robocopy /MIR /COPYALL /ZB' (built-in) where folders copied using 
::   Windows Explorer (a.k.a. File Explorer) may not retain unique permissions and inherit 
::   permissions from parent folder.
::
:: What's New:
::   Support of network-shared folder in UNC form ('\\...') is available
::   - In other words, for drives mapped using a drive letters, they are supported by specifying
::     the UNC path within this script. See 'How to Set up the Scripts' section below.
::   - To test or use this script for non-network cases (local drives) from v1.2 and on, specify
::     \\127.0.0.1\... or \\localhost\... where required
::
::   Support of non-admin users, provided by 'runas /savecred' (built-in)
::   - If users do not have admin rights, _runasAdmin.bat (included optional script) can be edited
::     to leverage 'runas /savecred' to run FolderTemplateProvisioner.bat (main script) as admin
::     without entering admin credentials
:: 
:: Features: Refer to README.md
:: 
:: Requirements:
::   - Windows OS with robocopy
::   - Non-admin rights (partially supported with an optional setup on _runasAdmin.bat)
::   - admin rights (with or without UAC)
:: 
:: Script Filenames: 
::   1. FolderTemplateProvisioner.bat (main script)
::   2. _elevate.vbs (optional, for admin users with UAC turned on, trigger UAC elevation prompt)
::   3. _runasAdmin.bat (optional, for non-admin users to leverage 'runas /savecred' to run as admin)
::
:: How to Set up the Scripts:
::   1. (Optional - in case users executing the script would not have admin rights):
::      Edit the UNC path in _runasAdmin.bat setting it to the the script path, e.g. 
::      \\serverName\d$\Human Resources\01_Personnel-Files\FolderTemplateProvisioner.bat
::      - It must be a UNC path starting with "\\" instead of a drive letter
::      - This script (runas /savecred) needs to be run once on PCs of users who need
::        to use the script without admin credentials. (The first run involves prompting for
::        admin credentials where admin needs to be there to input admin password once)
::   2. Edit 'encPath' variable at the upper area of 'FolderTemplateProvisioner.bat' script
::      by setting it to the network folder containing the script, e.g. 
::      \\serverName\d$\Human Resources\01_Personnel-Files
::   3. Edit 'templateName' variable at the upper area of 'FolderTemplateProvisioner.bat' script
::      by setting it to the folder acting as the template, e.g.
::      'ZZ IT_do not use\01 Template Folder', with required files and permissions inside
::   4. Place all scripts ('FolderTemplateProvisioner.bat', optionally '_elevate.vbs' and
::      '_runasAdmin.bat') inside a folder containing 'A,B...Z' sub-folders, sitting aside.
::      The 'A-Z' folders contains the template folder and provisioned folders named
::      'LASTNAME, Firstname' copied by the script from the template folder
::
:: Folder Hierarchy: Refer to README.md
::
:: How to Provision a New Folder:
::   1. Double-click FolderTemplateProvisioner.bat and follow on-screen instructions
::      - Note: for non-admin users, they should run "_runasAdmin.bat" (never run "_elevate.vbs")
::   2. Input last name and first name
::   3. Review the input
::   4. Wait for robocopy file copy (folder template provisioning)
::   5. Verify the created folder
::
:: Screenshots: Refer to README.md

@echo off

:: Clear UNC error message that can be ignored, e.g.
:: '\\path\to\somewhere'
:: CMD.EXE was started with the above path as the current directory.
:: UNC paths are not supported.  Defaulting to Windows directory.
cls

setlocal enabledelayedexpansion

:: Define the UNC path to file share and your template folder name here (without quotes)
set uncPath=\\127.0.0.1\d$\Dropbox (CSS)\CSS Main Folder (1)\07 Human Resources\01_Personnel-Files
set templateName=ZZ IT_do not use\01 Template Folder

:: Set the working directory where script is located by %~d0%~p0 (e.g. x:\...\here)
set WorkingDir=%~d0%~p0

:: Detect if system supports "attrib"
attrib >nul 2>&1
if "%errorlevel%"=="9009" set noAttrib=1

if not exist "%WorkingDir%\_elevate.vbs" goto :skipAdminCheck

:: UAC check
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA | find /i "0x1">nul 2>&1
if %errorlevel% EQU 0 set UACenabled=1

:: Detect if system has WSH disabled unsigned scripts
:: if useWINSAFER = 1, the TrustPolicy below is ignored and use SRP for this option instead. So check if = 0.
:: if TrustPolicy = 0, allow both signed and unsigned; if = 1, warn on unsigned; if = 2, disallow unsigned.
for /f "usebackq tokens=3 skip=2" %%a in (`reg query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v UseWINSAFER 2^>nul`) do (
	@if "%%a" EQU "0" (
		@for /f "usebackq tokens=3 skip=2" %%i in (`reg query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v TrustPolicy 2^>nul`) do (
			@if "%%i" GEQ "2" (
				set noWSH=1
			)
		)
	)
)

if defined noWSH (
	echo.
	echo :: Error: Windows Scripting Host is disabled.
	echo.
	pause
	goto :skipAdminCheck
)

:: Detect admin rights
if defined noAttrib goto :skipAdminCheck
attrib -h "%windir%\system32" | find /i "system32" >nul 2>&1
if %errorlevel% EQU 0 (
	REM only when UAC is enabled can this script be elevated. Otherwise, non-stop prompting will occur.
	if "%UACenabled%" EQU "1" (
		cscript //NoLogo "%WorkingDir%_elevate.vbs" "%WorkingDir%" "%WorkingDir%FolderTemplateProvisioner.bat" >nul 2>&1
		goto :EOF
	) else (
		echo.
		echo :: Error: Folder Template Provisioner requires admin rights. Please run as admin.
		echo.
		pause
		goto :EOF
	)
)
:skipAdminCheck

:: Detect admin rights (subsequent)

if defined noAttrib goto :skipAdminCheckSubsequent
attrib -h "%windir%\system32" | find /i "system32" >nul 2>&1
if %errorlevel% EQU 0 (
	echo.
	echo :: Error: Folder Template Provisioner requires admin rights. Please run as admin.
	echo.
	pause
	goto :EOF
)

:skipAdminCheckSubsequent

title Welcome to Folder Template Provisioner

:: Enter name
:enterName
set lastName=
set firstName=
set rerun=
cls

echo.
set /p lastName=:: Please input last name ^(in capital case, e.g. DOWNEY^): 
echo.
set /p firstName=:: Please input first name ^(in title case, e.g. Robert^): 

:: Review folder name
:reviewFolderName
set folderName=
set goAhead=
echo.
echo ___________________________________________________________________
echo.
echo :: Please ensure the folder does not exist; otherwise, any existing data will be overwritten:
echo.
echo    Folder name: "%lastName%, %firstName%"
echo.
set /p goAhead= :: Would you like to continue? [Y,N] 
if /i "%goAhead%" EQU "N" (
  goto :enterName
) else if /i "%goAhead%" EQU "Y" (
  set folderName=%lastName%, %firstName%
  set folderOpened=
  goto :folderExistenceCheck
) else (
  goto :reviewFolderName
)

:: Folder existence check
:folderExistenceCheck

if not defined firstName (
  echo.
  echo ___________________________________________________________________
  echo.
  echo :: Error: Name is invalid. Please try again
  echo.
  pause
  goto :enterName
)

if not defined lastName (
  echo.
  echo ___________________________________________________________________
  echo.
  echo :: Error: Name is invalid. Please try again
  echo.
  pause
  goto :enterName
)

REM Warn user that data could be deleted, due to robocopy /MIR, if destination contains the same folder name
set goAhead=
set lastName1st=

REM Grab first letter from last name
set lastName1st=%lastName:~0,1%


:: Create folder
:createFolder


echo.
echo ___________________________________________________________________
echo.
echo :: Starting file copy. Please wait . . .
echo.
ping 127.0.0.1 -n 2 >nul 2>&1

REM Copy template folder as a new folder
set robocopyError=
robocopy "%uncPath%\%templateName%" "%uncPath%\%lastName1st%\%folderName%" /MIR /COPYALL /ZB /TEE /LOG+:%Temp%\FolderCreator.log
if %errorlevel% GTR 3 set robocopyError=%errorlevel%

:: Folder created
:folderCreated
echo.
echo ___________________________________________________________________
set goAhead=
echo.
echo :: Completed
echo.
if defined robocopyError goto :robocopyError
echo Press any key to quit . . .
pause >nul
goto :end

:: End
:end
endlocal
cls
echo.
echo    Don't forget to verify the created folder :^)
echo.
echo    Thank you for using!
echo.
ping 127.0.0.1 -n 2 >nul 2>&1
cls
exit

:: Output robocopy error code if there as an error
:robocopyError
echo :: Error: Folder provisioning failed. The robocopy error code was %robocopyError%
echo.
echo Press any key to quit . . .
pause >nul
goto :EOF