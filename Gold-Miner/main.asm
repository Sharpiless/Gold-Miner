.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib

include include\test.inc
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
	exist DWORD ?; 1���ڣ�0�Ѳ����ڣ��÷֣�
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


	;��ʼ���÷�
	mov eax, 0
	mov playerScore, eax; ��ǰ�÷�

	;���õ�ǰ����Ϊ1
	mov eax, 0
	mov curWindow, eax
	invoke Flush
	

	;invoke InitGame; ����initGame
	invoke registerMouseEvent,iface_mouseEvent ;ע��������¼���ע�⣬���Ҫ���尴ť������������������ڽ��к�����������

	invoke init_second; ������initʱ���Żᴥ����ʱ���Ļص�����
	ret

main endp


end main
		