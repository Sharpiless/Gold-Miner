.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib StaticLib1.lib
include include\utils.inc
include include\msvcrt.inc

printf PROTO C :ptr dword,:VARARG
testProc PROTO C

calDistance PROTO C :dword, :dword, :dword, :dword  ; ����StaticLib1.lib



.data
szFmt1 byte '��%d��Ԫ�أ�ֵΪ%d', 0ah, 0
szFmt2 byte '��%d��Ԫ�أ�Years=%d', 0ah, 0
szFmt3 byte '��%d��Ԫ�أ�IdNum=%s', 0ah, 0
szFmt4 byte 'eax=%d', 0ah, 0

;����һ���ṹ��
Employee STRUCT
	IdNum BYTE "000000000"; 9���ֽ�
	Lastname BYTE 5 DUP(1) ; 5���ֽ�
	Years WORD 2; 2���ֽ�
	SalaryHistory DWORD 3,3,3,3; 16���ֽ�
Employee ENDS; ��32���ֽ�

worker1 Employee {"123456789"}; �����ṹ��ʵ������Ϊ���Ա����ֵ
workerCount = 10; ������10��Ԫ��

department Employee workerCount DUP({});  �����ṹ�����顣��� psin dd 360 DUP(0)��debugʱ&department��λ�����λ��
array byte 10 DUP(1); ����dd���顣����Ūһ��Ԫ������Ϊbyte�ļ����鿴����


var dword 10

.code  

main proc C
	;invoke testProc; ����initGame
	mov edi,0; ���������ƫ����
	mov eax,8;
	;�ײ���ã�Ϊ�ṹ��������ĳ��ʵ����ֵ����ΪYears��Ա�ĳ�����WORD�����Դ������Ӧ����ax
	mov department[edi].Years, ax
	;�ײ���ã���ӡ�ṹ��ʵ����debugʱ&worker1.Idnum��λ�ó�Ա��λ��
	invoke printf, offset worker1.IdNum;  
	
	;�ײ���ã���ӡ������ĳ��Ԫ��
	;invoke printf, offset szFmt1, edi, array[edi*4]
	;�ײ���ã���ӡ�ṹ��������ĳ��Ԫ�صĳ�Ա
	invoke printf, offset szFmt2, edi, department[edi].Years
	;��ӡ�ַ�����Աʱ���е����⣬û�д�β������־��ͣ������
	;invoke printf, offset szFmt3, edi, department[edi].IdNum

	;���Լ�����Ϊ���������
	mov eax, 5;
	sub eax, -6;
	;.if eax < 0;  ע�⣺�Ƚ�ʱ��eax�����޷����������-1��FFFFFFFF����0�����߼����ʽ������Ԥ�ڹ���
	.if eax != -1; �ж��Ƿ����-1�ǿ��������ġ�-1��FFFFFFFF��
		invoke printf, offset szFmt4, eax
	.else
		invoke printf, offset szFmt4, 100
	.endif
	;end����

	;���ԣ�ȡ��
	mov ebx, 2;
	mov eax, 0;
	sub eax,ebx;
	;end����







main endp

end main
		