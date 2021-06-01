.386
.model flat,stdcall
option casemap:none


.data

; 窗口
curWindow DWORD 0; 当前所在窗口。0为欢迎界面，1为游戏界面，2为过关界面，3为失败界面
public curWindow

; 窗体
gameX DWORD 0;
public gameX
gameY DWORD 0;
public gameY

; 游戏
goalScore DWORD 0; 本局游戏的目标得分。
public goalScore

playerScore DWORD 0; 当前得分
public playerScore

; 钩索
; A(这部分变量好像和hookODir一样，定义在model中即可。其他模块都不需要调用)
hookStat DWORD ?; 钩索状态。0时不释放，1时释放
public hookStat

hookDir DWORD ?; 钩索移动方向。0时向下移动，1时向上移动。仅当hookStat为1时有意义。
public hookDir

hookOmega DWORD ?; 钩索角速度，常量
public hookOmega

hookV DWORD ?; 钩索线速度，有一基础值，命中回收时依赖于抓到的物体类型
public hookV

; B
hookDeg DWORD 0; 钩索角度，取值范围180~360度
public hookDeg

hookPosX DWORD 0; 钩索位置横坐标
public hookPosX

hookPosY DWORD 0; 钩索位置纵坐标
public hookPosY



;TODO 把结构体的定义放在vars中，并将Items设置为public。注意：所有要使用Items的程序，必须对Item结构体再进行一次定义。
Item STRUCT
	exist DWORD ?; 1存在，0已不存在（得分）
	typ DWORD ?; 类别
	posX DWORD ?; 位置横坐标
	posY DWORD ?; 位置纵坐标
	radius DWORD ?; 半径
	weight DWORD ?; 重量
	value DWORD ?; 价值
Item ENDS; 一个实例占4*7=28B

itemNum DWORD 10; 物体数量
public itemNum

Items Item 50 DUP({}); 物体列表(最多有50个物体)
public Items

end

