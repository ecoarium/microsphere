
call powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"
C:\Windows\SysWOW64\cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"

call winrm quickconfig -q
call winrm quickconfig -transport:http
call winrm set winrm/config @{MaxTimeoutms="1800000"}
call winrm set winrm/config/winrs @{MaxMemoryPerShellMB="2048"}
call winrm set winrm/config/service @{AllowUnencrypted="true"}
call winrm set winrm/config/service/auth @{Basic="true"}
call winrm set winrm/config/client/auth @{Basic="true"}
call winrm set winrm/config/listener?Address=*+Transport=HTTP @{Port="5985"}
call winrm set winrm/config/winrs @{MaxShellsPerUser="30"}
call winrm set winrm/config/winrs @{MaxConcurrentUsers="30"}
call winrm set winrm/config/winrs @{MaxProcessesPerShell="30"}
call winrm set winrm/config/service @{MaxConcurrentOperationsPerUser="1500"}

netsh advfirewall firewall set rule group="remote administration" new enable=yes
netsh firewall add portopening TCP 5985 "Port 5985"
net stop winrm
sc config winrm start= auto
net start winrm

reg ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ /v HideFileExt /t REG_DWORD /d 0 /f
reg ADD HKCU\Console /v QuickEdit /t REG_DWORD /d 1 /f
reg ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ /v Start_ShowRun /t REG_DWORD /d 1 /f
reg ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ /v StartMenuAdminTools /t REG_DWORD /d 1 /f
reg ADD HKLM\SYSTEM\CurrentControlSet\Control\Power\ /v HibernateFileSizePercent /t REG_DWORD /d 0 /f
reg ADD HKLM\SYSTEM\CurrentControlSet\Control\Power\ /v HibernateEnabled /t REG_DWORD /d 0 /f

wmic useraccount where "name='vagrant'" set PasswordExpires=FALSE
