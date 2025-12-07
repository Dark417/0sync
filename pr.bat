@echo off
rem pr.bat - commit and push changes for 0sync
rem Usage: run from cmd at any time; uses absolute repo path below

setlocal enabledelayedexpansion
set REPO_ROOT=D:\1ai\1A.L\0sync
set REMOTE_URL=https://github.com/Dark417/0sync.git
set REMOTE_NAME=origin
set REPO_NAME=Dark417/0sync
cd /d "%REPO_ROOT%"

set PRLOG=%REPO_ROOT%\pr.log
echo ==== pr.bat started at %date% %time% ====>> "%PRLOG%"

rem initialize repo if needed
if not exist .git (
  git init >> "%PRLOG%" 2>&1
)

rem ensure branch
git branch -M main 2>> "%PRLOG%" || rem

rem jump over helper definition
goto :main

rem helper: ensure origin points to the expected URL
:ensure_origin
git remote get-url %REMOTE_NAME% >nul 2>&1
if errorlevel 1 (
  git remote add %REMOTE_NAME% "%REMOTE_URL%" >> "%PRLOG%" 2>&1
) else (
  for /f "usebackq delims=" %%r in (`git remote get-url %REMOTE_NAME% 2^>nul`) do set "CURRENT_REMOTE=%%r"
  if /i not "!CURRENT_REMOTE!"=="%REMOTE_URL%" (
    echo resetting %REMOTE_NAME% from !CURRENT_REMOTE! to %REMOTE_URL% >> "%PRLOG%"
    git remote set-url %REMOTE_NAME% "%REMOTE_URL%" >> "%PRLOG%" 2>&1
  )
)
goto :eof

:main
rem count lines in log.txt (robust)
set LINES=0
for /f "usebackq delims=" %%a in (`type "%REPO_ROOT%\log.txt" ^| find /v /c ""`) do set LINES=%%a
echo log.txt lines: !LINES! >> "%PRLOG%"

rem read last line from log.txt for commit message
set "LAST_LINE=autocommit"
for /f "usebackq delims=" %%a in ("%REPO_ROOT%\log.txt") do set "LAST_LINE=%%a"

set TIMESTAMP=%date% %time%

rem initial commit path (if only 1 line in log.txt)
if "!LINES!"=="1" (
  git add . >> "%PRLOG%" 2>&1
  git commit -m "%TIMESTAMP%: %LAST_LINE%" >> "%PRLOG%" 2>&1 || echo No changes to commit >> "%PRLOG%"
  rem initial path: ensure remote is configured and try to create the repo before first push
  call :ensure_origin
  set PUSHED=0
  where gh >nul 2>&1
  if errorlevel 0 (
    gh repo view %REPO_NAME% >> "%PRLOG%" 2>&1
    if errorlevel 1 (
      echo remote repo not found; creating via gh >> "%PRLOG%"
      gh repo create %REPO_NAME% --public --source=. --remote=%REMOTE_NAME% --push >> "%PRLOG%" 2>&1
      if not errorlevel 1 set PUSHED=1
    )
  )
  if not "!PUSHED!"=="1" (
    git push -u %REMOTE_NAME% main >> "%PRLOG%" 2>&1 || (
      echo initial push failed after remote setup >> "%PRLOG%"
    )
  )
) else (
  git add . >> "%PRLOG%" 2>&1
  git commit -m "%TIMESTAMP%: %LAST_LINE%" >> "%PRLOG%" 2>&1 || echo No changes to commit >> "%PRLOG%"
  call :ensure_origin
  git push %REMOTE_NAME% main >> "%PRLOG%" 2>&1 || (
    echo push failed, trying to set upstream or create remote >> "%PRLOG%"
    where gh >nul 2>&1
    if errorlevel 0 (
      gh repo view %REPO_NAME% >> "%PRLOG%" 2>&1
      if errorlevel 1 (
        echo remote repo not found; creating via gh >> "%PRLOG%"
        gh repo create %REPO_NAME% --public --source=. --remote=%REMOTE_NAME% --push >> "%PRLOG%" 2>&1
        if errorlevel 0 goto :bookappend
      )
    )
    git push -u %REMOTE_NAME% main >> "%PRLOG%" 2>&1 || echo push retry failed >> "%PRLOG%"
  )
)

:bookappend
echo %TIMESTAMP%: %LAST_LINE%>> "%REPO_ROOT%\book.md"
echo ==== pr.bat finished at %date% %time% ====>> "%PRLOG%"

endlocal
echo Completed pr.bat. See %REPO_ROOT%\pr.log for details.
