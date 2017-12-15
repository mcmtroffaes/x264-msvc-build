@echo on
rem set up Visual Studio 2017 64-bit environment for v140 toolset
rem see https://www.appveyor.com/docs/lang/cpp/
rem and https://stackoverflow.com/a/46994531
rem (differenes: no need for SDK, use native amd64 instead of x86_amd64)
if "%TOOLSET%" == "v90" (
  if "%PLATFORM%" == "x64" call "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcvarsall.bat" amd64
  if "%PLATFORM%" == "x86" call "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcvarsall.bat" x86
)
if "%TOOLSET%" == "v100" (
  if "%PLATFORM%" == "x64" call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" amd64
  if "%PLATFORM%" == "x86" call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" x86
)
if "%TOOLSET%" == "v110" (
  if "%PLATFORM%" == "x64" call "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" amd64
  if "%PLATFORM%" == "x86" call "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86
)
if "%TOOLSET%" == "v120" (
  if "%PLATFORM%" == "x64" call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" amd64
  if "%PLATFORM%" == "x86" call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86
)
if "%TOOLSET%" == "v140" (
  if "%PLATFORM%" == "x64" call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64
  if "%PLATFORM%" == "x86" call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86
)
rem v140 can be consumed by v141 so no point in compiling this
rem if "%TOOLSET%" == "v141" (
rem   if "%PLATFORM%" == "x64" call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat" -vcvars_ver=14.1
rem   if "%PLATFORM%" == "x86" call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars32.bat" -vcvars_ver=14.1
rem )
rem run main build script
C:\msys64\usr\bin\bash -lc "$APPVEYOR_BUILD_FOLDER/build.sh"
@echo off
