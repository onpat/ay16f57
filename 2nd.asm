;	AY-3-8910 PIC16F57 RSF Player

;	5V, PIC 3.58MHz, AY-3-8910 1.79Mhz
;	PORTC = DA7-DA0
;	PORTA = BDIR,(BC2),BC1,LED
;	PORTB = x,x,x,x,TACT,RST,SCL,SDA
;	MCLR  = VDD
;	SDA and SCL needs 10k pullup !!!

	LIST	P=PIC16F57
	INCLUDE "P16F5X.INC"
	__CONFIG _XT_OSC & _WDT_OFF & _CP_OFF

;Variable registers setting...

; AY register variable
adr	EQU	08h
dat	EQU	09h

; EEPROM register
ROM_CHIP	EQU	0Ah		;デバイスアドレスの指定で使う
ROM_ADD_H	EQU	0Bh		;アドレス上位1バイトの指定に使う
ROM_ADD_L	EQU	0Ch		;アドレス下位1バイトの指定に使う
BUFFER		EQU	0Dh		;各種状態ビットを格納
DATA_IN		EQU	0Eh		;EEPROM受信データ
DATA_OUT	EQU	0Fh		;EEPROMに送信するデータ
BITCOUNT	EQU	10h		;クロック数のレジスタ「8」
AY_ADDRL	EQU 11h		;AY アドレス変数0-7
AY_ADDRH	EQU 12h		;AY アドレス変数8-15
AY_STATUS	EQU	13h		;AY ステータス変数, 00000000=YM,x,x,LASTREAD,WAITCHK,ADDRH,ADDRL,WAITFE
AY_IF		EQU 14h		;分岐変数
AY_COUNT	EQU 15h		;ループカウンタ
SNG_STATUS	EQU 16h		;プレイヤー情報, 00000000=x,x,x,x,x,x,x,INFOLOAD
SNG_TPOS	EQU 17h		;曲位置
SNG_FSH		EQU	18h		;一曲目の上位アドレス
SNG_FSL		EQU	19h
SNG_SEH		EQU	1Ah
SNG_SEL		EQU	1Bh
SNG_THH		EQU	1Ch
SNG_THL		EQU	1Dh
SNG_FOH		EQU	1Eh
SNG_FOL		EQU	1Fh

;Bank 1
AY_IOA		EQU	30h

;EEPROM Definition
SCL     EQU  1  ; SCL端子とする端子番号
SDA     EQU  0  ; SDA端子とする端子番号, need to set 0
DO      EQU  0
DI      EQU  1
ACK_BIT EQU  2  ; ACK信号の有無

	org 0
	goto	START

; Main program ...
;Init

	org	8

START
	GOTO	INIT ;port, reset, regsiter init, check ym or ay
INIT2
	GOTO	MIX ;enable A and init IOA, IOB
MIX2
	BSF		STATUS, 5	; setting Status bit 5 enables access to 200-3FF
						; bit 6 unused?
	GOTO	UPINIT		;IO test
UPINIT2					;doesn't work on GI AY-3-8910
	GOTO	TEST_A5E
TEST_A5E2
	GOTO	TEST_AON
TEST_AON2
	BSF		PORTA, 0
	BTFSC	AY_STATUS, 7 ; if ym, led off
	BCF		PORTA, 0
	GOTO	TIME1000
TIME10002
	GOTO	TEST_AOFF
TEST_AOFF2

		;First, load song address ... 
		; if addr is 0000h that song is not avail
		MOVLW  h'0000'
		MOVWF  ROM_CHIP    ;デバイスアドレスを指定
		MOVLW  h'0000'
		MOVWF  ROM_ADD_H   ;アドレス上位1バイトを指定
		MOVLW  h'0000'
		MOVWF  ROM_ADD_L   ;アドレス下位1バイトを指定
		GOTO   ROM_READ    ;ROM読み出しルーチンへ
ROM_READ2

;Loop start

	GOTO LOOP1

;Sub-routines

;YMZ294 Routines from http://hijiri3.s65.xrea.com/sorekore/develop/pic/PIC04_YMZ.htm
WREG
		; Addr -> Inactive ->
		; Write -> Read(?)
		; or wait and Inactive (may be inaccurate)
		;                 d21l
		movlw		B'00001111'
		movwf		PORTA
		movf		adr,W
		movwf		PORTC; write addr
		movlw		B'00000101'
		movwf		PORTA

		movlw		B'00001101'
		movwf		PORTA
		movf		dat,W
		movwf		PORTC; write value
		;CALL		ROM_TIM
		movlw		B'00000110'
		movwf		PORTA
		RETLW	0

RREG	;Read from AY-3-8910
		; Inactive -> Addr -> 
		; (PORTC Hi-Z) -> Read
		;                 d21l
		movlw		B'00001111'
		movwf		PORTA
		movf		adr,W
		movwf		PORTC; write addr
		movlw		B'00000101'
		movwf		PORTA 

		MOVLW		b'11111111'
		TRIS		PORTC

		movlw		B'00000111'
		movwf		PORTA; read value
		CALL		ROM_TIM
		movf		PORTC,W
		movwf		dat
		movlw		B'00000100'
		movwf		PORTA
		MOVLW		b'00000000'
		TRIS		PORTC
		RETLW	0

TIME20
TMRLOOP
	BTFSS	01h,7
	GOTO	TMRLOOP
	MOVLW	3Ah
	MOVWF	01h
	RETLW	0

;eeprom ...
; I2C EEPROM 1バイト送信
BYTE_OUT
  MOVLW  H'0008'
  MOVWF  BITCOUNT    ;8ループ
BYTE_OUT_2
  BSF    BUFFER,DO
  BTFSS  DATA_OUT,7
  BCF    BUFFER,DO
  CALL   BIT_OUT
  RLF    DATA_OUT,F
  DECFSZ BITCOUNT,F
  GOTO   BYTE_OUT_2
  CALL   BIT_IN
  RETLW	0

; I2C EEPROM 1バイト受信
BYTE_IN
  CLRF   DATA_IN
  MOVLW  H'0008'
  MOVWF  BITCOUNT    ;8ループ 
  BCF    STATUS,C
BYTE_IN_2
  RLF    DATA_IN,F
  CALL   BIT_IN
  BTFSC  BUFFER,DI
  BSF    DATA_IN,0
  DECFSZ BITCOUNT,F
  GOTO   BYTE_IN_2
  BSF    BUFFER,DO
  BTFSC  BUFFER,ACK_BIT
  BCF    BUFFER,DO
  CALL   BIT_OUT
  RETURN

ROM_READ
  CALL   SDA_IN      ;SDA端子を入力モードにする

  CALL   START_CON   ;スタートシーケンスへ
  CALL   ROM_TIM

  ;h'00A0' = 1010   000      0
  ;               dev addr  r/w 
  ;If you use 1Mbit EEPROM (CAT24M01 etc.)
  ;     1010    00      0    0
  ;           dev addr a16  r/w
  ; a16 is this -> 1 FF FF h
  ;In sequencial read, you don't need to mind this
  ;unless start address of seq read is above FFFFh
  ; device addr is A1,A2 pin in datasheet(high = 1).
  ;Not a I2C address! (sure it wont fit in 2bit)
  ;https://www.zea.jp/audio/schematic/sc_file/021.htm

  MOVLW  h'00A0'     ;コントロールビット+書き込みビット
  IORWF  ROM_CHIP,W  ;上記にデバイスアドレスを加える
  MOVWF  DATA_OUT    ;DATA_OUTレジスタに移動
  CALL   BYTE_OUT    ;コントロールシーケンス（1バイト）の送出
  CALL   ROM_TIM

  MOVF   ROM_ADD_H,W
  MOVWF  DATA_OUT    ;アドレス上位をDATA_OUTレジスタに移動
  CALL   BYTE_OUT    ;アドレス上位送信
  CALL   ROM_TIM

  MOVF   ROM_ADD_L,W
  MOVWF  DATA_OUT    ;アドレス下位をDATA_OUTレジスタに移動
  CALL   BYTE_OUT    ;アドレス下位送信
  CALL   ROM_TIM

  CALL   START_CON   ;スタートシーケンスへ
  CALL   ROM_TIM

  MOVLW  h'00A1'     ;コントロールビット+読み込みビット
  IORWF  ROM_CHIP,W  ;上記にデバイスアドレスを加える
  MOVWF  DATA_OUT    ;DATA_OUTレジスタに移動
  CALL   BYTE_OUT    ;コントロールシーケンス（1バイト）の送出
  CALL   ROM_TIM


SEQ_READ
	;RSF Playback Routine
	;Register Stream Flow has 2 bytes of address and value follows
	;0x00 0x01 0x02 0x03 ...
	;adrh adrl val1 val2 ... valx valy
	;
	;          76543210
	;          --------
	;if adrl = 00010001, write val1 in 0x00 and val2 in 0x04
	;if adrh = 00001100, write valx in 0x0a and valy in 0x0b
	;
	;Please delete header before write the rsf file!
	BTFSC	AY_STATUS, 4 ;if lastread = 1
	GOTO	POST_RINT
	BSF    BUFFER,ACK_BIT ;ACKビットを立てて連続読み出しにする READ_INT
	CALL   BYTE_IN     ;1バイトを受信（受信後にACKを送出する）
POST_RINT
	BCF		AY_STATUS, 4 ; lastread = 0 

	BTFSS	SNG_STATUS, 0; if song status = 0
	GOTO	INFOLOAD

	BTFSC	PORTB, 3 ; if PORTB, 3 = High
	GOTO	LAST_READ
SEQTRIG2

	;BSF		STATUS, 5
	;GOTO	UPEXT		;Extended routine
;UPEXT2	

	BTFSC   AY_STATUS, 0 ;if WAITFE = 1
	goto	SEQFEWAIT

	;check if writing data
	BTFSS	AY_STATUS, 3; if wait check = 0
	GOTO	WRITELOOP

	MOVLW	h'FF'
	MOVWF	AY_IF
	movf	AY_IF,W; DATA2 if DATA1 = DATA2, 
	xorwf	DATA_IN,W; DATA1
	btfsc	STATUS,Z; do next
	goto	SEQWAIT;FF=wait

	MOVLW	h'FE'
	MOVWF	AY_IF
	movf	AY_IF,W; DATA2 if DATA1 = DATA2, 
	xorwf	DATA_IN,W; DATA1
	btfsc	STATUS,Z; do next
	goto	SEQWAITFE;FE=wait x times

	MOVLW	h'FD'
	MOVWF	AY_IF
	movf	AY_IF,W; DATA2 if DATA1 = DATA2, 
	xorwf	DATA_IN,W; DATA1
	btfsc	STATUS,Z; do next
	goto	LAST_READ;FD=song end

WRITELOOP
	BCF		AY_STATUS, 3; no wait check

	BTFSS	AY_STATUS, 2 ;if ADDRH = 0
	goto 	SEQADDRH; load addr hi

	BTFSS	AY_STATUS, 1 ;if ADDRL = 0
	goto 	SEQADDRL; load addr lo

	;Start reading values...
	;First, Lower address
	CLRF	AY_COUNT
LAW ;lower ay address (0x00-0x07) write
	BTFSC	AY_ADDRL, 0 ;if bit set, then write
	GOTO	SEQL
SEQL2
	RRF		AY_ADDRL, 1; incl to next bit
	incf	AY_COUNT,F ; incl. loop
	movf	AY_COUNT,W
	xorlw	0x08
	btfss	STATUS,Z
	GOTO 	LAW
	
HAW; higher ay address(0x08-0x0D) write
	BTFSC	AY_ADDRH, 0 ;if bit set, then write
	GOTO	SEQH
SEQH2
	RRF		AY_ADDRH, 1; incl to next bit
	incf	AY_COUNT,F ; incl. loop
	movf	AY_COUNT,W
	xorlw	0x0E
	btfss	STATUS,Z
	GOTO 	HAW

	;Clear STATUS
	BCF		AY_STATUS, 1;L
	BCF		AY_STATUS, 2;H
	BSF		AY_STATUS, 3;WAITCHK
	BSF		AY_STATUS, 4;LASTREAD

	GOTO	SEQWAIT

SEQWAIT
	CALL   TIME20
	GOTO   SEQ_READ

SEQWAITFE
	BSF		AY_STATUS, 0
	GOTO	SEQ_READ

SEQFEWAIT
LOOPFE	
	CALL	TIME20
	decfsz	DATA_IN,F
	GOTO	LOOPFE
	BCF		AY_STATUS, 0; Clear WAITFE
	GOTO	SEQ_READ

SEQADDRL
	MOVF   DATA_IN,W
	MOVWF  AY_ADDRL
	BSF    AY_STATUS, 1
	GOTO   SEQ_READ

SEQADDRH
	MOVF   DATA_IN,W
	MOVWF  AY_ADDRH
	BSF    AY_STATUS, 2
	GOTO   SEQ_READ

LAST_READ
  BCF    BUFFER,ACK_BIT ;ACKビットを送出しないで最終読み出し
  CALL   BYTE_IN     ;1バイトを受信（受信後にACKは送出しない）
  CALL   ROM_TIM

  ;add routine here

  CALL   STOP_CON    ;ストップシーケンスへ

  BTFSC  SNG_STATUS, 0
  GOTO   SEQSNGSEL			;Goto Song Selector
  BSF	 SNG_STATUS, 0
  GOTO   ROM_READ2          ;INIT end

; I2C EEPROM スタートシーケンス
START_CON
  BSF    PORTB,SCL
  CALL   ROM_TIM
  CALL   SDA_OUT
  BCF    PORTB,SDA
  CALL   ROM_TIM
  BCF    PORTB,SCL
  CALL   SDA_IN
  RETURN

; I2C EEPROM ストップシーケンス
STOP_CON
  CALL   SDA_OUT
  BCF    PORTB,SDA
  BSF    PORTB,SCL
  CALL   ROM_TIM
  CALL   SDA_IN
  RETURN

; I2C EEPROM 1ビット送信
BIT_OUT
  BCF    PORTB,SCL
  BTFSS  BUFFER,DO
  GOTO   BIT_OUT_3
BIT_OUT_2
  BSF    PORTB,SCL
  GOTO   $+1         ;2サイクル ROM_WAIT
  GOTO   $+1         ;2サイクル
  GOTO   $+1         ;2サイクル
  GOTO   $+1         ;2サイクル
  GOTO   $+1         ;2サイクル
  ;GOTO   $+1         ;2サイクル
  ;GOTO   $+1         ;2サイクル
  ;GOTO   $+1         ;2サイクル
  BCF    PORTB,SCL
  MOVLW	B'00001001' ; SDA_IN
  TRIS	PORTB   ;SDA端子を入力設定
  RETURN
BIT_OUT_3
  MOVLW	B'00001000' ; SDA_OUT
  TRIS	PORTB   ;SDA端子を出力設定
  BSF    PORTB,0
  BCF    PORTB,SDA
  GOTO   BIT_OUT_2

; I2C EEPROM 1ビット受信
BIT_IN
  BCF    PORTB,SCL
  MOVLW	B'00001001' ; SDA_IN
  TRIS	PORTB   ;SDA端子を入力設定
  BSF    BUFFER,DI
  BSF    PORTB,SCL
  GOTO   $+1         ;2サイクル ROM_WAIT
  GOTO   $+1         ;2サイクル
  GOTO   $+1         ;2サイクル
  GOTO   $+1         ;2サイクル
  GOTO   $+1         ;2サイクル
  ;GOTO   $+1         ;2サイクル
  ;GOTO   $+1         ;2サイクル
  ;GOTO   $+1         ;2サイクル
  BTFSS  PORTB,SDA
  BCF    BUFFER,DI
  BCF    PORTB,SCL
  RETURN

; I2C EEPROM SDA入力端子設定
SDA_IN
  MOVLW	B'00001001'
  TRIS	PORTB   ;SDA端子を入力設定
  RETURN

; I2C EEPROM SDA出力端子設定
SDA_OUT
  MOVLW	B'00001000'
  TRIS	PORTB   ;SDA端子を出力設定
  BSF    PORTB,0
  RETURN

ROM_TIM ;16 cycle = 1117ns * 16 = 17.8us in 3.58Mhz
  GOTO   $+1         ;2サイクル
  GOTO   $+1         ;2サイクル
  GOTO   $+1         ;2サイクル
  GOTO   $+1         ;2サイクル
  GOTO   $+1         ;2サイクル
  GOTO   $+1         ;2サイクル
  ;GOTO   $+1         ;2サイクル
  ;GOTO   $+1         ;2サイクル
	RETLW	0

INFOLOAD

	; EEPROM Structure:
	; 00 01 02 03 04 05 06 07 
	; 1H 1L 2H 2L 3H 3L 4H 4L 
	; =first address of songs
	; up to 4 tracks

	MOVF	DATA_IN, 0
	MOVWF	SNG_FSH
	BSF    BUFFER,ACK_BIT ;ACKビットを立てて連続読み出しにする SEQ_READ_INT
	CALL   BYTE_IN     ;1バイトを受信（受信後にACKを送出する）
	MOVF	DATA_IN, 0
	MOVWF	SNG_FSL
	BSF    BUFFER,ACK_BIT ;ACKビットを立てて連続読み出しにする SEQ_READ_INT
	CALL   BYTE_IN     ;1バイトを受信（受信後にACKを送出する）
	MOVF	DATA_IN, 0
	MOVWF	SNG_SEH
	BSF    BUFFER,ACK_BIT ;ACKビットを立てて連続読み出しにする SEQ_READ_INT
	CALL   BYTE_IN     ;1バイトを受信（受信後にACKを送出する）
	MOVF	DATA_IN, 0
	MOVWF	SNG_SEL
	BSF    BUFFER,ACK_BIT ;ACKビットを立てて連続読み出しにする SEQ_READ_INT
	CALL   BYTE_IN     ;1バイトを受信（受信後にACKを送出する）
	MOVF	DATA_IN, 0
	MOVWF	SNG_THH
	BSF    BUFFER,ACK_BIT ;ACKビットを立てて連続読み出しにする SEQ_READ_INT
	CALL   BYTE_IN     ;1バイトを受信（受信後にACKを送出する）
	MOVF	DATA_IN, 0
	MOVWF	SNG_THL
	BSF    BUFFER,ACK_BIT ;ACKビットを立てて連続読み出しにする SEQ_READ_INT
	CALL   BYTE_IN     ;1バイトを受信（受信後にACKを送出する）
	MOVF	DATA_IN, 0
	MOVWF	SNG_FOH
	BSF    BUFFER,ACK_BIT ;ACKビットを立てて連続読み出しにする SEQ_READ_INT
	CALL   BYTE_IN     ;1バイトを受信（受信後にACKを送出する）
	MOVF	DATA_IN, 0
	MOVWF	SNG_FOL
	GOTO	LAST_READ

SEQSNGSEL
		CALL	TIME20
SELECTLOOP
		BTFSC	PORTB, 3 ; if PORTB, 3 = High
		GOTO	SELECTLOOP

		MOVLW	h'00' ;end fs?
		MOVWF	AY_IF
		movf	AY_IF,W; DATA2 if DATA1 = DATA2, 
		xorwf	SNG_TPOS,W; DATA1
		btfsc	STATUS,Z; do next
		GOTO	NORFS

		MOVLW	h'01' ;end se?
		MOVWF	AY_IF
		movf	AY_IF,W; DATA2 if DATA1 = DATA2, 
		xorwf	SNG_TPOS,W; DATA1
		btfsc	STATUS,Z; do next
		GOTO	NORSE

		MOVLW	h'02' ;end th?
		MOVWF	AY_IF
		movf	AY_IF,W; DATA2 if DATA1 = DATA2, 
		xorwf	SNG_TPOS,W; DATA1
		btfsc	STATUS,Z; do next
		GOTO	NORTH

		MOVLW	h'03' ;end fo?
		MOVWF	AY_IF
		movf	AY_IF,W; DATA2 if DATA1 = DATA2, 
		xorwf	SNG_TPOS,W; DATA1
		btfsc	STATUS,Z; do next
		GOTO	NORFO

SEQL

	MOVF	DATA_IN, 0; SEQWRITE
	MOVWF	dat
	MOVF	AY_COUNT, 0
	MOVWF	adr

	; if 0x07, bit 7,6 is 1,0
	; IOB=Output, IOA=Input
	movlw	0x07 ;DATA1=DATA2 goto setio
	xorwf	adr,W
	btfsc	STATUS,Z
	goto	SETIO
SETIO2

	CALL	WREG
	BSF    BUFFER,ACK_BIT ;ACKビットを立てて連続読み出しにする SEQ_READ_INT
  	CALL   BYTE_IN     ;1バイトを受信（受信後にACKを送出する）	; write reg
	GOTO	SEQL2

SETIO
	movf	dat, W
	iorlw	B'10000000' ;set iob to output
	andlw	B'10111111' ;set ioa to input
	movwf	dat
	goto	SETIO2

SEQH
	MOVF	DATA_IN, 0; SEQWRITE
	MOVWF	dat
	MOVF	AY_COUNT, 0
	MOVWF	adr
	CALL	WREG
	BSF    BUFFER,ACK_BIT ;ACKビットを立てて連続読み出しにする SEQ_READ_INT
  	CALL   BYTE_IN     ;1バイトを受信（受信後にACKを送出する）	; write reg
	GOTO	SEQH2

LOOP1	
		MOVLW	h'00'
		MOVWF	AY_IF
		movf	AY_IF,W; DATA2 if DATA1 = DATA2, 
		xorwf	SNG_TPOS,W; DATA1
		btfsc	STATUS,Z; do next
		GOTO	LOADFS
LOADFS2
		MOVLW	h'01'
		MOVWF	AY_IF
		movf	AY_IF,W; DATA2 if DATA1 = DATA2, 
		xorwf	SNG_TPOS,W; DATA1
		btfsc	STATUS,Z; do next
		GOTO	LOADSE
LOADSE2
		MOVLW	h'02'
		MOVWF	AY_IF
		movf	AY_IF,W; DATA2 if DATA1 = DATA2, 
		xorwf	SNG_TPOS,W; DATA1
		btfsc	STATUS,Z; do next
		GOTO	LOADTH
LOADTH2
		MOVLW	h'03'
		MOVWF	AY_IF
		movf	AY_IF,W; DATA2 if DATA1 = DATA2, 
		xorwf	SNG_TPOS,W; DATA1
		btfsc	STATUS,Z; do next
		GOTO	LOADFO
LOADFO2
		GOTO	LOOP1

LOADFS
		movf	SNG_FSL,W ;zero check
		iorwf	SNG_FSH,W
		btfsc	STATUS,Z
		goto	NORFS

		MOVLW  h'0000'
		MOVWF  ROM_CHIP    ;デバイスアドレスを指定
		MOVF   SNG_FSH, 0
		MOVWF  ROM_ADD_H   ;アドレス上位1バイトを指定
		MOVF   SNG_FSL, 0
		MOVWF  ROM_ADD_L   ;アドレス下位1バイトを指定
		GOTO   ROM_READ    ;ROM読み出しルーチンへ
NORFS
		INCF	SNG_TPOS, 1
		CALL	TIME20
		GOTO	LOADFS2

LOADSE
		movf	SNG_SEL,W ;zero check
		iorwf	SNG_SEH,W
		btfsc	STATUS,Z
		goto	NORSE

		MOVLW  h'0000'
		MOVWF  ROM_CHIP    ;デバイスアドレスを指定
		MOVF   SNG_SEH, 0
		MOVWF  ROM_ADD_H   ;アドレス上位1バイトを指定
		MOVF   SNG_SEL, 0
		MOVWF  ROM_ADD_L   ;アドレス下位1バイトを指定
		GOTO   ROM_READ    ;ROM読み出しルーチンへ
NORSE
		INCF	SNG_TPOS, 1
		CALL	TIME20
		GOTO	LOADSE2	

LOADTH
		movf	SNG_THL,W ;zero check
		iorwf	SNG_THH,W
		btfsc	STATUS,Z
		goto	NORTH

		MOVLW  h'0000'
		MOVWF  ROM_CHIP    ;デバイスアドレスを指定
		MOVF   SNG_THH, 0
		MOVWF  ROM_ADD_H   ;アドレス上位1バイトを指定
		MOVF   SNG_THL, 0
		MOVWF  ROM_ADD_L   ;アドレス下位1バイトを指定
		GOTO   ROM_READ    ;ROM読み出しルーチンへ
NORTH
		INCF	SNG_TPOS, 1
		CALL	TIME20
		GOTO	LOADTH2	

LOADFO
		movf	SNG_FOL,W ;zero check
		iorwf	SNG_FOH,W
		btfsc	STATUS,Z
		goto	NORFO

		MOVLW  h'0000'
		MOVWF  ROM_CHIP    ;デバイスアドレスを指定
		MOVF   SNG_FOH, 0
		MOVWF  ROM_ADD_H   ;アドレス上位1バイトを指定
		MOVF   SNG_FOL, 0
		MOVWF  ROM_ADD_L   ;アドレス下位1バイトを指定
		GOTO   ROM_READ    ;ROM読み出しルーチンへ
NORFO
		CLRF	SNG_TPOS
		CALL	TIME20
		GOTO	LOADFO2	

INIT
	MOVLW	b'00001000'
	TRIS	PORTB ; PORTB is EEPROM/Switch
	BCF		PORTB, 2 ; reset enable
	MOVLW	0x00
	TRIS	PORTA ; PORTA is LED/ctrl
	MOVLW	B'00010111'	; TMR0 prescaler set to 64(19ms)
	OPTION
	CLRF	AY_COUNT
	BSF		PORTB, 2 ; reset disable
	BTFSC	PORTB, 3 ;if PORTB, 3 = High
	GOTO	DISPC
	MOVLW	0x00
	TRIS	PORTC ; PORTC is data/addr bus
	BSF		PORTA, 0
	CLRF	AY_ADDRL
	CLRF	AY_ADDRH
	CLRF	AY_STATUS
	CLRF	SNG_STATUS
	CLRF	SNG_TPOS
	GOTO	CHKAY
CHKAY2
	GOTO	INIT2

TIME1000
  MOVLW  D'63'
  MOVWF  adr
TIMELOOP1
  CALL	TIME20
  DECFSZ adr,F
  GOTO   TIMELOOP1
  GOTO	TIME10002

DISPC ;	PIC frequency test / Device mode
	MOVLW	0xFF
	TRIS	PORTC ; PORTC is data/addr bus
				  ; Hi-Z for use in Arduino etc
	MOVLW	b'00001110'
	TRIS	PORTA ; PORTA is BC1/BC2/BDIR, Hi-Z
LOOPDISPC
	CALL	TIME20
	BSF		PORTA, 0
	CALL	TIME20
	BCF		PORTA, 0
	INCF	AY_COUNT, F
	BTFSC	AY_COUNT, 7 ;if AY_COUNT is 127
	SLEEP
	GOTO	LOOPDISPC

DBGLOOP
	MOVF	PORTC, 0
	BCF		PORTA, 0
LOOP2
	MOVWF	PORTB
	goto	LOOP2

MIX
	MOVLW	07h
	MOVWF	adr
	MOVLW	0xB8 ; 10111000
	MOVWF	dat
	CALL	WREG
	GOTO	MIX2

TEST_A5E
		movlw		01h		;Address
		movwf		adr
		movlw		B'00000000'	;Data
		movwf		dat
		call		WREG
		movlw		00h		;Address
		movwf		adr
		movlw		B'11100010'	;Data
		movwf		dat
		call		WREG
		GOTO	TEST_A5E2

TEST_AON
		movlw		08h		;Address		(Ach Volume Setting)
		movwf		adr
		movlw		B'00001111'	;Data
		movwf		dat
		call		WREG
		GOTO	TEST_AON2

TEST_AOFF
		movlw		08h		;Address		(Ach Volume Setting)
		movwf		adr
		movlw		B'00000000'	;Data
		movwf		dat
		call		WREG
		GOTO	TEST_AOFF2

CHKAY
	;Check whether AY or YM
	;by reading unused bit
	; if YM, LED blinks

		movlw		B'00001111'
		movwf		PORTA
	MOVLW	0x01
		movwf		PORTC; write addr
		movlw		B'00000101'
		movwf		PORTA 
		movlw		B'00001100'
		movwf		PORTA
	MOVLW	B'10001010'
		movwf		PORTC; write value
		CALL		ROM_TIM
		movlw		B'00000101'
		movwf		PORTA
	MOVLW	0x01
	MOVWF	adr
	clrf	dat
	CALL	RREG
	BTFSC	dat, 7 ; if dat, 7 = 1
	BSF		AY_STATUS, 7 ; set YM bit
	GOTO	CHKAY2

;UARTLOOP ; not implemented
		 ; AY-AVR Player uses 57600bps,
		 ; 8bits, 1 stop bits, no parity
		 ; PIC is 895000 inst per sec
		 ; only RX is needed ...
;	GOTO	UARTTMR
;UARTTMR2
;	GOTO	UARTWAIT
;UARTWAIT2
;	GOTO	UARTLOOP
	
;UARTTMR
;UTLOOP
;	BTFSS	01h,7
;	GOTO	UTLOOP
;	MOVLW	h'F5'
;	MOVWF	01h
;	GOTO	UARTTMR2

;UARTWAIT
;UALOOP
;	BTFSS	01h,7
;	GOTO	UALOOP
;	MOVLW	h'00'
;	MOVWF	01h
;	GOTO	UARTWAIT2

	org 0x200 ;Page Boundary

UPWREG
		; Addr -> Inactive ->
		; Write -> Inactive
		;                 d21l
		movlw		B'00001111'
		movwf		PORTA
		movf		adr,W
		movwf		PORTC; write addr
		movlw		B'00000101'
		movwf		PORTA 

		movlw		B'00001100'
		movwf		PORTA
		movf		dat,W
		movwf		PORTC; write value
		movlw		B'00000101'
		movwf		PORTA
		NOP
		NOP
		RETLW	0

UPRREG	;Read from AY-3-8910
		; Inactive -> Addr -> 
		; (PORTC Hi-Z) -> Read
		;                 d21l
		movlw		B'00001111'
		movwf		PORTA
		movf		adr,W
		movwf		PORTC; write addr
		movlw		B'00000101'
		movwf		PORTA 

		MOVLW		b'11111111'
		TRIS		PORTC

		movlw		B'00000110'
		movwf		PORTA; read value
		NOP
		NOP
		movf		PORTC,W
		movwf		dat
		movlw		B'00000101'
		movwf		PORTA
		MOVLW		b'00000000'
		TRIS		PORTC
		RETLW	0

UPINIT
	;if ioa 3 = 1, iob = 10101010
	;else 01010101
	movlw	0x0e
	movwf	adr
	call	UPRREG
	movf	dat, W
	BSF		FSR, 5 ; bank 1
	movwf	AY_IOA
	BCF		FSR, 5 ; bank 0
	
	movlw	0x0f
	movwf	adr
	movlw	B'10101010'
	BSF		FSR, 5 ; bank 1
	BTFSS	AY_IOA, 3
	movlw	B'01010101'
	BCF		FSR, 5 ; bank 0
	movwf	dat
	call	UPWREG
	BCF		STATUS, 5
	GOTO	UPINIT2

;UPEXT
	;Main loop extended
;	BSF		FSR, 5 ; bank 1

;	BCF		FSR, 5 ; bank 0

;	BCF		STATUS, 5
;	GOTO	UPEXT2

;UPTIME20
;	MOVLW	3Ah
;	MOVWF	01h
;UPTMRLOOP
;	BTFSS	01h,7
;	GOTO	UPTMRLOOP
;	RETLW	0

	END



