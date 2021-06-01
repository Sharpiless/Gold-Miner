.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib

include include\test.inc
include include\vars.inc
;include include\windows.inc
include include\model.inc
include include\acllib.inc
printf PROTO C :ptr sbyte, :VARARG


.data


.code  


main proc; 
		
	invoke InitGame; 调用initGame
	invoke cancelTimer, 0 ; 关闭定时器
	ret

main endp




end main
		