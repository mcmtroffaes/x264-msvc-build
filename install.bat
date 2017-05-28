@echo on
git submodule update --init --recursive --depth 100
if "%PLATFORM%" == "x64" curl -o "c:\nasm.zip" http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/win64/nasm-2.13.01-win64.zip
if "%PLATFORM%" == "x86" curl -o "c:\nasm.zip" http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/win32/nasm-2.13.01-win32.zip
7z x c:\nasm.zip -oc:\
dir /s /b c:\nasm-2.13.01
set PATH=c:\nasm-2.13.01;%PATH%
@echo off