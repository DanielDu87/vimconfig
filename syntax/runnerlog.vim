if exists("b:current_syntax")
	finish
endif

syn sync fromstart

syn match RunnerLogSeparator /^=<>=.*/
syn match RunnerLogTime /^\[\d\{2}:\d\{2}:\d\{2}\]\s\+/
syn match RunnerLogPrefix /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs>>> [^:]+:/
syn match RunnerLogCommand /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?>>> [^:]+: \zs.*$/ contains=RunnerLogPath

" 专门高亮命令行参数 (如 -u, --version 等)，强制在 Command 中生效
syn match RunnerLogPythonFlag /\s\zs-\w\+\ze\s/ containedin=RunnerLogCommand
syn match RunnerLogOutput /^\[\d\{2}:\d\{2}:\d\{2}\]\s\+\zs.*$/
\ contains=RunnerLogUrl,RunnerLogErrorLine,RunnerLogWarnLine,RunnerLogSuccessLine,RunnerLogInfo,RunnerLogDebugLine

syn match RunnerLogPlainLine /^[^\[].*$/
\ contains=RunnerLogUrl,RunnerLogErrorLine,RunnerLogWarnLine,RunnerLogSuccessLine,RunnerLogInfo,RunnerLogDebugLine

" 新增：Django runserver 命令的 IP:Port 部分 (精确匹配)
syn match RunnerLogDjangoRunserver /runserver\s\+\(\%(\d\{1,3}\.\)\{3}\d\{1,3}\|localhost\):\d\+\(\/\S*\)\?/

syn match RunnerLogErrorLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<Error\>.*/
syn match RunnerLogErrorLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<Exception\>.*/
syn match RunnerLogErrorLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<Traceback\>.*/
syn match RunnerLogErrorLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<Failed\>.*/
syn match RunnerLogErrorLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<fatal\>.*/
syn match RunnerLogErrorLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<critical\>.*/
syn match RunnerLogErrorLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*状态码: [1-9].*/
syn match RunnerLogErrorLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*进程异常退出.*/
syn match RunnerLogErrorLine /\v^\s*File .*, line \d+.*/

syn match RunnerLogWarnLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<Warning\>.*/
syn match RunnerLogWarnLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<warn\>.*/
syn match RunnerLogWarnLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*WARN.*/

syn match RunnerLogSuccessLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<Success\>.*/
syn match RunnerLogSuccessLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<Completed\>.*/
syn match RunnerLogSuccessLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<ok\>.*/
syn match RunnerLogSuccessLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<done\>.*/
syn match RunnerLogSuccessLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<finished\>.*/

" 新增 Debug 级别
syn match RunnerLogDebugLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<debug\>.*/
syn match RunnerLogDebugLine /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?\zs.*\<trace\>.*/

syn match RunnerLogUrl /https\?:\/\/\S\+/
syn match RunnerLogUrl /localhost:\d\+\/\S\+/

syn match RunnerLogPath /[a-zA-Z0-9_\-\/]\+\.\(js\|ts\|jsx\|tsx\|vue\|css\|scss\|html\|py\)/
syn match RunnerLogPathFull /\/[a-zA-Z0-9_\-\/\.]\+/

syn match RunnerLogInfo /\[INFO\]/
syn match RunnerLogInfo /\[Browsersync\]/

syn region RunnerDjangoLaunchBlock
	\ start=/\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?>>> \s*运行项目:\s*/
	\ end=/\vhttps?:\/\/\S+:\d+/
	\ keepend

syn match RunnerDjangoCmdPath
	\ /\v^(\[\d{2}:\d{2}:\d{2}\]\s+)?>>> \s*运行项目:\s*\zs\/.*$/
	\ contained
	\ containedin=RunnerDjangoLaunchBlock

syn match RunnerDjangoCmdContinuation
	\ /\v^\s*.*manage\.py\s+runserver\>.*$/
	\ contained

syn match RunnerDjangoCmdContinuation
	\ /^\s*\%(python3\|python\|\/\S\+python3\|\/\S\+python\)\>\s\+.*$/
	\ contained

syn match RunnerDjangoServerUrl
	\ /\vhttps?:\/\/\S+:\d+/
	\ contained
	\ containedin=RunnerDjangoLaunchBlock

" 匹配 python 命令行（不限于启动块）
syn match RunnerPythonCmdLine /^\s*\%(python3\|python\|\/\S\+python3\|\/\S\+python\)\>\s\+.*$/

hi link RunnerLogSeparator Comment
hi link RunnerLogTime Number
hi link RunnerLogPrefix Function
hi link RunnerLogCommand String
hi link RunnerLogOutput Normal
hi link RunnerLogPlainLine Normal
hi link RunnerLogErrorLine ErrorMsg
hi link RunnerLogWarnLine WarningMsg
hi link RunnerLogSuccessLine String
hi link RunnerLogDebugLine Comment
hi link RunnerLogUrl Underlined
hi link RunnerLogPath Directory
hi link RunnerLogPathFull Directory
hi link RunnerLogInfo Question
hi link RunnerLogDjangoRunserver Special
hi link RunnerDjangoServerUrl Underlined
hi link RunnerPythonCmdLine String

let b:current_syntax = "runnerlog"
