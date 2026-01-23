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

syn match RunnerLogErrorLine /\c.*\<Error\>.*/ contained
syn match RunnerLogErrorLine /\c.*\<Exception\>.*/ contained
syn match RunnerLogErrorLine /\c.*\<Traceback\>.*/ contained
syn match RunnerLogErrorLine /\c.*\<Failed\>.*/ contained
syn match RunnerLogErrorLine /\c.*\<fatal\>.*/ contained
syn match RunnerLogErrorLine /\c.*\<critical\>.*/ contained
syn match RunnerLogErrorLine /.*状态码: [1-9].*/ contained
syn match RunnerLogErrorLine /.*进程异常退出.*/ contained
syn match RunnerLogErrorLine /^\s*File .*, line \d\+.*/ contained

syn match RunnerLogWarnLine /\c.*\<Warning\>.*/ contained
syn match RunnerLogWarnLine /\c.*\<warn\>.*/ contained
syn match RunnerLogWarnLine /.*WARN.*/ contained

syn match RunnerLogSuccessLine /\c.*\<Success\>.*/ contained
syn match RunnerLogSuccessLine /\c.*\<Completed\>.*/ contained
syn match RunnerLogSuccessLine /\c.*\<ok\>.*/ contained
syn match RunnerLogSuccessLine /\c.*\<done\>.*/ contained
syn match RunnerLogSuccessLine /\c.*\<finished\>.*/ contained

" 新增 Debug 级别
syn match RunnerLogDebugLine /\c.*\<debug\>.*/ contained
syn match RunnerLogDebugLine /\c.*\<trace\>.*/ contained

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

let b:current_syntax = "runnerlog"
