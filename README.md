# Jelly -- SoC platform for FPGA

## �T�v

MIPS�݊���CPU�R�A�������n�߂��̂����������ł����A����ł�FPGA��SoC����������ׂ̃v���b�g�t�H�[���ɂȂ����܂��B
��� Xilinx ��FPGA���^�[�Q�b�g�ɂ����A�l�X�ȃR�[�h��~�ς��Ă���A��� Verilog 2001 �ŊJ�����Ă���܂��B

�ŋ߂́A�M�҂̔��Ă���FPGA�p�̃o�C�i���j���[�����l�b�g�ł��� LUT-Network �̎��s�ɂ��ꕔ�R�[�h�𗬗p���Ă���A�d�v�������܂��Ă���܂��B

��{�I�ɂ͐F�X�Ȃ��̂��������ςŊ܂�ł���󋵂ł��B


## MIPS-I �݊��v���Z�b�T

/rtl/cpu/
�ȉ��ɂ���܂��B

Verilog�̕׋����n�߂����� Spartan-3 �����Ɏ����ɏ����Ă݂��v���Z�b�T�ł��B

�u���b�N�}�Ȃǂ�[Web�T�C�g](http://ryuz.my.coocan.jp/jelly/index.html)�̕��ɂ���܂��B


## ���A���^�C��GPU

/rtl/gpu
�ȉ��ɂ���܂��B

�t���[�����������g��Ȃ��t�B���^�^�̒�x���ȃ��A���^�C���`���ڎw�������̂ł��B

[����](https://www.youtube.com/watch?v=vl-lhSOOlSk)�͂�����ł��B


## ���C�u�����Q

���͂₱�ꂪ Jelly �̃��C�������ł�

- rtl/library      FIFO�Ƃ�RAM�Ƃ��l�X��RTL�̃p�[�c
- rtl/bus          AXI�Ƃ�WISHBONE�Ƃ��̃o�X�u���b�W���̃p�[�c
- rtl/math         GPU�Ƃ��Ŏg���悤�ȎZ�p�p�[�c
- rtl/peripheral   UART�Ƃ�I2C�Ƃ�TIMER�Ƃ��̂̃p�[�c
- rtl/video        DVI�Ƃ�HDMI�Ƃ��̃r�f�I����
- rtl/image        �摜�����p�p�[�c(�j���[�����l�b�g�̏�ݍ��݂ł����p)
- rtl/model        �V�~�����[�V�����p�֗̕����f�����낢��


## ���C�Z���X
  license.txt �ɂ���ʂ�AMIT ���C�Z���X�Ƃ��Ēu���Ă����܂��B

