.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib

printf PROTO C :ptr sbyte, :VARARG


.data  
notSameMsg sbyte 'not the same!', 0ah, 0
sameMsg sbyte 'the same!', 0ah, 0

.code

;TODO 下面这个函数为什么会死循环，无限重复调用？
testCMP proc C  ; 示例程序：使用CMP比较两个寄存器是否相同

	MOV EAX,1234H;
	MOV EBX,123H;
	CMP EAX,EBX;
	JE LABEL2; 若相同，则跳转至LABEL2

LABEL1:
	invoke	printf, offset notSameMsg  ; offset表示变量地址
	JMP FINISH
LABEL2:
	invoke	printf, offset sameMsg ;
FINISH:
testCMP endp

end

