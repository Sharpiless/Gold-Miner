.386
.model flat,stdcall
option casemap:none


.data

; ����
curWindow DWORD 0; ��ǰ���ڴ��ڡ�0Ϊ��ӭ���棬1Ϊ��Ϸ���棬2Ϊ���ؽ��棬3Ϊʧ�ܽ���
public curWindow

; ����
gameX DWORD 0;
public gameX
gameY DWORD 0;
public gameY

; ��Ϸ
goalScore DWORD 0; ������Ϸ��Ŀ��÷֡�
public goalScore

playerScore DWORD 0; ��ǰ�÷�
public playerScore

; ����
; A(�ⲿ�ֱ��������hookODirһ����������model�м��ɡ�����ģ�鶼����Ҫ����)
hookStat DWORD ?; ����״̬��0ʱ���ͷţ�1ʱ�ͷ�
public hookStat

hookDir DWORD ?; �����ƶ�����0ʱ�����ƶ���1ʱ�����ƶ�������hookStatΪ1ʱ�����塣
public hookDir

hookOmega DWORD ?; �������ٶȣ�����
public hookOmega

hookV DWORD ?; �������ٶȣ���һ����ֵ�����л���ʱ������ץ������������
public hookV

; B
hookDeg DWORD 0; �����Ƕȣ�ȡֵ��Χ180~360��
public hookDeg

hookPosX DWORD 0; ����λ�ú�����
public hookPosX

hookPosY DWORD 0; ����λ��������
public hookPosY



;TODO �ѽṹ��Ķ������vars�У�����Items����Ϊpublic��ע�⣺����Ҫʹ��Items�ĳ��򣬱����Item�ṹ���ٽ���һ�ζ��塣
Item STRUCT
	exist DWORD ?; 1���ڣ�0�Ѳ����ڣ��÷֣�
	typ DWORD ?; ���
	posX DWORD ?; λ�ú�����
	posY DWORD ?; λ��������
	radius DWORD ?; �뾶
	weight DWORD ?; ����
	value DWORD ?; ��ֵ
Item ENDS; һ��ʵ��ռ4*7=28B

itemNum DWORD 10; ��������
public itemNum

Items Item 50 DUP({}); �����б�(�����50������)
public Items

end

