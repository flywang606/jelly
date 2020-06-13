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

### Vivado�� bit �t�@�C�������

projects/zybo_z7_imx219/syn/vivado2019.2

�Ɉړ����� Vivado ���� zybo_z7_imx219.xpr ���J���Ă��������B

�ŏ��� BlockDesign �� tcl ����č\������K�v����܂��B

���ɓo�^����Ă��� i_design_1 ���蓮�ō폜���Ă���A���j���[�́uTools�v���uRun Tcl Script�v�ŁA�����f�B���N�g���ɂ��� design_1.tcl �����s����Ε����ł��܂��B

�������� Vivado �̃J�����g�f�B���N�g�����v���W�F�N�g�̂���f�B���N�g���ɂ��邱�Ƃ��m�F���������� update_design.tcl �����s����ƍ폜�ƍ\�z���܂Ƃ߂Ď��s�ł��܂��B

design_1 ���������ꂽ��uFlow�v���uRun Implementation�v�ō������s���܂��B����ɍ����ł����

zybo_z7_imx219.runs/impl_1

�� zybo_z7_imx219.bit ���o���オ��܂��B

### Debian�N�����̃p�����[�^�ݒ�(CMA�̈摝��)

����̓���ł́AIMX219�C���[�W�Z���T�[����PL�o�R�ŉ摜����荞�݂܂����A���̍ۂ� ikwzm���� [udmabuf](https://qiita.com/ikwzm/items/cc1bb33ff43a491440ea) ��p���āACMA(DMA Contiguous Memory Allocator)�̈悩��̈�����蓖�Ă܂��B
IMX219 �� 3280x2464 �Ƃ������ɑ傫�ȉ摜���擾�ł��܂��̂ŁA�̈���g�傷��K�v������܂��B

SD�J�[�h�̋N���p�[�e�B�[�V����(Debian�C���[�W����� /mnt/boot �Ƀ}�E���g����Ă���͂�)�� uEnv.txt �� linux_boot_args �� cma=128M ��ǉ����Ă��������B

```
linux_boot_args=console=ttyPS0,115200 root=/dev/mmcblk0p2 rw rootwait uio_pdrv_genirq.of_id=generic-uio cma=128M
```

����Ȋ����ɂȂ�͂��ł��B


### ZYBO Z7 �Ŏ��s

��t�����ɒ��ӂ��� ZYBO-Z7 �� MIPI�R�l�N�^(J2) �ɁACamera Module V2 ��ڑ����܂��B�t���L�̐ړ_���o�Ă��鑤����̊O���������܂��B

���� projects/zybo_z7_imx219/app �̓��e�ꎮ�Ɛ�قǍ������� zybo_z7_imx219.bit ���AZYBO �� Debian �ō�Ƃł���K���ȃf�B���N�g���ɃR�s�[���܂��Bbit�t�@�C��������app�f�B���N�g���ɓ���Ă��������B

ZYBO ���ł� Debian ���N���ς݂� ssh �ȂǂŐڑ����ł��Ă���O��ł��̂� scp �� samba �ȂǂŃR�s�[����Ɨǂ��ł��傤�Bapp �Ɋւ��Ă� ZYBO ���� git �� clone ���邱�Ƃ��\�ł��B

���̎��A

- OpenCV �� bootgen �ȂǕK�v�ȃc�[�����C���X�g�[���ł��Ă��邱��
- ssh �|�[�g�t�H���[�f�B���O�ȂǂŁAPC�� X-Window ���J����Ԃɂ��Ă�������
- /dev/uio �� /dev/i2c-0 �Ȃǂ̃f�o�C�X�̃A�N�Z�X���������邱��

�Ȃǂ̉�����������܂��̂ŁA�u���O�ȂǎQ�l�ɐݒ肭�������B

���Ȃ���΁Aapp ���R�s�[�����f�B���N�g����

```
make all
```

```
make run
```



## �Q�l���

- �u���O�L��
    - [Zybo Z7 �ւ� Raspberry Pi Camera V2 �ڑ�(MIPI CSI-2��M)](http://ryuz.txt-nifty.com/blog/2018/04/zybo-z7-raspber.html)
    - [Zybo Z7 �ւ� Raspberry Pi Camera V2 �ڑ� (1000fps����)](http://ryuz.txt-nifty.com/blog/2018/05/zybo-z7-raspber.html)

- [https://github.com/lvsoft/Sony-IMX219-Raspberry-Pi-V2-CMOS](https://github.com/lvsoft/Sony-IMX219-Raspberry-Pi-V2-CMOS)
    - Raspberry Pi Camera Module V2 �̊e����iIMX219�̃f�[�^�V�[�g����)
- [https://www.raspberrypi.org/forums/viewtopic.php?t=160611&start=25](https://www.raspberrypi.org/forums/viewtopic.php?t=160611&start=25)
    - �e����B[��H�}](https://cdn.hackaday.io/images/5813621484631479007.jpg)�̏�񂠂�
