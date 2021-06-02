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
calDistance PROTO C :dword, :dword, :dword, :dword  ; 来自StaticLib1.lib，计算两点间距离
calPSin PROTO C :dword, :dword ; 来自StaticLib1.lib，计算PSinθ
calPCos PROTO C :dword, :dword ; 来自StaticLib1.lib，计算PCosθ

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




; @brief: 移动钩索。
; @read: hookStat，hookODir，hookOmega，hookDir，hookV
; @write: hookDeg，hookPosX，hookPosY。若hookStat为0，写hookDeg；反之写hookPosX和hookPosY。
MoveHook proc C 
	pushad
	
	cmp hookStat, 0; 读hookStat
	jz ChangeDeg
ChangePos: ;改变钩索位置
	;TODO 若lastHit不为-1，需要带着该物体一起移动

	jmp FinishMoveHook
ChangeDeg: ; 改变钩索角度
	mov eax, hookOmega; 读hookOmega
	.if hookODir == 0; 读hookODir，向右转

		mov ebx, 360
		mov ecx, hookOmega
		sub ebx, ecx
		.if hookDeg > ebx ; 若到达右端尽头(不够加)，即hookDeg>360-hookOmega,不移动，并反转钩索角速度
			mov ebx, 1
			mov hookODir, ebx
		.else 
			add hookDeg, eax ; 写hookDeg，正常移动
		.endif

	.else ; 向左转
		mov ebx, 180
		mov ecx, hookOmega
		add ebx, ecx
		.if hookDeg < ebx ; 若到达左端尽头(不够减)，即hookDeg<180+hookOmega,不移动，并反转钩索角速度
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



; @brief: 判断钩索是否命中物体。遍历items中所有物体的位置(posX、posY)，判断钩索位置与物体位置的距离是否小于物体半径。
; @read: hookPosX，hookPosY，Items
; @write: lastHit，hookDir，hookV。若命中，写lastHit为命中物体的下标，写hookDir为1，写hookV为f(Items[lastHit].weight)。
IsHit proc C
	pushad
	mov edi, 0; 遍历初值
LoopTraverseItem:
	
	; 读hookPosX，hookPosY，Items，将计算得到的距离存入eax。
	invoke calDistance, hookPosX, hookPosY, Items[edi].posX, Items[edi].posY
	cmp eax, Items[edi].radius;比较大小
	jb Hit; 距离小于半径，跳转到Hit
	
	inc edi; 遍历变量++
	cmp edi, itemNum; 检查遍历是否结束
	jb LoopTraverseItem
	jmp NotHit; 未命中，跳转到NotHit

Hit:
	invoke printf, OFFSET szFmt3, edi, eax, Items[edi].radius; 打印命中信息，eax是距离
	; 写lastHit为命中物体的下标
	mov eax, edi
	mov lastHit, eax
	; 写hookDir为1
	mov eax, 1
	mov hookDir, eax
	; hookV = 100-物体重量（f具体表达式待定）
	mov ebx, 100;
	sub ebx, Items[edi].weight;
	mov hookV, ebx
	jmp Finish
NotHit:
	invoke printf, OFFSET szFmt4; 打印未命中信息

Finish:
	popad
	ret
IsHit endp

; @brief: 判断钩索是否出界或回到矿工手中。
; @read: hookPosX，hookPosY，lastHit
; @write: hootDir，hookStat，Items，playerScore。若出界，写hookDir为1；
; 若回到矿工手中，写hookStat为0，写Items[lastHit].exist为0，写playerScore+=Items[lastHit].value
IsOut proc C
	pushad
	mov eax, hookPosX; 读hookPosX
	mov ebx, hookPosY; 读hookPosY

	.if eax > gameX; 下出界,写hookDir为1
		mov eax, 1
		mov hookDir, eax
	.elseif ebx < 0; 左出界
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > gameY; 右出界
		mov eax, 1
		mov hookDir, eax

	.elseif eax < 0; 钩子回到矿工手中。注意钩索未释放时hookPosX=0，不进入该逻辑。
		; 写hookStat为0
		mov eax, 0
		mov hookStat, eax
		.if lastHit != -1 ; 读lastHit，若不为-1，加分并删除物体
			; 加分，写playerScore+=Items[lastHit].value
			mov edi, lastHit
			mov eax, Items[edi].value
			add playerScore, eax;
			; 删除物体，写Items[lastHit].exist为0
			mov eax, 0
			mov Items[edi].exist, eax 
		.endif
		

	.endif

	popad
	ret
IsOut endp

;@brief:定时器回调函数。每次触发定时器，调用MoveHook移动钩索，并调用IsHit和IsOut
;@param:定时器id
timer proc C id:dword
	add timeElapsed, 10; 维护流逝的时间
	invoke MoveHook; 移动钩索
	invoke IsHit;
	invoke IsOut;
	;TODO invoke绘图函数
	;invoke printf, OFFSET szFmt2, id, timeElapsed; 打印定时器回调函数信息
	ret
timer endp


;@brief:初始化游戏，为一局游戏中用到的全局变量赋初值，注册并启动定时器。
InitGame proc C
	pushad

	; 初始化窗体
IniGameSize:
	mov eax, 420
	mov gameX, eax; 窗体高度420
	mov eax, 700
	mov gameY, eax; 窗体宽度700

	; 初始化钩子变量
IniHook:
	; A
	mov eax, 0; 
	mov hookStat, eax; 设置hookStat，初始化为0
	mov eax, 1; 
	mov hookODir, eax; 设置hookODir，初始化为1
	mov eax, 0; 
	mov hookDir, eax; 设置hookDir, 初始化为0
	mov eax, 2; 
	mov hookOmega, eax; 设置角速度为2
	mov eax, 10; 
	mov hookV, eax; 设置线速度（默认为10）

	; B
	mov eax, 180; 
	mov hookDeg, eax; 设置hookDeg，初始化为180
	mov eax, 0; 
	mov hookPosX, eax; 设置hookPosX，初始化为0（即矿工位置x坐标）
	mov edx, 0
	mov eax, gameY; 被除数edx:eax
	mov ebx, 2; 除数
	div ebx; 除法的商保存在eax中
	mov hookPosY, eax; 设置hookPosY，初始化为gameY/2（即矿工位置纵坐标）


	;测试：向物体列表中某个元素赋值。实际中替换为随机初始化物体列表。(成功)
IniItem:
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

	;测试：calPSin和calPCos是否正常工作（成功）
	invoke calPSin, 0, 10; 第一个参数是角度（角度制），第二个参数是极径
	invoke calPSin, 30, 10
	invoke calPSin, 45, 10
	invoke calPSin, 60, 10
	invoke calPSin, 90, 10
	invoke calPSin, 180, 10
	invoke calPSin, 360, 10
	invoke calPCos, 0, 10
	invoke calPCos, 90, 10
	invoke calPCos, 180, 10
	invoke calPCos, 360, 10
	;end测试

	;测试：手动调用MoveHookTest移动。（成功）
	invoke MoveHookTest
	;end测试

	;测试：手动调用isHit和isOut
	invoke IsHit
	invoke IsOut
	;end测试

	;测试：注册并启动定时器。（未成功，现在定时器不work）
	invoke registerTimerEvent, offset timer  ;注册定时器回调函数timer
	invoke startTimer, 0, 10  ; 定时器编号为0，刷新间隔为10ms
	;end测试

	;测试：测试定时器是否work，阻塞在一个空循环中，直到时间流逝1s。
LoopTest:
	mov eax, timeElapsed
	cmp eax, 1000
	jb LoopTest;
	;end测试

	popad
	ret
InitGame endp


end

