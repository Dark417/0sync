@echo off
rem pr.bat - commit and push changes for 0sync
rem Usage: run from cmd at any time; uses absolute repo path below

setlocal enabledelayedexpansion
set REPO_ROOT=D:\1ai\1A.L\0sync
cd /d "%REPO_ROOT%"

set PRLOG=%REPO_ROOT%\pr.log
echo ==== pr.bat started at %date% %time% ====>> "%PRLOG%"

rem initialize repo if needed
if not exist .git (
  git init >> "%PRLOG%" 2>&1
)

rem ensure branch
git branch -M main 2>> "%PRLOG%" || rem

rem count lines in log.txt (robust)
set LINES=0
for /f "usebackq delims=" %%a in (`type "%REPO_ROOT%\log.txt" ^| find /v /c ""`) do set LINES=%%a
echo log.txt lines: %LINES% >> "%PRLOG%"

rem read last line from log.txt for commit message
set "LAST_LINE=autocommit"
for /f "usebackq delims=" %%a in ("%REPO_ROOT%\log.txt") do set "LAST_LINE=%%a"

set TIMESTAMP=%date% %time%

rem initial commit path (if only 1 line in log.txt)
if "%LINES%"=="1" (
  git add . >> "%PRLOG%" 2>&1
  git commit -m "%TIMESTAMP%: %LAST_LINE%" >> "%PRLOG%" 2>&1 || echo No changes to commit >> "%PRLOG%"
  rem try to push; if origin not set or push fails, attempt to create remote via gh or add remote then push
  git push -u origin main >> "%PRLOG%" 2>&1 || (
    echo initial push failed, attempting to create remote or set origin >> "%PRLOG%"
    git remote get-url origin >nul 2>&1 || (
      where gh >nul 2>&1
      if errorlevel 0 (
        gh repo create Dark417/0sync --public --source=. --remote=origin --push >> "%PRLOG%" 2>&1 || (
          git remote add origin https://github.com/Dark417/0sync.git >> "%PRLOG%" 2>&1
        )
      ) else (
        git remote add origin https://github.com/Dark417/0sync.git >> "%PRLOG%" 2>&1
      )
    )
    rem attempt push again
    git push -u origin main >> "%PRLOG%" 2>&1 || echo initial push retry failed >> "%PRLOG%"
  )
) else (
  git add . >> "%PRLOG%" 2>&1
  git commit -m "%TIMESTAMP%: %LAST_LINE%" >> "%PRLOG%" 2>&1 || echo No changes to commit >> "%PRLOG%"
  git push origin main >> "%PRLOG%" 2>&1 || (
    echo push failed, trying to set upstream or create remote >> "%PRLOG%"
    git remote get-url origin >nul 2>&1 || (
      where gh >nul 2>&1
      if errorlevel 0 (
        gh repo create Dark417/0sync --public --source=. --remote=origin --push >> "%PRLOG%" 2>&1 || (
          git remote add origin https://github.com/Dark417/0sync.git >> "%PRLOG%" 2>&1
        )
      ) else (
        git remote add origin https://github.com/Dark417/0sync.git >> "%PRLOG%" 2>&1
      )
    )
    git push -u origin main >> "%PRLOG%" 2>&1 || echo push retry failed >> "%PRLOG%"
  )
)

echo %TIMESTAMP%: %LAST_LINE%>> "%REPO_ROOT%\book.md"
echo ==== pr.bat finished at %date% %time% ====>> "%PRLOG%"

endlocal
echo Completed pr.bat. See %REPO_ROOT%\pr.log for details.
