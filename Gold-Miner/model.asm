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
	exist DWORD ?; 1���ڣ�0�Ѳ�����
	typ DWORD ?; ���
	posX DWORD ?; λ�ú�����
	posY DWORD ?; λ��������
	radius DWORD ?; �뾶
	weight DWORD ?; ����
	value DWORD ?; ��ֵ
Item ENDS; һ��ʵ��ռ4*7=28B
extern Items:Item; vars�ж������������

extern tool5:dword; TODO extern���������������
extern tool6:dword

printf PROTO C :ptr DWORD, :VARARG
calDistance PROTO C :dword, :dword, :dword, :dword  ; ����StaticLib1.lib��������������
calPSin PROTO C :dword, :dword ; ����StaticLib1.lib������PSin��
calPCos PROTO C :dword, :dword ; ����StaticLib1.lib������PCos��

.data
modelMusicgold byte "..\resource\music\gold.mp3", 0
modelMusicstone byte "..\resource\music\stone.mp3", 0
modelMusicbaganddiamond byte "..\resource\music\baganddiamond.mp3", 0
modelMusicback byte "..\resource\music\back.mp3", 0
modelMusicstartstore byte "..\resource\music\startstore.mp3", 0

modelMusicgoldP dd 0
modelMusicstoneP dd 0
modelMusicbaganddiamondP dd 0
modelMusicbackP dd 0
modelMusicstartstoreP dd 0


hookODir DWORD ?; ���ٶȷ���1���ң�0����
timeElapsed DWORD ?; ��¼����ʱ�䣨��λms��

szFmt1 BYTE '�����б��е�%d��Ԫ�أ�exist=%d, typ=%d, posX=%d, posY=%d, radius=%d, weight=%d, value=%d', 0ah, 0
szFmt2 BYTE '%d�ż�ʱ����Ӧ, ʱ��������%d ms', 0ah, 0
szFmt3 BYTE '���е�%d�����壡����=%d, ����뾶=%d', 0ah, 0
szFmt4 BYTE 'δ�������壡', 0ah, 0
szFmt5 BYTE '�ϵ�...', 0ah, 0
szFmt6 BYTE '���۲�Ĵ�����ֵ=%d', 0ah, 0
szFmt7 BYTE 'In timer, hoosStat=%d, hookODir=%d, hookDir=%d, hookDeg=%d, hookV=%d, hookPosX=%d, hookPosY=%d', 0ah, 0
szFmt8 BYTE '�����ʼ����%d������...posX=%d, posY=%d, radius=%d, typ=%d', 0ah, 0


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
	.if hookDir == 1; ��hookDirΪ1�������ƶ����Ԧѣ���������hookV��ȡ��
		mov ebx, 0
		mov ecx, hookV
		sub ebx, ecx
	.else; �����ƶ�
		mov ebx, hookV
		inc count; �����ƶ�ʱ��count++
	.endif

	;Step2.PSin����eax,��дhookPosX
	invoke calPSin, hookDeg, ebx; ��x = -��sin��
	;�����㾫�Ȳ������¦�x������Ϊ0ʱ����Ҫ��֤��x��Ϊ�㡣���ݲ�ͬ�������x��Ϊ1��-1
	.if eax == 0
		.if hookDir == 0;���������ƶ�
			mov eax, -1
		.else ;���������ƶ�
			mov eax, 1
		.endif
	.endif

	sub hookPosX, eax
	.if lastHit != -1; ��lastHit��Ϊ-1����Ҫ���Ÿ�����һ���ƶ���������λ������Ϊ�빳��λ����ͬ��
		mov edi, lastHit
		mov eax, hookPosX
		mov Items[edi].posX, eax
	.endif

	;Step3.PCos����eax����дhookPosY
	invoke calPCos, hookDeg, ebx; ��y = ��cos��
	add hookPosY, eax
	.if lastHit != -1
		mov edi, lastHit
		mov eax, hookPosY
		mov Items[edi].posY, eax
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
		mov ebx, Items[edi].radius
		.if ( tool5 == 0 && Items[edi].typ == 1);ӵ�д���,���Ӱ뾶+30
			add ebx, 50
		.endif
		cmp eax, ebx; �Ƚϴ�С
		jb Hit; ����С�ڰ뾶����ת��Hit���൱��break
	.endif

	add edi, 28; ���������±ꡣע�����ڼӵ���28��һ���ṹ��Ԫ�صĴ�С
	mov eax, itemNum
	mov ebx, 28;
	mul ebx;
	cmp edi, eax; ���ѭ���Ƿ����,����������edi==itemNum*28
	jne LoopTraverseItem; ѭ��δ������������һ��ѭ��
	jmp NotHit; ѭ��������δ���У���ת��NotHit

Hit:
	;invoke printf, OFFSET szFmt3, edi, eax, Items[edi].radius; ��ӡ������Ϣ��eax�Ǿ���
	; дlastHitΪ����������±�
	mov eax, edi
	mov lastHit, eax
	; дhookDirΪ1
	mov eax, 1
	mov hookDir, eax
	; дhookV = ��������
	mov eax, Items[edi].weight;
	mov hookV, eax
	.if tool3 == 0 ; ��ӵ����ˮ���ٶ�*2
		mov eax, Items[edi].weight;
		add hookV, eax
	.endif

	.if Items[edi].typ == 0
		invoke loadSound,addr modelMusicstone,addr modelMusicstoneP
		invoke playSound,modelMusicstoneP,0
	.elseif Items[edi].typ == 1
		invoke loadSound,addr modelMusicgold,addr modelMusicgoldP
		invoke playSound,modelMusicgoldP,0
	.else
		invoke loadSound,addr modelMusicbaganddiamond,addr modelMusicbaganddiamondP
		invoke playSound,modelMusicbaganddiamondP,0
	.endif
	
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

	.if eax > 80000001H; ����eax�Ǹ��������ӻص������С�ע�⹳��δ�ͷ�ʱhookPosX=0����������߼���
		;invoke printf, OFFSET szFmt5; ���Զϵ�
		
		; дhookStatΪ0
		mov eax, 0
		mov hookStat, eax
		; дhookPosX��hookPosYΪ��λ��
		mov eax, minerPosX
		mov hookPosX, eax
		mov eax, minerPosY
		mov hookPosY, eax
		
		.if lastHit != -1 ; ��lastHit������Ϊ-1���ӷֲ�ɾ������
			mov edi, lastHit
			; �ӷ֣�дplayerScore+=Items[lastHit].value
			mov eax, Items[edi].value
			add playerScore, eax;
			; ɾ�����壬дItems[lastHit].existΪ0
			mov eax, 0
			mov Items[edi].exist, eax 
			invoke loadSound,addr modelMusicback,addr modelMusicbackP
			invoke playSound,modelMusicbackP,0
		.endif

	.elseif eax > gameX; �³���,дhookDirΪ1
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > 80000000H; ����ebx�Ǹ���������磬дhookDirΪ1
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > gameY; �ҳ��磬дhookDirΪ1
		mov eax, 1
		mov hookDir, eax
	.endif

	popad
	ret
IsOut endp


; @brief: ʱ����������ݷ����Ƿ񵽴�Ŀ������л�����ǿ���л����̵����
IsTimeOut proc C
	; timeElapsed��1000ȡ�࣬������Ϊ0��restTime--
	mov edx, 0
	mov eax, timeElapsed
	mov ebx, 1000
	div ebx ; ������edx��
	.if edx == 0
		dec restTime;  ʱ�����1s
	.endif

	.if restTime == 0; ʱ�������ǿ���л�����
		invoke cancelTimer, 0  ; ȡ����ʱ��
		;����tool��
		mov tool1, 1
		mov tool2, 1
		mov tool3, 1
		mov tool4, 1
		mov tool5, 1
		mov tool6, 1

		mov eax, goalScore
		.if playerScore >= eax; ����
			mov eax, 2
			mov curWindow, eax; �л����̵����	
			invoke Flush; �����̵����
			invoke loadSound,addr modelMusicstartstore,addr modelMusicstartstoreP
			invoke playSound,modelMusicstartstoreP,0
		.else ; δ���ء�������Ҫʵ����main����ȫ��ͬ��ȫ����Ϸ��ʼ��.
			;���õ�ǰ����Ϊ1
			mov eax, 0
			mov curWindow, eax
			;���õ÷�
			mov eax, 0
			mov playerScore, eax; 
			;����Ŀ��÷�
			mov eax, 0
			mov goalScore, eax
			;���ñ�������
			mov eax, 0
			mov fireNum, eax
			invoke Flush; ���ƻ�ӭ����
		.endif
	.endif
	ret
IsTimeOut endp

;@brief:��ʱ���ص�������ÿ�δ�����ʱ��������MoveHook�ƶ�������������IsHit��IsOut
;@param:��ʱ��id
timer proc C id:dword
	add timeElapsed, 100; ά�����ŵ�ʱ�䣬��λms
	;invoke printf, OFFSET szFmt2, id , timeElapsed
	invoke MoveHook; �ƶ�����
	.if hookDir == 0; ���������ƶ�ʱ����IsHit
		invoke IsHit;
	.endif
	invoke IsOut;
	;invoke printf, OFFSET szFmt7, hookStat, hookODir, hookDir, hookDeg, hookV, hookPosX, hookPosY
	invoke Flush; ��ͼ��������
	invoke IsTimeOut
	;invoke printf, OFFSET szFmt2, id, timeElapsed; ��ӡ��ʱ���ص�������Ϣ
	ret
timer endp






;@brief:��ʼ��һ����Ϸ��Ϊһ����Ϸ���õ���ȫ�ֱ�������ֵ��ע�Ტ������ʱ����
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
	mov eax, 1;
	mov restTime, eax; ʣ��ʱ��30s
	mov eax, 0
	mov timeElapsed, 0;  ����ʱ��

	; ��ʼ���÷�
IniScore:
	add goalScore, 5; Ŀ��÷�����һ�صĻ���������400


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
	mov eax, 35; 
	mov hookV, eax; �������ٶȣ�Ĭ��Ϊ35��

	; B
	mov eax, 270;
	mov hookDeg, eax; ����hookDeg
	mov eax, minerPosX;
	mov hookPosX, eax; ����hookPosX������λ��x���꣩
	mov edx, 0
	mov eax, minerPosY;
	mov hookPosY, eax; ����hookPosY������λ��y���꣩



	; �����ʼ�������б�
	; ��ʱ����Ϊ���������
	push 0
	call crt_time
	add esp, 4
	push eax
	call crt_srand
	add esp, 4

	mov edi, 0; ����ƫ�Ƴ�ֵ
RandLoop:


	; ����exist����1
	mov eax, 1
	mov Items[edi].exist, eax

	invoke crt_rand; �����������������eax��
	mov edx, 0; ����ʹ��˫���ͳ���(EDX:EAX)/(SRC)_32
	mov ebx, 10;
	div ebx; ����0~9����edx��

	; �����������
	.if edx < 3; 0.3����Ϊʯͷ
		mov eax, 0
		mov Items[edi].typ, eax
	.else
		.if edx < 8; 0.5����Ϊ���
			mov eax, 1
			mov Items[edi].typ, eax
		.elseif edx < 9
			mov eax, 2; 0.1����Ϊ��ʯ
			mov Items[edi].typ, eax
		.else
			mov eax, 3; 0.1����Ϊ����
			mov Items[edi].typ, eax
		.endif
	.endif

	.if tool4 == 0; ӵ�����˲ݣ����ָ����ĸ�������Ϊ33%
		invoke crt_rand; �����������������eax��
		mov edx, 0; 
		mov ebx, 100;
		div ebx; 
		.if edx < 26; 0.1 + 0.9*0.26 = 0.33
			mov eax, 3; 0.1����Ϊ����
			mov Items[edi].typ, eax
		.endif
	.endif

	; ���������λ�� yyx�ģ�posX��Χ��Ϊ[100,420]
	invoke crt_rand
	mov edx, 0
	mov ebx, 320; PosX������
	div ebx; ���������edx��
	add edx, 100
	mov Items[edi].posX, edx

	invoke crt_rand
	mov edx, 0
	mov ebx, 700; posY������
	div ebx; ���������edx��
	mov Items[edi].posY, edx

	; ��������İ뾶����������ֵ����Ҫ���ж��������

	mov ebx, Items[edi].typ
	.if ebx == 3; ����

		mov eax, 20
		mov Items[edi].radius, eax

		invoke crt_rand
		mov edx, 0
		mov ebx, 5
		div ebx
		add edx, 5
		mov Items[edi].weight, edx

		invoke crt_rand
		mov edx, 0
		mov ebx, 1200
		div ebx
		add edx, 10
		mov Items[edi].value, edx

	.endif
	mov ebx, Items[edi].typ
	.if ebx == 2; ��ʯ
		mov eax, 20
		mov Items[edi].radius, eax
		mov eax, 12; ÿ���˶�120����
		mov Items[edi].weight, eax
		mov eax, 600
		mov Items[edi].value, eax
	.endif

	mov ebx, Items[edi].typ
	.if ebx == 1; ���
		invoke crt_rand; ������ߴ磬�趨Ϊ2:1:1
		mov edx, 0
		mov ebx, 4
		div ebx

		.if edx < 2; ��С�ߴ�Ľ��
			mov eax, 20
			mov Items[edi].radius, eax
			mov eax, 12
			mov Items[edi].weight, eax
			mov eax, 50
			mov Items[edi].value, eax
		.else
			.if edx < 3
				mov eax, 35
				mov Items[edi].radius, eax
				mov eax, 8
				mov Items[edi].weight, eax
				mov eax, 100
				mov Items[edi].value, eax
			.else
				mov eax, 50
				mov Items[edi].radius, eax
				mov eax, 3
				mov Items[edi].weight, eax
				mov eax, 500
				mov Items[edi].value, eax
			.endif
		.endif


	.endif

	mov ebx, Items[edi].typ
	.if ebx == 0; ʯͷ
		invoke crt_rand; ���ʯͷ�ߴ磬�趨Ϊ1:1
		mov edx, 0
		mov ebx, 2
		div ebx
		.if edx < 1; ��С�ߴ��ʯͷ
			mov eax, 20
			mov Items[edi].radius, eax
			mov eax, 8
			mov Items[edi].weight, eax
			mov eax, 10
			mov Items[edi].value, eax
		.else
			mov eax, 35
			mov Items[edi].radius, eax
			mov eax, 4
			mov Items[edi].weight, eax
			mov eax, 20
			mov Items[edi].value, eax
		.endif

		.if tool1 == 0; ��ӵ��ʯͷ�ղ���,value*2
			mov eax, Items[edi].value
			add Items[edi].value, eax
		.endif
	.endif

	add edi, 28; ���������±ꡣע�����ڼӵ���28��һ���ṹ��Ԫ�صĴ�С
	mov eax, itemNum
	mov ebx, 28;
	mul ebx;
	cmp edi, eax; ���ѭ���Ƿ����,����������edi==itemNum*28
	jne RandLoop  ; ѭ��δ������������һ��ѭ��


	;ע�Ტ������ʱ��������������main�е�init_secondʱ����ʱ��������
	invoke registerTimerEvent, offset timer  ;ע�ᶨʱ���ص�����timer
	invoke startTimer, 0, 100  ; ��ʱ�����Ϊ0��ˢ�¼��Ϊ100ms



	popad
	ret
InitGame endp


end

