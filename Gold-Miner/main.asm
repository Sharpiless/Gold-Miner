.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib


include include\vars.inc
include include\windows.inc
include include\model.inc
include include\acllib.inc
include include\msvcrt.inc
include include\view.inc
include include\controller.inc
printf PROTO C :ptr sbyte, :VARARG



.data

winTitle byte "�ƽ��", 0

szFmt5 BYTE '�ϵ�...', 0ah, 0

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


.code  


main proc; 

	;��ʼ����ͼ�����ʹ���
	invoke init_first  
	invoke initWindow, offset winTitle, 425, 50, 700, 500
	
	;���õ�ǰ����Ϊ1
	mov eax, 0
	mov curWindow, eax
	;���õ÷�
	mov eax, 0;
	mov playerScore, eax; 
	;����Ŀ��÷�
	mov eax, 0
	mov goalScore, eax
	;���ñ�������
	mov eax, 0
	mov fireNum, eax
	invoke Flush; ���ƻ�ӭ����
	

	;invoke InitGame; ����initGame
	invoke registerMouseEvent,iface_mouseEvent ;ע������¼���
	invoke registerKeyboardEvent, iface_keyboardEvent ;ע������¼�
	invoke init_second; ������initʱ���Żᴥ����ʱ���Ļص�����
	ret

main endp


end main
		