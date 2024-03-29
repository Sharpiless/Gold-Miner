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
	exist DWORD ?; 1存在，0已不存在
	typ DWORD ?; 类别
	posX DWORD ?; 位置横坐标
	posY DWORD ?; 位置纵坐标
	radius DWORD ?; 半径
	weight DWORD ?; 重量
	value DWORD ?; 价值
Item ENDS; 一个实例占4*7=28B
extern Items:Item; vars中定义的物体数组

extern tool5:dword; TODO extern语句放在这就能跑了
extern tool6:dword
extern roundNum:dword

printf PROTO C :ptr DWORD, :VARARG
calDistance PROTO C :dword, :dword, :dword, :dword  ; 来自StaticLib1.lib，计算两点间距离
calPSin PROTO C :dword, :dword ; 来自StaticLib1.lib，计算PSinθ
calPCos PROTO C :dword, :dword ; 来自StaticLib1.lib，计算PCosθ

.data
modelMusicgold byte "..\resource\music\gold.mp3", 0
modelMusicstone byte "..\resource\music\stone.mp3", 0
modelMusicbaganddiamond byte "..\resource\music\baganddiamond.mp3", 0
modelMusicback byte "..\resource\music\back.mp3", 0
modelMusicstartstore byte "..\resource\music\startstore.mp3", 0
modelMusicboomb byte "..\resource\music\boomb.mp3", 0

modelMusicgoldP dd 0
modelMusicstoneP dd 0
modelMusicbaganddiamondP dd 0
modelMusicbackP dd 0
modelMusicstartstoreP dd 0
modelMusicboombP dd 0


hookODir DWORD ?; 角速度方向。1朝右，0朝左
timeElapsed DWORD ?; 记录流逝时间（单位ms）

szFmt1 BYTE '物体列表中第%d个元素，exist=%d, typ=%d, posX=%d, posY=%d, radius=%d, weight=%d, value=%d', 0ah, 0
szFmt2 BYTE '%d号计时器响应, 时间已流逝%d ms', 0ah, 0
szFmt3 BYTE '命中第%d个物体！距离=%d, 物体半径=%d', 0ah, 0
szFmt4 BYTE '未命中物体！', 0ah, 0
szFmt5 BYTE '断点...', 0ah, 0
szFmt6 BYTE '待观察寄存器的值=%d', 0ah, 0
szFmt7 BYTE 'In timer, hoosStat=%d, hookODir=%d, hookDir=%d, hookDeg=%d, hookV=%d, hookPosX=%d, hookPosY=%d', 0ah, 0
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
	.if hookDir == 1; 若hookDir为1，向上移动，对ρ（极径，即hookV）取反
		mov ebx, 0
		mov ecx, hookV
		sub ebx, ecx
	.else; 向下移动
		mov ebx, hookV
		inc count; 向下移动时，count++
	.endif

	;Step2.PSin送入eax,并写hookPosX
	invoke calPSin, hookDeg, ebx; Δx = -ρsinΘ
	;当计算精度不够导致Δx计算结果为0时，需要保证Δx不为零。根据不同情况将Δx设为1或-1
	.if eax == 0
		.if hookDir == 0;钩子向下移动
			mov eax, -1
		.else ;钩子向上移动
			mov eax, 1
		.endif
	.endif

	sub hookPosX, eax
	.if lastHit != -1; 若lastHit不为-1，需要带着该物体一起移动（将物体位置设置为与钩子位置相同）
		mov edi, lastHit
		mov eax, hookPosX
		mov Items[edi].posX, eax
	.endif

	;Step3.PCos送入eax，并写hookPosY
	invoke calPCos, hookDeg, ebx; Δy = ρcosΘ
	add hookPosY, eax
	.if lastHit != -1
		mov edi, lastHit
		mov eax, hookPosY
		mov Items[edi].posY, eax
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


fireTNT proc C posX:dword, posY:dword
	pushad
	mov edi, 0; 初始化遍历变量
TraverseForTNT:
	
	.if Items[edi].exist == 1
		invoke calDistance, posX, posY, Items[edi].posX, Items[edi].posY
		mov ebx, 200; 200是爆炸半径
		.if eax<ebx; 比较大小
			; 写exist为0
			mov eax, 0
			mov Items[edi].exist, eax
			; 播放音效
			invoke loadSound,addr modelMusicboomb,addr modelMusicboombP
			invoke playSound,modelMusicboombP,0
			; 若是TNT，递归爆炸
			.if Items[edi].typ == 4  
				invoke fireTNT, Items[edi].posX, Items[edi].posY
			.endif
		.endif
	.endif

	add edi, 28; 增加数组下标。注意现在加的是28，一个结构体元素的大小
	mov eax, itemNum
	mov ebx, 28;
	mul ebx;
	cmp edi, eax; 检查循环是否结束,结束条件：edi==itemNum*28
	jne TraverseForTNT; 循环未结束，进行下一轮循环

	popad
	ret
fireTNT endp





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
		mov ebx, Items[edi].radius
		.if ( tool5 == 0 && Items[edi].typ == 1);拥有磁铁,金子半径+30
			add ebx, 50
		.endif
		cmp eax, ebx; 比较大小
		jb Hit; 距离小于半径，跳转到Hit。相当于break
	.endif

	add edi, 28; 增加数组下标。注意现在加的是28，一个结构体元素的大小
	mov eax, itemNum
	mov ebx, 28;
	mul ebx;
	cmp edi, eax; 检查循环是否结束,结束条件：edi==itemNum*28
	jne LoopTraverseItem; 循环未结束，进行下一轮循环
	jmp Finish; 循环结束且未命中，跳转到Finish

Hit:
	.if Items[edi].typ == 4;TNT
		; 写hookDir为1,并且空勾返回
		mov eax, 1
		mov hookDir, eax
		; 写exist为0，TNT直接爆炸
		mov eax, 0
		mov Items[edi].exist, eax
		; 播放音效
		invoke loadSound,addr modelMusicboomb,addr modelMusicboombP
		invoke playSound,modelMusicboombP,0
		; 递归爆炸
		invoke fireTNT, Items[edi].posX, Items[edi].posY 
		jmp Finish
	.endif

	; 写lastHit为命中物体的下标
	mov eax, edi
	mov lastHit, eax
	; 写hookDir为1
	mov eax, 1
	mov hookDir, eax
	; 写hookV = 物体重量
	mov eax, Items[edi].weight;
	mov hookV, eax
	.if tool3 == 0 ; 若拥有神水，速度*2
		mov eax, Items[edi].weight;
		add hookV, eax
	.endif

	.if Items[edi].typ == 0
		invoke loadSound,addr modelMusicstone,addr modelMusicstoneP
		invoke playSound,modelMusicstoneP,0
	.elseif Items[edi].typ == 1
		invoke loadSound,addr modelMusicgold,addr modelMusicgoldP
		invoke playSound,modelMusicgoldP,0
	.else
		invoke loadSound,addr modelMusicbaganddiamond,addr modelMusicbaganddiamondP
		invoke playSound,modelMusicbaganddiamondP,0
	.endif
	jmp Finish


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

	.if eax > 80000001H; （即eax是负数）钩子回到矿工手中。注意钩索未释放时hookPosX=0，不进入该逻辑。
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
			mov edi, lastHit
			; 加分，写playerScore+=Items[lastHit].value
			mov eax, Items[edi].value
			add playerScore, eax;
			; 删除物体，写Items[lastHit].exist为0
			mov eax, 0
			mov Items[edi].exist, eax 
			invoke loadSound,addr modelMusicback,addr modelMusicbackP
			invoke playSound,modelMusicbackP,0
		.endif

	.elseif eax > gameX; 下出界,写hookDir为1
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > 80000000H; （即ebx是负数）左出界，写hookDir为1
		mov eax, 1
		mov hookDir, eax
	.elseif ebx > gameY; 右出界，写hookDir为1
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
		;重置tool们
		mov tool1, 1
		mov tool2, 1
		mov tool3, 1
		mov tool4, 1
		mov tool5, 1
		mov tool6, 1

		mov eax, goalScore
		.if playerScore >= eax; 过关
			;过关
			inc roundNum
			;切换到商店界面	
			mov eax, 2
			mov curWindow, eax; 
			invoke Flush; 绘制商店界面
			invoke loadSound,addr modelMusicstartstore,addr modelMusicstartstoreP
			invoke playSound,modelMusicstartstoreP,0
		.else ; 未过关。这里需要实现与main中完全相同的全局游戏初始化.
			;设置当前窗口为1
			mov eax, 0
			mov curWindow, eax
			; 重置得分
			mov eax, 0;
			mov playerScore, eax; 
			;重置目标得分
			mov eax, 0
			mov goalScore, eax
			;重置关卡
			mov eax, 0
			mov roundNum, eax
			;设置鞭炮数量
			mov eax, 0
			mov fireNum, eax
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
	.if hookDir == 0; 仅在向下移动时调用IsHit
		invoke IsHit;
	.endif
	invoke IsOut;
	;invoke printf, OFFSET szFmt7, hookStat, hookODir, hookDir, hookDeg, hookV, hookPosX, hookPosY
	invoke Flush; 绘图主调函数
	invoke IsTimeOut
	;invoke printf, OFFSET szFmt2, id, timeElapsed; 打印定时器回调函数信息
	ret
timer endp






;@brief:初始化一局游戏，为一局游戏中用到的全局变量赋初值，注册并启动定时器。
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
	mov eax, 30;
	mov restTime, eax; 剩余时间30s
	mov eax, 0
	mov timeElapsed, 0;  流逝时间

	; 初始化得分
IniScore:
	add goalScore, 400; 目标得分在上一关的基础上增加400


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
	mov eax, 35; 
	mov hookV, eax; 设置线速度（默认为35）

	; B
	mov eax, 270;
	mov hookDeg, eax; 设置hookDeg
	mov eax, minerPosX;
	mov hookPosX, eax; 设置hookPosX（即矿工位置x坐标）
	mov edx, 0
	mov eax, minerPosY;
	mov hookPosY, eax; 设置hookPosY（即矿工位置y坐标）



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


	; 设置exist属性1
	mov eax, 1
	mov Items[edi].exist, eax

	invoke crt_rand; 函数返回随机数存在eax中
	mov edx, 0; 即将使用双字型除法(EDX:EAX)/(SRC)_32
	mov ebx, 10;
	div ebx; 余数0~9放在edx中

	; 设置物体类别
	.if roundNum < 2  ;前两关
		.if edx < 1; 0.1概率为石头
			mov eax, 0
			mov Items[edi].typ, eax
		.else
			.if edx < 5; 0.4概率为金块
				mov eax, 1
				mov Items[edi].typ, eax
			.elseif edx < 7
				mov eax, 2; 0.2概率为钻石
				mov Items[edi].typ, eax
			.elseif edx < 9
				mov eax, 3; 0.2概率为福袋
				mov Items[edi].typ, eax
			.else 
				mov eax, 4; 0.1概率为TNT
				mov Items[edi].typ, eax
			.endif
		.endif
	.elseif roundNum < 4 ;3、4关
		.if edx < 2; 0.2概率为石头
			mov eax, 0
			mov Items[edi].typ, eax
		.else
			.if edx < 6; 0.4概率为金块
				mov eax, 1
				mov Items[edi].typ, eax
			.elseif edx < 7
				mov eax, 2; 0.1概率为钻石
				mov Items[edi].typ, eax
			.elseif edx < 8
				mov eax, 3; 0.1概率为福袋
				mov Items[edi].typ, eax
			.else 
				mov eax, 4; 0.2概率为TNT
				mov Items[edi].typ, eax
			.endif
		.endif
	.else
		.if edx < 2; 0.2概率为石头
			mov eax, 0
			mov Items[edi].typ, eax
		.else
			.if edx < 5; 0.3概率为金块
				mov eax, 1
				mov Items[edi].typ, eax
			.elseif edx < 6
				mov eax, 2; 0.1概率为钻石
				mov Items[edi].typ, eax
			.elseif edx < 7
				mov eax, 3; 0.1概率为福袋
				mov Items[edi].typ, eax
			.else 
				mov eax, 4; 0.3概率为TNT
				mov Items[edi].typ, eax
			.endif
		.endif
	.endif

	.if tool4 == 0; 拥有幸运草，出现福袋的概率提升为33%
		invoke crt_rand; 函数返回随机数存在eax中
		mov edx, 0; 
		mov ebx, 100;
		div ebx; 
		.if edx < 26; 0.1 + 0.9*0.26 = 0.33
			mov eax, 3; 0.1概率为福袋
			mov Items[edi].typ, eax
		.endif
	.endif

	; 设置物体的位置 yyx改，posX范围改为[100,420]
	invoke crt_rand
	mov edx, 0
	mov ebx, 320; PosX的上限
	div ebx; 余数存放在edx中
	add edx, 100
	mov Items[edi].posX, edx

	invoke crt_rand
	mov edx, 0
	mov ebx, 700; posY的上限
	div ebx; 余数存放在edx中
	mov Items[edi].posY, edx

	; 设置物体的半径、重量、价值，需要先判断物体类别

	mov ebx, Items[edi].typ
	.if ebx == 4; TNT
		mov eax, 35
		mov Items[edi].radius, eax
	.endif

	mov ebx, Items[edi].typ
	.if ebx == 3; 福袋

		mov eax, 20
		mov Items[edi].radius, eax

		invoke crt_rand
		mov edx, 0
		mov ebx, 5
		div ebx
		add edx, 5
		mov Items[edi].weight, edx

		invoke crt_rand
		mov edx, 0
		mov ebx, 1200
		div ebx
		add edx, 10
		mov Items[edi].value, edx

	.endif
	mov ebx, Items[edi].typ
	.if ebx == 2; 钻石
		mov eax, 20
		mov Items[edi].radius, eax
		mov eax, 12; 每秒运动120像素
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
			mov eax, 20
			mov Items[edi].radius, eax
			mov eax, 12
			mov Items[edi].weight, eax
			mov eax, 50
			mov Items[edi].value, eax
		.else
			.if edx < 3
				mov eax, 35
				mov Items[edi].radius, eax
				mov eax, 8
				mov Items[edi].weight, eax
				mov eax, 100
				mov Items[edi].value, eax
			.else
				mov eax, 50
				mov Items[edi].radius, eax
				mov eax, 3
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
			mov eax, 20
			mov Items[edi].radius, eax
			mov eax, 8
			mov Items[edi].weight, eax
			mov eax, 10
			mov Items[edi].value, eax
		.else
			mov eax, 35
			mov Items[edi].radius, eax
			mov eax, 4
			mov Items[edi].weight, eax
			mov eax, 20
			mov Items[edi].value, eax
		.endif

		.if tool1 == 0; 若拥有石头收藏书,value*2
			mov eax, Items[edi].value
			add Items[edi].value, eax
		.endif
	.endif

	add edi, 28; 增加数组下标。注意现在加的是28，一个结构体元素的大小
	mov eax, itemNum
	mov ebx, 28;
	mul ebx;
	cmp edi, eax; 检查循环是否结束,结束条件：edi==itemNum*28
	jne RandLoop  ; 循环未结束，进行下一轮循环


	;注册并启动定时器。（当阻塞在main中的init_second时，定时器工作）
	invoke registerTimerEvent, offset timer  ;注册定时器回调函数timer
	invoke startTimer, 0, 100  ; 定时器编号为0，刷新间隔为100ms



	popad
	ret
InitGame endp


end

