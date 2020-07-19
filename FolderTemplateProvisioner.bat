:: Name: ws-folder-template-provisioner
:: Version: 1.1
:: Date: 20200719
:: GitHub Repository: https://github.com/wandersick/ws-folder-template-provisioner
:: Description:
::   This Windows batch script provisions (copies) new folders with exact permissions and content
::   from a specified existing folder (template) based on the information (first name & last name)
::   inputted by a user via its command-line interface.
:: 
::   It solves a problem using 'robocopy /MIR /COPYALL' in which folders copied using Windows
::   Explorer (a.k.a. File Explorer) may not retain unique permissions and inherit permissions
::   from parent folder.
:: 
::   The script has been designed with care to improve usability and avoid accidental deletion.
::
:: Features: Refer to README.md
:: 
:: Requirements:
::   1. Windows OS with robocopy
::   2. Administrator rights (required by robocopy /COPYALL)
::
:: Script Filenames: 
::   1. FolderTemplateProvisioner.bat (main script)
::   2. _elevate.vbs (optional, for UAC elevation if admin rights are unavailable)
::
:: Setting up the Scripts:
::   1. Edit `templateName` variable at the upper area of 'FolderTemplateProvisioner.bat' script
::      by setting it to the folder acting as the template, e.g.
::      'ZZ IT_do not use\01 Template Folder', with required files and permissions inside
::   2. Place both scripts ('FolderTemplateProvisioner.bat' and optionally '_elevate.vbs') inside
::      a folder containing 'A,B,C...Z' sub-folders, sitting beside them. The 'A-Z' folders contains
::      the template folder and provisioned folders named 'LASTNAME, Firstname' copied by the script
::      from the template folder
::
:: Folder Hierarchy: Refer to README.md
::
:: How to Provision a New Folder:
::   1. Double-click FolderTemplateProvisioner.bat and follow on-screen instructions
::   2. Input last name and first name
::   3. Review the input
::   4. Wait for robocopy file copy (folder template provisioning)
::   5. Verify the created folder (which pops up optionally at the end)
::
:: Screenshots: Refer to README.md

@echo off
setlocal enabledelayedexpansion

:: Define your template folder name here (without quotes)
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
		cscript //NoLogo "%WorkingDir%\_elevate.vbs" "%WorkingDir%" "%WorkingDir%\FolderTemplateProvisioner.bat" >nul 2>&1
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
echo :: Based on the entry, below folder will be created:
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

dir "%templateName%">nul 2>&1
if %errorlevel% NEQ 0 (
  echo.
  echo ___________________________________________________________________
  echo.
  echo :: Error: Template folder name "%templateName%" does not exist in target location
  echo.
  echo    Or it is defined wrongly in the script
  echo.
  endlocal
  echo Press any key to quit . . .
  pause >nul
  goto :EOF
)

REM Enter the responsible single-letter folder
pushd %lastName1st%>nul 2>&1
if %errorlevel% NEQ 0 (
  echo.
  echo ___________________________________________________________________
  echo.
  echo :: Error: Target A-Z folder "%lastName1st%" is invalid or inaccessible. Please check and try again
  echo.
  popd
  pause
  goto :enterName
) else (
  popd
)

if exist "%lastName1st%\%folderName%" (
  echo.
  echo ___________________________________________________________________
  echo.
  echo :: Warning: A folder with the same name as "%folderName%" already exists
  if "!folderOpened!" NEQ "1" (
    echo.
    echo    Please confirm it is unneeded . . . Opening the folder . . . 
    ping 127.0.0.1 -n 2 >nul 2>&1
    explorer "%lastName1st%\%folderName%"
    set folderOpened=1
  )
  echo.
  set /p goAhead= :: Are you sure to DELETE it and replace it with a new one? ^(Answer 'N' to quit if unsure^) [Y,N] 
 
  if /i "!goAhead!" EQU "N" (
    goto :enterName
  ) else if /i "!goAhead!" EQU "Y" (
    goto :createFolder
  ) else (
    goto :folderExistenceCheck
  )
)

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
robocopy "%templateName%" "%lastName1st%\%folderName%" /MIR /COPYALL /TEE /LOG+:%Temp%\FolderCreator.log
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
set /p goAhead= :: Open the new folder now? [Y,N] 
if /i "%goAhead%" EQU "N" (
  goto :end
) else if /i "%goAhead%" EQU "Y" (
  explorer "%lastName1st%\%folderName%"
  goto :end
) else (
  goto :folderCreated
)

:: End
:end
endlocal
cls
echo.
echo    Thank you for using :^)
echo.
echo    Have a good day!
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