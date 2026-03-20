@Echo off
setlocal

REM Get the directory where this script resides
set SCRIPT_DIR=%~dp0

REM Find the jar file in the same directory
set JAR_FILE=
for %%f in ("%SCRIPT_DIR%*.jar") do (
  set JAR_FILE=%%f
  goto :found_jar
)
:found_jar

if "%JAR_FILE%"=="" (
  echo Error: No .jar file found in %SCRIPT_DIR%
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
%JAVA_CMD% %JAVA_ARGS% -jar "%JAR_FILE%" %*

REM Exit with the same code as Java
exit /b %ERRORLEVEL%
