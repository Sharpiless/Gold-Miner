.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
includelib acllib.lib

include include\vars.inc
include include\model.inc
include include\acllib.inc
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
extern price5:dword
extern price6:dword

printf PROTO C :ptr DWORD, :VARARG
calPSin PROTO C :dword, :dword ; 来自StaticLib1.lib，计算PSinθ
calPCos PROTO C :dword, :dword ; 来自StaticLib1.lib，计算PCosθ


.data

modelMusicset_xpx byte "..\resource\music\set_xpx.mp3", 0
modelMusicboomb byte "..\resource\music\boomb.mp3", 0
modelMusicstartgame byte "..\resource\music\startgame.mp3", 0

modelMusicset_xpxP dd 0
modelMusicboombP dd 0
modelMusicstartgameP dd 0



coord sbyte "鼠标点击 %d,%d",0ah,0
strSpace sbyte "按下空格", 0ah, 0
strLeft sbyte "按下向左", 0ah, 0
strRight sbyte "按下向右", 0ah, 0




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
	

; 键盘事件回调函数
iface_keyboardEvent proc C key:dword, event:dword
	pushad
	mov ecx,event
	cmp ecx,KEY_DOWN
	jne not_press; 若事件不是按下键盘，则不触发任何逻辑

	
	.if curWindow == 1
		.if (key == VK_SPACE && fireNum > 0 && hookDir == 1 && lastHit != -1); 空格，释放鞭炮。仅当拥有鞭炮时触发
			invoke printf, offset strSpace
			; 鞭炮数量-1
			dec fireNum 
			; 写hookStat为0
			mov eax, 0
			mov hookStat, eax
			; 写hookPosX、hookPosY为矿工位置
			mov eax, minerPosX
			mov hookPosX, eax
			mov eax, minerPosY
			mov hookPosY, eax
		
			; 删除物体，写Items[lastHit].exist为0
			mov edi, lastHit
			mov eax, 0
			mov Items[edi].exist, eax 

			invoke loadSound,addr modelMusicboomb,addr modelMusicboombP
			invoke playSound,modelMusicboombP,0
		.endif

		.if ((key == VK_LEFT || key == VK_RIGHT) && tool6 == 0 && hookDir == 0); 微调 tool6==0
			.if key == VK_LEFT; 向左
				invoke printf, offset strLeft
				sub hookDeg, 2	
			.else; 向右
				invoke printf, offset strRight
				add hookDeg, 2
			.endif
			
			; TODO 根据最新的Deg算出对应的posX
			mov eax, hookV; 乘数放在eax中
			mov ebx, count
			mul ebx; 乘法结果在eax中
			
			invoke calPSin, hookDeg, eax; Δx = -ρsinΘ
			mov ebx, minerPosX; hookPosX赋值为minerPosX+Δx
			mov hookPosX, ebx
			sub hookPosX, eax

			; TODO 根据最新的Deg算出对应的posY
			mov eax, hookV; 乘数放在eax中
			mov ebx, count
			mul ebx; 乘法结果在eax中
			invoke calPCos, hookDeg, eax; 
			mov ebx, minerPosY;hookPosY赋值为minerPosY+ΔY
			mov hookPosY, ebx
			add hookPosY, eax
			
		.endif
	.endif

not_press:
	popad
	ret

iface_keyboardEvent endp

; 鼠标事件回调函数
iface_mouseEvent proc C x:dword,y:dword,button:dword,event:dword
	pushad; 将所有寄存器压入栈中，暂存寄存器的值
	mov ecx,event
	cmp ecx,BUTTON_DOWN
	jne not_click; 若事件不是鼠标点击，则不触发任何逻辑
	
	invoke printf,offset coord,x,y ;测试：打印用户点击的坐标

	.if curWindow == 0; 在欢迎界面
		invoke is_inside_the_rect,x,y,0,700,0,500;
		.if eax == 1; 
			; 窗体设为1
			mov eax, 1
			mov curWindow, eax
			invoke InitGame
			invoke loadSound,addr modelMusicstartgame,addr modelMusicstartgameP
			invoke playSound,modelMusicstartgameP,0
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
			mov count, 0 ; 初始化count，用于矫正posX和posY
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,630,700,30,45; 点击第一个商品，石头收藏书
		;矩形范围：630，30，？，15
		.if eax == 1; 点击菜单，回到欢迎界面
			;重置tool们
			mov tool1, 1
			mov tool2, 1
			mov tool3, 1
			mov tool4, 1
			mov tool5, 1
			mov tool6, 1
			;设置当前窗口为1
			mov eax, 0
			mov curWindow, eax
			;重置得分
			mov eax, 0
			mov playerScore, eax; 
			;重置目标得分
			mov eax, 0
			mov goalScore, eax
			;设置鞭炮数量
			mov eax, 0
			mov fireNum, eax
			invoke Flush; 绘制欢迎界面
		.endif



	.elseif curWindow == 2; 在商店
		invoke is_inside_the_rect,x,y,200,700,350,400; 点击"next game"区域
		;next game矩形范围：200，350，500，50
		.if eax == 1; 
			; 窗体设为1
			mov eax, 1
			mov curWindow, eax
			invoke InitGame
			invoke loadSound,addr modelMusicstartgame,addr modelMusicstartgameP
			invoke playSound,modelMusicstartgameP,0
		.endif

		invoke is_inside_the_rect,x,y,400,460,150,210 ; 点击第一个商品，石头收藏书
		;矩形范围：400，150，80，80
		.if eax == 1
			mov eax, price1
			.if playerScore > eax
				sub playerScore, eax; 得分减少
				mov tool1, 0 ; 购买
				invoke Flush; 刷新界面
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,340,400,150,210 ; 点击第二个商品，鞭炮
		;矩形范围：300，150，80，80
		.if eax == 1
			mov eax, price2
			.if playerScore > eax
				sub playerScore, eax; 得分减少
				mov tool2, 0 ; 购买
				inc fireNum
				invoke Flush; 刷新界面
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,280,340,150,210 ; 点击第三个商品，神水
		;矩形范围：200，150，80，80
		.if eax == 1
			mov eax, price3
			.if playerScore > eax
				sub playerScore, eax; 得分减少
				mov tool3, 0 ; 购买
				invoke Flush; 刷新界面
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,220,280,150,210 ; 点击第四个商品，幸运草
		;矩形范围：100，150，80，80
		.if eax == 1
			mov eax, price4
			.if playerScore > eax
				sub playerScore, eax; 得分减少
				mov tool4, 0 ; 购买
				invoke Flush; 刷新界面
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,160,220,150,210 ;TODO 点击第五个商品，磁铁
		.if eax == 1
			mov eax, price5
			.if playerScore > eax
				sub playerScore, eax; 得分减少
				mov tool5, 0 ; 购买
				invoke Flush; 刷新界面
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif

		invoke is_inside_the_rect,x,y,100,160,150,210 ;TODO 点击第六个商品，电动勾

		.if eax == 1
			mov eax, price6
			.if playerScore > eax
				sub playerScore, eax; 得分减少
				mov tool6, 0 ; 购买
				invoke Flush; 刷新界面
			.endif
			invoke loadSound,addr modelMusicset_xpx,addr modelMusicset_xpxP
			invoke playSound,modelMusicset_xpxP,0
		.endif


	
	.endif
					
not_click:
	popad; 弹出寄存器的值
	ret 
iface_mouseEvent endp

end
