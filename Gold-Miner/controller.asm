.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib
includelib StaticLib1.lib
include include\test.inc
include include\vars.inc
include include\model.inc
include include\acllib.inc
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
calPSin PROTO C :dword, :dword ; ����StaticLib1.lib������PSin��
calPCos PROTO C :dword, :dword ; ����StaticLib1.lib������PCos��


.data

coord sbyte "�������%d,%d",0ah,0
strSpace sbyte "���¿ո�", 0ah, 0
strLeft sbyte "��������", 0ah, 0
tmp sbyte "hookDeg=%d", 0ah, 0

str1 byte "count=%d", 0ah, 0
str2 byte "count*hookV=%d", 0ah, 0

tmpVar dd 0


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
		.endif

		.if (key == VK_LEFT && tool4 == 1 && hookDir == 0); ����΢��
			invoke printf, offset strLeft
			invoke printf, offset str1, count
			sub hookDeg, 2
			; TODO �������µ�Deg�����Ӧ��posX
			mov eax, hookV; ��������eax��
			mov ebx, count
			mul ebx; �˷������eax��
			
			invoke calPSin, hookDeg, eax; ��x = -��sin��
			mov ebx, minerPosX; hookPosX��ֵΪ��x
			mov hookPosX, ebx
			sub hookPosX, eax

			; TODO �������µ�Deg�����Ӧ��posY
			mov eax, hookV; ��������eax��
			mov ebx, count
			mul ebx; �˷������eax��
			invoke calPCos, hookDeg, eax; 
			mov ebx, minerPosY;
			mov hookPosY, ebx
			add hookPosY, eax
			
			invoke printf, offset tmp, hookDeg
		.endif

		.if (key == VK_RIGHT && tool4 == 1 && hookDir == 0); ����΢��
			add hookDeg, 2
			invoke printf, offset tmp, hookDeg
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
			
		.endif
		
	.elseif curWindow == 1; ����Ϸ����
		mov eax, gameX;
		add eax, 80;
		invoke is_inside_the_rect,x,y,0,gameY,80,eax; �ж��Ƿ�����Ϸ��Ч������
		.if eax == 1; ����Ϸ�����ͷŹ��ӡ�дhookStat��hookDir��hookV, lastHit
			mov hookStat, 1
			mov hookDir, 0
			mov hookV, 10 ;(����Ĭ���ٶ�) TODO ԭ����35
			mov lastHit, -1
			mov count, 0 ; ��ʼ��count�����ڽ���posX��posY
			
		.endif

	.elseif curWindow == 2; ���̵�
		invoke is_inside_the_rect,x,y,200,700,350,400; ���"next game"����
		;next game���η�Χ��200��350��500��50
		.if eax == 1; 
			; ������Ϊ1
			mov eax, 1
			mov curWindow, eax
			invoke InitGame
		.endif

		invoke is_inside_the_rect,x,y,400,480,150,230 ; �����һ����Ʒ��ʯͷ�ղ���
		;���η�Χ��400��150��80��80
		.if eax == 1
			mov eax, price1
			.if playerScore > eax
				sub playerScore, eax; �÷ּ���
				mov tool1, 0 ; ����
				invoke Flush; ˢ�½���
			.endif
		.endif

		invoke is_inside_the_rect,x,y,300,380,150,230 ; ����ڶ�����Ʒ��ըҩ
		;���η�Χ��300��150��80��80
		.if eax == 1
			mov eax, price2
			.if playerScore > eax
				sub playerScore, eax; �÷ּ���
				mov tool2, 0 ; ����
				inc fireNum
				invoke Flush; ˢ�½���
			.endif
		.endif

		invoke is_inside_the_rect,x,y,200,280,150,230 ; �����������Ʒ����ˮ
		;���η�Χ��200��150��80��80
		.if eax == 1
			mov eax, price3
			.if playerScore > eax
				sub playerScore, eax; �÷ּ���
				mov tool3, 0 ; ����
				invoke Flush; ˢ�½���
			.endif
		.endif

		invoke is_inside_the_rect,x,y,100,180,150,230 ; ������ĸ���Ʒ�����˲�
		;���η�Χ��100��150��80��80
		.if eax == 1
			mov eax, price4
			.if playerScore > eax
				sub playerScore, eax; �÷ּ���
				mov tool4, 0 ; ����
				invoke Flush; ˢ�½���
			.endif
		.endif
	
	.endif
					
not_click:
	popad; �����Ĵ�����ֵ
	ret 
iface_mouseEvent endp

end
