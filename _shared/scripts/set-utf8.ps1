# set-utf8.ps1 — 设置 PowerShell 控制台为 UTF-8 编码
# 在任何产生中文输出的脚本开头调用此脚本，防止乱码。
# 用法: . "$PSScriptRoot\set-utf8.ps1"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
