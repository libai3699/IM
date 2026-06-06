@echo off
chcp 65001 >nul
echo =====================================
echo   Flutter / Gradle / AGP / JDK Versions
echo =====================================

REM -------------------------
REM 1. Flutter 版本
REM -------------------------
echo.
echo [1] Flutter:
flutter --version 2>nul
if errorlevel 1 echo !!! Flutter 未安装或未加入 PATH !!!

REM -------------------------
REM 查找 android 文件夹
REM -------------------------
setlocal enabledelayedexpansion
set "CURDIR=%cd%"
set "ANDROID_DIR="

:SEARCH_LOOP
if exist "%CURDIR%\android\build.gradle" (
    set "ANDROID_DIR=%CURDIR%\android"
    goto FOUND_ANDROID
)
cd ..
if "%cd%"=="%SystemDrive%\" goto NOT_FOUND
goto SEARCH_LOOP

:FOUND_ANDROID
echo.
echo ✅ 找到 Android 目录: %ANDROID_DIR%
goto CONTINUE

:NOT_FOUND
echo.
echo !!! 未找到 android\build.gradle，请确认在 Flutter 项目里运行 !!!
goto END

:CONTINUE

REM -------------------------
REM 2. Gradle Wrapper 版本
REM -------------------------
echo.
echo [2] Gradle Wrapper:
if exist "%ANDROID_DIR%\gradle\wrapper\gradle-wrapper.properties" (
    for /f "tokens=2 delims==" %%i in ('findstr distributionUrl "%ANDROID_DIR%\gradle\wrapper\gradle-wrapper.properties"') do (
        echo %%i
    )
) else (
    echo !!! gradle-wrapper.properties 未找到 !!!
)

REM -------------------------
REM 3. Android Gradle Plugin (AGP) 版本
REM -------------------------
echo.
echo [3] Android Gradle Plugin:
for /f "tokens=*" %%i in ('findstr "com.android.tools.build:gradle" "%ANDROID_DIR%\build.gradle"') do (
    echo %%i
)

REM -------------------------
REM 4. JDK 版本
REM -------------------------
echo.
echo [4] JDK:
java -version 2>&1

echo.
echo =====================================
echo 检测完成，注意 Gradle / AGP / JDK 要匹配
echo =====================================
pause
