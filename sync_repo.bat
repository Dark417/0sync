@echo off
rem Sync script: Windows batch
rem Usage: run from command prompt: 0sync\sync_repo.bat [repo-path] [remote-spec]
rem remote-spec default: mygithub/lc (will use https://github.com/mygithub/lc.git)

setlocal enabledelayedexpansion
set REPO_DIR=%~1
if "%REPO_DIR%"=="" set REPO_DIR=%cd%
set REMOTE_SPEC=%~2
if "%REMOTE_SPEC%"=="" set REMOTE_SPEC=mygithub/lc
set REMOTE_NAME=origin
set REMOTE_URL=https://github.com/%REMOTE_SPEC%.git
set LOGFILE=%REPO_DIR%\0sync.log

cd /d "%REPO_DIR%"

:loop
if not exist .git (
  git init >> "%LOGFILE%" 2>&1
)

rem ensure remote exists; try gh if available
git remote | findstr /i "^%REMOTE_NAME%$" >nul 2>&1
if errorlevel 1 (
  where gh >nul 2>&1
  if errorlevel 0 (
    gh repo create %REMOTE_SPEC% --public --source=. --remote=%REMOTE_NAME% --push >> "%LOGFILE%" 2>&1 || (
      rem fallback to adding https remote
      git remote add %REMOTE_NAME% %REMOTE_URL% >> "%LOGFILE%" 2>&1
    )
  ) else (
    git remote add %REMOTE_NAME% %REMOTE_URL% >> "%LOGFILE%" 2>&1
  )
)

set BRANCH=main

rem create or switch to branch
git show-ref --verify --quiet refs/heads/%BRANCH%
if errorlevel 1 (
  git checkout -b %BRANCH% >> "%LOGFILE%" 2>&1
) else (
  git checkout %BRANCH% >> "%LOGFILE%" 2>&1
)

rem fetch and pull with minimal output
git fetch %REMOTE_NAME% --quiet >> "%LOGFILE%" 2>&1 || (
  echo %date% %time%: fetch failed >> "%LOGFILE%"
)
git pull %REMOTE_NAME% %BRANCH% --quiet >> "%LOGFILE%" 2>&1
if errorlevel 0 (
  echo %date% %time%: pull ok >> "%LOGFILE%"
) else (
  echo %date% %time%: pull failed >> "%LOGFILE%"
)

rem if no commits, create an initial commit so push can succeed
for /f "delims=" %%i in ('git status --porcelain') do set HAS_CHANGES=1
if not defined HAS_CHANGES (
  if not exist README.md echo Initial commit > README.md
  git add README.md >> "%LOGFILE%" 2>&1
  git commit -m "Initial commit" >> "%LOGFILE%" 2>&1
)

rem try push; if remote doesn't exist, attempt to create with gh or push (best-effort)
git push %REMOTE_NAME% %BRANCH% --quiet >> "%LOGFILE%" 2>&1
if errorlevel 1 (
  where gh >nul 2>&1
  if errorlevel 0 (
    gh repo create %REMOTE_SPEC% --public --source=. --remote=%REMOTE_NAME% --push >> "%LOGFILE%" 2>&1
  ) else (
    git push -u %REMOTE_NAME% %BRANCH% >> "%LOGFILE%" 2>&1
  )
)

rem sleep 60 seconds
timeout /t 60 /nobreak >nul
goto loop
