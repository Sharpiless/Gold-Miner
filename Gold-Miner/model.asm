.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib
includelib StaticLib1.lib

include include\vars.inc
include include\acllib.inc
include include\msvcrt.inc
include include\view.inc

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
timeElapsed DWORD ?; 记录流逝时间（单位ms）

szFmt1 BYTE '物体列表中第%d个元素，exist=%d, typ=%d, posX=%d, posY=%d, radius=%d, weight=%d, value=%d', 0ah, 0
szFmt2 BYTE '%d号计时器响应, 时间已流逝%d ms', 0ah, 0
szFmt3 BYTE '命中第%d个物体！距离=%d, 物体半径=%d', 0ah, 0
szFmt4 BYTE '未命中物体！', 0ah, 0
szFmt5 BYTE '断点...', 0ah, 0
szFmt6 BYTE 'eax=%d', 0ah, 0
szFmt7 BYTE 'In timer, hoosStat=%d, hookODir=%d, hookDeg=%d, hookV=%d, hookPosX=%d, hookPosY=%d', 0ah, 0
szFmt8 BYTE '随机初始化第%d个物体...posX=%d, posY=%d, radius=%d, typ=%d', 0ah, 0



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
	
	;Step1.hookV送入ebx
	.if hookDir == 1; 若hookDir为1，对ρ（极径，即hookV）取反
		mov ebx, 0
		mov ecx, hookV
		sub ebx, ecx
	.else
		mov ebx, hookV
	.endif

	;Step2.PSin送入eax,并写hookPosX
	invoke calPSin, hookDeg, ebx; Δx = -ρsinΘ
	sub hookPosX, eax
	.if lastHit != -1; 若lastHit不为-1，需要带着该物体一起移动
		mov edi, lastHit
		sub Items[edi].posX, eax
	.endif

	;Step3.PCos送入eax，并写hookPosY
	invoke calPCos, hookDeg, ebx; Δy = ρcosΘ
	add hookPosY, eax
	.if lastHit != -1
		mov edi, lastHit
		add Items[edi].posY, eax
	.endif
	
	jmp FinishMoveHook
ChangeDeg: ; 改变钩索角度
	mov eax, hookOmega; 读hookOmega
	.if hookODir == 0; 读hookODir，向右转

		mov ebx, 360
		mov ecx, hookOmega
		sub ebx, ecx
		.if hookDeg >= ebx ; 若到达右端尽头(不够加)，即hookDeg>360-hookOmega,不移动，并反转钩索角速度
			mov ebx, 1
			mov hookODir, ebx
		.else 
			add hookDeg, eax ; 写hookDeg，正常移动
		.endif

	.else ; 向左转
		mov ebx, 180
		mov ecx, hookOmega
		add ebx, ecx
		.if hookDeg <= ebx ; 若到达左端尽头(不够减)，即hookDeg<180+hookOmega,不移动，并反转钩索角速度
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
	mov edi, 0; 初始化遍历变量
LoopTraverseItem:
	
	; 读hookPosX，hookPosY，Items，将计算得到的距离存入eax。
	.if Items[edi].exist == 1
		invoke calDistance, hookPosX, hookPosY, Items[edi].posX, Items[edi].posY
		cmp eax, Items[edi].radius;比较大小
		jb Hit; 距离小于半径，跳转到Hit。相当于break
	.endif

	add edi, 28; 增加数组下标。注意现在加的是28，一个结构体元素的大小
	mov eax, itemNum
	mov ebx, 28;
	mul ebx;
	cmp edi, eax; 检查循环是否结束,结束条件：edi==itemNum*28
	jne LoopTraverseItem; 循环未结束，进行下一轮循环
	jmp NotHit; 循环结束且未命中，跳转到NotHit

Hit:
	;invoke printf, OFFSET szFmt3, edi, eax, Items[edi].radius; 打印命中信息，eax是距离
	; 写lastHit为命中物体的下标
	mov eax, edi
	mov lastHit, eax
	; 写hookDir为1
	mov eax, 1
	mov hookDir, eax
	; 写hookV = 物体重量
	mov ebx, Items[edi].weight;
	mov hookV, ebx
	jmp Finish
NotHit:
	;invoke printf, OFFSET szFmt4; 打印未命中信息

Finish:
	popad
	ret
IsHit endp

; @brief: 判断钩索是否出界或回到矿工手中。
; @read: hookPosX，hookPosY，lastHit
; @write: hootDir，hookStat，hookPosX,hookPosY，Items，playerScore。若出界，写hookDir为1；
; 若回到矿工手中，写hookStat为0，写hookPosX、hookPosY为矿工位置，写Items[lastHit].exist为0，写playerScore+=Items[lastHit].value
IsOut proc C
	pushad
	mov eax, hookPosX; 读hookPosX
	mov ebx, hookPosY; 读hookPosY
	
	;测试:打印hookPosX
	;push eax
	;invoke printf, OFFSET szFmt6, eax
	;pop eax
	;end测试

	.if eax > 80000001H; 钩子回到矿工手中。注意钩索未释放时hookPosX=0，不进入该逻辑。 <0不达意
		;invoke printf, OFFSET szFmt5; 测试断点
		
		; 写hookStat为0
		mov eax, 0
		mov hookStat, eax
		; 写hookPosX、hookPosY为矿工位置
		mov eax, minerPosX
		mov hookPosX, eax
		mov eax, minerPosY
		mov hookPosY, eax
		
		.if lastHit != -1 ; 读lastHit，若不为-1，加分并删除物体
			; 加分，写playerScore+=Items[lastHit].value
			mov edi, lastHit
			mov eax, Items[edi].value
			add playerScore, eax;
			; 删除物体，写Items[lastHit].exist为0
			mov eax, 0
			mov Items[edi].exist, eax 
		.endif

	.elseif eax > gameX; 下出界,写hookDir为1
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > 80000000H; 左出界 <0不达意
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > gameY; 右出界
		mov eax, 1
		mov hookDir, eax
	.endif

	popad
	ret
IsOut endp


; @brief: 时间结束，根据分数是否到达目标分数切换界面强制切换到商店界面
IsTimeOut proc C
	; timeElapsed对1000取余，若余数为0，restTime--
	mov edx, 0
	mov eax, timeElapsed
	mov ebx, 1000
	div ebx ; 余数在edx中
	.if edx == 0
		dec restTime;  时间减少1s
	.endif

	.if restTime == 0; 时间结束，强制切换界面
		invoke cancelTimer, 0  ; 取消定时器
		mov eax, goalScore
		.if playerScore >= eax; 过关
			mov eax, 2
			mov curWindow, eax; 切换到商店界面	
			invoke Flush; 绘制商店界面
		.else ; 未过关 TODO
			mov eax, 0
			mov curWindow, eax;
			; 重置得分
			mov eax, 0
			mov playerScore, eax; 
			; 重置目标得分
			mov eax, 0
			mov goalScore, eax
			invoke Flush; 绘制欢迎界面
		.endif
	.endif
	ret
IsTimeOut endp

;@brief:定时器回调函数。每次触发定时器，调用MoveHook移动钩索，并调用IsHit和IsOut
;@param:定时器id
timer proc C id:dword
	add timeElapsed, 100; 维护流逝的时间，单位ms
	;invoke printf, OFFSET szFmt2, id , timeElapsed
	invoke MoveHook; 移动钩索
	invoke IsHit;
	invoke IsOut;
	;invoke printf, OFFSET szFmt7, hookStat, hookODir, hookDeg, hookV, hookPosX, hookPosY
	invoke Flush; 绘图主调函数
	invoke IsTimeOut
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

	; 初始化时间
IniTime:
	mov eax, 30
	mov restTime, eax; 剩余时间30s
	mov eax, 0
	mov timeElapsed, 0;  流逝时间

	; 初始化得分
IniScore:
	add goalScore, 500; 目标得分在上一关的基础上增加500


	; 初始化矿工
IniMiner:
	mov eax, 0; 
	mov minerPosX, eax; 设置minerPosX，初始化为0
	mov eax, gameY; 被除数edx:eax
	mov ebx, 2; 除数
	div ebx; 除法的商保存在eax中
	mov minerPosY, eax; 设置minerPosY，初始化为gameY/2

	; 初始化钩子变量
IniHook:
	; A
	mov eax, 0;
	mov hookStat, eax; 设置hookStat
	mov eax, 0; 
	mov hookODir, eax; 设置hookODir，初始化为0
	mov eax, 0; 
	mov hookDir, eax; 设置hookDir, 初始化为0
	mov eax, 5; 
	mov hookOmega, eax; 设置角速度为2
	mov eax, 50; 
	mov hookV, eax; 设置线速度（默认为50）

	; B
	mov eax, 270; 
	mov hookDeg, eax; 设置hookDeg
	mov eax, minerPosX;
	mov hookPosX, eax; 设置hookPosX（即矿工位置x坐标）
	mov edx, 0
	mov eax, minerPosY;
	mov hookPosY, eax; 设置hookPosY（即矿工位置y坐标）


	;测试：向物体列表中某个元素赋值。实际中替换为随机初始化物体列表。(成功)
;IniItem:
	;mov edi, 0; 数组偏移，开始设为0
	;mov eax, 1; 
	;mov Items[edi].exist, eax; 设置第一个物体的exist是1。由于exist字段占四个字节，所以源操作数是eax。
	;mov eax, 0; 
	;mov Items[edi].typ, eax; 设置typ
	;mov eax, 350;
	;mov Items[edi].posX, eax; 设置位置
	;mov Items[edi].posY, eax;
	;mov eax, 30;
	;mov Items[edi].radius, eax; 设置半径为15
	;mov eax, 10;
	;mov Items[edi].weight, eax; 设置重量为10
	;mov Items[edi].value, eax; 设置价值为10
	;invoke	printf, OFFSET szFmt1, edi, Items[edi].exist, Items[edi].typ, Items[edi].posX, Items[edi].posY, Items[edi].radius, Items[edi].weight, Items[edi].value; 打印查看赋值是否成功。
	;end测试

	; 随机初始化物体列表
	; 用时间作为随机数种子
	push 0
	call crt_time
	add esp, 4
	push eax
	call crt_srand
	add esp, 4

	mov edi, 0; 数组偏移初值
RandLoop:

	;edi*28作为偏移量，存入ecx，取结构体数组中第edi个元素。
	;mov eax, edi;
	;mov ecx, 28;
	;mul ecx;
	;mov ecx, eax;

	; exist属性赋为1
	mov eax, 1
	;mov Items[ecx].exist, eax
	mov Items[edi].exist, eax

	invoke crt_rand; 函数返回随机数存在eax中
	mov edx, 0; 即将使用双字型除法(EDX:EAX)/(SRC)_32
	mov ebx, 10;
	div ebx; 余数0~9放在edx中

	.if edx < 3; 0.3概率为石头
		mov eax, 0
		mov Items[edi].typ, eax
	.else
		.if edx < 8; 0.5概率为金块
			mov eax, 1
			mov Items[edi].typ, eax
		.else
			mov eax, 2; 0.2概率为钻石
			mov Items[edi].typ, eax
		.endif
	.endif

	invoke crt_rand
	mov edx, 0
	mov ebx, 420; PosX的上限
	div ebx; 余数存放在edx中
	mov Items[edi].posX, edx

	invoke crt_rand
	mov edx, 0
	mov ebx, 700; posY的上限
	div ebx; 余数存放在edx中
	mov Items[edi].posY, edx

	; 设置物体的半径、重量、价值，需要先判断物体类别
	mov ebx, Items[edi].typ
	.if ebx == 2; 钻石
		mov eax, 10
		mov Items[edi].radius, eax
		mov eax, 120; 每秒运动120像素
		mov Items[edi].weight, eax
		mov eax, 600
		mov Items[edi].value, eax
	.endif

	mov ebx, Items[edi].typ
	.if ebx == 1; 金块
		invoke crt_rand; 随机金块尺寸，设定为2:1:1
		mov edx, 0
		mov ebx, 4
		div ebx

		.if edx < 2; 最小尺寸的金块
			mov eax, 10
			mov Items[edi].radius, eax
			mov eax, 120
			mov Items[edi].weight, eax
			mov eax, 50
			mov Items[edi].value, eax
		.else
			.if edx < 3
				mov eax, 18
				mov Items[edi].radius, eax
				mov eax, 80
				mov Items[edi].weight, eax
				mov eax, 100
				mov Items[edi].value, eax
			.else
				mov eax, 40
				mov Items[edi].radius, eax
				mov eax, 30
				mov Items[edi].weight, eax
				mov eax, 500
				mov Items[edi].value, eax
			.endif
		.endif
	.endif

	mov ebx, Items[edi].typ
	.if ebx == 0; 石头
		invoke crt_rand; 随机石头尺寸，设定为1:1
		mov edx, 0
		mov ebx, 2
		div ebx
		.if edx < 1; 最小尺寸的石头
			mov eax, 18
			mov Items[edi].radius, eax
			mov eax, 80
			mov Items[edi].weight, eax
			mov eax, 10
			mov Items[edi].value, eax
		.else
			mov eax, 25
			mov Items[edi].radius, eax
			mov eax, 40
			mov Items[edi].weight, eax
			mov eax, 20
			mov Items[edi].value, eax
		.endif
	.endif

	add edi, 28; 增加数组下标。注意现在加的是28，一个结构体元素的大小
	mov eax, itemNum
	mov ebx, 28;
	mul ebx;
	cmp edi, eax; 检查循环是否结束,结束条件：edi==itemNum*28
	jne RandLoop  ; 循环未结束，进行下一轮循环


	;测试：随机初始化是否正确
	;mov edi, 0; 数组偏移初值
;Test1:
	;invoke printf, OFFSET szFmt8, edi, Items[edi].posX, Items[edi].posY, Items[edi].radius, Items[edi].typ; 测试结果
	;add edi, 28; 增加数组下标。注意现在加的是28，一个结构体元素的大小
	;mov eax, itemNum
	;mov ebx, 28;
	;mul ebx;
	;cmp edi, eax; 检查循环是否结束
	;jne Test1  ; 循环未结束，进行下一轮循环
	;end测试

	

	;测试：手动调用MoveHook移动。
	;invoke MoveHook
	;end测试

	;测试：手动调用isHit和isOut
	;invoke IsHit
	;invoke IsOut
	;end测试

	;测试：注册并启动定时器。（成功，当阻塞在main中的init_second时，定时器工作）
	invoke registerTimerEvent, offset timer  ;注册定时器回调函数timer
	invoke startTimer, 0, 100  ; 定时器编号为0，刷新间隔为10ms
	;end测试


	;测试：阻塞在一个空循环中，直到时间流逝1s。（不成功）
;LoopTest:
	;mov eax, timeElapsed
	;cmp eax, 1000
	;jb LoopTest;
	;end测试

	popad
	ret
InitGame endp


end

