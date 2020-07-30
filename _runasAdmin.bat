:: Step 1. Edit the UNC path below by setting it to the the script path, e.g. \\serverName\d$\Dropbox (CSS)\CSS Main Folder (1)\07 Human Resources\01_Personnel-Files\FolderTemplateProvisioner.bat
:: Note: It must be a UNC path starting with "\\" instead of a drive letter
::
:: Step 2. Edit /u:DOMAIN\username by changing DOMAIN to the Active Directory domain name (NETBIOS name), and the username as the admin user. For non-domain scenarios, DOMAIN can be a 'dot' (.) or simply skipping 'DOMAIN\' altogether
:: Note:
:: - If a non-domain account is specified, runas command still requires the PC to be connected to domain. This appears to be a limitation of runas
:: - User Account Control (UAC) has to be disabled, i.e. setting EnableLUA to 0 under Windows registry HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System, or the target runas user is the built-in domain or local Administrator account which is unaffected by UAC.

:: Step 3. Before this script can be run by users, it (or the 'runas /savecred' ... command) needs to be run once on PCs of users who need to use the script without admin credentials.
:: Note: The first run involves prompting for admin credentials where admin needs to be there to input admin password once

runas /savecred /u:DOMAIN\username "\\serverName\d$\Dropbox (CSS)\CSS Main Folder (1)\07 Human Resources\01_Personnel-Files\FolderTemplateProvisioner.bat"