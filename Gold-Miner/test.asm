.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib

printf PROTO C :ptr sbyte, :VARARG


.data  
notSameMsg sbyte 'not the same!', 0ah, 0
sameMsg sbyte 'the same!', 0ah, 0

.code

;TODO �����������Ϊʲô����ѭ���������ظ����ã�
testCMP proc C  ; ʾ������ʹ��CMP�Ƚ������Ĵ����Ƿ���ͬ

	MOV EAX,1234H;
	MOV EBX,123H;
	CMP EAX,EBX;
	JE LABEL2; ����ͬ������ת��LABEL2

LABEL1:
	invoke	printf, offset notSameMsg  ; offset��ʾ������ַ
	JMP FINISH
LABEL2:
	invoke	printf, offset sameMsg ;
FINISH:
testCMP endp

end

