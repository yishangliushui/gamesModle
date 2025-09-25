@echo off
setlocal enabledelayedexpansion

:: 设置源目录和目标目录
set "source_dir=D:\java\code\gamesModle\Dont Starve Together\organize-items"
set "target_dir=D:\java\code\gamesModle\Dont Starve Together\"

:: 设置备份间隔时间（以秒为单位，例如 300 秒 = 5 分钟）
set "interval=300"

:loop
:: 获取当前时间戳
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "year=!datetime:~0,4!"
set "month=!datetime:~4,2!"
set "day=!datetime:~6,2!"
set "hour=!datetime:~8,2!"
set "minute=!datetime:~10,2!"
set "second=!datetime:~12,2!"
set "timestamp=!year!!month!!day! !hour!!minute!!second!"

:: 创建目标文件夹（如果不存在）
if not exist "!target_dir!\!timestamp!" mkdir "!target_dir!\!timestamp!"

:: 使用 xcopy 复制文件并保留原始文件名
xcopy "!source_dir!\*" "!target_dir!\!timestamp!" /E /H /C /I /Y

:: 等待指定的时间间隔
timeout /t %interval% /nobreak >nul

:: 重复循环
goto loop