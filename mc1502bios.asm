	Ideal
	model small ; produce .EXE file then truncate it
;---------------------------------------------------------------------------------------------------
; Macros
;---------------------------------------------------------------------------------------------------
; Pad code to create entry point at specified address (needed for 100% IBM BIOS compatibility)
macro	jmpfar	segm, offs
        db	0EAh;
        dw	offs, segm
endm
;---------------------------------------------------------------------------------------------------
; Line feed and carriage return
LF	equ	0Ah
CR	equ	0Dh

BDAseg equ 040h

equip_bits_ equ 010h
main_ram_size_ equ 013h
keybd_flags_1_ equ 017h
keybd_flags_2_ equ 018h
keybd_alt_num_ equ 019h
keybd_q_head_ equ 01Ah
keybd_q_tail_ equ 01Ch

dsk_recal_stat equ 03Eh
dsk_motor_stat equ 03Fh
dsk_motor_tmr equ 040h
dsk_ret_code_ equ 041h
dsk_status_1 equ 042h
dsk_status_2 equ 043h
dsk_status_3 equ 044h
dsk_status_4 equ 045h
dsk_status_5 equ 046h
dsk_status_7 equ 048h

video_mode_ equ 049h
video_columns_ equ 04Ah
video_buf_siz_ equ 04Ch 
video_pag_off_ equ 04Eh
vid_curs_pos0_ equ 050h

vid_curs_mode_ equ 060h
video_page_ equ 062h
video_port_ equ 063h
video_mode_reg_ equ 065h
video_color_ equ 066h

gen_use_ptr_ equ 067h
gen_use_seg_ equ 069h
keybd_break_ equ 071h
prn_timeout_1_ equ 078h
rs232_timeout1_ equ 07Ch

gen_int_occurd_ equ 06Bh
timer_low_ equ 06Ch
timer_hi_ equ 06Eh
timer_rolled_ equ 070h

dsk_motor_stat_ equ 043Fh

warm_boot_flag_ equ 072h

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
                db 18 dup (0)

; ---------------------------------------------------------------------------
proc		post	near
warm_boot:				; Entered by POWER_ON/RESET
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
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                xor	ax, ax
                mov	ss, ax
                mov	sp, 800h
                mov	bp, [ds:warm_boot_flag_]
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
                mov	ax, BDAseg
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

loc_FE12E:				; ...
                mov	ax, [bx]
                not	ax
                mov	[bx], ax
                cmp	ax, [bx]
                jnz	short Print_Startup_Information
                not	[word ptr bx]
                add	ch, 8
                mov	ds, cx
                assume ds:nothing
                add	di, 20h
                cmp	di, 2E0h
                jb	short loc_FE12E

Print_Startup_Information:				; ...
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
                cmp	bx, [ds:main_ram_size_]
                jb	short loc_FE17D

loc_FE1AC:				; ...
                mov	ax, BDAseg
                mov	ds, ax
                mov	[word ptr ds:gen_use_ptr_], 3
                mov	[word ptr ds:gen_use_seg_], 0BE00h

loc_FE1BD:				; ...
                mov	ax, BDAseg
                mov	ds, ax
                add	[word ptr ds:gen_use_seg_+1], 2
                cmp	[word ptr ds:gen_use_seg_], 0FE00h
                jz	short loc_FE1E2
                mov	es, [word ptr ds:gen_use_seg_]
                assume es:nothing
                cmp	[word ptr es:0], 0AA55h
                jnz	short loc_FE1BD
                call	[dword ptr ds:gen_use_ptr_]
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
                mov	[ds:main_ram_size_], bx
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
                mov	dh, [ds:dsk_status_4]
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
                test	[ds:dsk_recal_stat], al
                jnz	short loc_FE308
                call	sub_FE394
                jnb	short loc_FE304
                pop	cx
                jmp	short loc_FE36A
; ---------------------------------------------------------------------------
; dsk_status ?
loc_FE304:				; ...
                or	[ds:dsk_recal_stat], al

loc_FE308:				; ...
                mov	al, ah
                call	sub_FE2D3
                mov	dl, [ds:dsk_status_1]
                inc	dx
                out	dx, al
                mov	cl, [ds:dsk_status_7]
                shl	al, cl
                cmp	al, [si+dsk_status_5]
                jz	short loc_FE360
                inc	dx
                inc	dx
                out	dx, al
                xchg al, [si+dsk_status_5]
                dec	dx
                dec	dx
                out	dx, al
                dec	dx
                mov	al, 10h
                out	dx, al
                call	sub_FE2DD
                mov	al, ah
                mov	dl, [ds:dsk_status_1]
                inc	dx
                out	dx, al
                test	[byte ptr ds:dsk_motor_stat], 80h
                jz	short loc_FE360
                inc	dx
                inc	dx
                out	dx, al
                mov	dl, [ds:dsk_status_1]
                mov	al, bl
                out	dx, al
                mov	dl, [ds:dsk_status_3]
                in	al, dx
                mov	dl, [ds:dsk_status_1]
                in	al, dx
                and	al, 19h
                jz	short loc_FE360
                or	[byte ptr ds:dsk_ret_code_], 40h
                stc
                pop	cx
                jmp	short loc_FE36A
; ---------------------------------------------------------------------------

loc_FE360:				; ...
                pop	cx
                mov	al, cl
                mov	dl, [ds:dsk_status_1]
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
                mov	dl, [ds:dsk_status_1]
                out	dx, al
                call	sub_FE2DD
                mov	al, 0C0h
                out	dx, al
                mov	ah, 3
                add	ah, dl

loc_FE380:				; ...
                mov	dl, [ds:dsk_status_3]
                in	al, dx
                shr	al, 1
                mov	dl, ah
                in	al, dx
                jb	short loc_FE380
                mov	dl, [ds:dsk_status_1]
                in	al, dx
                and	al, 10h
                retn
endp		sub_FE36C





proc		sub_FE394 near		; ...
                push	ax
                mov	dl, [ds:dsk_status_2]
                in	al, dx
                mov	dl, [ds:dsk_status_1]
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
                or	[byte ptr ds:dsk_ret_code_], 80h
                stc

loc_FE3B7:				; ...
                mov	dl, [ds:dsk_status_2]
                in	al, dx
                mov	[byte ptr si+0046h], 0
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
                mov	[byte ptr ds:dsk_status_7], 0
                test	[byte ptr si+90h], 10h
                jnz	short loc_FE3E1
                mov	[byte ptr si+0090h], 17h

loc_FE3E1:				; ...
                test	[byte ptr si+0090h], 20h
                jz	short loc_FE3F8
                cmp	ch, 2Ch
                jnb	short loc_FE3F3
                inc	[byte ptr ds:dsk_status_7]
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
                mov	dl, [ds:dsk_status_2]
                out	dx, al
                in	al, dx
                mov	dl, [ds:dsk_status_1]
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
                mov	al, [ds:video_mode_reg_]
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
                cmp	ax, 0060h  ; 96 kb
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
                mov	al, [ds:video_mode_reg_]

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
                mov	ax, BDAseg
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
                mov	dx, [ds:keybd_q_head_]
                cmp	dx, [ds:keybd_q_tail_]
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
                and	[byte ptr ds:keybd_flags_1_], 0DFh
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
                test	[byte ptr ds:keybd_flags_1_], 4
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
                test	[byte ptr ds:keybd_flags_1_], 40h
                jnz	short loc_FE636
                test	[byte ptr ds:keybd_flags_1_], 3
                jnz	short loc_FE63D

loc_FE62F:				; ...
                mov	bx, offset unk_FE656
                xlat	[byte ptr cs:bx]
                jmp	short loc_FE654
; ---------------------------------------------------------------------------

loc_FE636:				; ...
                test	[byte ptr ds:keybd_flags_1_], 3
                jnz	short loc_FE62F

loc_FE63D:				; ...
                mov	bx, offset unk_FE689
                xlat	[byte ptr cs:bx]
                jmp	short loc_FE654
; ---------------------------------------------------------------------------

loc_FE644:				; ...
                test	[byte ptr ds:keybd_flags_1_], 3
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
unk_FE689	db  89h	; ?		; ...
                db  96h	; ?
                db  93h	; ?
                db  8Ah	; ?
                db  85h	; ?
                db  8Dh	; ?
                db  83h	; ?
                db  98h	; ?
                db  99h	; ?
                db  87h	; ?
                db  95h	; ?
                db  9Ah	; ?
                db    0
                db    0
                db  94h	; ?
                db  9Bh	; ?
                db  82h	; ?
                db  80h	; ?
                db  8Fh	; ?
                db  90h	; ?
                db  8Eh	; ?
                db  8Bh	; ?
                db  84h	; ?
                db  86h	; ?
                db  9Dh	; ?
                db 0F0h	; ?
                db    0
                db  5Dh	; ]
                db  9Fh	; ?
                db  97h	; ?
                db  91h	; ?
                db  8Ch	; ?
                db  88h	; ?
                db  92h	; ?
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

                jmpfar	0e000h,0
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

data_28		dw    0470h ; Data table (indexed access)
                dw    341h
                dw    1A1h
                dw    0D0h
                dw    068h
                dw    034h
                dw    01Ah
                dw    00Dh
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
;---------------------------------------------------------------------------------------------------
; Interrupt 16h - Keyboard
;---------------------------------------------------------------------------------------------------
proc		int_16h
                sti
                push	ds
                push	bx
                mov	bx, BDAseg
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
                mov	bx, [ds:keybd_q_head_]
                cmp	bx, [ds:keybd_q_tail_]
                sti
                jz	short loc_FE845
                mov	ax, [bx]
                call	sub_FE5E8
                mov	[ds:keybd_q_head_], bx
                pop	bx
                pop	ds
                iret
; ---------------------------------------------------------------------------

loc_FE85E:				; ...
                cli
                mov	bx, [ds:keybd_q_head_]
                cmp	bx, [ds:keybd_q_tail_]
                mov	ax, [bx]
                sti
                pop	bx
                pop	ds
                retf	2
; ---------------------------------------------------------------------------

loc_FE86F:				; ...
                mov	al, [ds:keybd_flags_1_]
                pop	bx
                pop	ds
                iret



proc		sub_FE875 near		; ...
                add	bx, 2

                cmp	bx, 0x003E
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
data_31		db  80h	;
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
                db  7Fh	;
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
                db  84h	;
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
unk_FE91F	db  1Bh	; ...
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
                mov	ax, BDAseg
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
                mov	ah, cs:data_31[di]
                test	al, 80h
                jnz	short loc_FEA14
                cmp	ah, 10h
                jnb	short loc_FE9CD
                or	[ds:keybd_flags_1_], ah
                jmp	loc_FEA4F
; ---------------------------------------------------------------------------

loc_FE9CD:				; ...
                test	[byte ptr ds:keybd_flags_1_], 4
                jnz	short loc_FEA3B
                cmp	al, 52h

loc_FE9D6:
                jnz	short loc_FE9FC
                test	[byte ptr ds:keybd_flags_1_], 8
                jz	short loc_FE9E1
                jmp	short loc_FEA3B
; ---------------------------------------------------------------------------

loc_FE9E1:				; ...
                test	[byte ptr ds:keybd_flags_1_], 20h
                jnz	short loc_FE9F5
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short loc_FE9FC

loc_FE9EF:				; ...
                mov	ax, 5230h
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FE9F5:				; ...
                test	[byte ptr ds:keybd_flags_1_], 3
                jz	short loc_FE9EF

loc_FE9FC:				; ...
                test	[ds:keybd_flags_2_], ah
                jnz	short loc_FEA4F
                or	[ds:keybd_flags_2_], ah
                xor	[ds:keybd_flags_1_], ah
                cmp	al, 52h
                jnz	short loc_FEA4F
                mov	ax, 5200h
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEA14:				; ...
                cmp	ah, 10h
                jnb	short loc_FEA33
                not	ah
                and	[ds:keybd_flags_1_], ah
                cmp	al, 0B8h
                jnz	short loc_FEA4F
                mov	al, [ds:keybd_alt_num_]
                mov	ah, 0
                mov	[ds:keybd_alt_num_], ah
                cmp	al, 0
                jz	short loc_FEA4F
                jmp	loc_FEBD0
; ---------------------------------------------------------------------------

loc_FEA33:				; ...
                not	ah
                and	[ds:keybd_flags_2_], ah
                jmp	short loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEA3B:				; ...
                cmp	al, 80h
                jnb	short loc_FEA4F
                test	[byte ptr ds:keybd_flags_2_], 8
                jz	short loc_FEA59
                cmp	al, 45h
                jz	short loc_FEA4F
                and	[byte ptr ds:keybd_flags_2_], 0F7h

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
                test	[byte ptr ds:keybd_flags_1_], 8
                jnz	short loc_FEA63
                jmp	loc_FEAF2
; ---------------------------------------------------------------------------

loc_FEA63:				; ...
                test	[byte ptr ds:keybd_flags_1_], 4
                jz	short near ptr unk_FEA9B
                cmp	al, 53h
                jnz	short near ptr unk_FEA9B
                mov	[word ptr ds:warm_boot_flag_], 1234h
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
; ---------------------------------------------------------------------------
unk_FEA9B:
		cmp	al,39h   ; '9'
		jne	loc_EAA4 ; Jump if not equal
                mov	al, 20h
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------
loc_EAA4:
                mov	di, offset unk_FEA77
                mov	cx, 0Ah
                repne scasb
                jnz	short loc_FEAC0
                sub	di, offset unk_FEA78
                mov	al, [ds:keybd_alt_num_]
                mov	ah, 0Ah
                mul	ah
                add	ax, di
                mov	[ds:keybd_alt_num_], al
                jmp	short loc_FEA4F
; ---------------------------------------------------------------------------

loc_FEAC0:				; ...
                mov	[byte ptr ds:keybd_alt_num_], 0
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
                test	[byte ptr ds:keybd_flags_1_], 4
                jz	short loc_FEB53
                cmp	al, 46h
                jnz	short loc_FEB15
                mov	bx, 1Eh
                mov	[ds:keybd_q_head_], bx
                mov	[ds:keybd_q_tail_], bx
                mov	[byte ptr ds:keybd_break_], 80h
                int	1Bh		; CTRL-BREAK KEY
                mov	ax, 0
                jmp	loc_FEBC7
; ---------------------------------------------------------------------------

loc_FEB15:				; ...
                cmp	al, 45h
                jnz	short loc_FEB3A
                or	[byte ptr ds:keybd_flags_2_], 8
                mov	al, 20h
                out	20h, al		; Interrupt controller,	8259A.
                cmp	[byte ptr ds:video_mode_], 7
                jz	short loc_FEB30
                mov	dx, 3D8h
                mov	al, [ds:video_mode_reg_]
                out	dx, al

loc_FEB30:				; ...
                test	[byte ptr ds:keybd_flags_2_], 8
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
                test	[byte ptr ds:keybd_flags_1_], 3
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
                test	[byte ptr ds:keybd_flags_1_], 20h
                jnz	short loc_FEBAA
                test	[byte ptr ds:keybd_flags_1_], 3
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
                test	[byte ptr ds:keybd_flags_1_], 3
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
                test	[byte ptr ds:keybd_flags_1_], 40h
                jz	short loc_FEBF7
                test	[byte ptr ds:keybd_flags_1_], 3
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
                mov	bx, [ds:keybd_q_tail_]
                mov	si, bx
                call	sub_FE875
                cmp	bx, [ds:keybd_q_head_]
                jz	short loc_FEC0F
                mov	[si], ax
                mov	[ds:keybd_q_tail_], bx
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
                mov	si, BDAseg
                mov	ds, si
                assume ds:nothing
                call	sub_FEC85
                mov	ah, [cs:MotorOff]
                mov	[ds:dsk_motor_tmr], ah
                mov	ah, [ds:dsk_ret_code_]
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
                mov	ah, [ds:dsk_ret_code_]
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

                and	[byte ptr ds:dsk_motor_stat], 7Fh
                or	ah, ah
                jz	short loc_FED01
                dec	ah
                jz	short loc_FED31
                mov	[byte ptr ds:dsk_ret_code_], 0
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
                mov	[byte ptr ds:dsk_ret_code_], 1
                retn
; ---------------------------------------------------------------------------

loc_FED01:				; ...
                mov	al, 0
                mov	[ds:3Eh], al
                mov	[ds:dsk_ret_code_], al
                mov	ah, [ds:dsk_motor_stat]
                test	ah, 3
                jz	short loc_FED1A
                mov	al, 4
                shr	ah, 1
                jb	short loc_FED1A
                mov	al, 18h

loc_FED1A:				; ...
                call	sub_FE2D3
                mov	dl, [ds:dsk_status_2]
                out	dx, al
                inc	ax
                out	dx, al
                mov	dl, [ds:dsk_status_1]
                mov	al, 0D0h
                out	dx, al
                mov	dl, [ds:dsk_status_2]
                in	al, dx
                retn
; ---------------------------------------------------------------------------

loc_FED31:				; ...
                mov	al, [ds:dsk_ret_code_]
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
                or	[byte ptr ds:dsk_motor_stat], 80h

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
                mov	cl, [ds:dsk_status_1]
                add	cl, 3
                test	[byte ptr ds:dsk_motor_stat], 80h
                jnz	short loc_FED9E

loc_FED6A:				; ...
                mov	di, bx
                mov	al, 80h
                mov	dl, [ds:dsk_status_1]
                out	dx, al
                mov	dl, [ds:dsk_status_3]
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
                mov	dl, [ds:dsk_status_1]
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
                mov	dl, [ds:dsk_status_1]
                out	dx, al
                mov	dl, [ds:dsk_status_3]
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
                mov	dl, [ds:dsk_status_1]
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
                test	[byte ptr ds:dsk_motor_stat], 80h
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
                or	[ds:dsk_ret_code_], ah
                mov	al, bh
                retn
endp		sub_FECC2





proc		sub_FEE04 near		; ...
                mov	dl, [ds:dsk_status_1]
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
                or	[byte ptr ds:dsk_motor_stat], 80h
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
                lds	bx, [ds:prn_timeout_1_]
                mov	di, [bx+7]
                mov	bx, BDAseg
                mov	ds, bx
                assume ds:nothing
                call	sub_FE452
                call	sub_FE2D3
                mov	dl, [ds:dsk_status_3]
                mov	bp, dx
                mov	dl, [ds:dsk_status_1]
                mov	al, 0F0h
                out	dx, al
                add	dl, 3
                test	[byte ptr ds:dsk_motor_stat], 20h
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
                mov	dl, [ds:dsk_status_1]
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

data_37	db  93h	; ?
                db  74h	; t
                db  15h
                db  97h	; ?
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

; ---------------------------------------------------------------------------
unk_FEF46:
                db  24h	; $		; ...
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
unk_FEF8F:
                db    0	;
                db  20h ;
                db    1 ;
                db  21h	;
                db  40h	;
                db  60h	;
                db  41h	;
                db  61h	;
unk_FEF97:
                db    0	;
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
                db  32 dup (0)

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
video_funcs:
                dw offset int_10_func_0 ; Set mode
                dw offset int_10_func_1 ; Set cursor type
                dw offset int_10_func_2 ; Set cursor position
                dw offset int_10_func_3 ; Get cursor position
                dw offset int10_end ; Read light pen position - not supported now
                dw offset int_10_func_5 ; Set active display page
                dw offset int_10_func_6 ; Scroll active page up
                dw offset int_10_func_7 ; Scroll active page down
                dw offset int_10_func_8 ; Read attribute/character
                dw offset int_10_func_9 ; Write attribute/character
                dw offset int_10_func_0A ; Write character only
                dw offset int_10_func_0B ; Set color
                dw offset int_10_func_0C ; Write pixel
                dw offset int_10_func_0D ; Read pixel
                dw offset int_10_func_0E ; Write teletype
                dw offset int_10_func_0F ; Return current video state
;---------------------------------------------------------------------------------------------------
; Interrupt 1Dh - Video Parameter Tables
;---------------------------------------------------------------------------------------------------
proc		int_1Dh	far

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
endp		int_1Dh

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
                cmp	al, 10h ; Is ah a legal video command?
                jb	short loc_FF07B
                jmp	int10_end ;   error return if not
; ---------------------------------------------------------------------------

loc_FF07B:				; ...
                xor	ah, ah
                shl	ax, 1  ; Make word value
                xchg	ax, bp
                mov	si, BDAseg
                mov	ds, si
                mov	si, 0B800h
                mov	es, si
                assume es:nothing
                jmp	[cs:video_funcs+bp] ;   vector to routines
				
;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 0: Set mode
;---------------------------------------------------------------------------------------------------
int_10_func_0:				; int 10 function 0: Set video mode
                push	ax
                and	al, 7Fh
                cmp	al, 7
                pop	ax
                jb	short loc_FF107
                jmp	int10_end
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
                mov	ax, [ds:video_mode_reg_]
                add	dx, 4
                out	dx, ax

int10_end:				; ...
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

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 1: Set cursor type
;---------------------------------------------------------------------------------------------------
int_10_func_1:				; ...
                mov	[ds:vid_curs_mode_], cx ; Save cursor type, from CX
                mov	dx, [ds:video_port_] ; Get the port
                mov	al, 0Ah  ; CRT index register 0Ah
                mov	ah, ch
                out	dx, ax
                inc	ax
                mov	ah, cl
                out	dx, ax
                jmp	short int10_end
				
;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 2: Set cursor position
;---------------------------------------------------------------------------------------------------
int_10_func_2:				; ...
                and	bh, 7
                xor	ax, ax
                mov	al, bh
                shl	ax, 1
                xchg	ax, si
                mov	[si+vid_curs_pos0_], dx
                cmp	[byte ptr ds:video_mode_], 4
                jnb	short loc_FF1EF
                cmp	bh, [ds:video_page_]
                jnz	short loc_FF1EF
                mov	ax, [ds:video_columns_]
                mul	dh
                xor	cx, cx
                mov	cl, dl
                add	cx, ax
                mov	ax, [ds:video_pag_off_]
                shr	ax, 1
                add	cx, ax
                mov	dx, [ds:video_port_]
                mov	al, 0Eh
                mov	ah, ch
                out	dx, ax
                inc	ax
                mov	ah, cl
                out	dx, ax

loc_FF1EF:				; ...
                jmp	short int10_end
;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 3: Get cursor position
;---------------------------------------------------------------------------------------------------
int_10_func_3:				; ...
                and	bh, 7
                mov	bl, bh
                xor	bh, bh
                shl	bx, 1
                mov	dx, [bx+50h]
                mov	cx, [ds:vid_curs_mode_]
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

int_10_func_5:			; Set active display page
                and	ax, 7
                mov	[ds:video_page_], al
                mov	bh, al
                mul	[word ptr ds:video_buf_siz_]
                mov	[ds:video_pag_off_], ax
                shr	ax, 1
                xchg	ax, cx
                mov	dx, [ds:video_port_]
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
                mov	ax, [ds:video_columns_]
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
                jmp	int10_end
;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 6: Scroll active page up
;---------------------------------------------------------------------------------------------------
int_10_func_6:
                mov	bl, al
                cmp	[byte ptr ds:video_mode_], 4
                jb	short loc_FF259
                jmp	loc_FF543
; ---------------------------------------------------------------------------

loc_FF259:				; ...
                sub	dl, cl
                inc	dl
                sub	dh, ch
                inc	dh
                mov	bp, [ds:video_columns_]
                mov	ax, bp
                mul	ch
                xor	ch, ch
                add	ax, cx
                shl	ax, 1
                add	ax, [ds:video_pag_off_]
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
                mov	ax, [ds:video_columns_]
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
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                mov	ax, [ds:video_mode_reg_]
                mov	dx, [ds:video_port_]
                add	dx, 4
                out	dx, ax
                jmp	int10_end

;---------------------------------------------------------------------------------------------------
;                 Function 7: Scroll active page down
;---------------------------------------------------------------------------------------------------
int_10_func_7:				; ...
                std
                mov	bl, al
                cmp	[byte ptr ds:video_mode_], 4
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
                mov	bp, [ds:video_columns_]
                mov	ax, bp
                mul	ch
                xor	ch, ch
                add	ax, cx
                shl	ax, 1
                add	ax, [ds:video_pag_off_]
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
                mov	ax, [ds:video_columns_]
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

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 8: Read attribute/character
;---------------------------------------------------------------------------------------------------
int_10_func_8:				; ...
                cmp	[byte ptr ds:video_mode_], 4
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
                mov	ax, [ds:video_buf_siz_]
                mul	bx
                xchg	ax, cx
                xchg	ax, dx
                mov	ax, [ds:video_columns_]
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
;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 9: Write attribute/character
;---------------------------------------------------------------------------------------------------
int_10_func_9:				; ...
                cmp	[byte ptr ds:video_mode_], 4
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
                mov	ax, [ds:video_buf_siz_]
                mul	bx
                xchg	ax, cx
                xchg	ax, dx
                mov	ax, [ds:video_columns_]
                mul	dh
                xor	dh, dh
                add	ax, dx
                shl	ax, 1
                add	ax, cx
                xchg	ax, di
                pop	cx
                pop	ax
                rep stosw
                jmp	int10_end

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 10: Write character only
;---------------------------------------------------------------------------------------------------
int_10_func_0A:
                cmp	[byte ptr ds:video_mode_], 4
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
                mov	ax, [ds:video_buf_siz_]
                mul	bx
                xchg	ax, cx
                xchg	ax, dx
                mov	ax, [ds:video_columns_]
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
                jmp	int10_end


;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 11: Set color
;---------------------------------------------------------------------------------------------------
int_10_func_0B:				; ...
                mov	dx, [ds:video_port_]
                add	dx, 5
                mov	al, [ds:video_color_]
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
                mov	[ds:video_color_], al
                jmp	int10_end

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 12: Write pixel
;---------------------------------------------------------------------------------------------------
int_10_func_0C:
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
                test	[byte ptr ds:video_mode_], 2
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
                test	[byte ptr ds:video_mode_], 2
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
                jmp	int10_end

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 13: Read pixel
;---------------------------------------------------------------------------------------------------
int_10_func_0D:				; ...
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
                test	[byte ptr ds:video_mode_], 2
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
                test	[byte ptr ds:video_mode_], 2
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

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 14: Write teletype
;---------------------------------------------------------------------------------------------------
int_10_func_0E:				; ...
                mov	bh, [ds:video_page_]
                xor	cx, cx
                mov	cl, bh
                shl	cx, 1
                mov	si, cx
                mov	dx, [si+vid_curs_pos0_]
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
                mov	ax, [ds:video_columns_]
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
                cmp	[byte ptr ds:video_mode_], 4
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
                mov	dx, [ds:video_columns_]
                dec	dx
                mov	dh, 18h

loc_FF507:				; ...
                int	10h		; - VIDEO - SCROLL PAGE	UP
                                        ; AL = number of lines to scroll window	(0 = blank whole window)
                                        ; BH = attributes to be	used on	blanked	lines
                                        ; CH,CL	= row,column of	upper left corner of window to scroll
                                        ; DH,DL	= row,column of	lower right corner of window
                jmp	int10_end
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
                jmp	int10_end
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
                test	[byte ptr ds:video_mode_], 2
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
                jmp	int10_end
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
                test	[byte ptr ds:video_mode_], 2
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
                jmp	int10_end
; ---------------------------------------------------------------------------

loc_FF65C:				; ...
                sub	sp, 8
                mov	bp, sp
                mov	dx, [ds:vid_curs_pos0_]
                test	[byte ptr ds:video_mode_], 2
                jnz	short loc_FF66E
                shl	dl, 1

loc_FF66E:				; ...
                mov	al, 0A0h
                mul	dh
                shl	ax, 1
                xor	dh, dh
                add	ax, dx
                xchg	ax, si
                mov	dl, [ds:video_mode_]
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
                mov	di, offset gfx_chars
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
                les	di, [ds:rs232_timeout1_]
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
                mov	dx, [ds:vid_curs_pos0_]
                test	[byte ptr ds:video_mode_], 2
                jnz	short loc_FF70B
                shl	dl, 1

loc_FF70B:				; ...
                mov	al, 0A0h
                mul	dh
                shl	ax, 1
                xor	dh, dh
                add	ax, dx
                xchg	ax, di
                mov	dl, [ds:video_mode_]
                mov	ax, cs
                mov	ds, ax
                assume ds:nothing
                xor	ax, ax
                mov	si, 0FA6Eh
                test	bh, 80h
                jz	short loc_FF731
                mov	ds, ax
                assume ds:nothing
                lds	si, [ds:rs232_timeout1_]
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
                jmp	int10_end

;---------------------------------------------------------------------------------------------------
; Interrupt 10h - Function 15: Return current video state
;---------------------------------------------------------------------------------------------------
int_10_func_0F:				; ...
                mov	ax, [ds:video_mode_]
                mov	bh, [ds:video_page_]
                pop	es
                pop	ds
                pop	di
                pop	si
                pop	bp
                pop	dx
                pop	cx
                add	sp, 4
                iret

;---------------------------------------------------------------------------------------------------
; Interrupt 12h - Memory Size
;---------------------------------------------------------------------------------------------------
proc		int_12h near
                sti
                push	ds
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                mov	ax, [ds:main_ram_size_]
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
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                mov	ax, [ds:equip_bits_]
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
                mov	ax, BDAseg
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
                mov	[ds:gen_int_occurd_], al
                mov	dx, 3F7Ah

loc_FF8DD:				; ...
                test	[byte ptr ds:keybd_break_], 80h
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
                test	[byte ptr ds:keybd_break_], 80h
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
                mov	[word ptr ds:gen_use_seg_], 0FFFFh
                mov	dx, 100h

loc_FF92F:				; ...
                test	[byte ptr ds:keybd_break_], 80h
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
                cmp	[word ptr ds:gen_use_seg_], 1D0Fh
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
                mov	ah, [ds:gen_int_occurd_]

loc_FF996:				; ...
                in	al, 62h		; PC/XT	PPI port C. Bits:
                                        ; 0-3: values of DIP switches
                                        ; 5: 1=Timer 2 channel out
                                        ; 6: 1=I/O channel check
                                        ; 7: 1=RAM parity check	error occurred.
                and	al, 40h
                cmp	al, ah
                loope	loc_FF996
                mov	[ds:gen_int_occurd_], al
                mov	al, 0
                out	43h, al		; Timer	8253-5 (AT: 8254.2).
                in	al, 40h		; Timer	8253-5 (AT: 8254.2).
                mov	ah, al
                in	al, 40h		; Timer	8253-5 (AT: 8254.2).
                xchg	al, ah
                mov	bx, [ds:gen_use_ptr_]
                sub	bx, ax
                mov	[ds:gen_use_ptr_], ax
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
                mov	[word ptr ds:gen_use_seg_], 0FFFFh
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
                mov	ax, [ds:gen_use_seg_]
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
                mov	ax, [ds:gen_use_seg_]
                rcr	ax, 1
                rcl	ax, 1
                clc
                jno	short loc_FFA4C
                xor	ax, 810h
                stc

loc_FFA4C:				; ...
                rcl	ax, 1
                mov	[ds:gen_use_seg_], ax
                retn
endp		sub_FFA3E

; ---------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------
; 8x8 Graphics Character Set (chars 0-127)
;---------------------------------------------------------------------------------------------------
gfx_chars	db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h		;   0  nul
                db	07Eh, 081h, 0A5h, 081h, 0BDh, 099h, 081h, 07Eh		;   1  soh
                db	07Eh, 0FFh, 0DBh, 0FFh, 0C3h, 0E7h, 0FFh, 07Eh		;   2  stx
                db	06Ch, 0FEh, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h		;   3  etx
                db	010h, 038h, 07Ch, 0FEh,	07Ch, 038h, 010h, 000h		;   4  eot
                db	038h, 07Ch, 038h, 0FEh,	0FEh, 07Ch, 038h, 07Ch		;   5  enq
                db	010h, 010h, 038h, 07Ch,	0FEh, 07Ch, 038h, 07Ch		;   6  ack
                db	000h, 000h, 018h, 03Ch,	03Ch, 018h, 000h, 000h		;   7  bel
                db	0FFh, 0FFh, 0E7h, 0C3h, 0C3h, 0E7h, 0FFh, 0FFh		;   8  bs
                db	000h, 03Ch, 066h, 042h, 042h, 066h, 03Ch, 000h		;   9  ht
                db	0FFh, 0C3h, 099h, 0BDh, 0BDh, 099h, 0C3h, 0FFh		;  10  lf
                db	00Fh, 007h, 00Fh, 07Dh, 0CCh, 0CCh, 0CCh, 078h		;  11  vt
                db	03Ch, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h		;  12  ff
                db	03Fh, 033h, 03Fh, 030h, 030h, 070h, 0F0h, 0E0h		;  13  cr
                db	07Fh, 063h, 07Fh, 063h, 063h, 067h, 0E6h, 0C0h		;  14  so
                db	099h, 05Ah, 03Ch, 0E7h, 0E7h, 03Ch, 05Ah, 099h		;  15  si
                db	080h, 0E0h, 0F8h, 0FEh, 0F8h, 0E0h, 080h, 000h		;  16  dle
                db	002h, 00Eh, 03Eh, 0FEh,	03Eh, 00Eh, 002h, 000h		;  17  dc1
                db	018h, 03Ch, 07Eh, 018h, 018h, 07Eh, 03Ch, 018h		;  18  dc2
                db	066h, 066h, 066h, 066h,	066h, 000h, 066h, 000h		;  19  dc3
                db	07Fh, 0DBh, 0DBh, 07Bh,	01Bh, 01Bh, 01Bh, 000h		;  20  dc4
                db	03Eh, 063h, 038h, 06Ch,	06Ch, 038h, 0CCh, 078h		;  21  nak
                db	000h, 000h, 000h, 000h,	07Eh, 07Eh, 07Eh, 000h		;  22  syn
                db	018h, 03Ch, 07Eh, 018h, 07Eh, 03Ch, 018h, 0FFh		;  23  etb
                db	018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 000h		;  24  can
                db	018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 000h		;  25  em
                db	000h, 018h, 00Ch, 0FEh, 00Ch, 018h, 000h, 000h		;  26  sub
                db	000h, 030h, 060h, 0FEh,	060h, 030h, 000h, 000h		;  27  esc
                db	000h, 000h, 0C0h, 0C0h,	0C0h, 0FEh, 000h, 000h		;  28  fs
                db	000h, 024h, 066h, 0FFh,	066h, 024h, 000h, 000h		;  29  gs
                db	000h, 018h, 03Ch, 07Eh,	0FFh, 0FFh, 000h, 000h		;  30  rs
                db	000h, 0FFh, 0FFh, 07Eh, 03Ch, 018h, 000h, 000h		;  31  us
                db	000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h		;  32  space
                db	030h, 078h, 078h, 030h,	030h, 000h, 030h, 000h		;  33  !
                db	06Ch, 06Ch, 06Ch, 000h,	000h, 000h, 000h, 000h		;  34  "
                db	06Ch, 06Ch, 0FEh, 06Ch,	0FEh, 06Ch, 06Ch, 000h		;  35  #
                db	030h, 07Ch, 0C0h, 078h, 00Ch, 0F8h, 030h, 000h		;  36  $
                db	000h, 0C6h, 0CCh, 018h, 030h, 066h, 0C6h, 000h		;  37  %
                db	038h, 06Ch, 038h, 076h,	0DCh, 0CCh, 076h, 000h		;  38  &
                db	060h, 060h, 0C0h, 000h,	000h, 000h, 000h, 000h		;  39  '
                db	018h, 030h, 060h, 060h,	060h, 030h, 018h, 000h		;  40  (
                db	060h, 030h, 018h, 018h,	018h, 030h, 060h, 000h		;  41  )
                db	000h, 066h, 03Ch, 0FFh,	03Ch, 066h, 000h, 000h		;  42  *
                db	000h, 030h, 030h, 0FCh,	030h, 030h, 000h, 000h		;  43  +
                db	000h, 000h, 000h, 000h,	000h, 030h, 030h, 060h		;  44  ,
                db	000h, 000h, 000h, 0FCh,	000h, 000h, 000h, 000h		;  45  -
                db	000h, 000h, 000h, 000h,	000h, 030h, 030h, 000h		;  46  .
                db	006h, 00Ch, 018h, 030h,	060h, 0C0h, 080h, 000h		;  47  /
                db	07Ch, 0C6h, 0CEh, 0DEh,	0F6h, 0E6h, 07Ch, 000h		;  48  0
                db	030h, 070h, 030h, 030h,	030h, 030h, 0FCh, 000h		;  49  1
                db	078h, 0CCh, 00Ch, 038h,	060h, 0CCh, 0FCh, 000h		;  50  2
                db	078h, 0CCh, 00Ch, 038h,	00Ch, 0CCh, 078h, 000h		;  51  3
                db	01Ch, 03Ch, 06Ch, 0CCh,	0FEh, 00Ch, 01Eh, 000h		;  52  4
                db	0FCh, 0C0h, 0F8h, 00Ch,	00Ch, 0CCh, 078h, 000h		;  53  5
                db	038h, 060h, 0C0h, 0F8h, 0CCh, 0CCh, 078h, 000h		;  54  6
                db	0FCh, 0CCh, 00Ch, 018h,	030h, 030h, 030h, 000h		;  55  7
                db	078h, 0CCh, 0CCh, 078h,	0CCh, 0CCh, 078h, 000h		;  56  8
                db	078h, 0CCh, 0CCh, 07Ch,	00Ch, 018h, 070h, 000h		;  57  9
                db	000h, 030h, 030h, 000h,	000h, 030h, 030h, 000h		;  58  :
                db	000h, 030h, 030h, 000h,	000h, 030h, 030h, 060h		;  59  ;
                db	018h, 030h, 060h, 0C0h,	060h, 030h, 018h, 000h		;  60  <
                db	000h, 000h, 0FCh, 000h,	000h, 0FCh, 000h, 000h		;  61  =
                db	060h, 030h, 018h, 00Ch, 018h, 030h, 060h, 000h		;  62  >
                db	078h, 0CCh, 00Ch, 018h,	030h, 000h, 030h, 000h		;  63  ?
                db	07Ch, 0C6h, 0DEh, 0DEh,	0DEh, 0C0h, 078h, 000h		;  64  @
                db	030h, 078h, 0CCh, 0CCh, 0FCh, 0CCh, 0CCh, 000h		;  65  A
                db	0FCh, 066h, 066h, 07Ch, 066h, 066h, 0FCh, 000h		;  66  B
                db	03Ch, 066h, 0C0h, 0C0h, 0C0h, 066h, 03Ch, 000h		;  67  C
                db	0F8h, 06Ch, 066h, 066h, 066h, 06Ch, 0F8h, 000h		;  68  D
                db	0FEh, 062h, 068h, 078h,	068h, 062h, 0FEh, 000h		;  69  E
                db	0FEh, 062h, 068h, 078h,	068h, 060h, 0F0h, 000h		;  70  F
                db	03Ch, 066h, 0C0h, 0C0h, 0CEh, 066h, 03Eh, 000h		;  71  G
                db	0CCh, 0CCh, 0CCh, 0FCh,	0CCh, 0CCh, 0CCh, 000h		;  72  H
                db	078h, 030h, 030h, 030h,	030h, 030h, 078h, 000h		;  73  I
                db	01Eh, 00Ch, 00Ch, 00Ch,	0CCh, 0CCh, 078h, 000h		;  74  J
                db	0E6h, 066h, 06Ch, 078h,	06Ch, 066h, 0E6h, 000h		;  75  K
                db	0F0h, 060h, 060h, 060h,	062h, 066h, 0FEh, 000h		;  76  L
                db	0C6h, 0EEh, 0FEh, 0FEh,	0D6h, 0C6h, 0C6h, 000h		;  77  M
                db	0C6h, 0E6h, 0F6h, 0DEh,	0CEh, 0C6h, 0C6h, 000h		;  78  N
                db	038h, 06Ch, 0C6h, 0C6h,	0C6h, 06Ch, 038h, 000h		;  79  O
                db	0FCh, 066h, 066h, 07Ch,	060h, 060h, 0F0h, 000h		;  80  P
                db	078h, 0CCh, 0CCh, 0CCh,	0DCh, 078h, 01Ch, 000h		;  81  Q
                db	0FCh, 066h, 066h, 07Ch,	06Ch, 066h, 0E6h, 000h		;  82  R   +
                db	078h, 0CCh, 0E0h, 070h,	01Ch, 0CCh, 078h, 000h		;  83  S   +
                db	0FCh, 0B4h, 030h, 030h,	030h, 030h, 078h, 000h		;  84  T   +
                db	0CCh, 0CCh, 0CCh, 0CCh,	0CCh, 0CCh, 0FCh, 000h		;  85  U   +
                db	0CCh, 0CCh, 0CCh, 0CCh,	0CCH, 078h, 030h, 000h		;  86  V   +
                db	0C6h, 0C6h, 0C6h, 0D6h,	0FEh, 0EEh, 0C6h, 000h		;  87  W   +
                db	0C6h, 0C6h, 06Ch, 038h,	038h, 06Ch, 0C6h, 000h		;  88  X   +
                db	0CCh, 0CCh, 0CCh, 078h,	030h, 030h, 078h, 000h		;  89  Y   +
                db	0FEh, 0C6h, 08Ch, 018h,	032h, 066h, 0FEh, 000h		;  90  Z   +
                db	078h, 060h, 060h, 060h,	060h, 060h, 078h, 000h		;  91  [   +
                db	0C0h, 060h, 030h, 018h,	00Ch, 006h, 002h, 000h		;  92  backslash   +
                db	078h, 018h, 018h, 018h,	018h, 018h, 078h, 000h		;  93  ]   +
                db	010h, 038h, 06Ch, 0C6h,	000h, 000h, 000h, 000h		;  94  ^   +
                db	000h, 000h, 000h, 000h,	000h, 000h, 000h, 0FFh		;  95  _   +
                db	030h, 030h, 018h, 000h,	000h, 000h, 000h, 000h		;  96  `   +
                db	000h, 000h, 078h, 00Ch,	07Ch, 0CCh, 076h, 000h		;  97  a   +
                db	0E0h, 060h, 060h, 07Ch,	066h, 066h, 0DCh, 000h		;  98  b   +
                db	000h, 000h, 078h, 0CCh,	0C0h, 0CCh, 078h, 000h		;  99  c   +
                db	01Ch, 00Ch, 00Ch, 07Ch,	0CCh, 0CCh, 076h, 000h		; 100  d   +
                db	000h, 000h, 078h, 0CCh,	0FCh, 0C0h, 078h, 000h		; 101  e   +
                db	038h, 06Ch, 060h, 0F0h,	060h, 060h, 0F0h, 000h		; 102  f   +
                db	000h, 000h, 076h, 0CCh,	0CCh, 07Ch, 00Ch, 0F8h		; 103  g   +
                db	0E0h, 060h, 06Ch, 076h,	066h, 066h, 0E6h, 000h		; 104  h   +
                db	030h, 000h, 070h, 030h,	030h, 030h, 078h, 000h		; 105  i   +
                db	00Ch, 000h, 00Ch, 00Ch,	00Ch, 0CCh, 0CCh, 078h		; 106  j   +
                db	0E0h, 060h, 066h, 06Ch,	078h, 06Ch, 0E6h, 000h		; 107  k   +
                db	070h, 030h, 030h, 030h,	030h, 030h, 078h, 000h		; 108  l   +
                db	000h, 000h, 0CCh, 0FEh,	0FEh, 0D6h, 0C6h, 000h		; 109  m   +
                db	000h, 000h, 0F8h, 0CCh,	0CCh, 0CCh, 0CCh, 000h		; 110  n   +
                db	000h, 000h, 078h, 0CCh,	0CCh, 0CCh, 078h, 000h		; 111  o   +
                db	000h, 000h, 0DCh, 066h,	066h, 07Ch, 060h, 0F0h		; 112  p   +
                db	000h, 000h, 076h, 0CCh,	0CCh, 07Ch, 00Ch, 01Eh		; 113  q   +
                db	000h, 000h, 0DCh, 076h,	066h, 060h, 0F0h, 000h		; 114  r   +
                db	000h, 000h, 07Ch, 0C0h,	078h, 00Ch, 0F8h, 000h		; 115  s   +
                db	010h, 030h, 07Ch, 030h,	030h, 034h, 018h, 000h		; 116  t   +
                db	000h, 000h, 0CCh, 0CCh,	0CCh, 0CCh, 076h, 000h		; 117  u   +
                db	000h, 000h, 0CCh, 0CCh,	0CCh, 078h, 030h, 000h		; 118  v   +
                db	000h, 000h, 0C6h, 0D6h, 0FEh, 0FEh, 06Ch, 000h		; 119  w   +
                db	000h, 000h, 0C6h, 06Ch,	038h, 06Ch, 0C6h, 000h		; 120  x   +
                db	000h, 000h, 0CCh, 0CCh,	0CCh, 07Ch, 00Ch, 0F8h		; 121  y   +
                db	000h, 000h, 0FCh, 098h,	030h, 064h, 0FCh, 000h		; 122  z   +
                db	01Ch, 030h, 030h, 0E0h,	030h, 030h, 01Ch, 000h		; 123  {   +
                db	018h, 018h, 018h, 000h,	018h, 018h, 018h, 000h		; 124  |   +
                db	0E0h, 030h, 030h, 01Ch,	030h, 030h, 0E0h, 000h		; 125  }   +
                db	076h, 0DCh, 000h, 000h,	000h, 000h, 000h, 000h		; 126  ~   +
                db	000h, 010h, 038h, 06Ch,	0C6h, 0C6h, 0FEh, 000h		; 127  del +
; ---------------------------------------------------------------------------
proc 		int_1Ah near
                push	ds
                push	ax
                mov	ax, BDAseg
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
                mov	al, [ds:timer_rolled_]
                mov	[byte ptr ds:timer_rolled_], 0
                mov	cx, [ds:timer_hi_]
                mov	dx, [ds:timer_low_]
                jmp	short loc_FFE7E
; ---------------------------------------------------------------------------

loc_FFE92:				; ...
                mov	[ds:timer_low_], dx
                mov	[ds:timer_hi_], cx
                mov	[byte ptr ds:timer_rolled_], 0
                jmp	short loc_FFE7E
; ---------------------------------------------------------------------------
proc		int_08h near
                push	ds
                push	ax
                push	dx
                mov	ax, BDAseg
                mov	ds, ax
                assume ds:nothing
                xor	ax, ax
                inc	[word ptr ds:timer_low_]
                jnz	short loc_FFEB9
                inc	[word ptr ds:timer_hi_]

loc_FFEB9:				; ...
                cmp	[word ptr ds:timer_hi_], 18h
                jnz	short loc_FFED3
                cmp	[word ptr ds:timer_low_], 0B0h
                jnz	short loc_FFED3
                mov	[ds:timer_hi_], ax
                mov	[ds:timer_low_], ax
                mov	[byte ptr ds:timer_rolled_], 1

loc_FFED3:				; ...
                inc	ax
                dec	[byte ptr ds:dsk_motor_tmr]
                jnz	short loc_FFEE7
                and	[byte ptr ds:dsk_motor_stat], 0FCh
                call	sub_FE2D3
                mov	dl, [ds:dsk_status_2]
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
                db    272 dup (0) ; Free Space
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
date	db '01/21/96',0
		db 0FEh  ; Computer type (XT)

ends		code
end
