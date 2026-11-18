@echo off
echo ========================================================
echo   Mafad One Plus Desktop - Windows Release Builder
echo ========================================================
echo.

echo 1. Resolving Flutter dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo Error during flutter pub get.
    pause
    exit /b %errorlevel%
)

echo.
echo 2. Enabling Windows Desktop...
call flutter config --enable-windows-desktop

echo.
echo 3. Building Windows Release (.exe)...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo Error during flutter build windows.
    pause
    exit /b %errorlevel%
)

echo.
echo 4. Copying portable platform-tools (adb.exe)...
if not exist "build\windows\x64\runner\Release\platform-tools" mkdir "build\windows\x64\runner\Release\platform-tools"
xcopy /E /I /Y "assets\platform-tools-windows\*" "build\windows\x64\runner\Release\platform-tools\"

echo.
echo ========================================================
echo   BUILD COMPLETED SUCCESSFULLY!
echo   Output folder: build\windows\x64\runner\Release\
echo ========================================================
echo.
pause
