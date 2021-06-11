.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib
include include\test.inc
include include\vars.inc
include include\model.inc
include include\acllib.inc
include include\view.inc

printf PROTO C :ptr DWORD, :VARARG

.data

coord sbyte "%d,%d",10,0

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
	
; �����Ӧ�¼�
iface_mouseEvent proc C x:dword,y:dword,button:dword,event:dword
	pushad; �����мĴ���ѹ��ջ�У��ݴ�Ĵ�����ֵ
	mov ecx,event
	cmp ecx,BUTTON_DOWN
	jne not_click; ���¼�������������򲻴����κ��߼�
	
	invoke printf,offset coord,x,y ;���ԣ���ӡ�û����������

	.if curWindow == 0; �ڻ�ӭ����
		invoke is_inside_the_rect,x,y,0,700,0,500; TODO �ĳɵ��"��ʼ"
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
			mov hookV, 35 ;(����Ĭ���ٶ�)
			mov lastHit, -1
			
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
