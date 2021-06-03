.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib
include include\test.inc
include include\vars.inc
include include\model.inc
include include\acllib.inc

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
	; lastHit: 在用户点击鼠标(出勾)时写为-1，在命中物体时设为下标
	; hookStat: 钩索状态。0时不释放，1时释放
	iface_mouseEvent proc C x:dword,y:dword,button:dword,event:dword
		pushad; 将所有寄存器压入栈中，暂存寄存器的值
		mov ecx,event
		cmp ecx,BUTTON_DOWN
		jne not_click; 若事件不是鼠标点击，则不触发逻辑

		invoke is_inside_the_rect,x,y,0,gameX,0,gameY
		.if eax == 1
			invoke printf,offset coord,x,y ;测试：打印用户点击的坐标
			mov hookStat, 1
			mov hookDir, 0
			mov lastHit, -1
		.else	
			invoke printf,offset coord,x,y
		.endif
					
	not_click:
		popad; 弹出寄存器的值
		ret 
	iface_mouseEvent endp
end
