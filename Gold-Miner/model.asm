.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib
includelib StaticLib1.lib

include include\vars.inc
include include\acllib.inc
include include\msvcrt.inc
include include\view.inc

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
timeElapsed DWORD ?; ��¼����ʱ��

szFmt1 BYTE '�����б��е�%d��Ԫ�أ�exist=%d, typ=%d, posX=%d, posY=%d, radius=%d, weight=%d, value=%d', 0ah, 0
szFmt2 BYTE '%d�ż�ʱ����Ӧ, ʱ��������%d ms', 0ah, 0
szFmt3 BYTE '���е�%d�����壡����=%d, ����뾶=%d', 0ah, 0
szFmt4 BYTE 'δ�������壡', 0ah, 0
szFmt5 BYTE '�ϵ�...', 0ah, 0
szFmt6 BYTE 'eax=%d', 0ah, 0
szFmt7 BYTE 'In timer, hoosStat=%d, hookODir=%d, hookDeg=%d, hookPosX=%d, hookPosY=%d', 0ah, 0

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
	
	;Step1.hookV����ebx
	.if hookDir == 1; ��hookDirΪ1���Ԧѣ���������hookV��ȡ��
		mov ebx, 0
		mov ecx, hookV
		sub ebx, ecx
	.else
		mov ebx, hookV
	.endif

	;Step2.PSin����eax,��дhookPosX
	invoke calPSin, hookDeg, ebx; ��x = -��sin��
	sub hookPosX, eax
	.if lastHit != -1; ��lastHit��Ϊ-1����Ҫ���Ÿ�����һ���ƶ�
		mov edi, lastHit
		sub Items[edi].posX, eax
	.endif

	;Step3.PCos����eax����дhookPosY
	invoke calPCos, hookDeg, ebx; ��y = ��cos��
	add hookPosY, eax
	.if lastHit != -1
		mov edi, lastHit
		sub Items[edi].posY, eax
	.endif
	
	jmp FinishMoveHook
ChangeDeg: ; �ı乳���Ƕ�
	mov eax, hookOmega; ��hookOmega
	.if hookODir == 0; ��hookODir������ת

		mov ebx, 360
		mov ecx, hookOmega
		sub ebx, ecx
		.if hookDeg >= ebx ; �������Ҷ˾�ͷ(������)����hookDeg>360-hookOmega,���ƶ�������ת�������ٶ�
			mov ebx, 1
			mov hookODir, ebx
		.else 
			add hookDeg, eax ; дhookDeg�������ƶ�
		.endif

	.else ; ����ת
		mov ebx, 180
		mov ecx, hookOmega
		add ebx, ecx
		.if hookDeg <= ebx ; ��������˾�ͷ(������)����hookDeg<180+hookOmega,���ƶ�������ת�������ٶ�
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
	mov edi, 0; ��ʼ����������
LoopTraverseItem:
	
	; ��hookPosX��hookPosY��Items��������õ��ľ������eax��
	.if Items[edi].exist == 1
		invoke calDistance, hookPosX, hookPosY, Items[edi].posX, Items[edi].posY
		cmp eax, Items[edi].radius;�Ƚϴ�С
		jb Hit; ����С�ڰ뾶����ת��Hit���൱��break
	.endif

	inc edi; ��������++
	cmp edi, itemNum; ���ѭ���Ƿ����
	jb LoopTraverseItem; ѭ��δ������������һ��ѭ��
	jmp NotHit; ѭ��������δ���У���ת��NotHit

Hit:
	invoke printf, OFFSET szFmt3, edi, eax, Items[edi].radius; ��ӡ������Ϣ��eax�Ǿ���
	; дlastHitΪ����������±�
	mov eax, edi
	mov lastHit, eax
	; дhookDirΪ1
	mov eax, 1
	mov hookDir, eax
	; дhookV = 100-����������f������ʽ������
	;mov ebx, 100;
	;sub ebx, Items[edi].weight;
	mov ebx,10; �������к��ٶ�Ϊ10 TODO �ٶ���Ϊ1���񲻶���
	mov hookV, ebx
	jmp Finish
NotHit:
	;invoke printf, OFFSET szFmt4; ��ӡδ������Ϣ

Finish:
	popad
	ret
IsHit endp

; @brief: �жϹ����Ƿ�����ص������С�
; @read: hookPosX��hookPosY��lastHit
; @write: hootDir��hookStat��hookPosX,hookPosY��Items��playerScore�������磬дhookDirΪ1��
; ���ص������У�дhookStatΪ0��дhookPosX��hookPosYΪ��λ�ã�дItems[lastHit].existΪ0��дplayerScore+=Items[lastHit].value
IsOut proc C
	pushad
	mov eax, hookPosX; ��hookPosX
	mov ebx, hookPosY; ��hookPosY
	
	;����:��ӡhookPosX
	;push eax
	;invoke printf, OFFSET szFmt6, eax
	;pop eax
	;end����

	.if eax > 80000001H; ���ӻص������С�ע�⹳��δ�ͷ�ʱhookPosX=0����������߼��� <0������
		invoke printf, OFFSET szFmt5; ���Զϵ�
		
		; дhookStatΪ0
		mov eax, 0
		mov hookStat, eax
		; дhookPosX��hookPosYΪ��λ��
		mov eax, minerPosX
		mov hookPosX, eax
		mov eax, minerPosY
		mov hookPosY, eax
		
		.if lastHit != -1 ; ��lastHit������Ϊ-1���ӷֲ�ɾ������
			; �ӷ֣�дplayerScore+=Items[lastHit].value
			mov edi, lastHit
			mov eax, Items[edi].value
			add playerScore, eax;
			; ɾ�����壬дItems[lastHit].existΪ0
			mov eax, 0
			mov Items[edi].exist, eax 
		.endif

	.elseif eax > gameX; �³���,дhookDirΪ1
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > 80000000H; ����� <0������
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > gameY; �ҳ���
		mov eax, 1
		mov hookDir, eax
	.endif

	popad
	ret
IsOut endp

;@brief:��ʱ���ص�������ÿ�δ�����ʱ��������MoveHook�ƶ�������������IsHit��IsOut
;@param:��ʱ��id
timer proc C id:dword
	add timeElapsed, 20; ά�����ŵ�ʱ�䣬��λms
	;invoke printf, OFFSET szFmt2, id , timeElapsed
	invoke MoveHook; �ƶ�����
	invoke IsHit;
	invoke IsOut;

	;invoke printf, OFFSET szFmt7, hookStat, hookODir, hookDeg, hookPosX, hookPosY
	invoke Flush; ��ͼ��������
	
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

	; ��ʼ��ʱ��
IniTime:
	mov eax, 30
	mov restTime, eax; ʣ��ʱ��30s

	; ��ʼ���÷�
IniScore:
	mov eax, 50
	mov goalScore, eax; Ŀ��÷�
	mov eax, 0
	mov playerScore, eax; ��ǰ�÷�


	; ��ʼ����
IniMiner:
	mov eax, 0; 
	mov minerPosX, eax; ����minerPosX����ʼ��Ϊ0
	mov eax, gameY; ������edx:eax
	mov ebx, 2; ����
	div ebx; �������̱�����eax��
	mov minerPosY, eax; ����minerPosY����ʼ��ΪgameY/2

	; ��ʼ�����ӱ���
IniHook:
	; A
	mov eax, 0;
	mov hookStat, eax; ����hookStat
	mov eax, 0; 
	mov hookODir, eax; ����hookODir����ʼ��Ϊ0
	mov eax, 0; 
	mov hookDir, eax; ����hookDir, ��ʼ��Ϊ0
	mov eax, 5; 
	mov hookOmega, eax; ���ý��ٶ�Ϊ2
	mov eax, 10; 
	mov hookV, eax; �������ٶȣ�Ĭ��Ϊ10��

	; B
	mov eax, 270; 
	mov hookDeg, eax; ����hookDeg
	mov eax, minerPosX;
	mov hookPosX, eax; ����hookPosX������λ��x���꣩
	mov edx, 0
	mov eax, minerPosY;
	mov hookPosY, eax; ����hookPosY������λ��y���꣩


	;���ԣ��������б���ĳ��Ԫ�ظ�ֵ��ʵ�����滻Ϊ�����ʼ�������б�(�ɹ�)
IniItem:
	mov edi, 0; ����ƫ�ƣ���ʼ��Ϊ0
	mov eax, 1; 
	mov Items[edi].exist, eax; ���õ�һ�������exist��1������exist�ֶ�ռ�ĸ��ֽڣ�����Դ��������eax��
	mov eax, 0; 
	mov Items[edi].typ, eax; ����typ
	mov eax, 350;
	mov Items[edi].posX, eax; ����λ��
	mov Items[edi].posY, eax;
	mov eax, 30;
	mov Items[edi].radius, eax; ���ð뾶Ϊ15
	mov eax, 10;
	mov Items[edi].weight, eax; ��������Ϊ10
	mov Items[edi].value, eax; ���ü�ֵΪ10
	invoke	printf, OFFSET szFmt1, edi, Items[edi].exist, Items[edi].typ, Items[edi].posX, Items[edi].posY, Items[edi].radius, Items[edi].weight, Items[edi].value; ��ӡ�鿴��ֵ�Ƿ�ɹ���
	;end����

	; ���ԣ������ʼ�������б�
	; ��ʱ����Ϊ���������
	push 0
	call crt_time
	add esp, 4
	push eax
	call crt_srand
	add esp, 4

	mov ecx, itemNum; (ecx)��ѭ������
	mov edi, 0; ����ƫ�Ƴ�ֵ
	RandLoop:
		mov eax, 1
		mov Item[edi].exist, eax

		invoke crt_rand; �����������������eax��
		mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
		mov ebx, 10;
		div ebx; ����0~9����edx��

		.if edx < 3; 0.3����Ϊʯͷ
			mov eax, 0
			mov Item[edi].type, eax
		.else
			.if edx < 8; 0.5����Ϊ���
				mov eax, 1
				mov Item[edi].type, eax
			.else
				mov eax, 2; 0.2����Ϊ��ʯ
				mov Item[edi].type, eax
			.endif
		.endif

		invoke crt_rand
		mov edx, 0
		mov ebx, 420; PosX������
		div ebx; ���������edx��
		mov Item[edi].posX, edx

		invoke crt_rand
		mov edx, 0
		mov ebx, 700; posY������
		div ebx; ���������edx��
		mov Item[edi].posY, edx

		; ��������İ뾶����������ֵ����Ҫ���ж��������
		mov ebx, Item[edi].type
		.if ebx == 2; ��ʯ
			mov eax, 10
			mov Item[edi].radius, eax
			mov eax, 120; ÿ���˶�120����
			mov Item[edi].weight, eax
			mov eax, 600
			mov Item[edi].value, eax
		.endif

		mov ebx, Item[edi].type
		.if ebx == 1; ���
			invoke crt_rand; ������ߴ磬�趨Ϊ2:1:1
			mov edx, 0
			mov ebx, 4
			div ebx

			.if edx < 2; ��С�ߴ�Ľ��
				mov eax, 10
				mov Item[edi].radius, eax
				mov eax, 120
				mov Item[edi].weight, eax
				mov eax, 50
				mov Item[edi].value, eax
			.else
				.if edx < 3
					mov eax, 18
					mov Item[edi].radius, eax
					mov eax, 80
					mov Item[edi].weight, eax
					mov eax, 100
					mov Item[edi].value, eax
				.else
					mov eax, 40
					mov Item[edi].radius, eax
					mov eax, 30
					mov Item[edi].weight, eax
					mov eax, 500
					mov Item[edi].value, eax
				.endif
			.endif
		.endif

		mov ebx, Item[edi].type
		.if ebx == 0; ʯͷ
			invoke crt_rand; ���ʯͷ�ߴ磬�趨Ϊ1:1
			mov edx, 0
			mov ebx, 2
			div ebx
			.if edx < 1; ��С�ߴ��ʯͷ
				mov eax, 18
				mov Item[edi].radius, eax
				mov eax, 80
				mov Item[edi].weight, eax
				mov eax, 10
				mov Item[edi].value, eax
			.else
				mov eax, 25
				mov Item[edi].radius, eax
				mov eax, 40
				mov Item[edi].weight, eax
				mov eax, 20
				mov Item[edi].value, eax
			.endif
		.endif

		inc edi; ���������±�
		loop RandLoop
	;end����

	;���ԣ�calPSin��calPCos�Ƿ������������ɹ���
	invoke calPSin, 0, 10; ��һ�������ǽǶȣ��Ƕ��ƣ����ڶ��������Ǽ���
	invoke calPSin, 30, 10
	invoke calPSin, 45, 10
	invoke calPSin, 60, 10
	;end����

	;���ԣ��ֶ�����MoveHook�ƶ���
	;invoke MoveHook
	;end����

	;���ԣ��ֶ�����isHit��isOut
	;invoke IsHit
	;invoke IsOut
	;end����

	;���ԣ�ע�Ტ������ʱ�������ɹ�����������main�е�init_secondʱ����ʱ��������
	invoke registerTimerEvent, offset timer  ;ע�ᶨʱ���ص�����timer
	invoke startTimer, 0, 10  ; ��ʱ�����Ϊ0��ˢ�¼��Ϊ10ms
	;end����


	;���ԣ�������һ����ѭ���У�ֱ��ʱ������1s�������ɹ���
;LoopTest:
	;mov eax, timeElapsed
	;cmp eax, 1000
	;jb LoopTest;
	;end����

	popad
	ret
InitGame endp


end

