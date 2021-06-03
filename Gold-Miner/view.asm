.386
.model flat,stdcall
option casemap:none

INCLUDELIB acllib.lib
INCLUDELIB lrfLib.lib
includelib StaticLib1.lib

include include\acllib.inc
include include\vars.inc
include include\model.inc
include include\msvcrt.inc

calPSin PROTO C :dword, :dword
calPCos PROTO C :dword, :dword
myitoa PROTO C :dword, :ptr sbyte
printf proto C :dword,:vararg

colorBLACK EQU 00000000h
colorWHITE EQU 00ffffffh
colorEMPTY EQU 0ffffffffh

Item STRUCT
	exist DWORD ?; 1���ڣ�0�Ѳ����ڣ��÷֣�
	typ DWORD ?; ���
	posX DWORD ?; λ�ú�����
	posY DWORD ?; λ��������
	radius DWORD ?; �뾶
	weight DWORD ?; ����
	value DWORD ?; ��ֵ
Item ENDS; һ��ʵ��ռ4*7=28B
extern Items :Item

.data	

hookpx DWORD ?
hookpy DWORD ?

srcini byte "..\resource\icon\window.jpg", 0
srcgame1 byte "..\resource\icon\game1.jpg", 0
srcdigger byte "..\resource\icon\digger.jpg", 0
srcfire byte "..\resource\icon\fire.jpg", 0
srcluckyleave byte "..\resource\icon\luckyleave.jpg", 0
srcstrengthwater byte "..\resource\icon\strengthwater.jpg", 0
srcstonebook byte "..\resource\icon\stonebook.jpg", 0
srcseller byte "..\resource\icon\seller.jpg", 0
srcwords byte "..\resource\icon\words.jpg", 0 
srcgold byte "..\resource\icon\gold.jpg", 0 
srcxpx byte "..\resource\icon\xpx.jpg", 0 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
srcdiamond byte "..\resource\icon\diamond.jpg", 0;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
srcbigstone byte "..\resource\icon\bigstone.jpg", 0;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



imgini ACL_Image <>
imggame1 ACL_Image <>
imgdigger ACL_Image <>
imgfire ACL_Image <>
imgluckyleave ACL_Image <>
imgstrengthwater ACL_Image <>
imgstonebook ACL_Image <>
imgseller ACL_Image <>
imgwords ACL_Image <>
imggold ACL_Image <>
imgxpx ACL_Image <> ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
imgdiamond ACL_Image <>;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
imgbigstone ACL_Image <>;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



strrestTime byte "10",0
strmusic byte "Music",0
strprice1 byte "53",0
strprice2 byte "370",0
strprice3 byte "156",0
strprice4 byte "87",0
strmenu byte "Menu",0
strng byte "Next Game !",0
strScore byte 10 DUP(0)
strTime byte 10 DUP(0)
titleScore byte "�� �֣�", 0
titleTime byte "ʱ �䣺", 0
titleGoal byte "Ŀ �� �� ����", 0;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
strGoal byte 10 DUP(0);;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.code


FlushScore proc C num: dword
	push ebx
	mov ebx, num
	mov playerScore, ebx
	invoke myitoa, ebx, offset strScore
	pop ebx
	ret
FlushScore endp
FlushTime proc C num: dword
	push ebx
	mov ebx, num
	mov restTime, ebx
	invoke myitoa, ebx, offset strTime
	pop ebx
	ret
FlushTime endp

DrawItem proc C x: dword, y: dword, r: dword, t: dword		;ֻ����������paintʱ���ô˺���
	push eax
	push ebx
	mov eax,x
	mov ebx,r
	sub eax,ebx
	add eax,80
	mov x,eax
	mov eax,y
	sub eax,ebx
	mov y,eax
	add ebx,ebx
	mov r,ebx
	pop ebx
	mov eax,t
	.if eax==0
		invoke loadImage, offset srcgold, offset imggold
		invoke putImageScale, offset imggold, y, x, r, r
	.elseif eax==1	
		invoke loadImage, offset srcdiamond, offset imgdiamond
		invoke putImageScale, offset imgdiamond, y, x, r, r
	.elseif eax==2;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		invoke loadImage, offset srcbigstone, offset imgbigstone;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		invoke putImageScale, offset imgbigstone, y, x, r, r;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.endif
	pop eax
	ret
DrawItem endp

;@brief:��������
Flush proc C 
	mov ebx, curWindow
	;ѡ�����ɵĴ���
	cmp ebx, 0  
	jz open
	cmp ebx, 1
	jz mainwindow
	cmp ebx,2
	jz store

mainwindow:
	;���ԣ�Ϊitem����ֵ����ɾ����model�и�ֵ
	;push ebx
	;mov ebx,300
	;mov Items[0].posX,ebx
	;mov Items[0].posY,ebx
	;mov ebx, 0
	;mov Items[0].typ,ebx
	;mov ebx, 30
	;mov Items[0].radius, ebx
	;pop ebx
	invoke FlushScore, playerScore
	invoke FlushTime, restTime
	invoke myitoa, goalScore, offset strGoal
	invoke loadImage, offset srcgame1, offset imggame1
	invoke loadImage, offset srcdigger, offset imgdigger
	invoke loadImage, offset srcxpx, offset imgxpx;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;��ʾ������
	invoke beginPaint
	invoke putImageScale, offset imggame1, 0, 0, 700, 500	;���Ʊ���
	invoke putImageScale, offset imgdigger, 325, 15, 50, 65		;���ƿ�
	;������Ʒ
	push ebx					
	push edi
	mov edi,0
	mov ebx,itemNum
	.while edi<ebx
		.if Items[edi].exist == 1  ; yyx�ӣ�����exist=1ʱ��������
			invoke DrawItem, Items[edi].posX, Items[edi].posY, Items[edi].radius, Items[edi].typ
		.endif
		inc edi
	.endw
	pop edi
	pop ebx
	;��С�з

	.if hookStat==0
		invoke calPSin, hookDeg, 30; ��x = -��sin��
		mov ebx,hookPosX
		sub ebx, eax
		mov hookpx,ebx
		invoke calPCos, hookDeg, 30; ��y = ��cos��
		mov ebx,hookPosY
		add ebx, eax
		mov hookpy,ebx
	.else
		mov ebx,hookPosX
		mov hookpx,ebx
		mov ebx,hookPosY
		mov hookpy,ebx
	.endif



	push ebx;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push eax;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ebx,hookpy;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax,12;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	sub ebx,eax;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax,hookpx
	add eax,80
	invoke putImageScale, offset imgxpx, ebx, eax, 25, 25	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	pop eax;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	pop ebx;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 630, 10, offset strmusic	;��ʾ����ѡ��
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 630, 30, offset strmenu	;��ʾ�˵�ѡ��
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 10, 30, offset titleScore	;��ʾ���÷֡�
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 60, 30, offset strScore	;��ʾ����
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 10, 10, offset titleTime	;��ʾ"ʱ��"
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 60, 10, offset strTime	;��ʾʣ��ʱ��
	push eax
	mov eax,hookpx
	add eax,80

	invoke line, hookpy, eax, 350, 80;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	pop eax
	invoke setTextSize, 15;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke setTextColor, 00cc9988h;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke setTextBkColor, colorWHITE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke paintText, 10, 50, offset titleGoal	;��ʾ"Ŀ�����";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke setTextSize, 15;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke setTextColor, 00cc9988h;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke setTextBkColor, colorWHITE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke paintText, 110, 50, offset strGoal	;��ʾĿ�����;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke endPaint
	jmp finish

open:
	;����ͼƬ
	invoke loadImage, offset srcini, offset imgini
	;��ʾ������
	invoke beginPaint
	invoke putImageScale, offset imgini, 0, 0, 700, 500		;80, 125, 125, 50
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 630, 10, offset strmusic
	invoke endPaint
	jmp finish

store:
	invoke FlushScore, playerScore
	;invoke loadImage, offset srcwords, offset imgwords
	invoke loadImage, offset srcgame1, offset imggame1
	invoke loadImage, offset srcseller, offset imgseller
	invoke loadImage, offset srcluckyleave, offset imgluckyleave
	invoke loadImage, offset srcstonebook, offset imgstonebook
	invoke loadImage, offset srcstrengthwater, offset imgstrengthwater
	invoke loadImage, offset srcfire, offset imgfire
	invoke loadImage, offset srcwords, offset imgwords;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;��ʾ������
	invoke beginPaint
	invoke putImageScale, offset imggame1, 0, 0, 700, 500
	invoke putImageScale, offset imgseller, 500, 50, 210, 250
	invoke putImageScale, offset imgwords, 150, 20, 300, 120;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;invoke putImageScale, offset imgwords, 200, 60, 200, 80
	;����Ϊ��ʾ��Ʒ��Ϣ
	push eax
	mov eax, tool1
	.if eax == 1			;���tool1==1����ʾ��Ʒ1
		invoke putImageScale, offset imgstonebook, 400, 150, 80, 80
		invoke setTextSize, 20
		invoke setTextColor, 00cc9988h
		invoke setTextBkColor, colorWHITE
		invoke paintText, 430, 250, offset strprice1
	.endif
	mov eax, tool2
	.if eax == 1
		invoke putImageScale, offset imgfire, 300, 150, 80, 80
		invoke setTextSize, 20
		invoke setTextColor, 00cc9988h
		invoke setTextBkColor, colorWHITE
		invoke paintText, 330, 250, offset strprice2
	.endif
	mov eax, tool3
	.if eax == 1
		invoke putImageScale, offset imgstrengthwater, 200, 150, 80, 80
		invoke setTextSize, 20
		invoke setTextColor, 00cc9988h
		invoke setTextBkColor, colorWHITE
		invoke paintText, 230, 250, offset strprice3
	.endif
	mov eax, tool4
	.if eax == 1
		invoke putImageScale, offset imgluckyleave, 100, 150, 80, 80
		invoke setTextSize, 20
		invoke setTextColor, 00cc9988h
		invoke setTextBkColor, colorWHITE
		invoke paintText, 130, 250, offset strprice4
	.endif
	pop eax
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 630, 10, offset strmusic	;��ʾ����ѡ��
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 630, 30, offset strmenu	;��ʾ�˵�ѡ��
	invoke setTextSize, 50
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 200, 350, offset strng	;��ʾNext Game
	invoke line, 0, 300, 700 ,300
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 10, 10, offset titleScore	;��ʾ���÷֡�
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 60, 10, offset strScore	;��ʾ����

	invoke endPaint
	jmp finish

finish:	
	ret 
Flush endp
end Flush
