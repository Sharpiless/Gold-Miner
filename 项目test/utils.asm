.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib

printf PROTO C :ptr dword,:VARARG

.data
Msg byte 'hello world!', 0ah, 0



.code  

testProc proc C
	invoke	printf, offset Msg
	ret
testProc endp

end

