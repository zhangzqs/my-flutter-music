@echo off
echo Testing My Music WebDAV Player compilation...
echo.

echo 1. Checking Flutter installation...
flutter --version
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter not found or not properly installed!
    pause
    exit /b 1
)

echo.
echo 2. Checking Windows desktop support...
flutter config --enable-windows-desktop
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Could not enable Windows desktop support!
    pause
    exit /b 1
)

echo.
echo 3. Getting dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to get dependencies!
    pause
    exit /b 1
)

echo.
echo 4. Analyzing code...
flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Code analysis found issues, but continuing...
)

echo.
echo 5. Testing compilation (debug build)...
flutter build windows --debug
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Debug build failed!
    pause
    exit /b 1
)

echo.
echo SUCCESS: Project compiled successfully!
echo You can now run the app with: flutter run -d windows
echo Or build release version with: flutter build windows --release
echo.
pause
