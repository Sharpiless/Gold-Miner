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
	exist DWORD ?; 1存在，0已不存在
	typ DWORD ?; 类别
	posX DWORD ?; 位置横坐标
	posY DWORD ?; 位置纵坐标
	radius DWORD ?; 半径
	weight DWORD ?; 重量
	value DWORD ?; 价值
Item ENDS; 一个实例占4*7=28B
extern Items :Item
extern tool5:dword; TODO extern语句放在这就能跑了
extern tool6:dword
extern price5:dword
extern price6:dword

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
srcbag byte "..\resource\icon\bag.jpg", 0
srctnt byte "..\resource\icon\tnt.jpg", 0
srcmagnet byte "..\resource\icon\magnet.jpg", 0; 展示在商店中
srcehook byte "..\resource\icon\ehook.jpg", 0
srcmagnet1 byte "..\resource\icon\magnet1.jpg", 0; 展示在游戏中
srcehook1 byte "..\resource\icon\ehook1.jpg", 0
srcehookwithmagnet1 byte "..\resource\icon\ehookwithmagnet1.jpg", 0

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
imgbag ACL_Image <>
imgtnt ACL_Image <>
imgmagnet ACL_Image <>
imgehook ACL_Image <>
imgmagnet1 ACL_Image <>
imgehook1 ACL_Image <>
imgehookwithmagnet1 ACL_Image <>

strrestTime byte "10",0
strmusic byte "Music",0
strprice1 byte 10 DUP(0) ;yyx改为使用itoa，根据price1得到
strprice2 byte 10 DUP(0)
strprice3 byte 10 DUP(0)
strprice4 byte 10 DUP(0)
strprice5 byte 10 DUP(0)
strprice6 byte 10 DUP(0)
strmenu byte "Menu",0
strng byte "Next Game !",0
strScore byte 10 DUP(0)
strTime byte 10 DUP(0)
titleScore byte "得 分：", 0
titleTime byte "时 间：", 0
titleGoal byte "目 标 分 数：", 0;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
strGoal byte 10 DUP(0);;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
strMulti byte "×", 0
strFireNum byte 10 DUP(0)


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
DrawItem proc C x: dword, y: dword, r: dword, t: dword		;只能在启动了paint时调用此函数
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

	; yyx改：改序号和物体的对应关系
	.if eax==0 ; 石头
		invoke loadImage, offset srcbigstone, offset imgbigstone
		invoke putImageScale, offset imgbigstone, y, x, r, r
	.elseif eax==1 ; 金块
		invoke loadImage, offset srcgold, offset imggold
		invoke putImageScale, offset imggold, y, x, r, r
	.elseif eax==2 ; 钻石
		invoke loadImage, offset srcdiamond, offset imgdiamond;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		invoke putImageScale, offset imgdiamond, y, x, r, r;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.elseif eax==3 ; 幸运袋
		invoke loadImage, offset srcbag, offset imgbag;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		invoke putImageScale, offset imgbag, y, x, r, r;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.elseif eax == 4; TNT
		invoke loadImage, offset srctnt, offset imgtnt;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		invoke putImageScale, offset imgtnt, y, x, r, r;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.endif
	pop eax
	ret
DrawItem endp

;@brief:主调函数
Flush proc C 
	mov ebx, curWindow
	;选择生成的窗口
	cmp ebx, 0  
	jz open
	cmp ebx, 1
	jz mainwindow
	cmp ebx,2
	jz store

mainwindow:
	;测试：为item赋初值。可删，在model中赋值
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
	invoke loadImage, offset srcmagnet1, offset imgmagnet1
	invoke loadImage, offset srcehook1, offset imgehook1
	invoke loadImage, offset srcehookwithmagnet1, offset imgehookwithmagnet1
	invoke loadImage, offset srcfire, offset imgfire
	;显示主界面
	invoke beginPaint
	invoke putImageScale, offset imggame1, 0, 0, 700, 500	;绘制背景
	invoke putImageScale, offset imgdigger, 325, 15, 50, 65		;绘制矿工

	;绘制物品 TODO yyx改：edi+=1改为edi+=28
	push ebx					
	push edi
	mov edi,0
	mov eax, itemNum; 将ebx设置为itemNum*28
	mov ebx, 28;
	mul ebx;
	mov ebx, eax
	.while edi<ebx

		.if Items[edi].exist == 1  ; yyx加，仅在exist=1时绘制物体
			invoke DrawItem, Items[edi].posX, Items[edi].posY, Items[edi].radius, Items[edi].typ
		.endif
		add edi, 28; 增加数组下标。注意现在加的是28，一个结构体元素的大小
	.endw
	pop edi
	pop ebx
	;画小螃蟹
	;yyx改 根据购买情况画不同种类的钩子
	.if hookStat==0
		invoke calPSin, hookDeg, 30; Δx = -ρsinΘ
		mov ebx,hookPosX
		sub ebx, eax
		mov hookpx,ebx
		invoke calPCos, hookDeg, 30; Δy = ρcosΘ
		mov ebx,hookPosY
		add ebx, eax
		mov hookpy,ebx
	.else
		mov ebx,hookPosX
		mov hookpx,ebx
		mov ebx,hookPosY
		mov hookpy,ebx
	.endif



	push ebx
	push eax
	mov ebx,hookpy
	mov eax,12
	sub ebx,eax
	mov eax,hookpx
	add eax,80
	.if( tool5 == 0 && tool6 == 0 );
		invoke putImageScale, offset imgehookwithmagnet1, ebx, eax, 25, 25
	.elseif tool5 == 0;
		invoke putImageScale, offset imgmagnet1, ebx, eax, 25, 25
	.elseif tool6 == 0;
		invoke putImageScale, offset imgehook1, ebx, eax, 25, 25
	.else
		invoke putImageScale, offset imgxpx, ebx, eax, 25, 25
	.endif

	pop eax
	pop ebx

	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 630, 10, offset strmusic	;显示音乐选项
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 630, 30, offset strmenu	;显示菜单选项
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 10, 30, offset titleScore	;显示“得分”
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 60, 30, offset strScore	;显示分数
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 10, 10, offset titleTime	;显示"时间"
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 60, 10, offset strTime	;显示剩余时间
	
	
	invoke putImageScale, offset imgfire, 400, 20, 30, 30; 绘制鞭炮小图案
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 430, 20, offset strMulti	;显示×
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	mov ebx, fireNum
	invoke myitoa, ebx, offset strFireNum
	invoke paintText, 445, 20, offset strFireNum	;显示鞭炮数


	
	
	; 画线
	push eax
	mov eax,hookpx
	add eax,80
	invoke line, hookpy, eax, 350, 80;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	pop eax
	invoke setTextSize, 15;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke setTextColor, 00cc9988h;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke setTextBkColor, colorWHITE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke paintText, 10, 50, offset titleGoal	;显示"目标分数";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke setTextSize, 15;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke setTextColor, 00cc9988h;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke setTextBkColor, colorWHITE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke paintText, 110, 50, offset strGoal	;显示目标分数;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke endPaint
	jmp finish

open:
	;载入图片
	invoke loadImage, offset srcini, offset imgini
	;显示主界面
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
	invoke loadImage, offset srcmagnet, offset imgmagnet
	invoke loadImage, offset srcehook, offset imgehook

	;显示主界面
	invoke beginPaint
	invoke putImageScale, offset imggame1, 0, 0, 700, 500
	invoke putImageScale, offset imgseller, 500, 50, 210, 250
	invoke putImageScale, offset imgwords, 150, 20, 300, 120;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;invoke putImageScale, offset imgwords, 200, 60, 200, 80
	;以下为显示商品信息
	push eax
	mov eax, tool1
	.if eax == 1			;如果tool1==1则显示商品1
		invoke putImageScale, offset imgstonebook, 400, 150, 60, 60
		invoke setTextSize, 20
		invoke setTextColor, 00cc9988h
		invoke setTextBkColor, colorWHITE
		mov ebx, price1
		invoke myitoa, ebx, offset strprice1
		invoke paintText, 410, 220, offset strprice1
	.endif
	mov eax, tool2
	.if eax == 1
		invoke putImageScale, offset imgfire, 340, 150, 60, 60
		invoke setTextSize, 20
		invoke setTextColor, 00cc9988h
		invoke setTextBkColor, colorWHITE
		mov ebx, price2
		invoke myitoa, ebx, offset strprice2
		invoke paintText, 350, 220, offset strprice2
	.endif
	mov eax, tool3
	.if eax == 1
		invoke putImageScale, offset imgstrengthwater, 280, 150, 60, 60
		invoke setTextSize, 20
		invoke setTextColor, 00cc9988h
		invoke setTextBkColor, colorWHITE
		mov ebx, price3
		invoke myitoa, ebx, offset strprice3
		invoke paintText, 290, 220, offset strprice3
	.endif
	mov eax, tool4
	.if eax == 1
		invoke putImageScale, offset imgluckyleave, 220, 150, 60, 60
		invoke setTextSize, 20
		invoke setTextColor, 00cc9988h
		invoke setTextBkColor, colorWHITE
		mov ebx, price4
		invoke myitoa, ebx, offset strprice4
		invoke paintText, 230, 220, offset strprice4
	.endif
	mov eax, 1
	;.if eax == 1
	.if eax == tool5
		invoke putImageScale, offset imgmagnet, 160, 150, 60, 60
		invoke setTextSize, 20
		invoke setTextColor, 00cc9988h
		invoke setTextBkColor, colorWHITE
		mov ebx, price5
		invoke myitoa, ebx, offset strprice5
		invoke paintText, 170, 220, offset strprice5
	.endif
	
	mov eax, 1
	;.if eax == 1
	.if eax == tool6
		invoke putImageScale, offset imgehook, 100, 150, 60, 60
		invoke setTextSize, 20
		invoke setTextColor, 00cc9988h
		invoke setTextBkColor, colorWHITE
		mov ebx, price6
		invoke myitoa, ebx, offset strprice6
		invoke paintText, 110, 220, offset strprice6
	.endif
	pop eax
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 630, 10, offset strmusic	;显示音乐选项
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 630, 30, offset strmenu	;显示菜单选项
	invoke setTextSize, 50
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 200, 350, offset strng	;显示Next Game
	invoke line, 0, 300, 700 ,300
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 10, 10, offset titleScore	;显示“得分”
	invoke setTextSize, 15
	invoke setTextColor, 00cc9988h
	invoke setTextBkColor, colorWHITE
	invoke paintText, 60, 10, offset strScore	;显示分数

	invoke endPaint
	jmp finish

finish:	
	ret 
Flush endp
end Flush
