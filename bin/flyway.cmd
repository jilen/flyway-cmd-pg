@Echo off
setlocal

REM Get the directory where this script resides
set SCRIPT_DIR=%~dp0

REM Find the lib directory
set LIB_DIR=%SCRIPT_DIR%..\lib

if not exist "%LIB_DIR%" (
  echo Error: lib directory not found at %LIB_DIR%
  exit /b 1
)

REM Determine Java command
if not "%FLYWAY_JAVA_CMD%"=="" (
  set JAVA_CMD=%FLYWAY_JAVA_CMD%
) else (
  if "%JAVA_HOME%"=="" (
    set JAVA_CMD=java
  ) else (
    set JAVA_CMD="%JAVA_HOME%\bin\java.exe"
  )
)

REM Execute Flyway
%JAVA_CMD% %JAVA_ARGS% -cp "%LIB_DIR%\*" org.flywaydb.commandline.Main %*

REM Exit with the same code as Java
exit /b %ERRORLEVEL%
