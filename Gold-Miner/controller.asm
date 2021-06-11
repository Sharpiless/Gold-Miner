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
;判断点击的坐标是否在矩形框内，是返回1，不是则返回0。
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
	
; 点击相应事件
iface_mouseEvent proc C x:dword,y:dword,button:dword,event:dword
	pushad; 将所有寄存器压入栈中，暂存寄存器的值
	mov ecx,event
	cmp ecx,BUTTON_DOWN
	jne not_click; 若事件不是鼠标点击，则不触发任何逻辑
	
	invoke printf,offset coord,x,y ;测试：打印用户点击的坐标

	.if curWindow == 0; 在欢迎界面
		invoke is_inside_the_rect,x,y,0,700,0,500; TODO 改成点击"开始"
		.if eax == 1; 
			; 窗体设为1
			mov eax, 1
			mov curWindow, eax
			invoke InitGame
			
		.endif
		
	.elseif curWindow == 1; 在游戏界面
		mov eax, gameX;
		add eax, 80;
		invoke is_inside_the_rect,x,y,0,gameY,80,eax; 判断是否在游戏有效区域内
		.if eax == 1; 在游戏区域，释放钩子。写hookStat，hookDir，hookV, lastHit
			mov hookStat, 1
			mov hookDir, 0
			mov hookV, 35 ;(钩索默认速度)
			mov lastHit, -1
			
		.endif

	.elseif curWindow == 2; 在商店
		invoke is_inside_the_rect,x,y,200,700,350,400; 点击"next game"区域
		;next game矩形范围：200，350，500，50
		.if eax == 1; 
			; 窗体设为1
			mov eax, 1
			mov curWindow, eax
			invoke InitGame
		.endif

		invoke is_inside_the_rect,x,y,400,480,150,230 ; 点击第一个商品，石头收藏书
		;矩形范围：400，150，80，80
		.if eax == 1
			mov eax, price1
			.if playerScore > eax
				sub playerScore, eax; 得分减少
				mov tool1, 0 ; 购买
				invoke Flush; 刷新界面
			.endif
		.endif

		invoke is_inside_the_rect,x,y,300,380,150,230 ; 点击第二个商品，炸药
		;矩形范围：300，150，80，80
		.if eax == 1
			mov eax, price2
			.if playerScore > eax
				sub playerScore, eax; 得分减少
				mov tool2, 0 ; 购买
				invoke Flush; 刷新界面
			.endif
		.endif

		invoke is_inside_the_rect,x,y,200,280,150,230 ; 点击第三个商品，神水
		;矩形范围：200，150，80，80
		.if eax == 1
			mov eax, price3
			.if playerScore > eax
				sub playerScore, eax; 得分减少
				mov tool3, 0 ; 购买
				invoke Flush; 刷新界面
			.endif
		.endif

		invoke is_inside_the_rect,x,y,100,180,150,230 ; 点击第四个商品，幸运草
		;矩形范围：100，150，80，80
		.if eax == 1
			mov eax, price4
			.if playerScore > eax
				sub playerScore, eax; 得分减少
				mov tool4, 0 ; 购买
				invoke Flush; 刷新界面
			.endif
		.endif
	
	.endif
					
not_click:
	popad; 弹出寄存器的值
	ret 
iface_mouseEvent endp

end
