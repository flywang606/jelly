/** 
 *  Hyper Operating System  Application Framework
 *
 * @file  mmcdrv.h
 * @brief %jp{�������}�b�v�h�t�@�C���p�f�o�C�X�h���C�o}
 *
 * Copyright (C) 2006-2007 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "mmcdrv_local.h"
#include "system/sysapi/sysapi.h"
#include "mmcfile.h"


/** �I�[�v�� */
HANDLE MmcDrv_Open(C_DRVOBJ *pDrvObj, const char *pszPath, int iMode)
{
	C_MMCDRV	*self;
	HANDLE		hFile;
	
	/* upper cast */
	self = (C_MMCDRV *)pDrvObj;
	
	SysMtx_Lock(self->hMtx);
	
	/* create file descriptor */
	hFile = MmcFile_Create(self, iMode);
	if ( hFile == HANDLE_NULL )
	{
		SysMtx_Unlock(self->hMtx);
		return HANDLE_NULL;
	}
	
	/* �I�[�v������ */
	if ( self->iOpenCount++ == 0 )
	{
		MmcDrv_CardInitialize(self);
	}
	
	SysMtx_Unlock(self->hMtx);
	
	return hFile;
}


/* end of file */