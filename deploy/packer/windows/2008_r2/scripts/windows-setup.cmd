
goto set_env_var_to_dir_this_script_is_in

:: ----------- set_env_var_to_dir_this_script_is_in ::
:set_env_var_to_dir_this_script_is_in
for /F "delims=" %%D in ("%~dp0") do set this_directory=%%~fD
:: -------------------------------------- ::

set msys2_version=20160205-3
set msys2_install_url=https://replace.com/msys2_x64-20160205-3.zip
set msys2_install_directory=C:\tools\msys\%msys2_version%
set msys2_root_directory=C:\tools\msys

set seven_zip_install_url=https://replace.com/7z_x64-920.msi
set seven_zip_install_bin=C:\Program Files\7-Zip\7z.exe

goto check_7zip_install_file_exists

:: ----------- check_7zip_install_file_exists ::
:check_7zip_install_file_exists
if not exist "%seven_zip_install_bin%" goto install_7zip
:: -------------------------------------- ::

goto check_msys2_install_directory_exists

:: ----------- install_7zip ::
:install_7zip
call powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%seven_zip_install_url%', '7z.msi')"
set error_code=%errorlevel%

if %error_code% neq 0 goto :fail

call msiexec /qb /i 7z.msi
set error_code=%errorlevel%

if %error_code% neq 0 goto :fail

:: -------------------------------------- ::

goto check_msys2_install_directory_exists

:: ----------- check_msys2_install_directory_exists ::
:check_msys2_install_directory_exists
if not exist "%msys2_install_directory%\usr" goto install_or_update_msys2
:: -------------------------------------- ::

goto ensure_symbolic_links_exist

:: ----------- install_or_update_msys2 ::
:install_or_update_msys2

mkdir "%msys2_root_directory%"

call powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%msys2_install_url%', 'msys2.zip')"
set error_code=%errorlevel%

if %error_code% neq 0 goto :fail

call "%seven_zip_install_bin%" x msys2.zip -o%msys2_root_directory% -y
set error_code=%errorlevel%

if %error_code% neq 0 goto :fail
:: -------------------------------------- ::

goto ensure_symbolic_links_exist

:: ----------- ensure_symbolic_links_exist ::
:ensure_symbolic_links_exist
for %%f in (usr etc opt var) do (
  if not exist "%msys2_install_directory%\%%f" (
    mkdir "%msys2_install_directory%\%%f"
  )

  if not exist "C:\%%f" (
    mklink /D "C:\%%f" "%msys2_install_directory%\%%f"
    set error_code=%errorlevel%

    if %error_code% neq 0 goto :fail
  )
)

if not exist "C:\c" (
  mklink /D "C:\c" "C:\"
  set error_code=%errorlevel%

  if %error_code% neq 0 goto :fail
)

:: -------------------------------------- ::

goto execute_windows_setup_bash_script

:: ----------- execute_windows_setup_bash_script ::
:execute_windows_setup_bash_script

%msys2_install_directory%\msys2_shell.bat "a:\windows-setup.bash"
exit /B %errorlevel%
:: -------------------------------------- ::

:: ----------- fail ::
:fail
echo "failed!!!"
exit /B %error_code%
:: -------------------------------------- ::
