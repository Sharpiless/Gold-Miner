.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib
include inc\acllib.inc
include include\test.inc
include include\vars.inc
include include\model.inc
include include\acllib.inc

.data
	coord sbyte "%d,%d",10,0

.code
	;�жϵ���������Ƿ��ھ��ο��ڣ��Ƿ���1�������򷵻�0,ע��
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
	; �����Ӧʱ��
	; lastHit: ���û�������(����)ʱдΪ-1������������ʱ��Ϊ�±�
	; hookStat: ����״̬��0ʱ���ͷţ�1ʱ�ͷ�
	iface_mouseEvent proc C x:dword,y:dword,button:dword,event:dword
		mov ecx,event
		cmp ecx,BUTTON_DOWN
		jne not_click

			invoke is_inside_the_rect,x,y,0,gameX,0,gameY
					.if eax == 1
						invoke printf,offset coord,x,y ;����˻���
						mov hookStat,1
						mov lastHit,-1
						invoke cancelTimer,0
					.else	
						invoke printf,offset coord,x,y
					.endif
					;action
					;	���������������

		not_click:
		ret 
	iface_mouseEvent endp
end
