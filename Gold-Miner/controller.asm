.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib

include include\vars.inc
include include\model.inc
include include\acllib.inc
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
extern price5:dword
extern price6:dword

printf PROTO C :ptr DWORD, :VARARG
calPSin PROTO C :dword, :dword ; ����StaticLib1.lib������PSin��
calPCos PROTO C :dword, :dword ; ����StaticLib1.lib������PCos��


.data

modelMusicset_xpx byte "..\resource\music\set_xpx.mp3", 0
modelMusicboomb byte "..\resource\music\boomb.mp3", 0
modelMusicstartgame byte "..\resource\music\startgame.mp3", 0

modelMusicset_xpxP dd 0
modelMusicboombP dd 0
modelMusicstartgameP dd 0



coord sbyte "����� %d,%d",0ah,0
strSpace sbyte "���¿ո�", 0ah, 0
strLeft sbyte "��������", 0ah, 0
strRight sbyte "��������", 0ah, 0




.code
;�жϵ���������Ƿ��ھ��ο��ڣ��Ƿ���1�������򷵻�0��
is_inside_the_rect proc C x:dword,y:dword,left:dword,right:dword,up:dword,bottom:dword
	mov eax,x
	mov ebx,y
	.if	eax <= left
		mov eax,0
	.elseif	eax >= right
		mov eax,0
	.elseif ebx >= bottom
		mov eax,0
	.elseif ebx <= up
		mov eax,0
	.else	
		mov eax,1
	.endif	
	ret
is_inside_the_rect endp
	

; �����¼��ص�����
iface_keyboardEvent proc C key:dword, event:dword
	pushad
	mov ecx,event
	cmp ecx,KEY_DOWN
	jne not_press; ���¼����ǰ��¼��̣��򲻴����κ��߼�

	
	.if curWindow == 1
		.if (key == VK_SPACE && fireNum > 0 && hookDir == 1 && lastHit != -1); �ո��ͷű��ڡ�����ӵ�б���ʱ����
			invoke printf, offset strSpace
			; ��������-1
			dec fireNum 
			; дhookStatΪ0
			mov eax, 0
			mov hookStat, eax
			; дhookPosX��hookPosYΪ��λ��
			mov eax, minerPosX
			mov hookPosX, eax
			mov eax, minerPosY
			mov hookPosY, eax
		
			; ɾ�����壬дItems[lastHit].existΪ0
			mov edi, lastHit
			mov eax, 0
			mov Items[edi].exist, eax 

			invoke loadSound,addr modelMusicboomb,addr modelMusicboombP
			invoke playSound,modelMusicboombP,0
		.endif

		.if ((key == VK_LEFT || key == VK_RIGHT) && tool6 == 0 && hookDir == 0); ΢�� tool6==0
			.if key == VK_LEFT; ����
				invoke printf, offset strLeft
				sub hookDeg, 2	
			.else; ����
				invoke printf, offset strRight
				add hookDeg, 2
			.endif
			
			; TODO �������µ�Deg�����Ӧ��posX
			mov eax, hookV; ��������eax��
			mov ebx, count
			mul ebx; �˷������eax��
			
			invoke calPSin, hookDeg, eax; ��x = -��sin��
			mov ebx, minerPosX; hookPosX��ֵΪminerPosX+��x
			mov hookPosX, ebx
			sub hookPosX, eax

			; TODO �������µ�Deg�����Ӧ��posY
			mov eax, hookV; ��������eax��
			mov ebx, count
			mul ebx; �˷������eax��
			invoke calPCos, hookDeg, eax; 
			mov ebx, minerPosY;hookPosY��ֵΪminerPosY+��Y
			mov hookPosY, ebx
			add hookPosY, eax
			
		.endif
	.endif

not_press:
	popad
	ret

iface_keyboardEvent endp

; ����¼��ص�����
iface_mouseEvent proc C x:dword,y:dword,button:dword,event:dword
	pushad; �����мĴ���ѹ��ջ�У��ݴ�Ĵ�����ֵ
	mov ecx,event
	cmp ecx,BUTTON_DOWN
	jne not_click; ���¼�������������򲻴����κ��߼�
	
	invoke printf,offset coord,x,y ;���ԣ���ӡ�û����������

	.if curWindow == 0; �ڻ�ӭ����
		invoke is_inside_the_rect,x,y,0,700,0,500;
		.if eax == 1; 
			; ������Ϊ1
			mov eax, 1
			mov curWindow, eax
			invoke InitGame
			invoke loadSound,addr modelMusicstartgame,addr modelMusicstartgameP
			invoke playSound,modelMusicstartgameP,0
		.endif
		
	.elseif curWindow == 1; ����Ϸ����
		mov eax, gameX;
		add eax, 80;
		invoke is_inside_the_rect,x,y,0,gameY,80,eax; �ж��Ƿ�����Ϸ��Ч������
		.if eax == 1; ����Ϸ�����ͷŹ��ӡ�дhookStat��hookDir��hookV, lastHit
			mov hookStat, 1
			mov hookDir, 0
			mov hookV, 35 ;(����Ĭ���ٶ�)
			mov lastHit, -1
			mov count, 0 ; ��ʼ��count�����ڽ���posX��posY
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,630,700,30,45; �����һ����Ʒ��ʯͷ�ղ���
		;���η�Χ��630��30������15
		.if eax == 1; ����˵����ص���ӭ����
			;����tool��
			mov tool1, 1
			mov tool2, 1
			mov tool3, 1
			mov tool4, 1
			mov tool5, 1
			mov tool6, 1
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



	.elseif curWindow == 2; ���̵�
		invoke is_inside_the_rect,x,y,200,700,350,400; ���"next game"����
		;next game���η�Χ��200��350��500��50
		.if eax == 1; 
			; ������Ϊ1
			mov eax, 1
			mov curWindow, eax
			invoke InitGame
			invoke loadSound,addr modelMusicstartgame,addr modelMusicstartgameP
			invoke playSound,modelMusicstartgameP,0
		.endif

		invoke is_inside_the_rect,x,y,400,460,150,210 ; �����һ����Ʒ��ʯͷ�ղ���
		;���η�Χ��400��150��80��80
		.if eax == 1
			mov eax, price1
			.if playerScore > eax
				sub playerScore, eax; �÷ּ���
				mov tool1, 0 ; ����
				invoke Flush; ˢ�½���
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,340,400,150,210 ; ����ڶ�����Ʒ������
		;���η�Χ��300��150��80��80
		.if eax == 1
			mov eax, price2
			.if playerScore > eax
				sub playerScore, eax; �÷ּ���
				mov tool2, 0 ; ����
				inc fireNum
				invoke Flush; ˢ�½���
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,280,340,150,210 ; �����������Ʒ����ˮ
		;���η�Χ��200��150��80��80
		.if eax == 1
			mov eax, price3
			.if playerScore > eax
				sub playerScore, eax; �÷ּ���
				mov tool3, 0 ; ����
				invoke Flush; ˢ�½���
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,220,280,150,210 ; ������ĸ���Ʒ�����˲�
		;���η�Χ��100��150��80��80
		.if eax == 1
			mov eax, price4
			.if playerScore > eax
				sub playerScore, eax; �÷ּ���
				mov tool4, 0 ; ����
				invoke Flush; ˢ�½���
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,160,220,150,210 ;TODO ����������Ʒ������
		.if eax == 1
			mov eax, price5
			.if playerScore > eax
				sub playerScore, eax; �÷ּ���
				mov tool5, 0 ; ����
				invoke Flush; ˢ�½���
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,100,160,150,210 ;TODO �����������Ʒ���綯��

		.if eax == 1
			mov eax, price6
			.if playerScore > eax
				sub playerScore, eax; �÷ּ���
				mov tool6, 0 ; ����
				invoke Flush; ˢ�½���
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif


	
	.endif
					
not_click:
	popad; �����Ĵ�����ֵ
	ret 
iface_mouseEvent endp

end
