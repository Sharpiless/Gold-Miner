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
printf PROTO C :ptr sbyte, :VARARG


.data

winTitle byte "黄金矿工", 0

Item STRUCT
	exist DWORD ?; 1存在，0已不存在（得分）
	typ DWORD ?; 类别
	posX DWORD ?; 位置横坐标
	posY DWORD ?; 位置纵坐标
	radius DWORD ?; 半径
	weight DWORD ?; 重量
	value DWORD ?; 价值
Item ENDS; 一个实例占4*7=28B
extern Items:Item; vars中定义的物体数组

szFmt2 BYTE '随机数=%d'

.code  


main proc; 

	;初始化绘图环境和窗口
	invoke init_first  
	invoke initWindow, offset winTitle, 425, 50, 700, 500

	;测试：产生随机数（成功）
	invoke crt_rand
	invoke printf, OFFSET szFmt2, eax
	;end测试

	;设置当前窗口为1
	mov eax, 1
	mov curWindow, eax

	invoke Flush;

;	invoke InitGame; 调用initGame
	;invoke registerMouseEvent,iface_mouseEvent ;注册控制流事件, 注意，如果要定义按钮动作，进入这个函数内进行函数代码的添加
	;invoke cancelTimer, 0 ; 关闭定时器


	
	invoke init_second

	ret

main endp




end main
		