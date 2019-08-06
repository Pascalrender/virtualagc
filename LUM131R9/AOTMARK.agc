### FILE="Main.annotation"
## Copyright:   Public domain.
## Filename:    AOTMARK.agc
## Purpose:     A section of LUM131 revision 9.
##              It is part of the reconstructed source code for the
##              third release of the flight software for the Lunar 
##              Module's (LM) Apollo Guidance Computer (AGC) for Apollo 13.
##              The code has been recreated from a copy of Luminary 131.
##              It has been adapted such that the resulting bugger words
##              exactly match those specified for LUM131 revision 9 in NASA
##              drawing 2021152L, which gives relatively high confidence that
##              the reconstruction is correct.
## Reference:   pp. 245-262
## Assembler:   yaYUL
## Contact:     Ron Burkey <info@sandroid.org>.
## Website:     www.ibiblio.org/apollo/index.html
## Warning:     THIS PROGRAM IS STILL UNDERGOING RECONSTRUCTION
##              AND DOES NOT YET REFLECT THE ORIGINAL CONTENTS OF
##              LUM131 REVISION 9.
## Mod history: 2019-08-04 MAS  Created from Luminary 130.

## Page 245
		BANK	12
		SETLOC	AOTMARK1
		BANK
		
		EBANK=	XYMARK
		COUNT*	$$/MARK
		
AOTMARK		INHINT
		CCS	MARKSTAT	# SEE IF AOTMARK BUSY
		TC	+2		# MARK SYSTEM BUSY - DO ALARM
		TC	EXTVBCHK
		TC	POODOO
		OCT	20105
		
EXTVBCHK	CAF	SIX		# SEE IF EXT. VERB WORKING
		MASK	EXTVBACT
		CCS	A
		TCF	MKABORT		# YES - ABORT
		
		CAF	BIT2		# NO - DISALLOW SOME EXTENDED VERB ACTION
		ADS	EXTVBACT	# BIT2 RESET IN ENDMARK
MKVAC		CCS	VAC1USE		# LOOK FOR A VAC AREA - DO ABORT IF
		TCF	MKVACFND	# NONE AVAILABLE
		CCS	VAC2USE
		TCF	MKVACFND
		CCS	VAC3USE
		TCF	MKVACFND
		CCS	VAC4USE
		TCF	MKVACFND
		CCS	VAC5USE
		TCF	MKVACFND
		DXCH	BUF2
		TC	BAILOUT1	# ALL VAC AREAS OCCUPIED - ABORT.
		OCT	31207
		
MKVACFND	AD	TWO
		TS	MARKSTAT	# STORE VAC ADR INLOW 9 OF MARKSTAT
		
		CAF	ZERO
		INDEX	MARKSTAT
		TS	0 -1		# ZERO IN VACUSE REG TO SHOW VAC OCCUPIED

		CAF	PRIO15
		TC	FINDVAC		# SET UP JOB FOR GETDAT
		EBANK=	XYMARK
		2CADR	GETDAT
		
		RELINT
		TCF	SWRETURN
## Page 246
MKABORT		DXCH	BUF2
		TC	BAILOUT1	# CONFLICT WITH EXTENDED VERB
		OCT	31211
		
MKRELEAS	CAF	ZERO
		XCH	MARKSTAT	# SET MARKSTAT TO ZERO
		MASK	LOW9		# PICK UP VAC AREA ADR
		CCS	A
		INDEX	A
		TS	0		# SHOW MKVAC AREA AVAILABLE
		CAF	ONE
		TC	IBNKCALL
		CADR	GOODEND		# GO WAKE UP CALLING JOB
		
## Page 247
KILLAOT		CAF	ZERO
		TS	EXTVBACT	# TERMINATE AOTMARK - ALLOW EXT VERB
		TC	GOTOPOOH
GETDAT		CS	MARKSTAT	# SET BIT12 TO DISCOURAGE MARKRUPT
		MASK	BIT12		#	BIT12 RESET AT GETMARK
		ADS	MARKSTAT
		
		CAF	V01N71		# DISPLAY DETENT AND STAR CODE
		TC	BANKCALL
		CADR	GOMARKF
		
		TCF	KILLAOT		# V34 - DOES GOTOPOOH
		TCF	DODAT		# V33 - PROCEED - USE THIS STAR FOR MARKS
ENTERDAT	TCF	GETDAT		# ENTER - REDISPLAY STAR CODE

DODAT		CAF	HIGH9		# PICK DETENT CODE FROM BITS7-9 OF AOTCODE
		MASK	AOTCODE		# AND SEE IF CODE 1 TO 6
		EXTEND
		MP	BIT9
		TS	XYMARK		# STORE DETENT
		
		EXTEND
		BZMF	GETDAT		# COAS CALIBRATION CODE - NO GOOD HERE
		
		AD	NEG7		# SEE IF DETENT 7 FOR COAS
		EXTEND
		BZF	CODE7
		
		TCF	CODE1TO6
		
CODE7		CAF	V06N87*		# CODE 7, COAS SIGHTING, GET OPTIC AXIS
		TC	BANKCALL	# AZ AND EL OF SIGHTING DEVICE FROM ASTRO
		CADR	GOMARKF
		
		TCF	KILLAOT		# V34 - DOES GOTOPOOH
		TCF	+2		# PROCEED
		TCF	CODE7		# ON ENTER, RECYCLE
		EXTEND
		DCA	AZ		# PICK UP AZ AND EL IN SP 2S COMP
		INDEX	FIXLOC
		DXCH	8D		# STORE IN 8D AND 9D OF LOCAL VAC
		CAF	ZERO		# BACKUP SYSTEM TO BE USED
		TCF	COASCODE	# ZERO APPARENT ROTATION
		
CODE1TO6	INDEX	XYMARK		# INDEX AOT POSITION BY DET CODE
		CA	AOTEL -1
		INDEX	FIXLOC
		TS	9D		# STORE ELEVATION IN VAC+9D
		
		INDEX	XYMARK		# INDEX DET CODE 1,2 OR 3
## Page 248
		CA	AOTAZ -1
		INDEX	FIXLOC
		TS	8D		# STORE AZIMUTH IN VAC+8D
		
		CA	AOTAZ +1	# COMPENSATION FOR APPARENT ROTATION OF
		EXTEND			# AOT FIELD OF VIEW IN LEFT AND RIGTHT
		INDEX	FIXLOC		# DETENTS IS STORED IN VAC +10D IN SP
		MSU	8D		# PRECISION ONES COMPLEMENT
COASCODE	INDEX	FIXLOC
		TS	10D		# ROT ANGLE
		
		TC	INTPRET		# COMPUTE X AND Y PLANE VECTORS
		
## Page 249
# THE OPTAXIS SUBROUTINE COMPUTES THE X AND Y MARK PLANE VECS AND
# AND ROTATES THEM THRU THE APPARENT FIELD OF VIEW ROTATION UNIQUE TO AOT
# OPTAXIS USES OANB TO COMPUTE THE OPTIC AXIS
#
#	INPUT -		AZIMUTH ANGLE IN SINGLE PREC AT CDU SCALE IN 8D OF JOB VAC
#			ELEVATION ANGLE IN SINGLE PREC AT CDU SCALE IN 9D OF JOB VAC
#			ROTATION ANGLE IN SINGLE PREC 1S COMPSCALED BY PI IN 10D OF VAC
#
#	OUTPUT -	OPTIC AXIS VEC IN NB COORDS IN SCAXIS
#			X-MARK PLANE 1/4VEC IN NB COORDS AT 18D OF JOB VAC
#			Y-MARK PLANE 1/4VEC IN NB COORDS AT 12D OF JOB VAC

OPTAXIS		CALL			# GO COMPUTE OA AND X AND Y PLANE VECS
			OANB
		SLOAD	SR1		# LOAD APP ROTATION IN ONES COMP
			10D		# RESCALE BY 2PI
		PUSH	SIN		# 1/2SIN(ROT) 0-1
		PDDL	COS
		PUSH	VXSC		# 1/2COS(ROT) 2-3
			18D
		PDDL	VXSC		# 1/4COS(ROT)UYP 4-9
			0
			24D		# 1/4SIN(ROT)UXP
		BVSU	STADR		# UP 4-9
		STODL	12D		# YPNB=1/4(COS(ROT)UYP-SIN(ROT)UXP)
		VXSC	PDDL		# UP 2-3 UP 0-1 FOR EXCHANGE
			24D		# 1/4COS(ROT)UXP 	PUSH 0-5
		VXSC	VAD		# 1/4SIN(ROT)UYP
			18D		# UP 0-5
		STADR
		STOVL	18D		# XPNB=1/4(COS(ROT)UXP+SIN(ROT)UYP)
			LO6ZEROS	# INITIALIZE AVE STAR VEC ACCUMULATOR
		STORE	STARAD +6
		EXIT
		TCF	GETMKS
		
## Page 250
# THE OANB SUBROUTINE COMPUTES THE OPTIC AXIS OF THE SIGHTING INSTRUMENT
# FROM AZIMUTH AND ELEVATION INPUT FROM THE ASTRONAUT.
#
#	INPUT -		AZIMUTH ANGLE IN SINGLE PREC 2S COMP IN 8D OF JOB VAC
#			ELEVATION ANGLE IN SINGLE PREC 2S COMP IN 9D OF VAC
#
#	OUTPUT -	OPTIC AXIS IN NB COORDS. IN SCAXIS
#			X-PLANE 1/2VEC IN NB COORDS AT 24D OF VAC
#			Y-PLANE 1/2VEC IN NB COORDS AT 18D OF VAC

		BANK	05
		SETLOC	AOTMARK2
		BANK
		
		COUNT*	$$/MARK
		
OANB		SETPD	STQ
			0
			GCTR		# STORE RETURN
		SLOAD	RTB
			9D		# PICK UP SP ELV
			CDULOGIC
		PUSH	COS
		PDDL	SIN		# 1/2COS(ELV)	PD 0-1
		STADR
		STODL	SCAXIS		# OAX=1/2SIN(ELV)
			8D		# PICK UP AZ SP
		RTB
			CDULOGIC
		PUSH	COS
                STORE   20D             # STORE UYP(Y) 20-21
                PDDL    SIN             # 1/2COS(AZ) PD 2-3
                PUSH    DCOMP           # PUSH 1/2SIN(AZ) 4-5
                STODL   22D             # STORE UYP(Z) 22-23
                        LO6ZEROS                        
                STODL   18D             # STORE UYP(X) 18-19   UP 4-5
		DMP	SL1
			0
		STODL	SCAXIS +2	# OAY=1/2COS(ELV)SIN(AZ)
		DMP	SL1		# UP	2-3
		STADR			# UP	0-1
		STOVL	SCAXIS +4	# OAZ=1/2COS(ELV)COS(AZ)
			18D		# LOAD UYP VEC
		VXV	UNIT
			SCAXIS		# UXP VEC=UYP X OA
		STORE	24D		# STORE UXP
		GOTO
			GCTR
## Page 251
# SURFSTAR COMPUTES A STAR VECTOR IN SM COORDINATES FOR LUNAR
# SURFACE ALIGNMENT AND EXITS TO AVEIT TO AVERAGE STAR VECTORS.
# 
#	GIVEN	X-MARK PLANE 1/4 VEC IN NB AT 18D OF LOCAL VAC
#		Y-MARK PLANE 1/4 VEC IN NB AT 12D OF LOCAL VAC
#		CURSOR SP 2COMP AT POSITION 1 OF INDEXED MARKVAC
#		SPIRAL SP 2COMP AT POSITION 3 OF INDEXED MARKVAC
#		CDUY,Z,X AT POSITIONS 0,2,4 OF INDEXED MARKVAC

		BANK	15
		SETLOC	P50S
		BANK
		COUNT*	$$/R59
		
SURFSTAR	VLOAD*
			0,1		# PUT X-MARK CDUS IN CDUSPOT FOR TRG*NBSM
		STORE	CDUSPOT
		SLOAD*	RTB
			1,1		# PICK UP YROT
			CDULOGIC
		STORE	24D		# STORE CURSOR FOR SPIRAL COMP (REVS)
		BZE
			YZCHK		# IF YROT ZERO - SEE IF SROT ZERO
JUSTZY		PUSH	COS
		PDDL	SIN		# 1/2COS(YROT) 	0-1
		VXSC	PDDL		# UP 0-1	1/8SIN(YROT)UXP	0-5
			18D
		VXSC	VSU		# UP 	0-5
			12D		# UYP
		UNIT	VXV
			SCAXIS
		UNIT	PUSH
		SLOAD*	RTB
			3,1		# PICK UP SPIRAL
			CDULOGIC
		STORE	26D		# STORE SPIRAL (REVS)
		DSU	DAD
			24D
			ABOUTONE
		DMP
			DP1/12
		STORE	26D		# SEP=(360 + SPIRAL -CURSOR)/12
		SIN	VXSC		# UP	0-5
		VSL1	PDDL		# 1/2SIN(SEP)(UPP X OA)	0-5
			26D
		COS	VXSC
			SCAXIS
		VSL1	VAD		# UP	0-5
JUSTOA		UNIT	CALL
			TRG*NBSM
		STCALL	24D		# STAR VEC IN SM
			AVEIT		# GO AVERAGE
## Page 252
ABOUTONE	2DEC	.99999999

DP1/12		EQUALS	DEG30		# .08333333
		BANK	7
		SETLOC	AOTMARK1
		BANK
		COUNT*	$$/MARK
YZCHK		SLOAD*	BZE		# YROT ZERO AND IF SROT ZERO FORCE STAR
			3,1		# ALONG OPTIC AXIS
			YSZERO
		DLOAD	GOTO
			24D
			JUSTZY		# SROT NOT ZERO - CONTINUE NORMALLY
YSZERO		VLOAD	GOTO
			SCAXIS
			JUSTOA
			
## Page 253
# THE GETMKS ROUTINE INITIALIZES THE SIGHTING MARK PROCEDURE

GETMKS		CAF	ZERO		# INITIALIZE MARK ID REGISTER AND MARK CNT
		TS	XYMARK
		TS	MARKCNTR
		CAF	LOW9		# ZERO BITS10 TO 15 RETAINING MKVAC ADR
		MASK	MARKSTAT
		TS	MARKSTAT
		CAF	MKVB54*		# DISPLAY VB54 INITIALLY
PASTIT		TC	BANKCALL
		CADR	GOMARK4
		
		TCF	KILLAOT		# V34 - DOES GOTOPOOH
		TCF	MARKCHEX	# VB33 - PROCEED, GOT MARKS, COMPUTE LOS
		TCF	GETDAT		# ENTER - RECYCLE TO V01N71
		
MARKCHEX	CS	MARKSTAT	# SET BIT12 TO DISCOURAGE MARKRUPT
		MASK	BIT12
		ADS	MARKSTAT
		MASK	LOW9
		TS	XYMARK		# JAM MARK VAC ADR IN XYMARK FOR AVESTAR
		CAF	ZERO
		TS	MKDEX		# SET MKDEX ZERO FOR LOS VEC CNTR
		CA	MARKSTAT
		MASK	PRIO3		# SEE IF LAST MK PARI COMPLETE
		TS	L
		CAF	PRIO3		# BITS10 AND 11
		EXTEND
		RXOR	LCHAN
		EXTEND
		BZF	AVESTAR		# LAST PAIR COMPLETE - GO COMPUTE LOS
CNTCHK		CCS	MARKCNTR	# NO PAIR SHOWING - SEE IF PAIR IN HOLD
		TCF	+2		# PAIR BURIED - DECREMENT COUNTER
		TCF	MKALARM		# NO PAIR - ALARM
		TS	MARKCNTR	# STORE DECREMENTED COUNTER
		
AVESTAR		CAF	BIT12		# INITIALIZE MKDEX FOR STAR LOS COUNTER
		ADS	MKDEX		# MKDEX WAS INITIALIZED ZERO IN MARKCHEX
		CS	MARKCNTR
		EXTEND
		MP	SIX		# GET C(L) = -6 MARKCNTR
		CS	XYMARK
		AD	L		# ADD - MARK VAC ADR SET IN MARKCHEX
		INDEX	FIXLOC
		TS	X1		# JAM - CDU ADR OF X-MARK IN X1
		
		CA	FIXLOC		# SET PD POINTER TO ZERO
		TS	PUSHLOC
		
		TC	INTPRET
## Page 254
		BON	VLOAD*
			SURFFLAG	# IF ON SURFACE COMPUTE VEC AT SURFSTAR
			SURFSTAR
			1,1		# PUT Y-MARK CDUS IN CDUSPOT FOR TRG*NBSM
		STOVL	CDUSPOT
			12D		# LOAD Y-PLANE VECTOR IN NB
		CALL
			TRG*NBSM	# CONVERT IT TO STABLE MEMBER
		PUSH	VLOAD*
			0,1		# PUT X-MARK CDUS IN CDUSPOT FOR TRG*NBSM
		STOVL	CDUSPOT
			18D		# LOAD X-PLANE VECTOR IN NB
		CALL
			TRG*NBSM	# CONVERT IT TO STABLE-MEMBER
		VXV	UNIT		# UNIT(XPSM * YPSM)
		STADR
		STORE	24D
		
AVEIT		SLOAD	PDVL		# N(NUMBER OF VECS) IN 0-1
			MKDEX
			24D		# LOAD CURRENT VECTOR
		VSR3	V/SC
			0
		STODL	24D		# VEC/N
			0
		DSU	DDV
			DP1/8		# (N-1)/N
		VXSC	VAD
			STARAD +6	# ADD VEC TO PREVIOUSLY AVERAGED VECTOR
			24D		# (N-1)/N AVESTVEC + VEC/N
		STORE	STARAD +6	# AVERAGE STAR VECTOR
		STORE	STARSAV2
		EXIT
		CCS	MARKCNTR	# SEE IF ANOTHER MARK PAIR IN MKVAC
		TCF	AVESTAR -1	# THERE IS - GO GET IT - DECREMENT COUNTER
ENDMARKS	CAF	FIVE		# NO MORE MARKS - TERMINATE AOTMARK
		INHINT
		TC	WAITLIST
		EBANK=	XYMARK
		2CADR	MKRELEAS
		
		TC	ENDMARK
		
MKALARM		TC	ALARM		# NOT A PAIR TO PROCESS - DO GETMKS
		OCT	111
		TCF	GETMKS
		
V01N71		VN	171
V06N87*		VN	687

## Page 255
# MARKRUPT IS ENTERED FROM INTERUPT LEAD-INS AND PROCESSES CHANNEL 16
# CAUSED BY X,Y MARK OR MARK REJECT OR BY THE RATE OF DESCENT SWITCH

MARKRUPT	TS	BANKRUPT
		CA	CDUY		# STORE CDUS AND TIME NOW - THEN SEE IF
		TS	ITEMP3		# WE NEED THEM
		CA	CDUZ
		TS	ITEMP4
		CA	CDUX
		TS	ITEMP5
		EXTEND
		DCA	TIME2
		DXCH	ITEMP1
		XCH	Q
		TS	QRUPT
		
		CAF	OCT140		# SEE IF ROD INPUT HAS BEEN MADE
		EXTEND
		RAND	NAVKEYIN
		CCS	A
		TCF	SOMEKEY		# YES
		
		CAF	BIT12		# ARE WE ASKING FOR A MARK
		MASK	MARKSTAT
		CCS	A
		TC	RESUME		# DONT WANT MARK OR MKREJECT - DO NOTHING

		CCS	MARKSTAT	# ARE MARKS BEING ACCEPTED
		TCF	FINDKEY		# THEY ARE - WHICH ONE IS IT
		TC	ALARM		# MARKS NOT BEING ACCEPTED - DO ALARM
		OCT	112
		TC	RESUME
		
FINDKEY		CAF	BIT5		# SEE IF MARK REJECT
		EXTEND
		RAND	NAVKEYIN
		CCS	A
		TCF	MKREJ		# ITS A MARK REJECT
		
		CAF	BIT4		# SEE IF Y MARK
		EXTEND
		RAND	NAVKEYIN
		CCS	A
		
		TCF	YMKRUPT		# ITS A Y MARK
		
		CAF	BIT3		# SEE IF X MARK
		EXTEND
		RAND	NAVKEYIN
		CCS	A
		
## Page 256
		TCF	XMKRUPT		# ITS A X MARK
		
SOMEKEY		CAF	OCT140		# NOT MARK OR MKREJECT - SEE IF DESCENT BITS
		EXTEND
		RAND	NAVKEYIN
		EXTEND
		BZF	+3		# IF NO BITS
		
		TC	POSTJUMP	# IF DESCENT BITS
		CADR	DESCBITS
		
		TC	ALARM		# NO INBITS IN CHANNEL 16
		OCT	113
		
		TC	RESUME
		
XMKRUPT		CAF	ZERO
		TS	RUPTREG1	# SET X MARK STORE INDEX TO ZERO
		CAF	BIT10
		TCF	+4
YMKRUPT		CAF	ONE
		TS	RUPTREG1	# SET Y MARK STORE INDEX TO ONE
		CAF	BIT11
		TS	XYMARK		# SET MARK IDENTIFIATION
		
		TC	MARKTYPE	# SEE IF SURFACE MARK
		TCF	SURFSTOR	# SURFACE MARK - JUST STORE CDUS
		
		CAF	BIT14		# GOT A MARK - SEE IF MARK PAIR MADE
		MASK	MARKSTAT
		EXTEND
		BZF	VERIFYMK	# NOT A PAIR, NORMAL PROCEDURE
		CS	MARKCNTR	# GOT A PAIR, SEE IF ANOTHER CAN BE MADE
		AD	FOUR		# IF SO, INCREMENT POINTER, CLEAR BITS 10,11
		EXTEND
		BZMF	5MKALARM	# HAVE FIVE MARK PAIRS - DONT ALLOW MARK
		INCR	MARKCNTR	# OK FOR ANOTHER PAIR, INCR POINTER
		CS	PRIO23		# CLEAR BITS 10,11,14 FOR NEXT PAIR
		MASK	MARKSTAT
		TS	MARKSTAT
		
VERIFYMK	CA	XYMARK
		MASK	MARKSTAT
		CCS	A
		TCF	+2		# THIS MARK NOT DESIRED
		TCF	VACSTOR		# MARK DESIRED - STORE CDUS
		TC	ALARM
		OCT	114
		TC	RESUME		# RESUME - DISPLAY UNCHANGED - WAIT FOR ACTION

## Page 257
5MKALARM	TC	ALARM		# ATTEMPTING TO MAKE MORE THAN 5 MK PAIRS
		OCT	107
		TC	MARKTYPE	# SEE IF SURFACE MARK
		TCF	DSPV6N79	# IT IS
		TC	RESUME		# DONT CHANGE DISPLAY - DO NOTHING
		
## Page 258
MKREJ		TC	MARKTYPE	# SEE IF SURFACE
		TCF	SURFREJ		# SURFACE - JUST CHECK MARK COUNTER
		
		CAF	PRIO3		# INFLIGHT - SEE IF MARKS MADE
		MASK	MARKSTAT
		CCS	A
		TCF	REJECT		# MARKS MADE - REJECT ONE
REJALM		TC	ALARM		# NO MARK TO REJECT - BAD PROCEDURE - ALARM
		OCT	115
		TC	RESUME		# DESIRED ACTION DISPLAYED
		
REJECT		CS	PRIO30		# ZERO BIT14, SHOW REJ.,SEE IF MARK SINCE
		MASK	MARKSTAT	# LAST REJECT
		AD	BIT13
		XCH	MARKSTAT
		MASK	BIT13
		CCS	A
		TCF	REJECT2		# ANOTHER REJECT SET BIT 10+11 TO ZERO
		
		CS	XYMARK		# MARK MADE SINCE REJECT - REJECT MARK IN 1D
RENEWMK		MASK	MARKSTAT
		TS	MARKSTAT
		TCF	REMARK		# GO REQUEST NEW MARK ACTION
		
REJECT2		CS	PRIO3		# ON SECOND REJECT - DISPLAY VB53 AGAIN
		TCF	RENEWMK
		
SURFREJ		CCS	MARKCNTR	# IF MARK DECREMENT COUNTER
		TCF	+2
		TCF	REJALM		# NO MARKS TO REJECT - ALARM
		TS	MARKCNTR
		TC	RESUME

## Page 259
# MARKTYPE TESTS TO SEE IF LEM ON LUNAR SURFACE.  IF IT IS RETURN TO LOC+1

MARKTYPE	CS	FLAGWRD8	# SURFFLAG *******TEMPORARY*****
		MASK	BIT8
		CCS	A
		INCR	Q		# IF SURFACE MARK REUTNR TO LOC +1
		TC	Q		# IF INFLIGHT MARK RETURN TO LOC +2
		
SURFSTOR	CAF	ZERO		# FOR SURFACE MARK ZERO MARK KIND INDEX
		TS	RUPTREG1
		
		CS	MARKSTAT	# SET BITS 10,11 TO SHOW SURFACE MARK
		MASK	PRIO3		# FOR MARKCHEX
		ADS	MARKSTAT
		
VACSTOR		CAF	LOW9
		MASK	MARKSTAT	# STORE MARK VAC ADR IN RUPTREG2
		TS	RUPTREG2
		EXTEND
		DCA	ITEMP1		# PICK UP MARKTIME
		DXCH	TSIGHT		# STORE LAST MARK TIME
		CA	MARKCNTR	# 6 X MARKCNTR FOR STORE INDEX
		EXTEND
		MP	SIX
		XCH	L		# GET INDEX FROM LOW ORDER PART
		AD	RUPTREG2	# SET CDU STORE INDEX TO MARKVAC
		ADS	RUPTREG1	# INCREMENT VAC PICKUP BY MARK FOR FLIGHT
		TS	MKDEX		# STORE HERE IN CASE OF SURFACE MARK
		CA	ITEMP3
		INDEX	RUPTREG1
		TS	0		# STORE CDUY
		CA	ITEMP4
		INDEX	RUPTREG1
		TS	2		# STORE CDUZ
		CA	ITEMP5
		INDEX	RUPTREG1
		TS	4		# STORE CDUX
		TC	MARKTYPE	# IF SURFACE MARK - JUST DO SURFJOB
		TCF	SURFJOB
		
		CAF	BIT13		# CLEAR BIT13 TO SHOW MARK MADE
		AD	XYMARK		# SET MARK ID IN MARKSTAT
		COM
		MASK	MARKSTAT
		AD	XYMARK
		TS	MARKSTAT
		MASK	PRIO3		# SEE IF X, Y MARK MADE
		TS	L
		
## Page 260
		CA	PRIO3
		EXTEND
		RXOR	LCHAN
		CCS	A
		TCF	REMARK		# NOT PAIR YET, DISPLAY MARK ACTION
		CS	MARKSTAT	# MARK PAIR COMPLETE - SET BIT14
		MASK	BIT14
		ADS	MARKSTAT
		TCF	REMARK		# GO DISPLAY V54
		
## Page 261
REMARK		CAF	PRIO3		# BITS 10 AND 11
		MASK	MARKSTAT
		EXTEND
		MP	BIT6		# SHIFT MARK IDS TO BE 0 TO 3 FOR INDEX
		TS	MKDEX		# STORE VERB INDEX
SURFJOB		CAF	PRIO15
		TC	NOVAC		# ENTER JOB TO CHANGE DISPLAY TO
		EBANK=	XYMARK		# REQUEST NEXT ACTION
		2CADR	CHANGEVB
		
		TC	RESUME
		
CHANGEVB	TC	MARKTYPE
		TCF	DSPV6N79	# SURFACE - DISPLAY V 06 N79
		INDEX	MKDEX		# INFLIGHT - PICK UP MARK VB INDEX
		CAF	MKVB54
		TC	PASTIT		# PASTE UP NEXT MK VERB DISPLAY
		
# THE FOUR MKVBS ARE INDEXED - THEIR ORDER CANNOT BE CHANGED

MKVB54		VN	5471		# MAKE X OR Y MARK
MKVB53		VN	5371		# MAKE Y MARK
MKVB52		VN	5271		# MAKE X MARK
MKVB54*		VN	5471		# MAKE X OR Y MARK
DP1/8		2DEC	.125

OCT34		OCT	34
V06N71		VN	671
V06N79*		VN	679

## Page 262
# ROUTINE TO REQUEST CURSOR AND SPIRAL MEASUREMENTS
		COUNT*	$$/R59
		
DSPV6N79	CAF	V06N79*		# CURSOR - SPIRAL DISPLAY
		TC	BANKCALL
		CADR	GOMARKF
		
		TCF	KILLAOT		# V34 - DOES GOTOPOOH
		TCF	SURFEND		# V33 - PROCEED, END MARKING
		CAF	BIT6		# IF V32 (OCT40) IN MPAC DO RECYCLE
		MASK	MPAC		# OTHERWISE IT IS LOAD VB ENTER SO
		CCS	A		# RE-DISPLAY V06N79
		TCF	SURFAGAN	# VB32 - RECYCLE
		TCF	DSPV6N79	# ENTER
		
SURFEND		CS	BIT14		# SET BIT14 TO SHOW MARK END
		MASK	MARKSTAT
		AD	BIT14
		TS	MARKSTAT
		
SURFAGAN	CA	CURSOR
		INDEX	MKDEX		# HOLDS VAC AREA POINTER FOR SURF MARKING
		TS	1		# STORE CURSOR SP 2COMP
		CA	SPIRAL
		INDEX	MKDEX
		TS	3		# STORE SPIRAL
		
		CS	MARKSTAT	# IF BIT 14 SET - END MARKING
		MASK	BIT14
		EXTEND
		BZF	MARKCHEX
		CA	MARKCNTR	# THIS IS RECYCLE - SEE IF 5 MARKS ALREADY
		AD	ONE
		COM
		AD	FIVE
		EXTEND
		BZMF	5MKALARM	# CANT RECYCLE - TO MANY MARKS - ALARM
		INCR	MARKCNTR	# OF FOR RECYCLE - INCR COUNTER
		TCF	GETMKS +3	# GO DISPLAY MARK VB
		
