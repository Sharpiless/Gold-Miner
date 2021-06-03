

# 黄金矿工

## 1.概述

采用MVC架构，model负责根据游戏逻辑维护游戏的全局变量，view负责根据全局变量绘制界面（UI），controller负责响应用户事件。

## 2.全局变量

### 窗口

当前窗口`curWindow`：DD，指示当前所在的游戏界面。0为欢迎界面，1为游戏界面，2为过关界面，3为失败界面。

### 窗体

游戏有效区域的高度和宽度`gameX` `gameY`：DD。

### 时间

本关卡剩余时间`restTime`：DD。（或者设定一个特殊的1min的定时器，减为0时强制根据得分是否达标强制进入过关或失败界面。）

定时器`timer`：每10ms为一个时间片，为游戏的最小时间单元。在每个时间片开始或结束时触发定时器，model维护全局变量，且view根据维护后的全局变量重绘界面。

### 得分

目标得分`goalScore`：DD，本局游戏的目标得分。

当前得分`playerScore`：DD，当前得分。在各关卡累加。仅当用户主动返回菜单或游戏未过关被动结束时清零。

### 矿工

`minerPosX`：DD，矿工位置X坐标。
`minerPosY`：DD，矿工位置Y坐标。

### 物体

`lastHit` DD，上一次命中的物体的下标。

`itemNum` DD，物体数量。

为方便起见，认为物体的**逻辑形状**是圆心位置固定的圆，**视觉形状**是不规则的图形（加载素材）。

描述一个物体的结构体`Item`定义如下：

* 存在`exist`：DD，1存在，0不存在。
* 类型`type`：DD，枚举值，{金块，石头，钻石}。
* X位置`posX`：DD，物体的圆心位置X坐标。
* Y位置`posY`：DD，物体的圆心位置Y坐标。
* 半径`radius`：DD，物体的半径。
* 重量`weight`：DD，与半径有关，例如：与半径成正比。不同类型物品系数不同。系数：石头>金块>钻石。
* 价值`value`：DD，与重量有关，例如：石头价值=石头基础价值 + 重量 x 系数。系数：钻石>金块>石头。

|   类别    |  半径  |    重量    | 价值 |
| :-------: | :----: | :--------: | :--: |
| 0（石头） | 18像素 | 80像素/秒  |  10  |
| 0（石头） | 25像素 | 40像素/秒  |  20  |
| 1（金块） | 10像素 | 120像素/秒 |  50  |
| 1（金块） | 18像素 | 80像素/秒  | 100  |
| 1（金块） | 40像素 | 30像素/秒  | 500  |
| 2（钻石） | 10像素 | 120像素/秒 | 600  |

### 钩索

A：

当前钩索状态`hookStat`：DD，当前钩索是否被释放。1时释放，表现为下一次触发时间片时钩索位置变化，钩索角度不变；0时不释放，表现为下一次触发时间片时钩索角度变化，钩索位置不变。

当前钩索角度移动方向`hookODir`：DD，**仅当hookStat为false时有意义。**为0时向右转，为1时向左转。

当前钩索位置移动方向`hookDir`:  DD，**仅当hookStat为true时有意义。**为0时向下移动（回收），为1时向上移动（下放）。

钩索角速度`hookOmega`，DD，常量。

钩索线速度`hookV`，DD，有一基础值(下放和未命中回收时)，命中回收时依赖于抓到的物体类型。

B：

钩索角度`hookDeg`：DD，取值范围为180~360度。

钩索位置`hookPosX` `hookPosY`：DD。



不同hookStat和hookDir(或hookODir)组合的含义如下：

| hookStat | hook（O）Dir | 含义     |
| -------- | ------------ | -------- |
| 0        | 0（o）       | 向右转   |
| 0        | 1（o）       | 向左转   |
| 1        | 0            | 向下移动 |
| 1        | 1            | 向上移动 |



## 3.控制器

### 用户事件

使用`空格键`释放钩索，即将键盘事件插入事件队列。控制器响应第一个用户事件，据此维护全局变量：`hookStat`置true，`hookDir`置false。

（不知道汇编能不能实现事件队列这种思路）

## 4. 模型

触发定时器时，依次调用以下函数。

根据A写B

### 函数：钩索移动

根据`hookStat`，计算并更新`hookPos`或`hookDeg`。

根据B写A

### 函数：判断钩索是否命中物体

; @brief: 判断钩索是否命中物体。遍历items中所有物体的位置(posX、posY)，判断钩索位置与物体位置的距离是否小于物体半径。
; @read: hookPosX，hookPosY，Items
; @write: lastHit，hookDir，hookV。若命中，写lastHit为命中物体的下标，写hookDir为1，写hookV为f(Items[lastHit].weight)。

### 函数：判断钩索是否出界

; @brief: 判断钩索是否出界或回到矿工手中。
; @read: hookPosX，hookPosY，lastHit
; @write: hootDir，hookStat，Items，playerScore。若出界，写hookDir为1；若回到矿工手中，写hookStat为0，写Items[lastHit].exist为0，写playerScore+=Items[lastHit].value

## 5.视图



## 6. 可能的问题

1. 由于离散刷新，在刷新间隔长且金子半径小的情况下可能“掠过”物体，即未响应应该响应的isHit。解决方法：在下勾时就根据轨迹直线判断能否命中物体，根据点到直线距离小于半径。问题是需要修改程序框架。
2. 坐标问题。计算机坐标系$(x,y)$ = 常规坐标系$(-y',x')$。`hookDeg`在常规坐标系上定义，取值范围$[180,360]$。故当调用moovHook改变钩索位置时，移动增量$(Δx,Δy) = (-ρsinθ, ρcosθ)$，其中 $θ$ 即`hookDeg`， $ρ$ 即`hookV`。

## 7. C语言库

用C语言处理一些计算，避免汇编中繁琐的浮点数运算。

计算两点间距离：

```
// 计算两点间距离
// @params: (x1,y1)第一个点坐标 (x2,y2)第二个点坐标
// @return: ans,int型距离。
extern "C" int calDistance(int x1, int y1, int x2, int y2) {
    int ans = (int)sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
    return ans;
}

```

计算psinθ：

```
// 计算ρsinθ
// @params: theta，角度制，实际取值范围[180, 360]；ρ，极径
// @return: ans
extern "C" int calPSin(int deg, int r) {
    int ans = (int)r*sin(deg * 2 * PI / 360);
    return ans;
}
```

计算pcosθ：

```
// 计算ρcosθ
// @params: 同上
// @return: ans
extern "C" int calPCos(int deg, int r) {
    int ans = (int)r*cos(deg * 2 * PI / 360);
    return ans;
}
```





