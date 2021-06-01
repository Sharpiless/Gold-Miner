.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib
includelib StaticLib1.lib

include include\vars.inc
include include\acllib.inc
include include\msvcrt.inc

Item STRUCT
	exist DWORD ?; 1���ڣ�0�Ѳ����ڣ��÷֣�
	typ DWORD ?; ���
	posX DWORD ?; λ�ú�����
	posY DWORD ?; λ��������
	radius DWORD ?; �뾶
	weight DWORD ?; ����
	value DWORD ?; ��ֵ
Item ENDS; һ��ʵ��ռ4*7=28B
extern Items:Item; vars�ж������������

printf PROTO C :ptr DWORD, :VARARG
calDistance PROTO C :dword, :dword, :dword, :dword  ; ����StaticLib1.lib

.data

hookODir DWORD ?; ���ٶȷ���1���ң�0����

timeElapsed DWORD 0; ��¼����ʱ��

szFmt1 BYTE '�����б��е�%d��Ԫ�أ�exist=%d, typ=%d, posX=%d, posY=%d, radius=%d, weight=%d, value=%d', 0ah, 0
szFmt2 BYTE '%d�ż�ʱ����Ӧ, ʱ��������%d ms', 0ah, 0
szFmt3 BYTE '���е�%d�����壡����=%d, ����뾶=%d', 0ah, 0
szFmt4 BYTE 'δ�������壡', 0ah, 0

.code

; �ƶ�����,����
; @brief: ������λ���ƶ���(50,50)
MoveHookTest proc C
	push eax
	mov eax, 50
	mov hookPosX, eax
	mov eax, 50
	mov hookPosY, eax
	pop eax
	ret
MoveHookTest endp



; �ƶ�����
; @brief����lastHit��Ϊ-1����Ҫ���Ÿ�����һ���ƶ�
MoveHook proc C 
	pushad
	
	cmp hookStat, 0
	jz ChangeDeg
ChangePos: ;�ı乳��λ��
	;TODO
	jmp FinishMoveHook
ChangeDeg: ; �ı乳���Ƕ�
	mov eax, hookOmega
	.if hookODir == 0 ; �����ƶ�

		mov ebx, 360
		mov ecx, hookOmega
		sub ebx, ecx
		.if hookDeg > ebx  ; �������Ҷ˾�ͷ(������)����hookDeg>360-hookOmega,��ת�������ٶ�
			mov ebx, 1
			mov hookODir, ebx
		.else 
			add hookDeg, eax ; �����ƶ�
		.endif

	.else ; �����ƶ�
		mov ebx, 180
		mov ecx, hookOmega
		add ebx, ecx
		.if hookDeg < ebx ; ��������˾�ͷ(������)����hookDeg<180+hookOmega,��ת�������ٶ�
			mov ebx, 0
			mov hookODir, ebx
		.else 
			sub hookDeg, eax ; �����ƶ�
		.endif
		

	.endif


FinishMoveHook:
	popad
	ret
MoveHook endp


; �жϹ����Ƿ��������塣
; @brief������items�����������λ��(posX��posY)���жϹ���λ��������λ�õľ����Ƿ�С������뾶��
; NEXT TODO �ƻ��Է���ֵ�ĸĽ�����������������±ꡣ
IsHit proc C
	pushad
	mov edi, 0; ������ֵ
LoopTraverseItem:
	
	; �������,���������eax��
	invoke calDistance, hookPosX, hookPosY, Items[edi].posX, Items[edi].posY
	cmp eax, Items[edi].radius;�Ƚϴ�С
	jb Hit; ����С�ڰ뾶����ת��Hit
	
	inc edi; ��������++
	cmp edi, itemNum; �������Ƿ����
	jb LoopTraverseItem
	jmp NotHit; δ���У���ת��NotHit

Hit:
	invoke printf, OFFSET szFmt3, edi, eax, Items[edi].radius; ��ӡ������Ϣ��eax���Ǿ��롣
	; дlastHit
	mov eax, edi
	mov lastHit, eax
	; �޸�hookDirΪ1
	mov eax, 1
	mov hookDir, eax
	; hookV = 100-����������������
	mov ebx, 100;
	sub ebx, Items[edi].weight;
	mov hookV, ebx
	; ��������������±�
	mov eax, edi
	jmp Finish
NotHit:
	invoke printf, OFFSET szFmt4; ��ӡδ������Ϣ.
	; �����еĻ���������ֵ������

Finish:
	popad
	ret
IsHit endp

; �жϹ����Ƿ�����ص�������
; ��Ĵ�����eax��ebx
IsOut proc C
	;push eax ����Ӻ���û�з���ֵ�������ݴ�eax
	mov eax, hookPosX
	mov ebx, hookPosY

	.if eax > gameX; �³���
		mov eax, 1
		mov hookDir, eax
	.elseif ebx < 0; �����
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > gameY; �ҳ���
		mov eax, 1
		mov hookDir, eax

	.elseif eax < 0; ���ӻص������С�ע�⹳��δ�ͷ�ʱhookPosX=0����������߼�������Ǻ����

		; �ı�hookStatΪ0
		mov eax, 0
		mov hookStat, eax

		;����Ŀǰ�����Ƿ������壬��Ӧ�ӷֲ�ɾ�������߼�
		;.if  lastHit == -1 (�ж�lastHit�Ƿ�Ϊ-1�� TODO
		;	playerScore += Items[lastHit].value
		;	Items[lastHit].exist = 0

			


	.endif

	;pop eax
	ret
IsOut endp

;@brief:��ʱ���ص�������ÿ�δ�����ʱ��������MoveHook�ƶ�������
timer proc C id:dword
	add timeElapsed, 10; ά�����ŵ�ʱ��
	invoke MoveHook; �ƶ�����
	invoke IsHit;
	invoke IsOut;
	;invoke printf, OFFSET szFmt2, id, timeElapsed; ��ӡ��ʱ���ص�������Ϣ
	ret
timer endp



InitGame proc C

	; �ݴ��Ӻ������õ��ļĴ���eax
	push eax

	; ��ʼ�����ӱ���
InitHook:
	mov eax, 0; ����hookStat����ʼ��Ϊ0
	mov hookStat, eax;
	mov eax, 1; ����hookODir����ʼ��Ϊ1
	mov hookODir, eax;
	mov eax, 0; ����hookDir, ��ʼ��Ϊ0
	mov hookDir, eax;
	mov eax, 2; ���ý��ٶ�
	mov hookOmega, eax; 
	mov eax, 10; �������ٶ�
	mov hookV, eax;

	;���ԣ��������б���ĳ��Ԫ�ظ�ֵ��(�ɹ�)
InitItem:
	mov edi, 0; ����ƫ�ƣ���ʼ��Ϊ0
	mov eax, 1; 
	mov Items[edi].exist, eax; ���õ�һ�������exist��1������exist�ֶ�ռ�ĸ��ֽڣ�����Դ��������eax��
	mov Items[edi].typ, eax; ����typ��1
	mov eax, 40;
	mov Items[edi].posX, eax; ����λ��Ϊ(40,40)
	mov Items[edi].posY, eax;
	mov eax, 15;
	mov Items[edi].radius, eax; ���ð뾶Ϊ15
	mov eax, 10;
	mov Items[edi].weight, eax; ��������Ϊ10
	mov Items[edi].value, eax; ���ü�ֵΪ10
	invoke	printf, OFFSET szFmt1, edi, Items[edi].exist, Items[edi].typ, Items[edi].posX, Items[edi].posY, Items[edi].radius, Items[edi].weight, Items[edi].value; ��ӡ�鿴��ֵ�Ƿ�ɹ���
	;end����


	;���ԣ�ע�Ტ������ʱ������δ�ɹ������ڶ�ʱ����work��
	invoke registerTimerEvent, offset timer  ;ע�ᶨʱ���ص�����timer
	invoke startTimer, 0, 10  ; ��ʱ�����Ϊ0��ˢ�¼��Ϊ10ms
	;end����

	;���ԣ��ֶ�����MoveHookTest�ƶ������ɹ���
	invoke MoveHookTest
	;end����

	;���ԣ��ֶ�����isHit��isOut
	invoke IsHit
	invoke IsOut
	;end����


	;���ԣ�������һ����ѭ���У�ֱ��ʱ������1s��
LoopTest:
	mov eax, timeElapsed
	cmp eax, 1000
	jb LoopTest;
	;end����

	pop eax
	ret
InitGame endp


end

