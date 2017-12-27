		Ideal
		;p8086n
		model small ;; we produce .EXE file 
;---------------------------------------------------------------------------------------------------
; Macros
;---------------------------------------------------------------------------------------------------
; Pad code to create entry point at specified address (needed for 100% IBM BIOS compatibility)
macro	jmpfar	segm, offs
	db	0EAh;
	dw	offs, segm
endm


; Line feed and carriage return
LF	equ	0Ah
CR	equ	0Dh


dsk_motor_stat equ 03Fh
dsk_motor_tmr equ 040h
dsk_ret_code equ 041h

dsk_motor_stat_ equ 043Fh


; ===========================================================================
		
; Segment type:	Pure code
segment		code byte public 'CODE'
		assume cs:code
		org 0E000h
		assume es:nothing, ss:nothing, ds:nothing


Banner:
str_banner	db  0Ah
		db  0Dh
		db    7
    		db 'New optimized superfast MS 1502 BIOS Version 7.2 (c) S. Mikayev '
		db '1996'
loc_0E047h:
		db 0Ah
		db 0Dh
		db	  0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		
; ---------------------------------------------------------------------------
proc		post	near
warm_boot:				; ...
		cli
		cld
@@init_PPI:
		mov	al, 88h
		out	63h, al		; PC/XT	PPI Command/Mode Register.
					; Selects which	PPI ports are input or output.
					; BIOS sets to 99H (Ports A and	C are input, B is output).
		mov	al, 98h
		out	6Bh, al
		mov	al, 9
		out	62h, al		; PC/XT	PPI port C. Bits:
					; 0-3: values of DIP switches
					; 5: 1=Timer 2 channel out
					; 6: 1=I/O channel check
					; 7: 1=RAM parity check	error occurred.

		mov	al, 0E0h
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
@@init_PIC:				;Basic offset 68h for keyboard scenner procedure
		mov	al, 13h
		out	20h, al		; Interrupt controller,	8259A.
		mov	al, 68h
		out	21h, al		; Interrupt controller,	8259A.
		mov	al, 9
		out	21h, al		; Interrupt controller,	8259A.
@@init_PIT:
		mov	al, 36h
		out	43h, al		; Timer	8253-5 (AT: 8254.2).
		mov	al, 0
		out	40h, al		; Timer	8253-5 (AT: 8254.2).
		out	40h, al		; Timer	8253-5 (AT: 8254.2).
		mov	al, 50h
		out	43h, al		; Timer	8253-5 (AT: 8254.2).
		mov	al, 4
		out	41h, al		; Timer	8253-5 (AT: 8254.2).
		mov	al, 0B6h
		out	43h, al		; Timer	8253-5 (AT: 8254.2).
		mov	al, 2
		out	42h, al		; Timer	8253-5 (AT: 8254.2).
		out	42h, al		; Timer	8253-5 (AT: 8254.2).
		mov	ax, 40h
		mov	ds, ax
		assume ds:nothing
		xor	ax, ax
		mov	ss, ax
		mov	sp, 800h
		mov	bp, [ds:72h]
		mov	di, ax
		mov	es, ax
		mov	cx, 380h
		rep stosw
		push	cs
		pop	ds
		assume ds:nothing

@@init_vec_table_1:
		mov	cx, 17h
		mov	si, offset int_vec_table_1
		mov	di, 20h

vec_table_1_loop:				; ...
		lodsw
		stosw
		mov	ax, cs
		stosw
		loop	vec_table_1_loop

@@init_vect_table_2:
		mov	cx, 8
		mov	si, offset int_vec_table_2
		mov	di, 1A0h

vec_table_2_loop:				; ...
		lodsw
		stosw
		mov	ax, cs
		stosw
		loop	vec_table_2_loop

@@init_dummy_int:
		mov	di, 8
		mov	ax, offset dummy_int
		stosw
		mov	ax, cs
		stosw

@@init_print_screen_int:
		mov	di, 14h
		mov	ax, offset int_05h
		stosw
		mov	ax, cs
		stosw
		mov	ax, 40h
		mov	es, ax
		assume es:nothing

@@init_BDA:
		mov	cx, 10h
		mov	si, offset BDA
		xor	di, di
		rep movsw
@@Test_type_fdc:
		in	al, 4Bh
		not	al
		out	4Bh, al
		mov	ah, al
		in	al, 4Bh
		mov	si, offset port_int_fdc
		cmp	al, ah
		jz	short init_fdc_BDA
		mov	si, offset port_ext_fdc

init_fdc_BDA:				; ...
		mov	di, 42h
		movsw
		movsw
		mov	di, 80h
		mov	ax, 1Eh
		stosw
		mov	ax, 3Eh
		stosw
		mov	al, 18h
		stosb
		mov	di, 90h
		xor	ax, ax
		stosw
		mov	bx, ax
		mov	cx, ax
		mov	di, ax
		mov	ds, ax
		assume ds:nothing

		dw 3 dup (0)
loc_FE12E:				; ...
		mov	ax, [bx]
		not	ax
		mov	[bx], ax
		cmp	ax, [bx]
		jnz	short loc_FE148
		not	[word ptr bx]
		add	ch, 8
		mov	ds, cx
		assume ds:nothing
		add	di, 20h
		cmp	di, 2E0h
		jb	short loc_FE12E

loc_FE148:				; ...
		mov	[es:13h], di
		mov	al, 0FCh
		out	21h, al		; Interrupt controller,	8259A.
		sti
		mov	ax, 3
		int	10h		; - VIDEO - SET	VIDEO MODE
					; AL = mode
		mov	si, Banner
		call	sub_FE24F
		cmp	bp, 1234h
		jz	short loc_FE1AC
		mov	si, offset TestingSystem
		call	sub_FE24F
		mov	cx, 2
		call	sub_FE247
		mov	ax, es
		mov	ds, ax
		assume ds:nothing
		xor	ax, ax
		mov	bx, ax
		mov	dx, ax
		mov	es, ax
		assume es:nothing
		jmp	short loc_FE182
; ---------------------------------------------------------------------------

loc_FE17D:				; ...
		call	sub_FE21E
		jnz	short loc_FE1F0

loc_FE182:				; ...
		mov	ax, es
		add	ah, 8
		mov	es, ax
		assume es:nothing
		mov	ax, dx
		add	al, 32h
		daa
		adc	ah, 0
		mov	dx, ax
		mov	cx, 3
		call	sub_FE247
		mov	al, dh
		call	sub_FE26B
		mov	al, dl
		call	sub_FE262
		add	bx, 20h
		cmp	bx, [ds:13h]
		jb	short loc_FE17D

loc_FE1AC:				; ...
		mov	ax, 40h
		mov	ds, ax
		mov	[word ptr ds:67h], 3
		mov	[word ptr ds:69h], 0BE00h

loc_FE1BD:				; ...
		mov	ax, 40h
		mov	ds, ax
		add	[word ptr ds:6Ah], 2
		cmp	[word ptr ds:69h], 0FE00h
		jz	short loc_FE1E2
		mov	es, [word ptr ds:69h]
		assume es:nothing
		cmp	[word ptr es:0], 0AA55h
		jnz	short loc_FE1BD
		call	[dword ptr ds:67h]
		jmp	short loc_FE1BD
; ---------------------------------------------------------------------------

loc_FE1E2:				; ...
		mov	si, loc_0E047h
		call	sub_FE24F
		xor	cx, cx

loc_FE1EA:				; ...
		loop	loc_FE1EA

loc_FE1EC:				; ...
		loop	loc_FE1EC
		int	19h		; DISK BOOT
					; causes reboot	of disk	system

loc_FE1F0:				; ...
		push	ax
		mov	si, offset FailedAt
		call	sub_FE24F
		dec	di
		dec	di
		mov	ax, es
		call	sub_FE25B
		mov	ax, 0E3Ah
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		mov	ax, di
		call	sub_FE25B
		mov	ax, 0E20h
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		pop	ax
		xor	ax, [es:di]
		call	sub_FE25B
		mov	[ds:13h], bx
		xor	ax, ax
		int	16h		; KEYBOARD - READ CHAR FROM BUFFER, WAIT IF EMPTY
					; Return: AH = scan code, AL = character
		jmp	short loc_FE1AC
endp		post



proc		sub_FE21E near		; ...
		mov	ax, 0FFFFh
		call	sub_FE238
		jnz	short locret_FE24E
		mov	ax, 0AAAAh
		call	sub_FE238
		jnz	short locret_FE24E
		mov	ax, 5555h
		call	sub_FE238
		jnz	short locret_FE24E
		xor	ax, ax
endp		sub_FE21E ; sp-analysis	failed





proc		sub_FE238 near		; ...
		mov	cx, 4000h
		xor	di, di
		rep stosw
		mov	cx, 4000h
		xor	di, di
		repe scasw
		retn
endp		sub_FE238





proc		sub_FE247 near		; ...
		mov	ax, 0E08h
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		loop	sub_FE247

locret_FE24E:				; ...
		retn
endp		sub_FE247





proc		sub_FE24F near		; ...
		lods	[byte ptr cs:si]
		or	al, al
		jz	short locret_FE24E
		mov	ah, 0Eh
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		jmp	short sub_FE24F
endp		sub_FE24F





proc		sub_FE25B near		; ...
		xchg	ah, al
		call	sub_FE262
		xchg	ah, al
endp		sub_FE25B ; sp-analysis	failed





proc		sub_FE262 near		; ...
		mov	cl, 4
		rol	al, cl
		call	sub_FE26B
		rol	al, cl
endp		sub_FE262 ; sp-analysis	failed





proc		sub_FE26B near		; ...
		push	ax
		and	al, 0Fh
		add	al, 90h
		daa
		adc	al, 40h
		daa
		mov	ah, 0Eh
		int	10h		; - VIDEO - WRITE CHARACTER AND	ADVANCE	CURSOR (TTY WRITE)
					; AL = character, BH = display page (alpha modes)
					; BL = foreground color	(graphics modes)
		pop	ax
		retn
endp		sub_FE26B

; ---------------------------------------------------------------------------
TestingSystem:
		db 0Ah, 0Dh, 'Testing system memory ...'
		db 0Ah, 0Dh, 'Complete 000 K', 0
		
FailedAt	db 7, 0Ah, 0Dh, 'Failed at ', 0

SystemNotFound	db 7, 0Ah, 0Dh, 'System not found.', 0Ah, 0Dh, 0
 
port_int_fdc:
		db  48h	 		; ...
		db  4Ch	 
		db  4Eh	 
		db  4Dh	 
		
port_ext_fdc:	
		db  0Ch
		db  00h
		db  08h
		db  0Ah




proc		sub_FE2D3 near		; ...
		mov	dh, [ds:45h]
		dec	dh
		and	dh, 1
		retn
endp		sub_FE2D3





proc		sub_FE2DD near		; ...
		push ax
		mov	[byte ptr ds:dsk_motor_tmr], 0FFh ; dsk_motor_tmr
		mov	[byte ptr ds:dsk_motor_tmr], 0FFh ; dsk_motor_tmr

loc_FE2E8:				; ...
		in	al, dx
		shr	al, 1
		jb	short loc_FE2E8
		pop	ax
		retn
endp		sub_FE2DD





proc		sub_FE2EF near		; ...
		push	ax
		push	cx
		mov	ax, si
		inc	ax
		mov	ah, ch
		test	[ds:3Eh], al
		jnz	short loc_FE308
		call	sub_FE394
		jnb	short loc_FE304
		pop	cx
		jmp	short loc_FE36A
; ---------------------------------------------------------------------------
; dsk_status ?
loc_FE304:				; ...
		or	[ds:3Eh], al

loc_FE308:				; ...
		mov	al, ah
		call	sub_FE2D3
		mov	dl, [ds:0042h]
		inc	dx
		out	dx, al
		mov	cl, [ds:0048h]
		shl	al, cl
		cmp	al, [si+46h]
		nop
		jz	short loc_FE360
		inc	dx
		inc	dx
		out	dx, al
		xchg al, [si+ 0046h]
		nop
		dec	dx
		dec	dx
		out	dx, al
		dec	dx
		mov	al, 10h
		out	dx, al
		call	sub_FE2DD
		mov	al, ah
		mov	dl, [ds:0042h]
		inc	dx
		out	dx, al
		test	[byte ptr ds:dsk_motor_stat], 80h
		jz	short loc_FE360
		inc	dx
		inc	dx
		out	dx, al
		mov	dl, [ds:42h]
		mov	al, bl
		out	dx, al
		mov	dl, [ds:44h]
		in	al, dx
		mov	dl, [ds:42h]
		in	al, dx
		and	al, 19h
		jz	short loc_FE360
		or	[byte ptr ds:41h], 40h
		stc
		pop	cx
		jmp	short loc_FE36A
; ---------------------------------------------------------------------------

loc_FE360:				; ...
		pop	cx
		mov	al, cl
		mov	dl, [ds:42h]
		inc	dx
		inc	dx
		out	dx, al

loc_FE36A:				; ...
		pop	ax
		retn
endp		sub_FE2EF





proc		sub_FE36C near		; ...
		mov	al, 0D0h
		call	sub_FE2D3
		mov	dl, [ds:42h]
		out	dx, al
		call	sub_FE2DD
		mov	al, 0C0h
		out	dx, al
		mov	ah, 3
		add	ah, dl

loc_FE380:				; ...
		mov	dl, [ds:44h]
		in	al, dx
		shr	al, 1
		mov	dl, ah
		in	al, dx
		jb	short loc_FE380
		mov	dl, [ds:42h]
		in	al, dx
		and	al, 10h
		retn
endp		sub_FE36C





proc		sub_FE394 near		; ...
		push	ax
		mov	dl, [ds:43h]
		in	al, dx
		mov	dl, [ds:42h]
		mov	al, 0D0h
		out	dx, al
		call	sub_FE2DD
		mov	al, 9
		out	dx, al
		call	sub_FE2DD
		in	al, dx
		and	al, 5
		cmp	al, 4
		jz	short loc_FE3B7
		or	[byte ptr ds:41h], 80h
		stc

loc_FE3B7:				; ...
		mov	dl, [ds:43h]
		in	al, dx
		mov	[byte ptr si+0046h], 0
		nop
		pop	ax
		retn
endp		sub_FE394





proc		sub_FE3C3 near		; ...
		push	ax
		push	cx
		and	dl, 1
		mov	si, dx
		and	si, 1
		mov	cl, dl
		inc	cx
		mov	[byte ptr ds:0048h], 0
		test	[byte ptr si+90h], 10h
		jnz	short loc_FE3E1
		mov	[byte ptr si+0090h], 17h

loc_FE3E1:				; ...
		test	[byte ptr si+0090h], 20h
		jz	short loc_FE3F8
		cmp	ch, 2Ch
		jnb	short loc_FE3F3
		inc	[byte ptr ds:0048h]
		jmp	short loc_FE3F8
; ---------------------------------------------------------------------------

loc_FE3F3:				; ...
		and	[byte ptr si+90h], 0DFh

loc_FE3F8:				; ...
		mov	al, 82h
		test	[byte ptr ds:dsk_motor_stat], 40h
		jz	short loc_FE404
		xor	dl, 1

loc_FE404:				; ...
		test	dl, 1
		jz	short loc_FE40B
		mov	al, 8Ch

loc_FE40B:				; ...
		or	al, dh
		test	[byte ptr si+90h], 0C0h
		jnz	short loc_FE416
		or	al, 10h

loc_FE416:				; ...
		rol	al, 1
		call	sub_FE2D3
		mov	ah, 0FFh
		mov	[ds:dsk_motor_tmr], ah
		
		inc	ah
		mov	dl, [ds:43h]
		out	dx, al
		in	al, dx
		mov	dl, [ds:42h]
		mov	al, 0D0h
		out	dx, al
		test	[ds:dsk_motor_stat], cl
		jnz	short loc_FE446

loc_FE436:				; ...
		mov	al, [ds:dsk_motor_tmr]
		sub	al, ah
		not	al
		shr	al, 1
		cmp	al, [cs:MotorOn]
		jb	short loc_FE436

loc_FE446:				; ...
		and	[byte ptr ds:dsk_motor_stat], 0FCh
		or	[ds:dsk_motor_stat], cl
		pop	cx
		pop	ax
		retn
endp		sub_FE3C3





proc		sub_FE452 near		; ...
		cli
		push	ax
		mov	al, [ds:65h]
		test	al, 1
		jz	short loc_FE48C
		mov	ax, es
		push	cx
		mov	cl, 4
		push	bx
		shr	bx, cl
		add	ax, bx
		pop	bx
		pop	cx
		push	ax
		mov	ax, [ds:0013h] ; main_ram_size
		cmp	ax, 0060h
		pop	ax
		ja	short loc_FE475
		mov	al, 0
		jmp	short loc_FE488
; ---------------------------------------------------------------------------

loc_FE475:				; ...
		cmp	ax, 7EC0h
		jb	short loc_FE48C
		cmp	ax, 0C000h
		jnb	short loc_FE48C
		mov	al, 0
		jmp	short loc_FE488
endp		sub_FE452





proc		sub_FE483 near		; ...
		sti
		push	ax
		mov	al, [ds:65h]

loc_FE488:				; ...
		mov	dx, 3D8h
		out	dx, al

loc_FE48C:				; ...
		pop	ax
		retn
endp		sub_FE483

;---------------------------------------------------------------------------------------------------
; Interrupt 69h - Keyboard scan
;---------------------------------------------------------------------------------------------------
proc		int_69h near
		sti
		push	ax
		push	bx
		push	cx
		push	dx
		push	di
		push	bp
		push	ds
		mov	ax, 40h
		mov	ds, ax
		mov	bx, offset unk_FE58C
		mov	di, 0
		mov	bp, 0FFFEh

loc_FE4A4:				; ...
		mov	ax, bp
		out	69h, ax
		in	al, 68h
		mov	ah, al
		or	al, [di+93h]
		inc	al
		jz	short loc_FE4D2
		neg	al
		or	[di+93h], al
		call	sub_FE51F
		mov	[ds:0A0h], di
		mov	dl, 80h

loc_FE4C3:				; ...
		rol	dl, 1
		test	al, dl
		jz	short loc_FE4C3
		mov	[ds:0A2h], dl
		mov	[byte ptr ds:9Eh], 9

loc_FE4D2:				; ...
		mov	al, ah
		and	al, [di+93h]
		jz	short loc_FE4E1
		xor	[di+93h], al
		call	sub_FE54B

loc_FE4E1:				; ...
		inc	di
		rol	bp, 1
		test	bp, 800h
		jnz	short loc_FE4A4
		mov	di, [ds:0A0h]
		mov	al, [ds:0A2h]
		test	[di+93h], al
		jz	short loc_FE50F
		dec	[byte ptr ds:9Eh]
		jnz	short loc_FE50F
		mov	[byte ptr ds:9Eh], 1
		mov	dx, [ds:1Ah]
		cmp	dx, [ds:1Ch]
		jnz	short loc_FE50F
		call	sub_FE51F

loc_FE50F:				; ...
		xor	ax, ax
		out	69h, ax
		mov	al, 20h
		out	20h, al		; Interrupt controller,	8259A.
		pop	ds
		assume ds:nothing
		pop	bp
		pop	di
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		iret
endp 		int_69h




proc		sub_FE51F near		; ...
		push	ax
		mov	dx, di
		mov	cx, 803h
		mov	dh, al
		shl	dl, cl

loc_FE529:				; ...
		rcl	dh, 1
		jnb	short loc_FE545
		call	sub_FE571
		or	al, al
		jnz	short loc_FE541
		test	[byte ptr ds:9Fh], 80h
		jnz	short loc_FE545
		not	[byte ptr ds:9Fh]
		jmp	short loc_FE545
; ---------------------------------------------------------------------------

loc_FE541:				; ...
		out	60h, al		; 8042 keyboard	controller data	register.
		int	9		;  - IRQ1 - KEYBOARD INTERRUPT
					; Generated when data is received from the keyboard.

loc_FE545:				; ...
		dec	ch
		jnz	short loc_FE529
		pop	ax
		retn
endp		sub_FE51F





proc		sub_FE54B near		; ...
		mov	dx, di
		mov	cx, 803h
		mov	dh, al
		shl	dl, cl

loc_FE554:				; ...
		rcl	dh, 1
		jnb	short loc_FE56C
		call	sub_FE571
		or	al, al
		jnz	short loc_FE566
		and	[byte ptr ds:9Fh], 7Fh
		jmp	short loc_FE56C
; ---------------------------------------------------------------------------

loc_FE566:				; ...
		or	al, 80h
		out	60h, al		; 8042 keyboard	controller data	register.
		int	9		;  - IRQ1 - KEYBOARD INTERRUPT
					; Generated when data is received from the keyboard.

loc_FE56C:				; ...
		dec	ch
		jnz	short loc_FE554
		retn
endp		sub_FE54B





proc		sub_FE571 near		; ...
		mov	al, ch
		dec	al
		or	al, dl
		xlat	[byte ptr cs:bx]
		cmp	al, 55h
		jb	short locret_FE58B
		and	[byte ptr ds:17h], 0DFh
		push	bx
		mov	bx, offset unk_FE5E4
		sub	al, 55h
		xlat	[byte ptr cs:bx]
		pop	bx

locret_FE58B:				; ...
		retn
endp		sub_FE571

; ---------------------------------------------------------------------------
unk_FE58C:
		db  4Ah	; J		; ...
		db  46h	; F
		db  44h	; D
		db  36h	; 6
		db  2Ah	; *
		db  47h	; G
		db  48h	; H
		db  49h	; I
		db    1
		db  0Fh
		db  1Dh
		db  38h	; 8
		db    0
		db  52h	; R
		db  53h	; S
		db  4Eh	; N
		db    2
		db  10h
		db  1Eh
		db  2Ch	; ,
		db  3Ah	; :
		db  4Fh	; O
		db  50h	; P
		db  51h	; Q
		db  3Bh	; ;
		db    3
		db  11h
		db  1Fh
		db  2Dh	; -
		db  4Bh	; K
		db  4Ch	; L
		db  4Dh	; M
		db  3Ch	; <
		db    4
		db  12h
		db  20h
		db  2Eh	; .
		db  45h	; E
		db  42h	; B
		db  43h	; C
		db  3Dh	; =
		db    5
		db  13h
		db  21h	; !
		db  2Fh	; /
		db  0Eh
		db  41h	; A
		db  40h	; @
		db    6
		db  14h
		db  22h	; "
		db  30h	; 0
		db  39h	; 9
		db  55h	; U
		db  1Ch
		db  37h	; 7
		db  3Eh	; >
		db    7
		db  15h
		db  23h	; #
		db  31h	; 1
		db  57h	; W
		db  58h	; X
		db  2Bh	; +
		db  3Fh	; ?
		db    8
		db  16h
		db  24h	; $
		db  32h	; 2
		db  29h	; )
		db  1Bh
		db  0Dh
		db    9
		db  17h
		db  25h	; %
		db  33h	; 3
		db  56h	; V
		db  28h	; (
		db  1Ah
		db  0Ch
		db  0Ah
		db  18h
		db  26h	; &
		db  34h	; 4
		db  35h	; 5
		db  27h	; '
		db  19h
		db  0Bh
unk_FE5E4:	
		db  4Dh	; M		; ...
		db  4Bh	; K
		db  50h	; P
		db  48h	; H




proc		sub_FE5E8 near		; ...
		call	sub_FE875
		test	[byte ptr ds:9Fh], 7Fh
		jz	short locret_FE655
		test	[byte ptr ds:17h], 4
		jnz	short locret_FE655
		push	bx
		cmp	ah, 2
		jb	short loc_FE654
		cmp	ah, 0Ch
		jb	short loc_FE644
		cmp	ah, 10h
		jb	short loc_FE654
		cmp	ah, 1Ch
		jb	short loc_FE61D
		cmp	ah, 1Eh
		jb	short loc_FE654
		cmp	ah, 2Ah
		jz	short loc_FE654
		cmp	ah, 35h
		jge	short loc_FE654

loc_FE61D:				; ...
		mov	al, ah
		sub	al, 10h
		test	[byte ptr ds:17h], 40h
		jnz	short loc_FE636
		test	[byte ptr ds:17h], 3
		jnz	short loc_FE63D

loc_FE62F:				; ...
		mov	bx, offset unk_FE656
		xlat	[byte ptr cs:bx]
		jmp	short loc_FE654
; ---------------------------------------------------------------------------

loc_FE636:				; ...
		test	[byte ptr ds:17h], 3
		jnz	short loc_FE62F

loc_FE63D:				; ...
		mov	bx, offset unk_FE689
		xlat	[byte ptr cs:bx]
		jmp	short loc_FE654
; ---------------------------------------------------------------------------

loc_FE644:				; ...
		test	[byte ptr ds:17h], 3
		jz	short loc_FE654
		mov	al, ah
		sub	al, 2
		mov	bx, offset unk_FE67B
		xlat	[byte ptr cs:bx]

loc_FE654:				; ...
		pop	bx

locret_FE655:				; ...
		retn
endp		sub_FE5E8

; ---------------------------------------------------------------------------
unk_FE656	db 0A9h	; ©		; ...
		db 0E6h	; ?
		db 0E3h	; ?
		db 0AAh	; ?
		db 0A5h	; ?
		db 0ADh	; ­
		db 0A3h	; ?
		db 0E8h	; ?
		db 0E9h	; ?
		db 0A7h	; §
		db 0E5h	; ?
		db 0EAh	; ?
		db    0
		db    0
		db 0E4h	; ?
		db 0EBh	; ?
		db 0A2h	; ?
		db 0A0h	;  
		db 0AFh	; ?
		db 0E0h	; ?
		db 0AEh	; ®
		db 0ABh	; «
		db 0A4h	; ?
		db 0A6h	; ¦
		db 0EDh	; ?
		db 0F1h	; ?
		db    0
		db  5Bh	; [
		db 0EFh	; ?
		db 0E7h	; ?
		db 0E1h	; ?
		db 0ACh	; ¬
		db 0A8h	; ?
		db 0E2h	; ?
		db 0ECh	; ?
		db 0A1h	; ?
		db 0EEh	; ?
unk_FE67B	db  21h	; !		; ...
		db  22h	; "
		db  23h	; #
		db  3Bh	; ;
		db  3Ah	; :
		db  2Ch	; ,
		db  2Eh	; .
		db  2Ah	; *
		db  28h	; (
		db  29h	; )
		db    0
		db    0
		db    0
		db    0
unk_FE689	db  89h	; ‰		; ...
		db  96h	; –
		db  93h	; “
		db  8Ah	; ?
		db  85h	; …
		db  8Dh	; ?
		db  83h	; ?
		db  98h	; ?
		db  99h	; ™
		db  87h	; ‡
		db  95h	; •
		db  9Ah	; ?
		db    0
		db    0
		db  94h	; ”
		db  9Bh	; ›
		db  82h	; ‚
		db  80h	; ˆ
		db  8Fh	; ?
		db  90h	; ?
		db  8Eh	; ?
		db  8Bh	; ‹
		db  84h	; „
		db  86h	; †
		db  9Dh	; ?
		db 0F0h	; ?
		db    0
		db  5Dh	; ]
		db  9Fh	; ?
		db  97h	; —
		db  91h	; ‘
		db  8Ch	; ?
		db  88h	; ?
		db  92h	; ’
		db  9Ch	; ?
		db  81h	; ?
		db  9Eh	; ?
; ---------------------------------------------------------------------------

loc_FE6AE:				; ...
		test	[byte ptr es:417h], 3
		jnz	short loc_FE6FA
		mov	ax, 0E000h
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		mov	ds, ax
		assume ds:nothing
		cmp	[word ptr ds:1FEh], 0AA55h
		jnz	short loc_FE6F8
		cmp	[byte ptr ds:20h], 0EAh
		jz	short loc_FE6F8
		;jmp	far ptr	0E000h:0
		jmpfar	0e000h,0
; ---------------------------------------------------------------------------
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
;---------------------------------------------------------------------------------------------------
; Interrupt 19h - Warm Boot
;---------------------------------------------------------------------------------------------------
proc		int_19h
		xor	dx, dx
		mov	es, dx
		jmp	short loc_FE6AE
loc_FE6F8:				; ...
		mov	dl, 80h

loc_FE6FA:				; ...
		mov	cx, 3

loc_FE6FD:				; ...
		push	cx
		mov	ah, dh
		int	13h		; DISK - RESET DISK SYSTEM
					; DL = drive (if bit 7 is set both hard	disks and floppy disks reset)
		jb	short loc_FE714
		mov	bx, 7C00h
		mov	cx, 1
		mov	ax, 201h
		int	13h		; DISK - READ SECTORS INTO MEMORY
					; AL = number of sectors to read, CH = track, CL = sector
					; DH = head, DL	= drive, ES:BX -> buffer to fill
					; Return: CF set on error, AH =	status,	AL = number of sectors read
		pop	cx
		jnb	short loc_FE733
		loop	loc_FE6FD

loc_FE714:				; ...
		shl	dl, 1
		jb	short loc_FE6FA
		test	[byte ptr es:dsk_motor_stat_], 40h
		jnz	short loc_FE728
		or	[byte ptr es:dsk_motor_stat_], 40h
		jmp	short loc_FE6FA
; ---------------------------------------------------------------------------

loc_FE728:				; ...
		mov	si, offset SystemNotFound
		call	sub_FE24F
		sti

loc_FE731:				; ...
		jmp	short loc_FE731
; ---------------------------------------------------------------------------

loc_FE733:				; ...
		cmp	[word ptr es:7DFEh], 0AA55h
		jnz	short loc_FE714
		;jmp	far ptr	0:7C00h
		jmpfar 0,7C00h
endp		int_19h
; ---------------------------------------------------------------------------
                                
data_28		dw	0470h ; Data table (indexed access)
		db  41h	; A
		db    3
		db 0A1h	; ?
		db    1
		db 0D0h	; ?
		db    0
		db  68h	; h
		db    0
		db  34h	; 4
		db    0
		db  1Ah
		db    0
		db  0Dh
		db    0
;---------------------------------------------------------------------------------------------------
; Interrupt 14h - RS232
;---------------------------------------------------------------------------------------------------
proc		int_14h
		sti
		push	bx
		push	cx
		push	dx
		mov	dx, 28h
		or	ah, ah
		jnz	short loc_FE7BA
		push	ax
		mov	ah, al
		mov	al, 76h
		out	43h, al		; Timer	8253-5 (AT: 8254.2).
		xor	bx, bx
		mov	bl, ah
		mov	cl, 4
		rol	bl, cl
		and	bl, 0Eh
		mov	ax, cs:data_28[bx]
		out	41h, al		; Timer	8253-5 (AT: 8254.2).
		nop
		mov	al, ah
		out	41h, al		; Timer	8253-5 (AT: 8254.2).
		inc	dx
		mov	al, 65h
		out	dx, al
		call	sub_FEF60
		mov	al, 5
		out	dx, al
		call	sub_FEF60
		mov	al, 65h
		out	dx, al
		call	sub_FEF60
		pop	ax
		or	ah, 4Ah
		test	al, 1
		jz	short loc_FE798
		or	ah, 4

loc_FE798:				; ...
		test	al, 4
		jz	short loc_FE79F
		or	ah, 80h

loc_FE79F:				; ...
		test	al, 8
		jz	short loc_FE7AD
		or	ah, 10h
		test	al, 10h
		jz	short loc_FE7AD
		or	ah, 20h

loc_FE7AD:				; ...
		mov	al, ah
		out	dx, al
		call	sub_FEF60
		mov	al, 27h
		out	dx, al
		dec	dx
		jmp	loc_FEF66
; ---------------------------------------------------------------------------

loc_FE7BA:				; ...
		dec	ah
		jz	short loc_FE7CC
		dec	ah
		jz	short loc_FE7F7
		dec	ah
		jnz	short loc_FE7C9
		jmp	loc_FEF66
; ---------------------------------------------------------------------------

loc_FE7C9:				; ...
		jmp	short loc_FE7F3
; ---------------------------------------------------------------------------
		nop

loc_FE7CC:				; ...
		mov	ah, 0
		push	ax
		inc	dx
		mov	al, 27h
		out	dx, al
		xor	cx, cx

loc_FE7D5:				; ...
		in	al, dx
		test	al, 80h
		jnz	short loc_FE7DF
		loop	loc_FE7D5
		pop	ax
		jmp	short loc_FE7F0
; ---------------------------------------------------------------------------

loc_FE7DF:				; ...
		xor	cx, cx

loc_FE7E1:				; ...
		in	al, dx
		test	al, 1
		jnz	short loc_FE7EB
		loop	loc_FE7E1
		pop	ax
		jmp	short loc_FE7F0
; ---------------------------------------------------------------------------

loc_FE7EB:				; ...
		dec	dx
		pop	ax
		out	dx, al
		jmp	short loc_FE7F3
; ---------------------------------------------------------------------------

loc_FE7F0:				; ...
		or	ah, 80h

loc_FE7F3:				; ...
		pop	dx
		pop	cx
		pop	bx
		iret
endp		int_14h
; ---------------------------------------------------------------------------

loc_FE7F7:				; ...
		mov	ah, 0
		xor	cx, cx
		inc	dx

loc_FE7FC:				; ...
		in	al, dx
		test	al, 4
		jnz	short loc_FE805
		loop	loc_FE7FC
		jmp	short loc_FE7F0
; ---------------------------------------------------------------------------

loc_FE805:				; ...
		mov	al, 27h
		out	dx, al
		xor	cx, cx

loc_FE80A:				; ...
		in	al, dx
		test	al, 80h
		jnz	short loc_FE813
		loop	loc_FE80A
		jmp	short loc_FE7F0
; ---------------------------------------------------------------------------

loc_FE813:				; ...
		xor	cx, cx

loc_FE815:				; ...
		in	al, dx
		test	al, 2
		jz	short loc_FE81D
		jmp	near ptr unk_FEF46
; ---------------------------------------------------------------------------

loc_FE81D:				; ...
		loop	loc_FE815
		jmp	short loc_FE7F0
; ---------------------------------------------------------------------------
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
;---------------------------------------------------------------------------------------------------
; Interrupt 16h - Keyboard
;---------------------------------------------------------------------------------------------------
proc		int_16h
		sti
		push	ds
		push	bx
		mov	bx, 40h
		mov	ds, bx
		assume ds:nothing
		or	ah, ah
		jz	short loc_FE845
		dec	ah
		jz	short loc_FE85E
		dec	ah
		jz	short loc_FE86F
		pop	bx
		pop	ds
		assume ds:nothing
		iret
endp		int_16h
; ---------------------------------------------------------------------------

loc_FE845:				; ...
		cli
		mov	bx, [ds:1Ah]
		cmp	bx, [ds:1Ch]
		sti
		nop
		jz	short loc_FE845
		mov	ax, [bx]
		call	sub_FE5E8
		mov	[ds:1Ah], bx
		pop	bx
		pop	ds
		iret
; ---------------------------------------------------------------------------

loc_FE85E:				; ...
		cli
		mov	bx, [ds:1Ah]
		cmp	bx, [ds:1Ch]
		mov	ax, [bx]
		sti
		pop	bx
		pop	ds
		retf	2
; ---------------------------------------------------------------------------

loc_FE86F:				; ...
		mov	al, [ds:17h]
		pop	bx
		pop	ds
		iret



proc		sub_FE875 near		; ...
		add	bx, 2
		
		cmp	bx, 0x003E
		nop
		jnz	short locret_FE881
		mov	bx, 1Eh
endp		sub_FE875 ; sp-analysis	failed


locret_FE881:				; ...
		retn
; ---------------------------------------------------------------------------
unk_FE882	db  52h	; R		; ...
unk_FE883	db  3Ah	; :		; ...
		db  45h	; E
		db  46h	; F
		db  38h	; 8
		db  1Dh
		db  2Ah	; *
		db  36h	; 6
data_31		db  80h	; ˆ
		db  40h	; @
		db  20h
		db  10h
		db    8
		db    4
		db    2
		db    1
unk_FE892	db  1Bh			; ...
		db 0FFh
		db    0
		db 0FFh
		db 0FFh
		db 0FFh
		db  1Eh
		db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh
		db  1Fh
		db 0FFh
		db  7Fh	; 
		db 0FFh
		db  11h
		db  17h
		db    5
		db  12h
		db  14h
		db  19h
		db  15h
		db    9
		db  0Fh
		db  10h
		db  1Bh
		db  1Dh
		db  0Ah
		db 0FFh
		db    1
		db  13h
		db    4
		db    6
		db    7
		db    8
		db  0Ah
		db  0Bh
		db  0Ch
		db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh
		db  1Ch
		db  1Ah
		db  18h
		db    3
		db  16h
		db    2
		db  0Eh
		db  0Dh
		db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh
		db  20h
		db 0FFh
unk_FE8CC	db  5Eh	; ^		; ...
		db  5Fh	; _
		db  60h	; `
		db  61h	; a
		db  62h	; b
		db  63h	; c
		db  64h	; d
		db  65h	; e
		db  66h	; f
		db  67h	; g
		db 0FFh
		db 0FFh
		db  77h	; w
		db 0FFh
		db  84h	; „
		db 0FFh
		db  73h	; s
		db 0FFh
		db  74h	; t
		db 0FFh
		db  75h	; u
		db 0FFh
		db  76h	; v
		db 0FFh
		db 0FFh
unk_FE8E5	db  1Bh			; ...
		db  31h	; 1
		db  32h	; 2
		db  33h	; 3
		db  34h	; 4
		db  35h	; 5
		db  36h	; 6
		db  37h	; 7
		db  38h	; 8
		db  39h	; 9
		db  30h	; 0
		db  2Dh	; -
		db  3Dh	; =
		db    8
		db    9
		db  71h	; q
		db  77h	; w
		db  65h	; e
		db  72h	; r
		db  74h	; t
		db  79h	; y
		db  75h	; u
		db  69h	; i
		db  6Fh	; o
		db  70h	; p
		db  5Bh	; [
		db  5Dh	; ]
		db  0Dh
		db 0FFh
		db  61h	; a
		db  73h	; s
		db  64h	; d
		db  66h	; f
		db  67h	; g
		db  68h	; h
		db  6Ah	; j
		db  6Bh	; k
		db  6Ch	; l
		db  3Bh	; ;
		db  27h	; '
		db  60h	; `
		db 0FFh
		db  5Ch	; \
		db  7Ah	; z
		db  78h	; x
		db  63h	; c
		db  76h	; v
		db  62h	; b
		db  6Eh	; n
		db  6Dh	; m
		db  2Ch	; ,
		db  2Eh	; .
		db  2Fh	; /
		db 0FFh
		db  2Ah	; *
		db 0FFh
		db  20h
		db 0FFh
unk_FE91F	db  1Bh			; ...
		db  21h	; !
		db  40h	; @
		db  23h	; #
		db  24h	; $
		db  25h	; %
		db  5Eh	; ^
		db  26h	; &
		db  2Ah	; *
		db  28h	; (
		db  29h	; )
		db  5Fh	; _
		db  2Bh	; +
		db    8
		db    0
		db  51h	; Q
		db  57h	; W
		db  45h	; E
		db  52h	; R
		db  54h	; T
		db  59h	; Y
		db  55h	; U
		db  49h	; I
		db  4Fh	; O
		db  50h	; P
		db  7Bh	; {
		db  7Dh	; }
		db  0Dh
		db 0FFh
		db  41h	; A
		db  53h	; S
		db  44h	; D
		db  46h	; F
		db  47h	; G
		db  48h	; H
		db  4Ah	; J
		db  4Bh	; K
		db  4Ch	; L
		db  3Ah	; :
		db  22h	; "
		db  7Eh	; ~
		db 0FFh
		db  7Ch	; |
		db  5Ah	; Z
		db  58h	; X
		db  43h	; C
		db  56h	; V
		db  42h	; B
		db  4Eh	; N
		db  4Dh	; M
		db  3Ch	; <
		db  3Eh	; >
		db  3Fh	; ?
		db 0FFh
		db    0
		db 0FFh
		db  20h
		db 0FFh
unk_FE959	db  54h	; T		; ...
		db  55h	; U
		db  56h	; V
		db  57h	; W
		db  58h	; X
		db  59h	; Y
		db  5Ah	; Z
		db  5Bh	; [
		db  5Ch	; \
		db  5Dh	; ]
unk_FE963	db  68h	; h		; ...
		db  69h	; i
		db  6Ah	; j
		db  6Bh	; k
		db  6Ch	; l
		db  6Dh	; m
		db  6Eh	; n
		db  6Fh	; o
		db  70h	; p
		db  71h	; q
unk_FE96D	db  37h	; 7		; ...
		db  38h	; 8
		db  39h	; 9
		db  2Dh	; -
		db  34h	; 4
		db  35h	; 5
		db  36h	; 6
		db  2Bh	; +
		db  31h	; 1
		db  32h	; 2
		db  33h	; 3
		db  30h	; 0
		db  2Eh	; .
unk_FE97A	db  47h	; G		; ...
		db  48h	; H
		db  49h	; I
		db 0FFh
		db  4Bh	; K
		db 0FFh
		db  4Dh	; M
		db 0FFh
		db  4Fh	; O
; ---------------------------------------------------------------------------
		push	ax  ; TODO Unknown PUSH
		push	cx
		push	dx
		push	bx

;---------------------------------------------------------------------------------------------------
; Interrupt 09h - keyaboard IRQ1 
;---------------------------------------------------------------------------------------------------
proc		int_09h
		sti
		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		cld
		mov	ax, 40h
		mov	ds, ax
		assume ds:nothing
		in	al, 60h		; 8042 keyboard	controller data	register
		mov	ah, al
		cmp	al, 0FFh
		jnz	short loc_FE9A1
		jmp	loc_FEC0F
; ---------------------------------------------------------------------------

loc_FE9A1:				; ...
		and	al, 7Fh
		push	cs
		pop	es
		assume es:nothing
		mov	di, offset unk_FE882
		mov	cx, 8
		repne scasb
		mov	al, ah
		jz	short loc_FE9B4
		jmp	loc_FEA3B
; ---------------------------------------------------------------------------

loc_FE9B4:				; ...
		sub	di, offset unk_FE883
		mov	ah, [cs:di-1776h]
		test	al, 80h
		jnz	short loc_FEA14
		cmp	ah, 10h
		jnb	short loc_FE9CD
		or	[ds:17h], ah
		jmp	loc_FEA4F
; ---------------------------------------------------------------------------

loc_FE9CD:				; ...
		test	[byte ptr ds:17h], 4
		jnz	short loc_FEA3B
		cmp	al, 52h

loc_FE9D6:
		jnz	short loc_FE9FC
		test	[byte ptr ds:17h], 8
		jz	short loc_FE9E1
		jmp	short loc_FEA3B
; ---------------------------------------------------------------------------

loc_FE9E1:				; ...
		test	[byte ptr ds:17h], 20h
		jnz	short loc_FE9F5
		test	[byte ptr ds:17h], 3
		jz	short loc_FE9FC

loc_FE9EF:				; ...
		mov	ax, 5230h
		jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FE9F5:				; ...
		test	[byte ptr ds:17h], 3
		jz	short loc_FE9EF

loc_FE9FC:				; ...
		test	[ds:18h], ah
		jnz	short loc_FEA4F
		or	[ds:18h], ah
		xor	[ds:17h], ah
		cmp	al, 52h
		jnz	short loc_FEA4F
		mov	ax, 5200h
		jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEA14:				; ...
		cmp	ah, 10h
		jnb	short loc_FEA33
		not	ah
		and	[ds:17h], ah
		cmp	al, 0B8h
		jnz	short loc_FEA4F
		mov	al, [ds:19h]
		mov	ah, 0
		mov	[ds:19h], ah
		cmp	al, 0
		jz	short loc_FEA4F
		jmp	loc_FEBD0
; ---------------------------------------------------------------------------

loc_FEA33:				; ...
		not	ah
		and	[ds:18h], ah
		jmp	short loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEA3B:				; ...
		cmp	al, 80h
		jnb	short loc_FEA4F
		test	[byte ptr ds:18h], 8
		jz	short loc_FEA59
		cmp	al, 45h
		jz	short loc_FEA4F
		and	[byte ptr ds:18h], 0F7h

loc_FEA4F:				; ...
		cli

loc_FEA50:				; ...
		pop	es
		assume es:nothing
		pop	ds
		assume ds:nothing
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		iret

endp		int_09h
; ---------------------------------------------------------------------------

loc_FEA59:				; ...
		test	[byte ptr ds:17h], 8
		jnz	short loc_FEA63
		jmp	loc_FEAF2
; ---------------------------------------------------------------------------

loc_FEA63:				; ...
		test	[byte ptr ds:17h], 4
		jz	short near ptr unk_FEA9B
		cmp	al, 53h
		jnz	short near ptr unk_FEA9B
		mov	[word ptr ds:72h], 1234h
		jmp	warm_boot
; ---------------------------------------------------------------------------
unk_FEA77	db  52h	; R		; ...
unk_FEA78	db  4Fh	; O		; ...
		db  50h	; P
		db  51h	; Q
		db  4Bh	; K
		db  4Ch	; L
		db  4Dh	; M
		db  47h	; G
		db  48h	; H
		db  49h	; I
		db  10h
		db  11h
		db  12h
		db  13h
		db  14h
		db  15h
		db  16h
		db  17h
		db  18h
		db  19h
		db  1Eh
		db  1Fh
		db  20h
		db  21h	; !
		db  22h	; "
		db  23h	; #
		db  24h	; $
		db  25h	; %
		db  26h	; &
		db  2Ch	; ,
		db  2Dh	; -
		db  2Eh	; .
		db  2Fh	; /
		db  30h	; 0
		db  31h	; 1
		db  32h	; 2
unk_FEA9B	db  3Ch	; <		; ...
; ---------------------------------------------------------------------------
		cmp	[di+5],	si
		mov	al, 20h
		jmp	loc_FEBC7
; ---------------------------------------------------------------------------
		mov	di, offset unk_FEA77
		mov	cx, 0Ah
		repne scasb
		jnz	short loc_FEAC0
		sub	di, offset unk_FEA78
		mov	al, [ds:19h]
		mov	ah, 0Ah
		mul	ah
		add	ax, di
		mov	[ds:19h], al
		jmp	short loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEAC0:				; ...
		mov	[byte ptr ds:19h], 0
		mov	cx, 1Ah
		repne scasb
		jnz	short loc_FEAD1
		mov	al, 0
		jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEAD1:				; ...
		cmp	al, 2
		jb	short loc_FEAE1
		cmp	al, 0Eh
		jnb	short loc_FEAE1
		add	ah, 76h
		mov	al, 0
		jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEAE1:				; ...
		cmp	al, 3Bh
		jnb	short loc_FEAE8

loc_FEAE5:				; ...
		jmp	loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEAE8:				; ...
		cmp	al, 47h
		jnb	short loc_FEAE5
		mov	bx, offset unk_FE963
		jmp	loc_FEC15
; ---------------------------------------------------------------------------

loc_FEAF2:				; ...
		test	[byte ptr ds:17h], 4
		jz	short loc_FEB53
		cmp	al, 46h
		jnz	short loc_FEB15
		mov	bx, 1Eh
		mov	[ds:1Ah], bx
		mov	[ds:1Ch], bx
		mov	[byte ptr ds:71h], 80h
		int	1Bh		; CTRL-BREAK KEY
		mov	ax, 0
		jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEB15:				; ...
		cmp	al, 45h
		jnz	short loc_FEB3A
		or	[byte ptr ds:18h], 8
		mov	al, 20h
		out	20h, al		; Interrupt controller,	8259A.
		cmp	[byte ptr ds:49h], 7
		jz	short loc_FEB30
		mov	dx, 3D8h
		mov	al, [ds:65h]
		out	dx, al

loc_FEB30:				; ...
		test	[byte ptr ds:18h], 8
		jnz	short loc_FEB30
		jmp	loc_FEA50
; ---------------------------------------------------------------------------

loc_FEB3A:				; ...
		cmp	al, 37h
		jnz	short loc_FEB44
		mov	ax, 7200h
		jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEB44:				; ...
		mov	bx, offset unk_FE892
		cmp	al, 3Bh
		jnb	short loc_FEB4D
		jmp	short loc_FEBC3
; ---------------------------------------------------------------------------

loc_FEB4D:				; ...
		mov	bx, offset unk_FE8CC
		jmp	loc_FEC15
; ---------------------------------------------------------------------------

loc_FEB53:				; ...
		cmp	al, 47h
		jnb	short loc_FEB83
		test	[byte ptr ds:17h], 3
		jz	short loc_FEBB8
		cmp	al, 0Fh
		jnz	short loc_FEB67
		mov	ax, 0F00h
		jmp	short loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEB67:				; ...
		cmp	al, 37h
		jnz	short loc_FEB74
		mov	al, 20h
		out	20h, al		; Interrupt controller,	8259A.
		int	5		;  - PRINT-SCREEN KEY
					; automatically	called by keyboard scanner when	print-screen key is pressed
		jmp	loc_FEA50
; ---------------------------------------------------------------------------

loc_FEB74:				; ...
		cmp	al, 3Bh
		jb	short loc_FEB7E
		mov	bx, offset unk_FE959
		jmp	loc_FEC15
; ---------------------------------------------------------------------------

loc_FEB7E:				; ...
		mov	bx, offset unk_FE91F
		jmp	short loc_FEBC3
; ---------------------------------------------------------------------------

loc_FEB83:				; ...
		test	[byte ptr ds:17h], 20h
		jnz	short loc_FEBAA
		test	[byte ptr ds:17h], 3
		jnz	short loc_FEBB1

loc_FEB91:				; ...
		cmp	al, 4Ah
		jz	short loc_FEBA0
		cmp	al, 4Eh
		jz	short loc_FEBA5
		sub	al, 47h
		mov	bx, offset unk_FE97A
		jmp	loc_FEC17
; ---------------------------------------------------------------------------

loc_FEBA0:				; ...
		mov	ax, 4A2Dh
		jmp	short loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEBA5:				; ...
		mov	ax, 4E2Bh
		jmp	short loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEBAA:				; ...
		test	[byte ptr ds:17h], 3
		jnz	short loc_FEB91

loc_FEBB1:				; ...
		sub	al, 46h
		mov	bx, offset unk_FE96D
		jmp	short loc_FEBC3
; ---------------------------------------------------------------------------

loc_FEBB8:				; ...
		cmp	al, 3Bh
		jb	short loc_FEBC0
		mov	al, 0
		jmp	short loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEBC0:				; ...
		mov	bx, offset unk_FE8E5

loc_FEBC3:				; ...
		dec	al
		xlat	[byte ptr cs:bx]

loc_FEBC7:				; ...
		cmp	al, 0FFh
		jz	short loc_FEBEA
		cmp	ah, 0FFh
		jz	short loc_FEBEA

loc_FEBD0:				; ...
		test	[byte ptr ds:17h], 40h
		jz	short loc_FEBF7
		test	[byte ptr ds:17h], 3
		jz	short loc_FEBED
		cmp	al, 41h
		jb	short loc_FEBF7
		cmp	al, 5Ah
		ja	short loc_FEBF7
		add	al, 20h
		jmp	short loc_FEBF7
; ---------------------------------------------------------------------------

loc_FEBEA:				; ...
		jmp	loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEBED:				; ...
		cmp	al, 61h
		jb	short loc_FEBF7
		cmp	al, 7Ah
		ja	short loc_FEBF7
		sub	al, 20h

loc_FEBF7:				; ...
		mov	bx, [ds:1Ch]
		mov	si, bx
		call	sub_FE875
		cmp	bx, [ds:1Ah]
		jz	short loc_FEC0F
		mov	[si], ax
		mov	[ds:1Ch], bx
		jmp	loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEC0F:				; ...
		call	loc_FEC1F
		jmp	loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEC15:				; ...
		sub	al, 3Bh

loc_FEC17:				; ...
		xlat	[byte ptr cs:bx]
		mov	ah, al
		mov	al, 0
		jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEC1F:				; ...
		push	ax
		push	bx
		push	cx
		mov	bx, 0C0h
		in	al, 61h		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		push	ax

loc_FEC28:				; ...
		and	al, 0FCh
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		mov	cx, 48h

loc_FEC2F:				; ...
		loop	loc_FEC2F
		or	al, 2
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		mov	cx, 48h

loc_FEC38:				; ...
		loop	loc_FEC38
		dec	bx
		jnz	short loc_FEC28
		pop	ax
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		pop	cx
		pop	bx
		pop	ax
		retn
; ---------------------------------------------------------------------------
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
;---------------------------------------------------------------------------------------------------
; Interrupt 13h - Floppydisk
;---------------------------------------------------------------------------------------------------
proc		int_13h	near
		cld
		sti
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		mov	si, 40h
		mov	ds, si
		assume ds:nothing
		call	sub_FEC85
		mov	ah, [cs:MotorOff]
		mov	[ds:dsk_motor_tmr], ah
		mov	ah, [ds:dsk_ret_code]
		cmp	ah, 1
		cmc
		pop	es
		pop	ds
		assume ds:nothing
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		retf	2
endp		int_13h




proc		sub_FEC85 near		; ...
		push	dx
		call	sub_FECC2
		pop	dx
		mov	bx, dx
		and	bx, 1
		mov	ah, [ds:41h]
		cmp	ah, 40h
		jz	short loc_FECBA
		cmp	ax, 400h
		jnz	short locret_FECC1
		call	sub_FE36C
		jz	short loc_FECBA
		mov	al, [bx+90h]
		mov	ah, 0
		test	al, 0C0h
		jnz	short loc_FECAE
		mov	ah, 80h

loc_FECAE:				; ...
		and	al, 3Fh
		or	al, ah
		mov	[bx+90h], al
		mov	al, 0
		jmp	short locret_FECC1
; ---------------------------------------------------------------------------

loc_FECBA:				; ...
		xor	[byte ptr bx+90h], 20h
		mov	al, 0

locret_FECC1:				; ...
		retn
endp		sub_FEC85





proc		sub_FECC2 near		; ...

; FUNCTION CHUNK AT EE0E SIZE 000000C5 BYTES
; FUNCTION CHUNK AT EF0A SIZE 0000003C BYTES

		and	[byte ptr ds:3Fh], 7Fh
		or	ah, ah
		jz	short loc_FED01
		dec	ah
		jz	short loc_FED31
		mov	[byte ptr ds:41h], 0
		cmp	dl, 1
		ja	short loc_FECFB
		dec	ah
		jz	short loc_FED43
		dec	ah
		jz	short loc_FED3E
		dec	ah
		jz	short loc_FED35
		dec	ah
		jnz	short loc_FECEC
		jmp	loc_FEE0E
; ---------------------------------------------------------------------------

loc_FECEC:				; ...
		sub	ah, 12h
		jnz	short loc_FECF4
		jmp	loc_FEF0A
; ---------------------------------------------------------------------------

loc_FECF4:				; ...
		dec	ah
		jnz	short loc_FECFB
		jmp	loc_FEF26
; ---------------------------------------------------------------------------

loc_FECFB:				; ...
		mov	[byte ptr ds:41h], 1
		retn
; ---------------------------------------------------------------------------

loc_FED01:				; ...
		mov	al, 0
		mov	[ds:3Eh], al
		mov	[ds:41h], al
		mov	ah, [ds:3Fh]
		test	ah, 3
		jz	short loc_FED1A
		mov	al, 4
		shr	ah, 1
		jb	short loc_FED1A
		mov	al, 18h

loc_FED1A:				; ...
		call	sub_FE2D3
		mov	dl, [ds:43h]
		out	dx, al
		inc	ax
		out	dx, al
		mov	dl, [ds:42h]
		mov	al, 0D0h
		out	dx, al
		mov	dl, [ds:43h]
		in	al, dx
		retn
; ---------------------------------------------------------------------------

loc_FED31:				; ...
		mov	al, [ds:41h]
		retn
; ---------------------------------------------------------------------------

loc_FED35:				; ...
		mov	bx, 0FC00h
		mov	es, bx
		assume es:nothing
		mov	bh, bl
		jmp	short loc_FED43
; ---------------------------------------------------------------------------

loc_FED3E:				; ...
		or	[byte ptr ds:3Fh], 80h

loc_FED43:				; ...
		call	sub_FE3C3
		push	bx
		mov	bl, 15h
		call	sub_FE2EF
		pop	bx
		jnb	short loc_FED52
		xor	al, al
		retn
; ---------------------------------------------------------------------------

loc_FED52:				; ...
		call	sub_FE452
		mov	ch, al
		xor	ah, ah
		call	sub_FE2D3
		mov	cl, [ds:42h]
		add	cl, 3
		test	[byte ptr ds:3Fh], 80h
		jnz	short loc_FED9E

loc_FED6A:				; ...
		mov	di, bx
		mov	al, 80h
		mov	dl, [ds:42h]
		out	dx, al
		mov	dl, [ds:44h]
		jmp	short loc_FED7A
; ---------------------------------------------------------------------------

loc_FED79:				; ...
		stosb

loc_FED7A:				; ...
		in	al, dx
		shr	al, 1
		xchg	dl, cl
		in	al, dx
		xchg	dl, cl
		jb	short loc_FED79
		mov	bx, di
		mov	dl, [ds:42h]
		in	al, dx
		and	al, 1Fh
		jnz	short loc_FEDD7
		inc	ah
		call	sub_FEE04
		cmp	ch, ah
		jnz	short loc_FED6A
		mov	al, ah
		call	sub_FE483
		retn
; ---------------------------------------------------------------------------

loc_FED9E:				; ...
		push	ds
		mov	al, 0A0h
		mov	dl, [ds:42h]
		out	dx, al
		mov	dl, [ds:44h]
		mov	si, es
		mov	ds, si
		assume ds:nothing
		mov	si, bx

loc_FEDB0:				; ...
		in	al, dx
		shr	al, 1
		lodsb
		xchg	dl, cl
		out	dx, al
		xchg	dl, cl
		jb	short loc_FEDB0
		dec	si
		mov	bx, si
		pop	ds
		assume ds:nothing
		mov	dl, [ds:42h]
		in	al, dx
		and	al, 5Fh
		jnz	short loc_FEDD7
		inc	ah
		call	sub_FEE04
		cmp	ch, ah
		jnz	short loc_FED9E
		mov	al, ah
		call	sub_FE483
		retn
; ---------------------------------------------------------------------------

loc_FEDD7:				; ...
		call	sub_FE483
		mov	bh, ah
		test	[byte ptr ds:3Fh], 80h
		jz	short loc_FEDE9
		test	al, 40h
		mov	ah, 3
		jnz	short loc_FEDFD

loc_FEDE9:				; ...
		test	al, 10h
		mov	ah, 4
		jnz	short loc_FEDFD
		test	al, 8
		mov	ah, 10h
		jnz	short loc_FEDFD
		test	al, 1
		mov	ah, 80h
		jnz	short loc_FEDFD
		mov	ah, 20h

loc_FEDFD:				; ...
		or	[ds:41h], ah
		mov	al, bh
		retn
endp		sub_FECC2





proc		sub_FEE04 near		; ...
		mov	dl, [ds:42h]
		inc	dx
		inc	dx
		in	al, dx
		inc	ax
		out	dx, al
		retn
endp		sub_FEE04

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR sub_FECC2

loc_FEE0E:				; ...
		push	bx
		or	[byte ptr ds:3Fh], 80h
		call	sub_FE3C3
		mov	bl, 11h
		call	sub_FE2EF
		pop	si
		jnb	short loc_FEE20
		retn
; ---------------------------------------------------------------------------

loc_FEE20:				; ...
		push	ax
		push	bp
		mov	ah, al
		xor	bx, bx
		mov	ds, bx
		lds	bx, [ds:78h]
		mov	di, [bx+7]
		mov	bx, 40h
		mov	ds, bx
		assume ds:nothing
		call	sub_FE452
		call	sub_FE2D3
		mov	dl, [ds:44h]
		mov	bp, dx
		mov	dl, [ds:42h]
		mov	al, 0F0h
		out	dx, al
		add	dl, 3
		test	[byte ptr ds:3Fh], 20h
		jz	short loc_FEE60
		lods	[word ptr es:si]
		xchg	ax, cx

loc_FEE54:				; ...
		xchg	bp, dx
		in	al, dx
		lods	[byte ptr es:si]
		xchg	bp, dx
		out	dx, al
		loop	loc_FEE54
		jmp	short loc_FEEB1
; ---------------------------------------------------------------------------

loc_FEE60:				; ...
		mov	bx, offset unk_FEEEB
		mov	ch, 5
		call	sub_FEED3

loc_FEE68:				; ...
		mov	bx, offset unk_FEEF5
		mov	ch, 3
		call	sub_FEED3
		mov	cx, 4

loc_FEE73:				; ...
		xchg	bp, dx
		in	al, dx
		lods	[byte ptr es:si]
		xchg	bp, dx
		out	dx, al
		loop	loc_FEE73
		push	ax
		mov	ch, 5
		call	sub_FEED3
		pop	cx
		mov	bx, 80h
		shl	bx, cl
		mov	cx, bx
		mov	bx, di

loc_FEE8D:				; ...
		xchg	bp, dx
		in	al, dx
		mov	al, bh
		xchg	bp, dx
		out	dx, al
		loop	loc_FEE8D
		xchg	bp, dx
		in	al, dx
		mov	al, 0F7h
		xchg	bp, dx
		out	dx, al
		mov	cx, di
		xor	ch, ch

loc_FEEA3:				; ...
		xchg	bp, dx
		in	al, dx
		mov	al, 4Eh
		xchg	bp, dx
		out	dx, al
		loop	loc_FEEA3
		dec	ah
		jnz	short loc_FEE68

loc_FEEB1:				; ...
		xchg	bp, dx
		in	al, dx
		xchg	bp, dx
		shr	al, 1
		mov	al, 4Eh
		out	dx, al
		jb	short loc_FEEB1
		pop	bp
		pop	cx
		mov	dl, [ds:42h]
		in	al, dx
		and	al, 47h
		jz	short loc_FEECD
		sub	ah, ah
		jmp	loc_FEDD7
; ---------------------------------------------------------------------------

loc_FEECD:				; ...
		call	sub_FE483
		mov	al, cl
		retn
; END OF FUNCTION CHUNK	FOR sub_FECC2




proc		sub_FEED3 near		; ...
		mov	cl, [cs:bx+1]

loc_FEED7:				; ...
		xchg	bp, dx
		in	al, dx
		mov	al, [cs:bx]
		xchg	bp, dx
		out	dx, al
		dec	cl
		jnz	short loc_FEED7
		inc	bx
		inc	bx
		dec	ch
		jnz	short sub_FEED3
		retn
endp		sub_FEED3

; ---------------------------------------------------------------------------
unk_FEEEB	db  4Eh	; N		; ...
		db  10h
		db    0
		db  0Ch
		db 0F6h	; ?
		db    3
		db 0FCh	; ?
		db    1
		db  4Eh	; N
		db  32h	; 2
unk_FEEF5	db    0			; ...
		db  0Ch
		db 0F5h	; ?
		db    3
		db 0FEh	; ?
		db    1
		db 0F7h	; ?
		db    1
		db  4Eh	; N
		db  16h
		db    0
		db  0Ch
		db 0F5h	; ?
		db    3
		db 0FBh	; ?
		db    1
	
data_37	db  93h	; “
		db  74h	; t
		db  15h
		db  97h	; —
		db  17h
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR sub_FECC2

loc_FEF0A:				; ...
		dec	ax
		cmp	al, 5
		jb	short loc_FEF12
		jmp	loc_FECFB
; ---------------------------------------------------------------------------

loc_FEF12:				; ...
		mov	bx, ax
		and	bx, 7
		mov	al, data_37[bx]

loc_FEF1C:
		mov	bx, dx
		and	bx, 1
		mov	[bx+90h], al
		retn
; ---------------------------------------------------------------------------

loc_FEF26:				; ...
		mov	al, 2
		cmp	cx, 2709h
		jz	short loc_FEF12
		inc	ax
		cmp	cx, 4F0Fh
		jz	short loc_FEF12
		inc	ax
		cmp	cx, 4F09h
		jz	short loc_FEF12
		inc	ax
		cmp	cx, 4F12h
		jz	short loc_FEF12
		jmp	loc_FECFB
; END OF FUNCTION CHUNK	FOR sub_FECC2
; ---------------------------------------------------------------------------
unk_FEF46	db  24h	; $		; ...
		db  78h	; x
; ---------------------------------------------------------------------------
		mov	cl, 3
		shr	al, cl
		mov	bx, offset unk_FEF97
		xlat	[byte ptr cs:bx]
		mov	ah, al
		dec	dx
		in	al, dx
		inc	dx
		mov	bl, al
		mov	al, 37h
		out	dx, al
		mov	al, bl
		jmp	loc_FE7F3




proc		sub_FEF60 near		; ...
		mov	cx, 14h

loc_FEF63:				; ...
		loop	loc_FEF63
		retn
endp		sub_FEF60

; ---------------------------------------------------------------------------

loc_FEF66:				; ...
		inc	dx
		in	al, dx
		mov	ch, al
		mov	cl, 2
		shr	ch, cl
		and	ch, 20h
		mov	bx, offset unk_FEF8F
		mov	ah, al
		and	al, 7
		xlat	[byte ptr cs:bx]
		xchg	ah, al
		mov	cl, 3
		shr	al, cl
		and	al, 0Fh
		mov	bx, offset unk_FEF97
		xlat	[byte ptr cs:bx]
		or	ah, al
		inc	dx
		mov	al, 0F0h
		jmp	loc_FE7F3
; ---------------------------------------------------------------------------
unk_FEF8F	db    0			; ...
		db  20h
		db    1
		db  21h	; !
		db  40h	; @
		db  60h	; `
		db  41h	; A
		db  61h	; a
unk_FEF97	db    0			; ...
		db    4
		db    2
		db    6
		db    8
		db  0Ch
		db  0Ah
		db  0Eh
		db  10h
		db  14h
		db  12h
		db  16h
		db  18h
		db  1Ch
		db  1Ah
		db  1Eh
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0

;---------------------------------------------------------------------------------------------------
; Interrupt 1Eh - Diskette Parameter Table
;---------------------------------------------------------------------------------------------------
proc    	int_1Eh  far

SrtHdUnld       db      0CFh                       ; Disk parameter table
DmaHdLd        	db      2
MotorOff        db      25h
SectSize        db      2
LastTrack       db      9
GapLen          db      2Ah
DTL             db      0FFh
GapFMT          db      50h
FullChar        db      0F6h
HDSettle        db      19h
MotorOn         db      4

endp    	int_1Eh

;---------------------------------------------------------------------------------------------------
; Interrupt 17h - Parallel LPT Services
;---------------------------------------------------------------------------------------------------
proc		int_17h	near
		push	dx
		push	cx
		push	bx
		or	ah, ah
		jz	short loc_FEFE5
		dec	ah
		jz	short loc_FF028
		dec	ah
		jz	short loc_FF00D

loc_FEFE1:				; ...
		pop	bx
		pop	cx
		pop	dx
		iret
endp		int_17h
; ---------------------------------------------------------------------------

loc_FEFE5:				; ...
		push	ax
		mov	bl, 0Ah
		xor	cx, cx
		out	60h, al		; 8042 keyboard	controller data	register.

loc_FEFEC:				; ...
		in	al, 6Ah
		mov	ah, al
		test	al, 80h
		jz	short loc_FF002
		loop	loc_FEFEC
		dec	bl
		jnz	short loc_FEFEC
		or	ah, 1
		and	ah, 0F1h
		jmp	short loc_FF015
; ---------------------------------------------------------------------------

loc_FF002:				; ...
		in	al, 61h		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		or	al, 4
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		and	al, 0FBh
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		pop	ax

loc_FF00D:				; ...
		push	ax

loc_FF00E:				; ...
		in	al, 6Ah
		mov	ah, al
		and	ah, 0D0h

loc_FF015:				; ...
		pop	dx
		mov	al, dl
		test	ah, 10h
		jnz	short loc_FF020
		or	ah, 8

loc_FF020:				; ...
		and	ah, 0E9h
		xor	ah, 0D0h
		jmp	short loc_FEFE1
; ---------------------------------------------------------------------------

loc_FF028:				; ...
		push	ax
		in	al, 61h		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		and	al, 0E3h
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		mov	cx, 4B0h

loc_FF032:				; ...
		loop	loc_FF032
		in	al, 61h		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		or	al, 10h
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		jmp	short loc_FF00E
; ---------------------------------------------------------------------------
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
off_FF045	dw offset loc_FF0FC
		dw offset loc_FF1A2
		dw offset loc_FF1B5
		dw offset loc_FF1F1
		dw offset loc_FF198
		dw offset loc_FF20C
		dw offset loc_FF24D
		dw offset loc_FF2C8
		dw offset loc_FF335
		dw offset loc_FF372
		dw offset loc_FF3AC
		dw offset loc_FF3E6
		dw offset loc_FF40C
		dw offset loc_FF463
		dw offset loc_FF4AF
		dw offset loc_FF7B5
		dw offset unk_FFCFB
;---------------------------------------------------------------------------------------------------
; Interrupt 1Dh - Video Parameter Tables
;---------------------------------------------------------------------------------------------------
proc	int_1Dh	far

	db	38h, 28h, 2Dh, 0Ah, 1Fh, 6, 19h	; Init string for 40x25 color
	db	1Ch, 2, 7, 6, 7
	db	0, 0, 0, 0

	db	71h, 50h, 5Ah, 0Ah, 1Fh, 6, 19h	; Init string for 80x25 color
	db	1Ch, 2, 7, 6, 7
	db	0, 0, 0, 0

	db	38h, 28h, 2Dh, 0Ah, 7Fh, 6, 64h	; Init string for graphics
	db	70h, 2, 1, 6, 7
	db	0, 0, 0, 0

	db	61h, 50h, 52h, 0Fh, 19h, 6, 19h	; Init string for 80x25 b/w
	db	19h, 2, 0Dh, 0Bh, 0Ch
	db	0, 0, 0, 0

regen_len	dw	0800h			; Regen length, 40x25
		dw	1000h			;	        80x25
		dw	4000h			;	        graphics
		dw	4000h

max_cols	db	28h, 28h, 50h, 50h, 28h, 28h, 50h, 50h	; Maximum columns
video_hdwr_mode db	2Ch, 28h, 2Dh, 29h, 2Ah, 2Eh, 1Eh, 29h	; Table of mode sets
mul_lookup      db	00h, 00h, 10h, 10h, 20h, 20h, 20h, 30h	; Table lookup for multiply
		db 13 dup (0)
endp	int_1Dh

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Video BIOS (Mono/CGA) Main Entry
;---------------------------------------------------------------------------------------------------
proc		int_10h near
		push	ax
		push	bx
		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds
		push	es
		mov	bp, ax
		mov	al, ah
		cmp	al, 10h
		jb	short loc_FF07B
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF07B:				; ...
		xor	ah, ah
		shl	ax, 1
		xchg	ax, bp
		mov	si, 40h
		mov	ds, si
		mov	si, 0B800h
		mov	es, si
		assume es:nothing
		jmp	[cs:off_FF045+bp]
; ---------------------------------------------------------------------------

loc_FF0FC:				; ...
		push	ax
		and	al, 7Fh
		cmp	al, 7
		pop	ax
		jb	short loc_FF107
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF107:				; ...
		push	es
		push	ax
		push	ds
		pop	es
		assume es:nothing
		mov	di, 49h
		stosb
		mov	bx, 28h
		test	al, 2
		jz	short loc_FF118
		shl	bx, 1

loc_FF118:				; ...
		xchg	ax, bx
		stosw
		mov	ax, 4000h
		cmp	bl, 4
		jnb	short loc_FF12B
		mov	ah, 8
		test	bl, 2
		jz	short loc_FF12B
		shl	ah, 1

loc_FF12B:				; ...
		stosw
		xor	ax, ax
		stosw
		mov	cx, 8
		rep stosw
		mov	ax, 607h
		stosw
		xor	ax, ax
		stosb
		mov	ax, 3D4h
		stosw
		xchg	ax, dx
		xor	ax, ax
		add	dx, 4
		out	dx, al
		sub	dx, 4
		mov	al, video_hdwr_mode[bx]
		cmp	bl, 4
		jb	short loc_FF15C
		mov	ah, 30h
		cmp	bl, 6
		jb	short loc_FF15C
		mov	ah, 0Fh

loc_FF15C:				; ...
		stosw
		mov	ax, 409h
		cmp	bl, 4
		jb	short loc_FF167
		mov	ah, 1

loc_FF167:				; ...
		out	dx, ax
		mov	ax, 60Ah
		out	dx, ax
		mov	ax, 70Bh
		out	dx, ax
		mov	ax, 0Ch
		out	dx, ax
		inc	ax
		out	dx, ax
		inc	ax
		out	dx, ax
		inc	ax
		out	dx, ax
		pop	ax
		pop	es
		assume es:nothing
		shl	al, 1
		jb	short loc_FF191
		xor	ax, ax
		cmp	bl, 4
		jnb	short loc_FF18A
		mov	ax, 720h

loc_FF18A:				; ...
		mov	cx, 2000h
		xor	di, di
		rep stosw

loc_FF191:				; ...
		mov	ax, [ds:65h]
		add	dx, 4
		out	dx, ax

loc_FF198:				; ...
		pop	es
		pop	ds
		assume ds:nothing
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		iret
endp		int_10h
; ---------------------------------------------------------------------------

loc_FF1A2:				; ...
		mov	[ds:60h], cx
		mov	dx, [ds:63h]
		mov	al, 0Ah
		mov	ah, ch
		out	dx, ax
		inc	ax
		mov	ah, cl
		out	dx, ax
		jmp	short loc_FF198
; ---------------------------------------------------------------------------

loc_FF1B5:				; ...
		and	bh, 7
		xor	ax, ax
		mov	al, bh
		shl	ax, 1
		xchg	ax, si
		mov	[si+50h], dx
		nop
		cmp	[byte ptr ds:49h], 4
		jnb	short loc_FF1EF
		cmp	bh, [ds:62h]
		jnz	short loc_FF1EF
		mov	ax, [ds:4Ah]
		mul	dh
		xor	cx, cx
		mov	cl, dl
		add	cx, ax
		mov	ax, [ds:4Eh]
		shr	ax, 1
		add	cx, ax
		mov	dx, [ds:63h]
		mov	al, 0Eh
		mov	ah, ch
		out	dx, ax
		inc	ax
		mov	ah, cl
		out	dx, ax

loc_FF1EF:				; ...
		jmp	short loc_FF198
; ---------------------------------------------------------------------------

loc_FF1F1:				; ...
		and	bh, 7
		mov	bl, bh
		xor	bh, bh
		shl	bx, 1
		mov	dx, [bx+50h]
		nop ; TODO
		mov	cx, [ds:60h]
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	bx
		pop	bx
		pop	bx
		pop	ax
		iret
; ---------------------------------------------------------------------------

loc_FF20C:				; ...
		and	ax, 7
		mov	[ds:62h], al
		mov	bh, al
		mul	[word ptr ds:4Ch]
		mov	[ds:4Eh], ax
		shr	ax, 1
		xchg	ax, cx
		mov	dx, [ds:63h]
		mov	al, 0Ch
		mov	ah, ch
		out	dx, ax
		inc	ax
		mov	ah, cl
		out	dx, ax
		xor	ax, ax
		mov	al, bh
		shl	ax, 1
		xchg	ax, si
		mov	bx, [si+50h]
		nop ; TODO
		mov	ax, [ds:4Ah]
		mul	bh
		add	cx, ax
		xor	bh, bh
		add	cx, bx
		mov	al, 0Eh
		mov	ah, ch
		out	dx, ax
		inc	ax
		mov	ah, cl
		out	dx, ax
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF24D:				; ...
		mov	bl, al
		cmp	[byte ptr ds:49h], 4
		jb	short loc_FF259
		jmp	loc_FF543
; ---------------------------------------------------------------------------

loc_FF259:				; ...
		sub	dl, cl
		inc	dl
		sub	dh, ch
		inc	dh
		mov	bp, [ds:4Ah]
		mov	ax, bp
		mul	ch
		xor	ch, ch
		add	ax, cx
		shl	ax, 1
		add	ax, [ds:4Eh]
		xchg	ax, di
		xor	ax, ax
		mov	al, dl
		sub	bp, ax
		shl	bp, 1
		mov	al, bl
		dec	al
		mov	ah, dh
		dec	ah
		sub	ah, al
		jbe	short loc_FF2A7
		xchg	ax, cx
		mov	ax, [ds:4Ah]
		shl	ax, 1
		mul	bl
		mov	si, ax
		add	si, di
		xchg	ax, cx
		xor	cx, cx
		push	es
		pop	ds

loc_FF299:				; ...
		mov	cl, dl
		rep movsw
		add	si, bp
		add	di, bp
		dec	dh
		dec	ah
		jnz	short loc_FF299

loc_FF2A7:				; ...
		mov	ah, bh
		mov	al, 20h

loc_FF2AB:				; ...
		mov	cl, dl
		rep stosw
		add	di, bp
		dec	dh
		jnz	short loc_FF2AB

loc_FF2B5:				; ...
		mov	ax, 40h
		mov	ds, ax
		assume ds:nothing
		mov	ax, [ds:65h]
		mov	dx, [ds:63h]
		add	dx, 4
		out	dx, ax
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF2C8:				; ...
		std
		mov	bl, al
		cmp	[byte ptr ds:49h], 4
		jb	short loc_FF2D5
		jmp	loc_FF5CD
; ---------------------------------------------------------------------------

loc_FF2D5:				; ...
		push	dx
		sub	dl, cl
		inc	dl
		sub	dh, ch
		inc	dh
		pop	cx
		mov	bp, [ds:4Ah]
		mov	ax, bp
		mul	ch
		xor	ch, ch
		add	ax, cx
		shl	ax, 1
		add	ax, [ds:4Eh]
		xchg	ax, di
		xor	ax, ax
		mov	al, dl
		sub	bp, ax
		shl	bp, 1
		mov	al, bl
		dec	al
		mov	ah, dh
		dec	ah
		sub	ah, al
		jbe	short loc_FF325
		xchg	ax, cx
		mov	ax, [ds:4Ah]
		shl	ax, 1
		mul	bl
		mov	si, di
		sub	si, ax
		xchg	ax, cx
		xor	cx, cx
		push	es
		pop	ds
		assume ds:nothing

loc_FF317:				; ...
		mov	cl, dl
		rep movsw
		sub	si, bp
		sub	di, bp
		dec	dh
		dec	ah
		jnz	short loc_FF317

loc_FF325:				; ...
		mov	ah, bh
		mov	al, 20h

loc_FF329:				; ...
		mov	cl, dl
		rep stosw
		sub	di, bp
		dec	dh
		jnz	short loc_FF329
		jmp	short loc_FF2B5
; ---------------------------------------------------------------------------

loc_FF335:				; ...
		cmp	[byte ptr ds:49h], 4
		jb	short loc_FF33F
		jmp	loc_FF65C
; ---------------------------------------------------------------------------

loc_FF33F:				; ...
		and	bh, 7
		xor	ax, ax
		mov	al, bh
		mov	bx, ax
		shl	ax, 1
		xchg	ax, si
		mov	cx, [si+50h]
		nop ; TODO
		mov	ax, [ds:4Ch]
		mul	bx
		xchg	ax, cx
		xchg	ax, dx
		mov	ax, [ds:4Ah]
		mul	dh
		xor	dh, dh
		add	ax, dx
		shl	ax, 1
		add	ax, cx
		xchg	ax, bx
		mov	ax, [es:bx]

loc_FF367:				; ...
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		pop	bx
		inc	sp
		inc	sp
		iret
; ---------------------------------------------------------------------------

loc_FF372:				; ...
		cmp	[byte ptr ds:49h], 4
		jb	short loc_FF37C
		jmp	loc_FF6FC
; ---------------------------------------------------------------------------

loc_FF37C:				; ...
		mov	ah, bl
		push	ax
		push	cx
		and	bh, 7
		xor	ax, ax
		mov	al, bh
		mov	bx, ax
		shl	ax, 1
		xchg	ax, si
		mov	cx, [si+50h]
		nop
		mov	ax, [ds:4Ch]
		mul	bx
		xchg	ax, cx
		xchg	ax, dx
		mov	ax, [ds:4Ah]
		mul	dh
		xor	dh, dh
		add	ax, dx
		shl	ax, 1
		add	ax, cx
		xchg	ax, di
		pop	cx
		pop	ax
		rep stosw
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF3AC:				; ...
		cmp	[byte ptr ds:49h], 4
		jb	short loc_FF3B6
		jmp	loc_FF6FC
; ---------------------------------------------------------------------------

loc_FF3B6:				; ...
		push	ax
		push	cx
		and	bh, 7
		xor	ax, ax
		mov	al, bh
		mov	bx, ax
		shl	ax, 1
		xchg	ax, si
		mov	cx, [si+50h]
		nop
		mov	ax, [ds:4Ch]
		mul	bx
		xchg	ax, cx
		xchg	ax, dx
		mov	ax, [ds:4Ah]
		mul	dh
		xor	dh, dh
		add	ax, dx
		shl	ax, 1
		add	ax, cx
		xchg	ax, di
		pop	cx
		pop	ax

loc_FF3DF:				; ...
		stosb
		inc	di
		loop	loc_FF3DF
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF3E6:				; ...
		mov	dx, [ds:63h]
		add	dx, 5
		mov	al, [ds:66h]
		or	bh, bh
		jnz	short loc_FF3FD
		and	al, 20h
		and	bl, 1Fh
		or	al, bl
		jmp	short loc_FF405
; ---------------------------------------------------------------------------

loc_FF3FD:				; ...
		and	al, 1Fh
		shr	bl, 1
		jnb	short loc_FF405
		or	al, 20h

loc_FF405:				; ...
		out	dx, al
		mov	[ds:66h], al
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF40C:				; ...
		xor	bx, bx
		mov	dh, al
		shr	dl, 1
		jnb	short loc_FF416
		mov	bh, 20h

loc_FF416:				; ...
		mov	al, 50h
		mul	dl
		mov	dl, cl
		and	dl, 7
		shr	cx, 1
		test	[byte ptr ds:49h], 2
		jnz	short loc_FF42D
		and	dl, 3
		shl	cx, 1

loc_FF42D:				; ...
		shr	cx, 1
		shr	cx, 1
		add	ax, cx
		add	bx, ax
		mov	al, [es:bx]
		mov	ah, 80h
		mov	cl, dl
		mov	dl, dh
		ror	dh, 1
		test	[byte ptr ds:49h], 2
		jnz	short loc_FF44D
		mov	ah, 0C0h
		shl	cl, 1
		ror	dh, 1

loc_FF44D:				; ...
		and	dh, ah
		shr	ah, cl
		shr	dh, cl
		shl	dl, 1
		jb	short loc_FF45B
		or	al, ah
		xor	al, ah

loc_FF45B:				; ...
		xor	al, dh
		mov	[es:bx], al
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF463:				; ...
		xor	bx, bx
		shr	dl, 1
		jnb	short loc_FF46B
		mov	bh, 20h

loc_FF46B:				; ...
		mov	al, 50h
		mul	dl
		mov	dl, cl
		and	dl, 7
		shr	cx, 1
		test	[byte ptr ds:49h], 2
		jnz	short loc_FF482
		and	dl, 3
		shl	cx, 1

loc_FF482:				; ...
		shr	cx, 1
		shr	cx, 1
		add	ax, cx
		add	bx, ax
		mov	al, [es:bx]
		mov	ah, 80h
		mov	cl, dl
		test	[byte ptr ds:49h], 2
		jnz	short loc_FF49C
		mov	ah, 0C0h
		shl	cl, 1

loc_FF49C:				; ...
		shl	al, cl
		and	al, ah
		rol	al, 1
		rol	al, 1
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		pop	bx
		inc	sp
		inc	sp
		iret
; ---------------------------------------------------------------------------

loc_FF4AF:				; ...
		mov	bh, [ds:62h]
		xor	cx, cx
		mov	cl, bh
		shl	cx, 1
		mov	si, cx
		mov	dx, [si+50h]
		nop
		cmp	al, 7
		jz	short loc_FF512
		cmp	al, 8
		jz	short loc_FF52F
		cmp	al, 0Ah
		jz	short loc_FF538
		cmp	al, 0Dh
		jz	short loc_FF53F
		mov	ah, 0Ah
		mov	cx, 1
		int	10h		; - VIDEO -
		inc	dl
		mov	ax, [ds:4Ah]
		cmp	dl, al
		jb	short loc_FF50E
		xor	dl, dl
		cmp	dh, 18h
		jb	short loc_FF50C

loc_FF4E6:				; ...
		mov	ah, 2
		int	10h		; - VIDEO - SET	CURSOR POSITION
					; DH,DL	= row, column (0,0 = upper left)
					; BH = page number
		cmp	[byte ptr ds:49h], 4
		jb	short loc_FF4F5
		mov	bh, 0
		jmp	short loc_FF4FB
; ---------------------------------------------------------------------------

loc_FF4F5:				; ...
		mov	ah, 8
		int	10h		; - VIDEO - READ ATTRIBUTES/CHARACTER AT CURSOR	POSITION
					; BH = display page
					; Return: AL = character
					; AH = attribute of character (alpha modes)
		mov	bh, ah

loc_FF4FB:				; ...
		mov	ax, 601h
		xor	cx, cx
		mov	dx, [ds:4Ah]
		dec	dx
		mov	dh, 18h

loc_FF507:				; ...
		int	10h		; - VIDEO - SCROLL PAGE	UP
					; AL = number of lines to scroll window	(0 = blank whole window)
					; BH = attributes to be	used on	blanked	lines
					; CH,CL	= row,column of	upper left corner of window to scroll
					; DH,DL	= row,column of	lower right corner of window
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF50C:				; ...
		inc	dh

loc_FF50E:				; ...
		mov	ah, 2
		jmp	short loc_FF507
; ---------------------------------------------------------------------------

loc_FF512:				; ...
		mov	al, 0B6h
		out	43h, al		; Timer	8253-5 (AT: 8254.2).
		mov	al, 50h
		out	42h, al		; Timer	8253-5 (AT: 8254.2).
		mov	al, 2
		out	42h, al		; Timer	8253-5 (AT: 8254.2).
		in	al, 61h		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		or	al, 3
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		xor	cx, cx

loc_FF526:				; ...
		loop	loc_FF526
		xor	al, 3
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF52F:				; ...
		cmp	dl, 0
		jz	short loc_FF50E
		dec	dl
		jmp	short loc_FF50E
; ---------------------------------------------------------------------------

loc_FF538:				; ...
		cmp	dh, 18h
		jnz	short loc_FF50C
		jmp	short loc_FF4E6
; ---------------------------------------------------------------------------

loc_FF53F:				; ...
		xor	dl, dl
		jmp	short loc_FF50E
; ---------------------------------------------------------------------------

loc_FF543:				; ...
		sub	dl, cl
		inc	dl
		sub	dh, ch
		inc	dh
		mov	al, 0A0h
		mul	ch
		shl	ax, 1
		xor	ch, ch
		test	[byte ptr ds:49h], 2
		jnz	short loc_FF55E
		shl	cl, 1
		shl	dl, 1

loc_FF55E:				; ...
		add	ax, cx
		xchg	ax, di
		xor	ax, ax
		mov	al, dl
		mov	bp, ax
		mov	al, bl
		dec	al
		mov	ah, dh
		dec	ah
		shl	dh, 1
		shl	dh, 1
		shl	dh, 1
		sub	ah, al
		jbe	short loc_FF5B2
		shl	ah, 1
		shl	ah, 1
		shl	ah, 1
		xchg	ax, cx
		mov	al, 0A0h
		mul	bl
		shl	ax, 1
		mov	si, ax
		add	si, di
		xchg	ax, cx
		mov	cx, es
		mov	ds, cx
		xor	cx, cx

loc_FF591:				; ...
		mov	cl, dl
		rep movsb
		sub	si, bp
		sub	di, bp
		xor	si, 2000h
		xor	di, 2000h
		test	ah, 1
		jz	short loc_FF5AC
		add	si, 50h
		add	di, 50h

loc_FF5AC:				; ...
		dec	dh
		dec	ah
		jnz	short loc_FF591

loc_FF5B2:				; ...
		mov	al, bh

loc_FF5B4:				; ...
		mov	cl, dl
		rep stosb
		sub	di, bp
		xor	di, 2000h
		test	dh, 1
		jz	short loc_FF5C6
		add	di, 50h

loc_FF5C6:				; ...
		dec	dh
		jnz	short loc_FF5B4
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF5CD:				; ...
		push	dx
		sub	dl, cl
		inc	dl
		sub	dh, ch
		inc	dh
		pop	cx
		mov	al, 0A0h
		mul	ch
		shl	ax, 1
		xor	ch, ch
		test	[byte ptr ds:49h], 2
		jnz	short loc_FF5EA
		shl	cl, 1
		shl	dl, 1

loc_FF5EA:				; ...
		add	ax, cx
		add	ax, 20F0h
		xchg	ax, di
		xor	ax, ax
		mov	al, dl
		mov	bp, ax
		mov	al, bl
		dec	al
		mov	ah, dh
		dec	ah
		shl	dh, 1
		shl	dh, 1
		shl	dh, 1
		sub	ah, al
		jbe	short loc_FF641
		shl	ah, 1
		shl	ah, 1
		shl	ah, 1
		xchg	ax, cx
		mov	al, 0A0h
		mul	bl
		shl	ax, 1
		mov	si, di
		sub	si, ax
		xchg	ax, cx
		mov	cx, es
		mov	ds, cx
		xor	cx, cx

loc_FF620:				; ...
		mov	cl, dl
		rep movsb
		add	si, bp
		add	di, bp
		xor	si, 2000h
		xor	di, 2000h
		test	ah, 1
		jz	short loc_FF63B
		sub	si, 50h
		sub	di, 50h

loc_FF63B:				; ...
		dec	dh
		dec	ah
		jnz	short loc_FF620

loc_FF641:				; ...
		mov	al, bh
		mov	cl, dl
		rep stosb
		add	di, bp
		xor	di, 2000h
		test	dh, 1
		jz	short loc_FF655
		sub	di, 50h

loc_FF655:				; ...
		dec	dh
		jnz	short loc_FF641
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF65C:				; ...
		sub	sp, 8
		mov	bp, sp
		mov	dx, [ds:50h]
		test	[byte ptr ds:49h], 2
		jnz	short loc_FF66E
		shl	dl, 1

loc_FF66E:				; ...
		mov	al, 0A0h
		mul	dh
		shl	ax, 1
		xor	dh, dh
		add	ax, dx
		xchg	ax, si
		mov	dl, [ds:49h]
		mov	ax, es
		mov	ds, ax
		mov	ax, ss
		mov	es, ax
		mov	di, bp
		mov	cx, 8

loc_FF68A:				; ...
		mov	al, [si]
		test	dl, 2
		jnz	short loc_FF6A9
		mov	ah, al
		mov	al, [si+1]
		mov	bx, ax
		shl	bx, 1
		or	bx, ax
		push	cx
		mov	cx, 8

loc_FF6A0:				; ...
		shr	bx, 1
		shr	bx, 1
		rcr	al, 1
		loop	loc_FF6A0
		pop	cx

loc_FF6A9:				; ...
		stosb
		xor	si, 2000h
		test	cl, 1
		jz	short loc_FF6B6
		add	si, 50h

loc_FF6B6:				; ...
		loop	loc_FF68A
		mov	ax, cs
		mov	es, ax
		assume es:nothing
		mov	ax, ss
		mov	ds, ax
		mov	al, [bp+0]
		mov	di, offset unk_FFA6E
		xor	bx, bx

loc_FF6C8:				; ...
		scasb
		jz	short loc_FF6E6

loc_FF6CB:				; ...
		add	di, 7
		inc	bl
		jns	short loc_FF6C8
		shl	bh, 1
		jb	short loc_FF6F2
		xchg	bh, bl
		xor	cx, cx
		mov	ds, cx
		les	di, [ds:7Ch]
		assume es:nothing
		mov	cx, ss
		mov	ds, cx
		jmp	short loc_FF6C8
; ---------------------------------------------------------------------------

loc_FF6E6:				; ...
		mov	cx, 7
		mov	si, bp
		inc	si
		push	di
		repe cmpsb
		pop	di
		jnz	short loc_FF6CB

loc_FF6F2:				; ...
		mov	al, bl
		add	al, bh
		add	sp, 8
		jmp	loc_FF367
; ---------------------------------------------------------------------------

loc_FF6FC:				; ...
		mov	bh, al
		mov	dx, [ds:50h]
		test	[byte ptr ds:49h], 2
		jnz	short loc_FF70B
		shl	dl, 1

loc_FF70B:				; ...
		mov	al, 0A0h
		mul	dh
		shl	ax, 1
		xor	dh, dh
		add	ax, dx
		xchg	ax, di
		mov	dl, [ds:49h]
		mov	ax, cs
		mov	ds, ax
		assume ds:nothing
		xor	ax, ax
		mov	si, 0FA6Eh
		test	bh, 80h
		jz	short loc_FF731
		mov	ds, ax
		assume ds:nothing
		lds	si, [ds:7Ch]
		and	bh, 7Fh

loc_FF731:				; ...
		mov	al, bh
		shl	ax, 1
		shl	ax, 1
		shl	ax, 1
		add	si, ax
		mov	dh, 8

loc_FF73D:				; ...
		lodsb
		test	dl, 2
		jnz	short loc_FF78B
		xor	bp, bp
		push	cx
		mov	cx, 8

loc_FF749:				; ...
		shl	al, 1
		rcl	bp, 1
		rol	bp, 1
		loop	loc_FF749
		mov	ax, bp
		shr	ax, 1
		or	bp, ax
		mov	al, bl
		and	al, 3
		mov	ah, al
		mov	cl, 3

loc_FF75F:				; ...
		shl	ah, 1
		shl	ah, 1
		or	al, ah
		loop	loc_FF75F
		pop	cx
		mov	ah, al
		and	ax, bp
		xchg	al, ah
		test	bl, 80h
		jz	short loc_FF783
		push	cx
		push	di

loc_FF775:				; ...
		xor	[es:di], al
		inc	di
		xor	[es:di], ah
		inc	di
		loop	loc_FF775
		pop	di
		pop	cx
		jmp	short loc_FF7A2
; ---------------------------------------------------------------------------

loc_FF783:				; ...
		push	cx
		push	di
		rep stosw
		pop	di
		pop	cx
		jmp	short loc_FF7A2
; ---------------------------------------------------------------------------

loc_FF78B:				; ...
		test	bl, 80h
		jz	short loc_FF79C
		push	cx
		push	di

loc_FF792:				; ...
		xor	[es:di], al
		inc	di
		loop	loc_FF792
		pop	di
		pop	cx
		jmp	short loc_FF7A2
; ---------------------------------------------------------------------------

loc_FF79C:				; ...
		push	cx
		push	di
		rep stosb
		pop	di
		pop	cx

loc_FF7A2:				; ...
		xor	di, 2000h
		test	dh, 1
		jz	short loc_FF7AE
		add	di, 50h

loc_FF7AE:				; ...
		dec	dh
		jnz	short loc_FF73D
		jmp	loc_FF198
; ---------------------------------------------------------------------------

loc_FF7B5:				; ...
		mov	ax, [ds:49h]
		mov	bh, [ds:62h]
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		add	sp, 4
		iret
; ---------------------------------------------------------------------------
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
;---------------------------------------------------------------------------------------------------
; Interrupt 12h - Memory Size
;---------------------------------------------------------------------------------------------------
proc		int_12h near
		sti
		push	ds
		mov	ax, 40h
		mov	ds, ax
		assume ds:nothing
		mov	ax, [ds:13h]
		pop	ds
		assume ds:nothing
		iret
endp		int_12h
;---------------------------------------------------------------------------------------------------
; Interrupt 11h - Equipment Check
;---------------------------------------------------------------------------------------------------
proc		int_11h near
		sti
		push	ds
		mov	ax, 40h
		mov	ds, ax
		assume ds:nothing
		mov	ax, [ds:10h]
		pop	ds
		assume ds:nothing
		iret
endp		int_11h
;---------------------------------------------------------------------------------------------------
; Interrupt 15h - Cassette
;---------------------------------------------------------------------------------------------------
proc		int_15h near
		push	ds
		push	ax
		mov	ax, 40h
		mov	ds, ax
		assume ds:nothing
		pop	ax
		call	sub_FF869
		pop	ds
		assume ds:nothing
		sti
		retf	2
endp		int_15h




proc		sub_FF869 near		; ...
		or	ah, ah
		jz	short locret_FF87C
		dec	ah
		jz	short locret_FF87C
		dec	ah
		jz	short loc_FF89B
		dec	ah
		jz	short loc_FF87D
		mov	ah, 80h
		stc

locret_FF87C:				; ...
		retn
; ---------------------------------------------------------------------------

loc_FF87D:				; ...
		call	sub_FF9B7
		call	sub_FF9E0
		push	cx
		mov	cx, 20h

loc_FF887:				; ...
		stc
		call	sub_FFA21
		loop	loc_FF887
		pop	cx
		mov	al, 0B0h
		out	43h, al		; Timer	8253-5 (AT: 8254.2).
		mov	ax, 1
		call	sub_FFA37
		sub	ax, ax
		retn
; ---------------------------------------------------------------------------

loc_FF89B:				; ...
		call	sub_FF8C7
		jb	short locret_FF8C6
		call	sub_FF925
		push	ax
		test	ah, 3
		jnz	short loc_FF8BB
		call	sub_FF961
		jmp	short loc_FF8BB
; ---------------------------------------------------------------------------

loc_FF8AE:				; ...
		dec	si
		jz	short loc_FF8B3
		jmp	short loc_FF8CD
; ---------------------------------------------------------------------------

loc_FF8B3:				; ...
		pop	si
		pop	cx
		pop	bx
		sub	dx, dx
		mov	ah, 4
		push	ax

loc_FF8BB:				; ...
		in	al, 21h		; Interrupt controller,	8259A.
		and	al, 0FEh
		out	21h, al		; Interrupt controller,	8259A.
		pop	ax
		cmp	ah, 1
		cmc

locret_FF8C6:				; ...
		retn
endp		sub_FF869





proc		sub_FF8C7 near		; ...
		push	bx
		push	cx
		push	si
		mov	si, 7

loc_FF8CD:				; ...
		in	al, 61h		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		and	al, 7Fh
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		in	al, 62h		; PC/XT	PPI port C. Bits:
					; 0-3: values of DIP switches
					; 5: 1=Timer 2 channel out
					; 6: 1=I/O channel check
					; 7: 1=RAM parity check	error occurred.
		and	al, 40h
		mov	[ds:6Bh], al
		mov	dx, 3F7Ah

loc_FF8DD:				; ...
		test	[byte ptr ds:71h], 80h
		jz	short loc_FF8E6
		jmp	short loc_FF8B3
; ---------------------------------------------------------------------------

loc_FF8E6:				; ...
		dec	dx
		jnz	short loc_FF8EB
		jmp	short loc_FF8B3
; ---------------------------------------------------------------------------

loc_FF8EB:				; ...
		call	sub_FF98F
		jcxz	short loc_FF8DD
		mov	dx, 378h
		mov	cx, 200h
		in	al, 21h		; Interrupt controller,	8259A.
		or	al, 1
		out	21h, al		; Interrupt controller,	8259A.

loc_FF8FC:				; ...
		test	[byte ptr ds:71h], 80h
		jnz	short loc_FF8B3
		push	cx
		call	sub_FF98F
		or	cx, cx
		pop	cx
		jz	short loc_FF8CD
		cmp	dx, bx
		jcxz	short loc_FF914
		jnb	short loc_FF8CD
		loop	loc_FF8FC

loc_FF914:				; ...
		jb	short loc_FF8FC
		call	sub_FF98F
		call	sub_FF961
		cmp	al, 16h
		jnz	short loc_FF8AE
		clc
		pop	si
		pop	cx
		pop	bx
		retn
endp		sub_FF8C7





proc		sub_FF925 near		; ...
		push	cx

loc_FF926:				; ...
		mov	[word ptr ds:69h], 0FFFFh
		mov	dx, 100h

loc_FF92F:				; ...
		test	[byte ptr ds:71h], 80h
		jnz	short loc_FF959
		call	sub_FF961
		jb	short loc_FF959
		jcxz	short loc_FF942
		mov	[es:bx], al
		inc	bx
		dec	cx

loc_FF942:				; ...
		dec	dx
		jg	short loc_FF92F
		call	sub_FF961
		call	sub_FF961
		sub	ah, ah
		cmp	[word ptr ds:69h], 1D0Fh
		jnz	short loc_FF95B
		jcxz	short loc_FF95D
		jmp	short loc_FF926
; ---------------------------------------------------------------------------

loc_FF959:				; ...
		mov	ah, 1

loc_FF95B:				; ...
		inc	ah

loc_FF95D:				; ...
		pop	dx
		sub	dx, cx
		retn
endp		sub_FF925





proc		sub_FF961 near		; ...
		push	bx
		push	cx
		mov	cl, 8

loc_FF965:				; ...
		push	cx
		call	sub_FF98F
		jcxz	short loc_FF98B
		push	bx
		call	sub_FF98F
		pop	ax
		jcxz	short loc_FF98B
		add	bx, ax
		cmp	bx, 6F0h
		cmc
		lahf
		pop	cx
		rcl	ch, 1
		sahf
		call	sub_FFA3E
		dec	cl
		jnz	short loc_FF965
		mov	al, ch
		clc

loc_FF988:				; ...
		pop	cx
		pop	bx
		retn
; ---------------------------------------------------------------------------

loc_FF98B:				; ...
		pop	cx
		stc
		jmp	short loc_FF988
endp		sub_FF961





proc		sub_FF98F near		; ...
		mov	cx, 64h
		mov	ah, [ds:6Bh]

loc_FF996:				; ...
		in	al, 62h		; PC/XT	PPI port C. Bits:
					; 0-3: values of DIP switches
					; 5: 1=Timer 2 channel out
					; 6: 1=I/O channel check
					; 7: 1=RAM parity check	error occurred.
		and	al, 40h
		cmp	al, ah
		loope	loc_FF996
		mov	[ds:6Bh], al
		mov	al, 0
		out	43h, al		; Timer	8253-5 (AT: 8254.2).
		in	al, 40h		; Timer	8253-5 (AT: 8254.2).
		mov	ah, al
		in	al, 40h		; Timer	8253-5 (AT: 8254.2).
		xchg	al, ah
		mov	bx, [ds:67h]
		sub	bx, ax
		mov	[ds:67h], ax
		retn
endp		sub_FF98F





proc		sub_FF9B7 near		; ...
		push	bx
		push	cx
		in	al, 61h		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		and	al, 0FDh
		or	al, 81h
		out	61h, al		; PC/XT	PPI port B bits:
					; 0: Tmr 2 gate	??? OR	03H=spkr ON
					; 1: Tmr 2 data	??  AND	0fcH=spkr OFF
					; 3: 1=read high switches
					; 4: 0=enable RAM parity checking
					; 5: 0=enable I/O channel check
					; 6: 0=hold keyboard clock low
					; 7: 0=enable kbrd
		mov	al, 0B6h
		out	43h, al		; Timer	8253-5 (AT: 8254.2).
		mov	ax, 4A0h
		call	sub_FFA37
		mov	cx, 800h

loc_FF9CE:				; ...
		stc
		call	sub_FFA21
		loop	loc_FF9CE
		clc
		call	sub_FFA21
		pop	cx
		pop	bx
		mov	al, 16h
		call	sub_FFA0A
		retn
endp		sub_FF9B7





proc		sub_FF9E0 near		; ...
		mov	[word ptr ds:69h], 0FFFFh
		mov	dx, 100h

loc_FF9E9:				; ...
		mov	al, [es:bx]
		call	sub_FFA0A
		jcxz	short loc_FF9F3
		inc	bx
		dec	cx

loc_FF9F3:				; ...
		dec	dx
		jg	short loc_FF9E9
		mov	ax, [ds:69h]
		not	ax
		push	ax
		xchg	ah, al
		call	sub_FFA0A
		pop	ax
		call	sub_FFA0A
		or	cx, cx
		jnz	short sub_FF9E0
		retn
endp		sub_FF9E0





proc		sub_FFA0A near		; ...
		push	cx
		push	ax
		mov	ch, al
		mov	cl, 8

loc_FFA10:				; ...
		rcl	ch, 1
		pushf
		call	sub_FFA21
		popf
		call	sub_FFA3E
		dec	cl
		jnz	short loc_FFA10
		pop	ax
		pop	cx
		retn
endp		sub_FFA0A





proc		sub_FFA21 near		; ...
		mov	ax, 4A0h
		jb	short loc_FFA29
		mov	ax, 250h

loc_FFA29:				; ...
		push	ax

loc_FFA2A:				; ...
		in	al, 62h		; PC/XT	PPI port C. Bits:
					; 0-3: values of DIP switches
					; 5: 1=Timer 2 channel out
					; 6: 1=I/O channel check
					; 7: 1=RAM parity check	error occurred.
		and	al, 20h
		jz	short loc_FFA2A

loc_FFA30:				; ...
		in	al, 62h		; PC/XT	PPI port C. Bits:
					; 0-3: values of DIP switches
					; 5: 1=Timer 2 channel out
					; 6: 1=I/O channel check
					; 7: 1=RAM parity check	error occurred.
		and	al, 20h
		jnz	short loc_FFA30
		pop	ax
endp		sub_FFA21 ; sp-analysis	failed





proc		sub_FFA37 near		; ...
		out	42h, al		; Timer	8253-5 (AT: 8254.2).
		mov	al, ah
		out	42h, al		; Timer	8253-5 (AT: 8254.2).
		retn
endp		sub_FFA37





proc		sub_FFA3E near		; ...
		mov	ax, [ds:69h]
		rcr	ax, 1
		rcl	ax, 1
		clc
		jno	short loc_FFA4C
		xor	ax, 810h
		stc

loc_FFA4C:				; ...
		rcl	ax, 1
		mov	[ds:69h], ax
		retn
endp		sub_FFA3E

; ---------------------------------------------------------------------------
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
unk_FFA6E	db    0			; ...
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db  7Eh	; ~
		db  81h	; ?
		db 0A5h	; ?
		db  81h	; ?
		db 0BDh	; ?
		db  99h	; ™
		db  81h	; ?
		db  7Eh	; ~
		db  7Eh	; ~
		db 0FFh
		db 0DBh	; ?
		db 0FFh
		db 0C3h	; ?
		db 0E7h	; ?
		db 0FFh
		db  7Eh	; ~
		db  6Ch	; l
		db 0FEh	; ?
		db 0FEh	; ?
		db 0FEh	; ?
		db  7Ch	; |
		db  38h	; 8
		db  10h
		db    0
		db  10h
		db  38h	; 8
		db  7Ch	; |
		db 0FEh	; ?
		db  7Ch	; |
		db  38h	; 8
		db  10h
		db    0
		db  38h	; 8
		db  7Ch	; |
		db  38h	; 8
		db 0FEh	; ?
		db 0FEh	; ?
		db  7Ch	; |
		db  38h	; 8
		db  7Ch	; |
		db  10h
		db  10h
		db  38h	; 8
		db  7Ch	; |
		db 0FEh	; ?
		db  7Ch	; |
		db  38h	; 8
		db  7Ch	; |
		db    0
		db    0
		db  18h
		db  3Ch	; <
		db  3Ch	; <
		db  18h
		db    0
		db    0
		db 0FFh
		db 0FFh
		db 0E7h	; ?
		db 0C3h	; ?
		db 0C3h	; ?
		db 0E7h	; ?
		db 0FFh
		db 0FFh
		db    0
		db  3Ch	; <
		db  66h	; f
		db  42h	; B
		db  42h	; B
		db  66h	; f
		db  3Ch	; <
		db    0
		db 0FFh
		db 0C3h	; ?
		db  99h	; ™
		db 0BDh	; ?
		db 0BDh	; ?
		db  99h	; ™
		db 0C3h	; ?
		db 0FFh
		db  0Fh
		db    7
		db  0Fh
		db  7Dh	; }
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db  78h	; x
		db  3Ch	; <
		db  66h	; f
		db  66h	; f
		db  66h	; f
		db  3Ch	; <
		db  18h
		db  7Eh	; ~
		db  18h
		db  3Fh	; ?
		db  33h	; 3
		db  3Fh	; ?
		db  30h	; 0
		db  30h	; 0
		db  70h	; p
		db 0F0h	; ?
		db 0E0h	; ?
		db  7Fh	; 
		db  63h	; c
		db  7Fh	; 
		db  63h	; c
		db  63h	; c
		db  67h	; g
		db 0E6h	; ?
		db 0C0h	; ?
		db  99h	; ™
		db  5Ah	; Z
		db  3Ch	; <
		db 0E7h	; ?
		db 0E7h	; ?
		db  3Ch	; <
		db  5Ah	; Z
		db  99h	; ™
		db  80h	; ˆ
		db 0E0h	; ?
		db 0F8h	; ?
		db 0FEh	; ?
		db 0F8h	; ?
		db 0E0h	; ?
		db  80h	; ˆ
		db    0
		db    2
		db  0Eh
		db  3Eh	; >
		db 0FEh	; ?
		db  3Eh	; >
		db  0Eh
		db    2
		db    0
		db  18h
		db  3Ch	; <
		db  7Eh	; ~
		db  18h
		db  18h
		db  7Eh	; ~
		db  3Ch	; <
		db  18h
		db  66h	; f
		db  66h	; f
		db  66h	; f
		db  66h	; f
		db  66h	; f
		db    0
		db  66h	; f
		db    0
		db  7Fh	; 
		db 0DBh	; ?
		db 0DBh	; ?
		db  7Bh	; {
		db  1Bh
		db  1Bh
		db  1Bh
		db    0
		db  3Eh	; >
		db  63h	; c
		db  38h	; 8
		db  6Ch	; l
		db  6Ch	; l
		db  38h	; 8
		db 0CCh	; ?
		db  78h	; x
		db    0
		db    0
		db    0
		db    0
		db  7Eh	; ~
		db  7Eh	; ~
		db  7Eh	; ~
		db    0
		db  18h
		db  3Ch	; <
		db  7Eh	; ~
		db  18h
		db  7Eh	; ~
		db  3Ch	; <
		db  18h
		db 0FFh
		db  18h
		db  3Ch	; <
		db  7Eh	; ~
		db  18h
		db  18h
		db  18h
		db  18h
		db    0
		db  18h
		db  18h
		db  18h
		db  18h
		db  7Eh	; ~
		db  3Ch	; <
		db  18h
		db    0
		db    0
		db  18h
		db  0Ch
		db 0FEh	; ?
		db  0Ch
		db  18h
		db    0
		db    0
		db    0
		db  30h	; 0
		db  60h	; `
		db 0FEh	; ?
		db  60h	; `
		db  30h	; 0
		db    0
		db    0
		db    0
		db    0
		db 0C0h	; ?
		db 0C0h	; ?
		db 0C0h	; ?
		db 0FEh	; ?
		db    0
		db    0
		db    0
		db  24h	; $
		db  66h	; f
		db 0FFh
		db  66h	; f
		db  24h	; $
		db    0
		db    0
		db    0
		db  18h
		db  3Ch	; <
		db  7Eh	; ~
		db 0FFh
		db 0FFh
		db    0
		db    0
		db    0
		db 0FFh
		db 0FFh
		db  7Eh	; ~
		db  3Ch	; <
		db  18h
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db  30h	; 0
		db  78h	; x
		db  78h	; x
		db  30h	; 0
		db  30h	; 0
		db    0
		db  30h	; 0
		db    0
		db  6Ch	; l
		db  6Ch	; l
		db  6Ch	; l
		db    0
		db    0
		db    0
		db    0
		db    0
		db  6Ch	; l
		db  6Ch	; l
		db 0FEh	; ?
		db  6Ch	; l
		db 0FEh	; ?
		db  6Ch	; l
		db  6Ch	; l
		db    0
		db  30h	; 0
		db  7Ch	; |
		db 0C0h	; ?
		db  78h	; x
		db  0Ch
		db 0F8h	; ?
		db  30h	; 0
		db    0
		db    0
		db 0C6h	; ?
		db 0CCh	; ?
		db  18h
		db  30h	; 0
		db  66h	; f
		db 0C6h	; ?
		db    0
		db  38h	; 8
		db  6Ch	; l
		db  38h	; 8
		db  76h	; v
		db 0DCh	; ?
		db 0CCh	; ?
		db  76h	; v
		db    0
		db  60h	; `
		db  60h	; `
		db 0C0h	; ?
		db    0
		db    0
		db    0
		db    0
		db    0
		db  18h
		db  30h	; 0
		db  60h	; `
		db  60h	; `
		db  60h	; `
		db  30h	; 0
		db  18h
		db    0
		db  60h	; `
		db  30h	; 0
		db  18h
		db  18h
		db  18h
		db  30h	; 0
		db  60h	; `
		db    0
		db    0
		db  66h	; f
		db  3Ch	; <
		db 0FFh
		db  3Ch	; <
		db  66h	; f
		db    0
		db    0
		db    0
		db  30h	; 0
		db  30h	; 0
		db 0FCh	; ?
		db  30h	; 0
		db  30h	; 0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db  30h	; 0
		db  30h	; 0
		db  60h	; `
		db    0
		db    0
		db    0
		db 0FCh	; ?
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db  30h	; 0
		db  30h	; 0
		db    0
		db    6
		db  0Ch
		db  18h
		db  30h	; 0
		db  60h	; `
		db 0C0h	; ?
		db  80h	; ˆ
		db    0
		db  7Ch	; |
		db 0C6h	; ?
		db 0CEh	; ?
		db 0DEh	; ?
		db 0F6h	; ?
		db 0E6h	; ?
		db  7Ch	; |
		db    0
		db  30h	; 0
		db  70h	; p
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db 0FCh	; ?
		db    0
		db  78h	; x
		db 0CCh	; ?
		db  0Ch
		db  38h	; 8
		db  60h	; `
		db 0CCh	; ?
		db 0FCh	; ?
		db    0
		db  78h	; x
		db 0CCh	; ?
		db  0Ch
		db  38h	; 8
		db  0Ch
		db 0CCh	; ?
		db  78h	; x
		db    0
		db  1Ch
		db  3Ch	; <
		db  6Ch	; l
		db 0CCh	; ?
		db 0FEh	; ?
		db  0Ch
		db  1Eh
		db    0
		db 0FCh	; ?
		db 0C0h	; ?
		db 0F8h	; ?
		db  0Ch
		db  0Ch
		db 0CCh	; ?
		db  78h	; x
		db    0
		db  38h	; 8
		db  60h	; `
		db 0C0h	; ?
		db 0F8h	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db  78h	; x
		db    0
		db 0FCh	; ?
		db 0CCh	; ?
		db  0Ch
		db  18h
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db    0
		db  78h	; x
		db 0CCh	; ?
		db 0CCh	; ?
		db  78h	; x
		db 0CCh	; ?
		db 0CCh	; ?
		db  78h	; x
		db    0
		db  78h	; x
		db 0CCh	; ?
		db 0CCh	; ?
		db  7Ch	; |
		db  0Ch
		db  18h
		db  70h	; p
		db    0
		db    0
		db  30h	; 0
		db  30h	; 0
		db    0
		db    0
		db  30h	; 0
		db  30h	; 0
		db    0
		db    0
		db  30h	; 0
		db  30h	; 0
		db    0
		db    0
		db  30h	; 0
		db  30h	; 0
		db  60h	; `
		db  18h
		db  30h	; 0
		db  60h	; `
		db 0C0h	; ?
		db  60h	; `
		db  30h	; 0
		db  18h
		db    0
		db    0
		db    0
		db 0FCh	; ?
		db    0
		db    0
		db 0FCh	; ?
		db    0
		db    0
		db  60h	; `
		db  30h	; 0
		db  18h
		db  0Ch
		db  18h
		db  30h	; 0
		db  60h	; `
		db    0
		db  78h	; x
		db 0CCh	; ?
		db  0Ch
		db  18h
		db  30h	; 0
		db    0
		db  30h	; 0
		db    0
		db  7Ch	; |
		db 0C6h	; ?
		db 0DEh	; ?
		db 0DEh	; ?
		db 0DEh	; ?
		db 0C0h	; ?
		db  78h	; x
		db    0
		db  30h	; 0
		db  78h	; x
		db 0CCh	; ?
		db 0CCh	; ?
		db 0FCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db    0
		db 0FCh	; ?
		db  66h	; f
		db  66h	; f
		db  7Ch	; |
		db  66h	; f
		db  66h	; f
		db 0FCh	; ?
		db    0
		db  3Ch	; <
		db  66h	; f
		db 0C0h	; ?
		db 0C0h	; ?
		db 0C0h	; ?
		db  66h	; f
		db  3Ch	; <
		db    0
		db 0F8h	; ?
		db  6Ch	; l
		db  66h	; f
		db  66h	; f
		db  66h	; f
		db  6Ch	; l
		db 0F8h	; ?
		db    0
		db 0FEh	; ?
		db  62h	; b
		db  68h	; h
		db  78h	; x
		db  68h	; h
		db  62h	; b
		db 0FEh	; ?
		db    0
		db 0FEh	; ?
		db  62h	; b
		db  68h	; h
		db  78h	; x
		db  68h	; h
		db  60h	; `
		db 0F0h	; ?
		db    0
		db  3Ch	; <
		db  66h	; f
		db 0C0h	; ?
		db 0C0h	; ?
		db 0CEh	; ?
		db  66h	; f
		db  3Eh	; >
		db    0
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0FCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db    0
		db  78h	; x
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db  78h	; x
		db    0
		db  1Eh
		db  0Ch
		db  0Ch
		db  0Ch
		db 0CCh	; ?
		db 0CCh	; ?
		db  78h	; x
		db    0
		db 0E6h	; ?
		db  66h	; f
		db  6Ch	; l
		db  78h	; x
		db  6Ch	; l
		db  66h	; f
		db 0E6h	; ?
		db    0
		db 0F0h	; ?
		db  60h	; `
		db  60h	; `
		db  60h	; `
		db  62h	; b
		db  66h	; f
		db 0FEh	; ?
		db    0
		db 0C6h	; ?
		db 0EEh	; ?
		db 0FEh	; ?
		db 0FEh	; ?
		db 0D6h	; ?
		db 0C6h	; ?
		db 0C6h	; ?
		db    0
		db 0C6h	; ?
		db 0E6h	; ?
		db 0F6h	; ?
		db 0DEh	; ?
		db 0CEh	; ?
		db 0C6h	; ?
		db 0C6h	; ?
		db    0
		db  38h	; 8
		db  6Ch	; l
		db 0C6h	; ?
		db 0C6h	; ?
		db 0C6h	; ?
		db  6Ch	; l
		db  38h	; 8
		db    0
		db 0FCh	; ?
		db  66h	; f
		db  66h	; f
		db  7Ch	; |
		db  60h	; `
		db  60h	; `
		db 0F0h	; ?
		db    0
		db  78h	; x
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0DCh	; ?
unk_FFCFB	db  78h	; x		; ...
		db  1Ch
		db    0
		db 0FCh	; ?
		db  66h	; f
		db  66h	; f
		db  7Ch	; |
		db  6Ch	; l
		db  66h	; f
		db 0E6h	; ?
		db    0
		db  78h	; x
		db 0CCh	; ?
		db 0E0h	; ?
		db  70h	; p
		db  1Ch
		db 0CCh	; ?
		db  78h	; x
		db    0
		db 0FCh	; ?
		db 0B4h	; ?
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db  78h	; x
		db    0
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0FCh	; ?
		db    0
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db  78h	; x
		db  30h	; 0
		db    0
		db 0C6h	; ?
		db 0C6h	; ?
		db 0C6h	; ?
		db 0D6h	; ?
		db 0FEh	; ?
		db 0EEh	; ?
		db 0C6h	; ?
		db    0
		db 0C6h	; ?
		db 0C6h	; ?
		db  6Ch	; l
		db  38h	; 8
		db  38h	; 8
		db  6Ch	; l
		db 0C6h	; ?
		db    0
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db  78h	; x
		db  30h	; 0
		db  30h	; 0
		db  78h	; x
		db    0
		db 0FEh	; ?
		db 0C6h	; ?
		db  8Ch	; ?
		db  18h
		db  32h	; 2
		db  66h	; f
		db 0FEh	; ?
		db    0
		db  78h	; x
		db  60h	; `
		db  60h	; `
		db  60h	; `
		db  60h	; `
		db  60h	; `
		db  78h	; x
		db    0
		db 0C0h	; ?
		db  60h	; `
		db  30h	; 0
		db  18h
		db  0Ch
		db    6
		db    2
		db    0
		db  78h	; x
		db  18h
		db  18h
		db  18h
		db  18h
		db  18h
		db  78h	; x
		db    0
		db  10h
		db  38h	; 8
		db  6Ch	; l
		db 0C6h	; ?
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db 0FFh
		db  30h	; 0
		db  30h	; 0
		db  18h
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db  78h	; x
		db  0Ch
		db  7Ch	; |
		db 0CCh	; ?
		db  76h	; v
		db    0
		db 0E0h	; ?
		db  60h	; `
		db  60h	; `
		db  7Ch	; |
		db  66h	; f
		db  66h	; f
		db 0DCh	; ?
		db    0
		db    0
		db    0
		db  78h	; x
		db 0CCh	; ?
		db 0C0h	; ?
		db 0CCh	; ?
		db  78h	; x
		db    0
		db  1Ch
		db  0Ch
		db  0Ch
		db  7Ch	; |
		db 0CCh	; ?
		db 0CCh	; ?
		db  76h	; v
		db    0
		db    0
		db    0
		db  78h	; x
		db 0CCh	; ?
		db 0FCh	; ?
		db 0C0h	; ?
		db  78h	; x
		db    0
		db  38h	; 8
		db  6Ch	; l
		db  60h	; `
		db 0F0h	; ?
		db  60h	; `
		db  60h	; `
		db 0F0h	; ?
		db    0
		db    0
		db    0
		db  76h	; v
		db 0CCh	; ?
		db 0CCh	; ?
		db  7Ch	; |
		db  0Ch
		db 0F8h	; ?
		db 0E0h	; ?
		db  60h	; `
		db  6Ch	; l
		db  76h	; v
		db  66h	; f
		db  66h	; f
		db 0E6h	; ?
		db    0
		db  30h	; 0
		db    0
		db  70h	; p
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db  78h	; x
		db    0
		db  0Ch
		db    0
		db  0Ch
		db  0Ch
		db  0Ch
		db 0CCh	; ?
		db 0CCh	; ?
		db  78h	; x
		db 0E0h	; ?
		db  60h	; `
		db  66h	; f
		db  6Ch	; l
		db  78h	; x
		db  6Ch	; l
		db 0E6h	; ?
		db    0
		db  70h	; p
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db  30h	; 0
		db  78h	; x
		db    0
		db    0
		db    0
		db 0CCh	; ?
		db 0FEh	; ?
		db 0FEh	; ?
		db 0D6h	; ?
		db 0C6h	; ?
		db    0
		db    0
		db    0
		db 0F8h	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db    0
		db    0
		db    0
		db  78h	; x
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db  78h	; x
		db    0
		db    0
		db    0
		db 0DCh	; ?
		db  66h	; f
		db  66h	; f
		db  7Ch	; |
		db  60h	; `
		db 0F0h	; ?
		db    0
		db    0
		db  76h	; v
		db 0CCh	; ?
		db 0CCh	; ?
		db  7Ch	; |
		db  0Ch
		db  1Eh
		db    0
		db    0
		db 0DCh	; ?
		db  76h	; v
		db  66h	; f
		db  60h	; `
		db 0F0h	; ?
		db    0
		db    0
		db    0
		db  7Ch	; |
		db 0C0h	; ?
		db  78h	; x
		db  0Ch
		db 0F8h	; ?
		db    0
		db  10h
		db  30h	; 0
		db  7Ch	; |
		db  30h	; 0
		db  30h	; 0
		db  34h	; 4
		db  18h
		db    0
		db    0
		db    0
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db  76h	; v
		db    0
		db    0
		db    0
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db  78h	; x
		db  30h	; 0
		db    0
		db    0
		db    0
		db 0C6h	; ?
		db 0D6h	; ?
		db 0FEh	; ?
		db 0FEh	; ?
		db  6Ch	; l
		db    0
		db    0
		db    0
		db 0C6h	; ?
		db  6Ch	; l
		db  38h	; 8
		db  6Ch	; l
		db 0C6h	; ?
		db    0
		db    0
		db    0
		db 0CCh	; ?
		db 0CCh	; ?
		db 0CCh	; ?
		db  7Ch	; |
		db  0Ch
		db 0F8h	; ?
		db    0
		db    0
		db 0FCh	; ?
		db  98h	; ?
		db  30h	; 0
		db  64h	; d
		db 0FCh	; ?
		db    0
		db  1Ch
		db  30h	; 0
		db  30h	; 0
		db 0E0h	; ?
		db  30h	; 0
		db  30h	; 0
		db  1Ch
		db    0
		db  18h
		db  18h
		db  18h
		db    0
		db  18h
		db  18h
		db  18h
		db    0
		db 0E0h	; ?
		db  30h	; 0
		db  30h	; 0
		db  1Ch
		db  30h	; 0
		db  30h	; 0
		db 0E0h	; ?
		db    0
		db  76h	; v
		db 0DCh	; ?
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db  10h
		db  38h	; 8
		db  6Ch	; l
		db 0C6h	; ?
		db 0C6h	; ?
		db 0FEh	; ?
		db    0
; ---------------------------------------------------------------------------
proc 		int_1Ah near
		push	ds
		push	ax
		mov	ax, 40h
		mov	ds, ax
		assume ds:nothing
		pop	ax
		or	ah, ah
		jz	short loc_FFE80
		dec	ah
		jz	short loc_FFE92

loc_FFE7E:				; ...
		pop	ds
		assume ds:nothing
		iret
endp		int_1Ah
; ---------------------------------------------------------------------------

loc_FFE80:				; ...
		mov	al, [ds:70h]
		mov	[byte ptr ds:70h], 0
		mov	cx, [ds:6Eh]
		mov	dx, [ds:6Ch]
		jmp	short loc_FFE7E
; ---------------------------------------------------------------------------

loc_FFE92:				; ...
		mov	[ds:6Ch], dx
		mov	[ds:6Eh], cx
		mov	[byte ptr ds:70h], 0
		jmp	short loc_FFE7E
; ---------------------------------------------------------------------------
		db    0
		db    0
		db    0
		db    0
; ---------------------------------------------------------------------------
proc		int_08h near
		push	ds
		push	ax
		push	dx
		mov	ax, 40h
		mov	ds, ax
		assume ds:nothing
		xor	ax, ax
		inc	[word ptr ds:6Ch]
		jnz	short loc_FFEB9
		inc	[word ptr ds:6Eh]

loc_FFEB9:				; ...
		cmp	[word ptr ds:6Eh], 18h
		jnz	short loc_FFED3
		cmp	[word ptr ds:6Ch], 0B0h
		jnz	short loc_FFED3
		mov	[ds:6Eh], ax
		mov	[ds:6Ch], ax
		mov	[byte ptr ds:70h], 1

loc_FFED3:				; ...
		inc	ax
		dec	[byte ptr ds:dsk_motor_tmr]
		jnz	short loc_FFEE7
		and	[byte ptr ds:dsk_motor_stat], 0FCh
		call	sub_FE2D3
		mov	dl, [ds:43h]
		out	dx, al

loc_FFEE7:				; ...
		int	1Ch		; CLOCK	TICK
		mov	al, 20h
		out	20h, al		; Interrupt controller,	8259A.
		pop	dx
		pop	ax
		pop	ds
		assume ds:nothing
		iret
endp		int_08h
; ---------------------------------------------------------------------------
		db    0
		db    0
int_vec_table_1:		
		dw offset int_08h         ; Offest int_08h
		dw offset int_09h         ; Offset int_09h
		dw offset dummy_int       ; Offset int_0Ah
		dw offset dummy_int       ; Ofsset int_0Bh
		dw offset dummy_int       ; Offset int_0Ch
		dw offset dummy_int       ; Offset int_0Dh
		dw offset dummy_int       ; Offset int_0Eh
		dw offset dummy_int       ; Offset int_0Fh
		dw offset int_10h         ; Offset int_10h
		dw offset int_11h         ; Ofsset int_11h
		dw offset int_12h         ; Offset int_12h
		dw offset int_13h         ; Offset int_13h
		dw offset int_14h         ; Offset int_14h
		dw offset int_15h         ; Offset int_15h
		dw offset int_16h         ; Offset int_16h
		dw offset int_17h         ; Offset int_17h
		dw offset dummy_int       ; Offset int_18h
		dw offset int_19h         ; Offset int_19h
		dw offset int_1Ah	  ; Offset int_1Ah
		dw offset dummy_int       ; Offset int_1Bh
		dw offset dummy_int       ; Offset int_1Ch
		dw offset int_1Dh	  ; Offset int_1Dh
		dw offset int_1Eh         ; Offset int_1Eh
int_vec_table_2:
		dw offset int_68h
		dw offset int_69h
		dw offset int_6Ah
		dw offset int_6Bh
		dw offset int_6Ch
		dw offset int_6Dh
		dw offset int_6Eh
		dw offset int_6Fh

BDA:

rs232_1:	dw    3F8h	
rs232_2:	dw    2F8h	
rs232_3:	dw    0
rs232_4:	dw    0
lpt_1:		dw    378h	
lpt_2:		dw    278h	
lpt_3:		dw    0
bios_data_seg:	dw    0
equip_bit:	dw    626Dh	
manufact_test:	db    0
main_ram_size:	dw    0
error_codes:	dw    40h
kb_flag_1:	db    0
kb_flag_2:	db    0
kb_alt_num:	db    0
kb_q_head:	dw  1Eh
kb_q_tail:	dw  1Eh
kb_queue:	dw  1Eh
		db    2 dup(0)
; ---------------------------------------------------------------------------
;  Dummy interrupt
;----------------------------------------------------------------------------
proc		dummy_int near
		iret
endp		dummy_int

;---------------------------------------------------------------------------------------------------
; Interrupt 5h - Print Screen
;---------------------------------------------------------------------------------------------------
proc		int_05h	far				; Print screen service		
		sti
		push	ds
		push	ax
		push	bx
		push	cx
		push	dx
		mov	ax, 50h
		mov	ds, ax
		assume ds:nothing
		cmp	[byte ptr ds:0], 1
		jz	short loc_FFFC5
		mov	[byte ptr ds:0], 1
		mov	ah, 0Fh
		int	10h		; - VIDEO - GET	CURRENT	VIDEO MODE
					; Return: AH = number of columns on screen
					; AL = current video mode
					; BH = current active display page
		mov	cl, ah
		mov	ch, 19h
		call	print_cr_lf
		push	cx
		mov	ah, 3
		int	10h		; - VIDEO - READ CURSOR	POSITION
					; BH = page number
					; Return: DH,DL	= row,column, CH = cursor start	line, CL = cursor end line
		pop	cx
		push	dx
		xor	dx, dx

loc_FFF7F:				; ...
		mov	ah, 2
		int	10h		; - VIDEO - SET	CURSOR POSITION
					; DH,DL	= row, column (0,0 = upper left)
					; BH = page number
		mov	ah, 8
		int	10h		; - VIDEO - READ ATTRIBUTES/CHARACTER AT CURSOR	POSITION
					; BH = display page
					; Return: AL = character
					; AH = attribute of character (alpha modes)
		or	al, al
		jnz	short loc_FFF8D
		mov	al, 20h

loc_FFF8D:				; ...
		push	dx
		xor	dx, dx
		xor	ah, ah
		int	17h		; PRINTER - OUTPUT CHARACTER
					; AL = character, DX = printer port (0-3)
					; Return: AH = status bits
		pop	dx
		test	ah, 25h
		jnz	short loc_FFFBB
		inc	dl
		cmp	cl, dl
		jnz	short loc_FFF7F
		xor	dl, dl
		mov	ah, dl
		push	dx
		call	print_cr_lf
		pop	dx
		inc	dh
		cmp	ch, dh
		jnz	short loc_FFF7F
		pop	dx
		mov	ah, 2
		int	10h		; - VIDEO - SET	CURSOR POSITION
					; DH,DL	= row, column (0,0 = upper left)
					; BH = page number
		mov	[byte ptr ds:0], 0
		jmp	short loc_FFFC5

loc_FFFBB:				; ...
		pop	dx
		mov	ah, 2
		int	10h		; - VIDEO - SET	CURSOR POSITION
					; DH,DL	= row, column (0,0 = upper left)
					; BH = page number
		mov	[byte ptr ds:0], 0FFh

loc_FFFC5:				; ...
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		pop	ds
		assume ds:nothing
		iret
endp		int_05h



;--------------------------------------------------------------------------------------------------
; Prints CR+LF on the printer
;--------------------------------------------------------------------------------------------------
proc    	print_cr_lf     near
		xor	dx, dx
		xor	ah, ah
		mov	al, LF
		int	17h		; PRINTER - OUTPUT CHARACTER
					; AL = character, DX = printer port (0-3)
					; Return: AH = status bits
		xor	ah, ah
		mov	al, CR
		int	17h		; PRINTER - OUTPUT CHARACTER
					; AL = character, DX = printer port (0-3)
					; Return: AH = status bits
		retn
endp		print_cr_lf	

; ---------------------------------------------------------------------------
; Second interrupt table procedure. This table create for scanning keyboard matrix usualy is one hardware interrupt
;---------------------------------------------------------------------------
proc		int_68h near
		int	8		;  - IRQ0 - TIMER INTERRUPT
		iret
endp		int_68h
; ---------------------------------------------------------------------------
proc		int_6Ah near
		int	0Ah		;  - IRQ2 - EGA	VERTICAL RETRACE
		iret
endp		int_6Ah
; ---------------------------------------------------------------------------
proc		int_6Bh	near
		int	0Bh		;  - IRQ3 - COM2 INTERRUPT
		iret
endp		int_6Bh
; ---------------------------------------------------------------------------
proc		int_6Ch  near
		int	0Ch		;  - IRQ4 - COM1 INTERRUPT
		iret
endp		int_6Ch
; ---------------------------------------------------------------------------
proc		int_6Dh	near
		int	0Dh		;  - IRQ5 - FIXED DISK (PC), LPT2 (AT/PS)
		iret
endp		int_6Dh
; ---------------------------------------------------------------------------
proc		int_6Eh  near
		int	0Eh		;  - IRQ6 - DISKETTE INTERRUPT
		iret
endp		int_6Eh
; ---------------------------------------------------------------------------
proc		int_6Fh near
		int	0Fh		;  - IRQ7 - PRINTER INTERRUPT
		iret
endp		int_6Fh
; ---------------------------------------------------------------------------
		db    0
;--------------------------------------------------------------------------------------------------
; Power-On Entry Point
;--------------------------------------------------------------------------------------------------
proc		power	far				;   CPU begins here on power up
		jmpfar	0F000h, warm_boot
endp 		power
; ---------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------
; BIOS Release Date and Signature
;--------------------------------------------------------------------------------------------------
date		db '01/21/96',0

		db 0FEh
		;db    0

ends		code


		end
