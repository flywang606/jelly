# 1 "../system.cfg"
# 1 "<built-in>"
# 1 "<command line>"
# 1 "../system.cfg"
# 14 "../system.cfg"
KERNEL_HEP_MEM(0x100000, 0x01200000);
KERNEL_INT_STK(2048, NULL);
KERNEL_SYS_STK(2048, NULL);
KERNEL_MAX_TSKID(32);
KERNEL_MAX_SEMID(32);
KERNEL_MAX_FLGID(32);
KERNEL_MAX_MTXID(32);
KERNEL_MAX_MBXID(32);
KERNEL_MAX_MPFID(32);
KERNEL_MAX_ISRID(32);



INCLUDE("\"boot.h\"");
CRE_TSK(TSKID_BOOT, {TA_HLNG | TA_ACT, 0, Boot_Task, 2, 1024, NULL});
