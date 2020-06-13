# ZYBO-Z7 �� Raspberry Pi Camera Module V2 (Sony IMX219) �� 1000fps�Ŏg���T���v��

## �T�v
�^�C�g���̂Ƃ���AZYBO-Z7 �� Raspberry Pi Camera Module V2 (Sony IMX219) �� 1000fps�Ŏg���T���v���ł��B
������� 3280�~2464@20fps �������Ƃł��܂��̂ł����S���B


## ��

���̂悤�Ȋ��Ŏ��{���Ă���܂��B

- Digilent�� [Zybo Z7-20](https://reference.digilentinc.com/reference/programmable-logic/zybo-z7/start) (�����ĂȂ��ł������� Z7-10�ł����v�Ǝv���܂�)
- Raspberry Pi Camera Module V2
- [Vivado 2019.2.1](https://japan.xilinx.com/support/download.html)
- [ikwzm��](https://qiita.com/ikwzm) �� [Debian�u�[�g�C���[�W](https://qiita.com/ikwzm/items/7e90f0ca2165dbb9a577)
- Debian�C���[�W�ւ� OpenCV �ȂǊe��J�����̃C���X�g�[��
- X-Window server �ƂȂ�PC (��҂� Windows10 + [Xming](https://sourceforge.net/projects/xming/) �Ŏ��{)

��{�I�Ȋ��\�z��[������̃u���O](https://ryuz.qrunch.io/entries/jU8BkKu8bxqOeGAC)�ł��Љ�Ă���܂��̂ŎQ�l�ɂ��Ă��������B

�\�t�g�E�F�A�� Debian �C���[�W��ŃZ���t�R���p�C���\�ł��̂ŁA�z�X�gPC���� Vivado �݂̂ł��J�����\�ł�(Vitis�Ȃǂ���������悢�ł���)�B


## ��������

### git���|�W�g���擾

```
git clone https://github.com/ryuz/jelly.git
```

�ňꎮ�擾���Ă��������B

Vivado ����

projects/zybo_z7_imx219/syn/vivado2019.2/zybo_z7_imx219.xpr

���J���Ă��������B

�����āA�v���W�F�N�g�Ɠ����f�B���N�g���ɂ��� 


### Vivado�� bit �t�@�C�������



https://github.com/lvsoft/Sony-IMX219-Raspberry-Pi-V2-CMOS
