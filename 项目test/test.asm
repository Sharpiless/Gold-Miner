.386
.model flat,stdcall
option casemap:none

includelib msvcrt.lib
include include\utils.inc

printf PROTO C :ptr dword,:VARARG
testProc PROTO C


.data
szFmt1 byte '第%d个元素，值为%d', 0ah, 0
szFmt2 byte '第%d个元素，Years=%d', 0ah, 0
szFmt3 byte '第%d个元素，IdNum=%s', 0ah, 0
szFmt4 byte 'eax=%d', 0ah, 0

;定义一个结构体
Employee STRUCT
	IdNum BYTE "000000000"; 9个字节
	Lastname BYTE 5 DUP(1) ; 5个字节
	Years WORD 2; 2个字节
	SalaryHistory DWORD 3,3,3,3; 16个字节
Employee ENDS; 共32个字节

worker1 Employee {"123456789"}; 创建结构体实例，并为其成员赋初值
workerCount = 10; 数组中10个元素

department Employee workerCount DUP({});  创建结构体数组。类比 psin dd 360 DUP(0)。debug时&department定位数组的位置
array byte 10 DUP(1); 创建dd数组。（先弄一个元素类型为byte的简单数组看看）


var dword 10

.code  

main proc C
	;invoke testProc; 调用initGame
	mov edi,0; 访问数组的偏移量
	mov eax,8;
	;亲测可用，为结构体数组中某个实例赋值。因为Years成员的长度是WORD，因此源操作数应该是ax
	mov department[edi].Years, ax
	;亲测可用，打印结构体实例。debug时&worker1.Idnum定位该成员的位置
	invoke printf, offset worker1.IdNum;  
	
	;亲测可用，打印数组中某个元素
	;invoke printf, offset szFmt1, edi, array[edi*4]
	;亲测可用，打印结构体数组中某个元素的成员
	invoke printf, offset szFmt2, edi, department[edi].Years
	;打印字符串成员时，有点问题，没有串尾结束标志，停不下来
	;invoke printf, offset szFmt3, edi, department[edi].IdNum

	;测试减法减为负数的情况
	mov eax, 5;
	sub eax, 6;
	.if eax<0; 注意：比较时将eax当作无符号数，因此这样做无法实现判定一个数是否为负。
		invoke printf, offset szFmt4, eax
	.else
		invoke printf, offset szFmt4, 100
	.endif
	;end测试



main endp

end main
		