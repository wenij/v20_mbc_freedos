/*
    This file is part of SUPPL - the supplemental library for DOS
    Copyright (C) 1996-2000 Steffen Kaiser

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; if not, write to the Free
    Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/
/* $RCSfile$
   $Locker$	$Name$	$State$

ob(ject): DOSalloc
su(bsystem): farmem
ty(pe): 
sh(ort description): Allocate a block of memory using the DOS API
he(ader files): 
lo(ng description): Allocates a block of memory directly via the DOS API, this
	block must be deallocated by \tok{DOSfree()} or any other function using
	the DOS API to deallocate (free) a block of memory.\par
	\para{length} specifies the size of the block to allocate in
	\em{paragraphes}. One paragraphe is a chunk of 16 bytes.\newline
	\para{mode} is a bitfield specifying what to do with UMBs. If no UMBs
	are available this setting is ignored (except for bit 0x10). Because only
	some individual combination make sense, they are enumerated:
	\item \tok{0x00}: low memory first fit
	\item \tok{0x01}: low memory best fit
	\item \tok{0x02}: low memory last fit
	\item \tok{0x0F}: use current allocation strategy
	\item \tok{0x40}: high memory first fit
	\item \tok{0x41}: high memory best fit
	\item \tok{0x42}: high memory last fit
	\item \tok{0x80}: first fit, try high then low memory
	\item \tok{0x81}: best fit, try high then low memory
	\item \tok{0x82}: last fit, try high then low memory
	\item \tok{0x8F}: make high memory accessable, but don't change strategy
	\nolist
	If bit 0x10 is set, the maximal allocateable block size is returned.\newline
	If bit 0x10 is clear, a block is allocated and its segment is returned.
	This segment is the handle to be passed back to \tok{DOSfree()} or the
	DOS API to de-allocated the memory. The far memory address can be
	generated by \tok{MK_FP(segment, 0)}.\par
	To support memory tracking utitilites, like \cmd{MEM}, the applications
	ID (eight byte name) is passed from its own memory block to the allocated
	ones.
pr(erequistes): 
va(lue): 0: on failure\item else: segment of allocated block or, if bit 0x10
	is set, the number of paragraphes of the largest unused block
re(lated to): DOSfree DOSresize
se(condary subsystems): 
in(itialized by): 
wa(rning): 
bu(gs): 
fi(le): dosalloc.c

 */

#include "initsupl.loc"

#ifndef _MICROC_
#include <dos.h>
#include <string.h>
#endif
#include <portable.h>
#include "suppl.h"
#include "mcb.h"
#include "fmemory.h"

#include "suppldbg.h"

word DOSalloc(word length, int mode)
{	int UMBLink = 1, allocStrat;
	USEREGS

	DBG_ENTER("DOSalloc", Suppl_farmem)
	DBG_ARGUMENTS( ("len=%u, mode=0x%04x", length, mode) )

	if(mode & 0x10)		/* probe for max unused block */
		length = ~0;
	else if(!length)
		DBG_RETURN_I( 0)

	if(mode & (0x40 | 0x80)) {	/* UMBs have to be linked in */
		_AX = 0x5802;		/* Get UMB Link State */
			/* FreeDOS doesn't change the flags if the API call fails */
    /* /// Modified to use __emit__(), which doesn't require an assembler,
       if we're compiling with TurboC.  - Ron Cemer */
#if defined(_TC_EARLY_)
        __emit__((unsigned char)0xf9);      /* stc */
#elif defined(__WATCOMC__) || defined(__GNUC__)
		reg.x.flags |= 1;
#else
		asm {
			stc
		}
#endif
		geninterrupt(0x21);	/* This fails prior DOS 5 */
		UMBLink = _AL;
		if(_CFLAG) 		/* no UMBs */
			UMBLink = 1, 	/* disables the UMB Unlink call */
			mode &= 0xF;	/* Disables side effects with elder DOSs */
		else {
			if(!UMBLink) {		/* UMBs need to be linked in */
				_BX = 1;		/* Link in UMBs */
				_AX = 0x5803;	/* Set UMB Link State */
				geninterrupt(0x21);
			}
		}
	}

	allocStrat = 0;
	if((mode & 0xF) != 0xF) {
	/* allocate the block, with the specified mode
		--> save the old allocation mode */
		_AX = 0x5800;						/* Get Allocation Strategy */
			/* FreeDOS this call never fails, but doesn't change the
				flags */
    /* /// Modified to use __emit__(), which doesn't require an assembler,
       if we're compiling with TurboC.  - Ron Cemer */
#if defined(_TC_EARLY_)
        __emit__((unsigned char)0xf8);      /* clc */
#elif defined(__WATCOMC__) || defined(__GNUC__)
		reg.x.flags &= ~1;
#else
		asm {
			clc
		}
#endif
		geninterrupt(0x21);
		allocStrat = _AL;
		if(_CFLAG)						/* MCB chain destroyed */
			length = 0;			/* don't return here, because of UMB state */
		else {
			_BX = mode & ~0x10;				/* allocation strategy to set */
			_AX = 0x5801;					/* Set Allocation Strategy */
			geninterrupt(0x21);
		}
	}
	
	if(length) {
		/* now, try to allocate the block */
		_BX = length;							/* size of block */
		_AH = 0x48;								/* Allocate Memory Block */
		geninterrupt(0x21);
		length = _AX;
		if(_CFLAG)
			length = (mode & 0x10)? _BX: 0;	/* allocation failed */
		else					/* allocation OK; update name field */
			_fmemcpy(MK_FP(SEG2MCB(length), MCB_OFF_NAME)
			 , MK_FP(SEG2MCB(_psp), MCB_OFF_NAME), 8);

		if((mode & 0xF) != 0xF) {
		/* reset allocation strategy */
			_BX = allocStrat;
			_AX = 0x5801;
			geninterrupt(0x21);
		}
	}

	/* reset UMBLink state */
	if(!UMBLink) {
		_BX = 0;								/* Unlink UMBs from chain */
		_AX = 0x5803;
		geninterrupt(0x21);
	}

	DBG_RETURN_I( length)		/* allocated block */
}
