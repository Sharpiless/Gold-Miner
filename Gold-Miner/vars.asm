.386
.model flat,stdcall
option casemap:none


.data

; ����
curWindow DWORD 0; ��ǰ���ڴ��ڡ�0Ϊ��ӭ���棬1Ϊ��Ϸ���棬2Ϊ���ؽ��棬3Ϊʧ�ܽ���
public curWindow

; ����
gameX DWORD 0; ��Ч����߶�
public gameX
gameY DWORD 0; ��Ч������
public gameY

; ʱ��
restTime DWORD ?; ��ǰ�ؿ�ʣ��ʱ��(��sΪ��λ)
public restTime

; �÷�
goalScore DWORD 0; ������Ϸ��Ŀ��÷֡�
public goalScore

playerScore DWORD 0; ��ǰ�÷�
public playerScore

; ��
minerPosX DWORD ?
public minerPosX
minerPosY DWORD ?
public minerPosY

; ����
; A 
; ��A���ֱ��������hookODirһ����������model�м��ɡ�����ģ�鶼����Ҫ���ã�
hookStat DWORD ?; ����״̬��0ʱ���ͷţ�1ʱ�ͷ�
public hookStat

hookDir DWORD ?; �����ƶ�����0ʱ�����ƶ���1ʱ�����ƶ�������hookStatΪ1ʱ�����塣
public hookDir

hookOmega DWORD ?; �������ٶȣ�����
public hookOmega

hookV DWORD ?; �������ٶȣ���һ����ֵ�����л���ʱ������ץ������������
public hookV

; B
hookDeg DWORD ?; �����Ƕȣ�ȡֵ��Χ180~360��
public hookDeg

hookPosX DWORD ?; ����λ�ú�����
public hookPosX

hookPosY DWORD ?; ����λ��������
public hookPosY


; ����

lastHit DWORD -1; ��һ�����е����塣 д�����û�������(����)ʱдΪ-1������������ʱ��Ϊ�±ꡣ �������ӷ��ؿ�ʱ���ӷ���Ϊ��������ļ�ֵ
public lastHit

;�ѽṹ��Item�Ķ������vars�У�����Items����Ϊpublic��ע�⣺����Ҫʹ��Items�ĳ��򣬱����Item�ṹ���ٽ���һ�ζ��塣
Item STRUCT
	exist DWORD ?; 1���ڣ�0�Ѳ�����
	typ DWORD ?; ���
	posX DWORD ?; λ�ú�����
	posY DWORD ?; λ��������
	radius DWORD ?; �뾶
	weight DWORD ?; ����
	value DWORD ?; ��ֵ
Item ENDS; һ��ʵ��ռ4*7=28B

Items Item 50 DUP({}); �����б�(�����50������)
public Items

itemNum DWORD 10; ��������
public itemNum

;�̵�
tool1 dd 1
public tool1
tool2 dd 1
public tool2
tool3 dd 1
public tool3
tool4 dd 1
public tool4
tool5 dd 1
public tool5
tool6 dd 1
public tool6


price1 dd 53
public price1
price2 dd 370
public price2
price3 dd 156
public price3
price4 dd 87
public price4
;price5 dd 220
;public price5
;price6 dd 270
;public price6


fireNum dd 0
public fireNum

count dd 0
public count


end

