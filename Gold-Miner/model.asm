.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib
includelib StaticLib1.lib

include include\vars.inc
include include\acllib.inc
include include\msvcrt.inc

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

printf PROTO C :ptr DWORD, :VARARG
calDistance PROTO C :dword, :dword, :dword, :dword  ; 来自StaticLib1.lib

.data

hookODir DWORD ?; 角速度方向。1朝右，0朝左

timeElapsed DWORD 0; 记录流逝时间

szFmt1 BYTE '物体列表中第%d个元素，exist=%d, typ=%d, posX=%d, posY=%d, radius=%d, weight=%d, value=%d', 0ah, 0
szFmt2 BYTE '%d号计时器响应, 时间已流逝%d ms', 0ah, 0
szFmt3 BYTE '命中第%d个物体！距离=%d, 物体半径=%d', 0ah, 0
szFmt4 BYTE '未命中物体！', 0ah, 0

.code

; 移动钩索,测试
; @brief: 将钩索位置移动到(50,50)
MoveHookTest proc C
	push eax
	mov eax, 50
	mov hookPosX, eax
	mov eax, 50
	mov hookPosY, eax
	pop eax
	ret
MoveHookTest endp



; 移动钩索
; @brief：若lastHit不为-1，需要带着该物体一起移动
MoveHook proc C 
	pushad
	
	cmp hookStat, 0
	jz ChangeDeg
ChangePos: ;改变钩索位置
	;TODO
	jmp FinishMoveHook
ChangeDeg: ; 改变钩索角度
	mov eax, hookOmega
	.if hookODir == 0 ; 向右移动

		mov ebx, 360
		mov ecx, hookOmega
		sub ebx, ecx
		.if hookDeg > ebx  ; 若到达右端尽头(不够减)，即hookDeg>360-hookOmega,反转钩索角速度
			mov ebx, 1
			mov hookODir, ebx
		.else 
			add hookDeg, eax ; 正常移动
		.endif

	.else ; 向左移动
		mov ebx, 180
		mov ecx, hookOmega
		add ebx, ecx
		.if hookDeg < ebx ; 若到达左端尽头(不够减)，即hookDeg<180+hookOmega,反转钩索角速度
			mov ebx, 0
			mov hookODir, ebx
		.else 
			sub hookDeg, eax ; 正常移动
		.endif
		

	.endif


FinishMoveHook:
	popad
	ret
MoveHook endp


; 判断钩索是否命中物体。
; @brief：遍历items中所有物体的位置(posX、posY)，判断钩索位置与物体位置的距离是否小于物体半径。
; NEXT TODO 计划对返回值的改进：返回命中物体的下标。
IsHit proc C
	pushad
	mov edi, 0; 遍历初值
LoopTraverseItem:
	
	; 计算距离,将距离存入eax。
	invoke calDistance, hookPosX, hookPosY, Items[edi].posX, Items[edi].posY
	cmp eax, Items[edi].radius;比较大小
	jb Hit; 距离小于半径，跳转到Hit
	
	inc edi; 遍历变量++
	cmp edi, itemNum; 检查遍历是否结束
	jb LoopTraverseItem
	jmp NotHit; 未命中，跳转到NotHit

Hit:
	invoke printf, OFFSET szFmt3, edi, eax, Items[edi].radius; 打印命中信息，eax中是距离。
	; 写lastHit
	mov eax, edi
	mov lastHit, eax
	; 修改hookDir为1
	mov eax, 1
	mov hookDir, eax
	; hookV = 100-物体重量（待定）
	mov ebx, 100;
	sub ebx, Items[edi].weight;
	mov hookV, ebx
	; 返回命中物体的下标
	mov eax, edi
	jmp Finish
NotHit:
	invoke printf, OFFSET szFmt4; 打印未命中信息.
	; 不命中的话，不返回值可以吗？

Finish:
	popad
	ret
IsHit endp

; 判断钩索是否出界或回到矿工手中
; 脏寄存器：eax、ebx
IsOut proc C
	;push eax 这个子函数没有返回值，无需暂存eax
	mov eax, hookPosX
	mov ebx, hookPosY

	.if eax > gameX; 下出界
		mov eax, 1
		mov hookDir, eax
	.elseif ebx < 0; 左出界
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > gameY; 右出界
		mov eax, 1
		mov hookDir, eax

	.elseif eax < 0; 钩子回到矿工手中。注意钩索未释放时hookPosX=0，不进入该逻辑。因此是合理的

		; 改变hookStat为0
		mov eax, 0
		mov hookStat, eax

		;根据目前手中是否有物体，响应加分并删除物体逻辑
		;.if  lastHit == -1 (判断lastHit是否为-1） TODO
		;	playerScore += Items[lastHit].value
		;	Items[lastHit].exist = 0

			


	.endif

	;pop eax
	ret
IsOut endp

;@brief:定时器回调函数。每次触发定时器，调用MoveHook移动钩索。
timer proc C id:dword
	add timeElapsed, 10; 维护流逝的时间
	invoke MoveHook; 移动钩索
	invoke IsHit;
	invoke IsOut;
	;invoke printf, OFFSET szFmt2, id, timeElapsed; 打印定时器回调函数信息
	ret
timer endp



InitGame proc C

	; 暂存子函数中用到的寄存器eax
	push eax

	; 初始化钩子变量
InitHook:
	mov eax, 0; 设置hookStat，初始化为0
	mov hookStat, eax;
	mov eax, 1; 设置hookODir，初始化为1
	mov hookODir, eax;
	mov eax, 0; 设置hookDir, 初始化为0
	mov hookDir, eax;
	mov eax, 2; 设置角速度
	mov hookOmega, eax; 
	mov eax, 10; 设置线速度
	mov hookV, eax;

	;测试：向物体列表中某个元素赋值。(成功)
InitItem:
	mov edi, 0; 数组偏移，开始设为0
	mov eax, 1; 
	mov Items[edi].exist, eax; 设置第一个物体的exist是1。由于exist字段占四个字节，所以源操作数是eax。
	mov Items[edi].typ, eax; 设置typ是1
	mov eax, 40;
	mov Items[edi].posX, eax; 设置位置为(40,40)
	mov Items[edi].posY, eax;
	mov eax, 15;
	mov Items[edi].radius, eax; 设置半径为15
	mov eax, 10;
	mov Items[edi].weight, eax; 设置重量为10
	mov Items[edi].value, eax; 设置价值为10
	invoke	printf, OFFSET szFmt1, edi, Items[edi].exist, Items[edi].typ, Items[edi].posX, Items[edi].posY, Items[edi].radius, Items[edi].weight, Items[edi].value; 打印查看赋值是否成功。
	;end测试


	;测试：注册并启动定时器。（未成功，现在定时器不work）
	invoke registerTimerEvent, offset timer  ;注册定时器回调函数timer
	invoke startTimer, 0, 10  ; 定时器编号为0，刷新间隔为10ms
	;end测试

	;测试：手动调用MoveHookTest移动。（成功）
	invoke MoveHookTest
	;end测试

	;测试：手动调用isHit和isOut
	invoke IsHit
	invoke IsOut
	;end测试


	;测试：阻塞在一个空循环中，直到时间流逝1s。
LoopTest:
	mov eax, timeElapsed
	cmp eax, 1000
	jb LoopTest;
	;end测试

	pop eax
	ret
InitGame endp


end

