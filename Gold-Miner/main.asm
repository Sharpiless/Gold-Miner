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
		
	invoke InitGame; ����initGame
	invoke cancelTimer, 0 ; �رն�ʱ��
	ret

main endp




end main
		