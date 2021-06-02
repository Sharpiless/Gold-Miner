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
calDistance PROTO C :dword, :dword, :dword, :dword  ; ����StaticLib1.lib��������������
calPSin PROTO C :dword, :dword ; ����StaticLib1.lib������PSin��
calPCos PROTO C :dword, :dword ; ����StaticLib1.lib������PCos��

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




; @brief: �ƶ�������
; @read: hookStat��hookODir��hookOmega��hookDir��hookV
; @write: hookDeg��hookPosX��hookPosY����hookStatΪ0��дhookDeg����֮дhookPosX��hookPosY��
MoveHook proc C 
	pushad
	
	cmp hookStat, 0; ��hookStat
	jz ChangeDeg
ChangePos: ;�ı乳��λ��
	;TODO ��lastHit��Ϊ-1����Ҫ���Ÿ�����һ���ƶ�

	jmp FinishMoveHook
ChangeDeg: ; �ı乳���Ƕ�
	mov eax, hookOmega; ��hookOmega
	.if hookODir == 0; ��hookODir������ת

		mov ebx, 360
		mov ecx, hookOmega
		sub ebx, ecx
		.if hookDeg > ebx ; �������Ҷ˾�ͷ(������)����hookDeg>360-hookOmega,���ƶ�������ת�������ٶ�
			mov ebx, 1
			mov hookODir, ebx
		.else 
			add hookDeg, eax ; дhookDeg�������ƶ�
		.endif

	.else ; ����ת
		mov ebx, 180
		mov ecx, hookOmega
		add ebx, ecx
		.if hookDeg < ebx ; ��������˾�ͷ(������)����hookDeg<180+hookOmega,���ƶ�������ת�������ٶ�
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



; @brief: �жϹ����Ƿ��������塣����items�����������λ��(posX��posY)���жϹ���λ��������λ�õľ����Ƿ�С������뾶��
; @read: hookPosX��hookPosY��Items
; @write: lastHit��hookDir��hookV�������У�дlastHitΪ����������±꣬дhookDirΪ1��дhookVΪf(Items[lastHit].weight)��
IsHit proc C
	pushad
	mov edi, 0; ������ֵ
LoopTraverseItem:
	
	; ��hookPosX��hookPosY��Items��������õ��ľ������eax��
	invoke calDistance, hookPosX, hookPosY, Items[edi].posX, Items[edi].posY
	cmp eax, Items[edi].radius;�Ƚϴ�С
	jb Hit; ����С�ڰ뾶����ת��Hit
	
	inc edi; ��������++
	cmp edi, itemNum; �������Ƿ����
	jb LoopTraverseItem
	jmp NotHit; δ���У���ת��NotHit

Hit:
	invoke printf, OFFSET szFmt3, edi, eax, Items[edi].radius; ��ӡ������Ϣ��eax�Ǿ���
	; дlastHitΪ����������±�
	mov eax, edi
	mov lastHit, eax
	; дhookDirΪ1
	mov eax, 1
	mov hookDir, eax
	; hookV = 100-����������f������ʽ������
	mov ebx, 100;
	sub ebx, Items[edi].weight;
	mov hookV, ebx
	jmp Finish
NotHit:
	invoke printf, OFFSET szFmt4; ��ӡδ������Ϣ

Finish:
	popad
	ret
IsHit endp

; @brief: �жϹ����Ƿ�����ص������С�
; @read: hookPosX��hookPosY��lastHit
; @write: hootDir��hookStat��Items��playerScore�������磬дhookDirΪ1��
; ���ص������У�дhookStatΪ0��дItems[lastHit].existΪ0��дplayerScore+=Items[lastHit].value
IsOut proc C
	pushad
	mov eax, hookPosX; ��hookPosX
	mov ebx, hookPosY; ��hookPosY

	.if eax > gameX; �³���,дhookDirΪ1
		mov eax, 1
		mov hookDir, eax
	.elseif ebx < 0; �����
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > gameY; �ҳ���
		mov eax, 1
		mov hookDir, eax

	.elseif eax < 0; ���ӻص������С�ע�⹳��δ�ͷ�ʱhookPosX=0����������߼���
		; дhookStatΪ0
		mov eax, 0
		mov hookStat, eax
		.if lastHit != -1 ; ��lastHit������Ϊ-1���ӷֲ�ɾ������
			; �ӷ֣�дplayerScore+=Items[lastHit].value
			mov edi, lastHit
			mov eax, Items[edi].value
			add playerScore, eax;
			; ɾ�����壬дItems[lastHit].existΪ0
			mov eax, 0
			mov Items[edi].exist, eax 
		.endif
		

	.endif

	popad
	ret
IsOut endp

;@brief:��ʱ���ص�������ÿ�δ�����ʱ��������MoveHook�ƶ�������������IsHit��IsOut
;@param:��ʱ��id
timer proc C id:dword
	add timeElapsed, 10; ά�����ŵ�ʱ��
	invoke MoveHook; �ƶ�����
	invoke IsHit;
	invoke IsOut;
	;TODO invoke��ͼ����
	;invoke printf, OFFSET szFmt2, id, timeElapsed; ��ӡ��ʱ���ص�������Ϣ
	ret
timer endp


;@brief:��ʼ����Ϸ��Ϊһ����Ϸ���õ���ȫ�ֱ�������ֵ��ע�Ტ������ʱ����
InitGame proc C
	pushad

	; ��ʼ������
IniGameSize:
	mov eax, 420
	mov gameX, eax; ����߶�420
	mov eax, 700
	mov gameY, eax; ������700

	; ��ʼ�����ӱ���
IniHook:
	; A
	mov eax, 0; 
	mov hookStat, eax; ����hookStat����ʼ��Ϊ0
	mov eax, 1; 
	mov hookODir, eax; ����hookODir����ʼ��Ϊ1
	mov eax, 0; 
	mov hookDir, eax; ����hookDir, ��ʼ��Ϊ0
	mov eax, 2; 
	mov hookOmega, eax; ���ý��ٶ�Ϊ2
	mov eax, 10; 
	mov hookV, eax; �������ٶȣ�Ĭ��Ϊ10��

	; B
	mov eax, 180; 
	mov hookDeg, eax; ����hookDeg����ʼ��Ϊ180
	mov eax, 0; 
	mov hookPosX, eax; ����hookPosX����ʼ��Ϊ0������λ��x���꣩
	mov edx, 0
	mov eax, gameY; ������edx:eax
	mov ebx, 2; ����
	div ebx; �������̱�����eax��
	mov hookPosY, eax; ����hookPosY����ʼ��ΪgameY/2������λ�������꣩


	;���ԣ��������б���ĳ��Ԫ�ظ�ֵ��ʵ�����滻Ϊ�����ʼ�������б�(�ɹ�)
IniItem:
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

	;���ԣ�calPSin��calPCos�Ƿ������������ɹ���
	invoke calPSin, 0, 10; ��һ�������ǽǶȣ��Ƕ��ƣ����ڶ��������Ǽ���
	invoke calPSin, 30, 10
	invoke calPSin, 45, 10
	invoke calPSin, 60, 10
	invoke calPSin, 90, 10
	invoke calPSin, 180, 10
	invoke calPSin, 360, 10
	invoke calPCos, 0, 10
	invoke calPCos, 90, 10
	invoke calPCos, 180, 10
	invoke calPCos, 360, 10
	;end����

	;���ԣ��ֶ�����MoveHookTest�ƶ������ɹ���
	invoke MoveHookTest
	;end����

	;���ԣ��ֶ�����isHit��isOut
	invoke IsHit
	invoke IsOut
	;end����

	;���ԣ�ע�Ტ������ʱ������δ�ɹ������ڶ�ʱ����work��
	invoke registerTimerEvent, offset timer  ;ע�ᶨʱ���ص�����timer
	invoke startTimer, 0, 10  ; ��ʱ�����Ϊ0��ˢ�¼��Ϊ10ms
	;end����

	;���ԣ����Զ�ʱ���Ƿ�work��������һ����ѭ���У�ֱ��ʱ������1s��
LoopTest:
	mov eax, timeElapsed
	cmp eax, 1000
	jb LoopTest;
	;end����

	popad
	ret
InitGame endp


end

