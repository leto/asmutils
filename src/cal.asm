;; cal.asm for asmutils
;; Copyright (C) 2002 by Scott Lanning,
;; under the GNU General Public License. No warranty.
;; Usage: cal [month year]
;; where month=[1-12] and year=[1970-2038].
;; It's not possible yet to only give the year.
;; Displays the current month if no arguments are given.
;; You can set the UTC_OFFSET %define variable below
;; to be your timezone's offset from UTC/GMT if you're
;; picky about "current month".

;; $Id: cal.asm,v 1.4 2002/03/14 07:12:12 konst Exp $

%include "system.inc"

CODESEG

%define SECS_PER_MIN	60
%define SECS_PER_HOUR	SECS_PER_MIN * 60
%define SECS_PER_DAY	SECS_PER_HOUR * 24
%define SECS_PER_YEAR	SECS_PER_DAY * 365
%define DAYS_PER_WEEK	7

;;; CONFIGURATION
;;;
;;; Put your offset from UTC (GMT) in hours here
;;; It doesn't consider the timezone.
;;; This example is EST (-0500).
%define UTC_OFFSET -5 * SECS_PER_HOUR
;;;
;;;

mon_yday:
	;; non-leapyear year-days
	dw 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365
	mon_yday_len	equ	$ - mon_yday
	;; leapyear year-days
	dw 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366

	;; Month names assumed 3 bytes each plus one whitespace.
	;; The real `cal` displays the complete month name.
months:
	db 'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec '

	;; There are a maximum of 6 rows of day numbers,
	;; plus the month/year row and the day-of-week row at the top.
	;; Each row is 21 bytes wide, mdays 3 bytes each.
	;;       Mar 2002      \n
	;; Su Mo Tu We Th Fr Sa\n
	;;                 1  2\n
	;;  3  4  5  6  7  8  9\n
	;; 10 11 12 13 14 15 16\n
	;; 17 18 19 20 21 22 23\n
	;; 24 25 26 27 28 29 30\n
	;; 31                  \n
	;; (Maybe should move to udataseg and movsb the .days_of_week,
	;; spaces, and \n at runtime. Also this method isn't nice for
	;; displaying all months of the year.)
month_buf:
.month_year	db '                    ', __n
.days_of_week	db 'Su Mo Tu We Th Fr Sa', __n
.month_days:
%rep 6
	db '                    ', __n
%endrep
	month_buf_len	equ	8 * 21

START:
	pop	esi
	cmp	esi, byte 3
	jne	.do_current_month

	;; I figured out already how to do this given the seconds
	;; returned by sys_gettimeofday, so if the user gives month
	;; and year on the command line, I calculate a second that
	;; falls within that month.
	pop	esi		; skip argv[0] == "cal"

	pop	esi		; a month (1-12)
	call	StrToLong
	mov	ebx, edx
	dec	ebx		; (we use 0-11)

	pop	esi		; a year
	call	StrToLong	; returns long in edx
	sub	edx, 1970
	_mov	eax, SECS_PER_YEAR
	mul	edx
	mov	ecx, eax	; save seconds so far

	;; Now eax has num secs from 1970 to Jan 1 of the year given
	;; (except maybe a few leapdays). Next add the number of
	;; seconds to the month given. It's slightly tricky because
	;; of leapyears, but there are only 16 leapyears in 1970-2038,
	;; so we can calculate a second that falls after about day 16
	;; of the month; then, regardless of the number of leapdays
	;; subtracted, we'll still be within that month, which is
	;; all that matters.

	mov	dx, word[mon_yday + 2*ebx]	; num days till that month
	add	edx, byte 20			; 20th of that month
	_mov	eax, SECS_PER_DAY
	mul	edx
	add	eax, ecx

	;; Finally, put it in timeval_struct just like sys_gettimeofday.
	mov	[timeval_struct.tv_sec], eax
	jmp	.skip_gettimeofday

.do_current_month:
	sys_gettimeofday timeval_struct

.skip_gettimeofday:
	mov	eax, [timeval_struct.tv_sec]
	_add	eax, UTC_OFFSET
	_mov	ecx, SECS_PER_DAY
	xor	edx, edx
	div	ecx
	; eax = days = *t / SECS_PER_DAY
	; edx = rem  = *t % SECS_PER_DAY
	; skip offset adjustment (assume GMT)
	mov	edi, eax	; saved copy
	mov	esi, edx	; saved copy

set_tm_wday:
	; tm_wday = (4 + days) % 7
;	_mov	eax, edi	; %edi was saved copy of 'days'
	add	eax, byte 4		; Jan 1, 1970 was a Thursday (4)
	_mov	ecx, DAYS_PER_WEEK
	xor	edx, edx
	div	ecx
	mov	[tm_struct.tm_wday], edx

set_tm_year:
	mov	eax, edi	; days
	_mov	ecx, 365
	xor	edx, edx
	div	ecx
	mov	esi, eax
	add	esi, 1970
	mov	[tm_struct.tm_year], esi

	mov	ebx, edx
set_tm_yday:
	add	eax, byte 2
	_mov	ecx, 4		; should rightshift by 2
	xor	edx, edx
	div	ecx		; eax = num leapdays
	sub	ebx, eax

	mov	eax, esi	; year
	_mov	esi, mon_yday	; ip = __mon_yday[0]

;	cmp	edx, 0		; edx = 0 if leapyear
	or	edx,edx
	jne	.not_leap_year
	inc	ebx
	_add	esi, mon_yday_len	; ip = __mon_yday[1]
	mov	dword [is_leap_year], 1
.not_leap_year:

set_tm_mon:
	_mov	ecx, 12
	add	esi, byte 22	; i = 11; esi = ip[i]
	std
.previous_month:
	lodsw			; %ax = offset of first day of month
	cmp	bx, ax		; days < ip[i]
	jg	.found_mon_yday
	loop	.previous_month

.found_mon_yday:
	cld
	dec	ecx
	mov	[tm_struct.tm_mon], ecx

set_tm_mday:
	sub	bx, ax
	inc	ebx
	mov	[tm_struct.tm_mday], ebx

	;; put month in top row
	_mov	esi, months
	mov	ecx, [tm_struct.tm_mon]
	inc	ecx
	rep	lodsd
	_mov	edi, month_buf.month_year
	add	edi, byte 6		; center ((20 - 4(month) - 4(year))/2)
	stosd

	;; put year in top row
	mov	eax, [tm_struct.tm_year]
	add	edi, byte 3	; end of year
	_mov	ebx, 3		; num of digits - 1
	call	int2str

	;; Find the wday (assume Sunday at left) of 1st of the month.
	;; We know today's wday and mday,
	;; so we divide mday by 7 (days per week) and subtract the
	;; remainder (minus one) from the wday (and make sure it's positive).
	;; (maybe instead subtract 7 till mday <= 7)
	mov	eax, [tm_struct.tm_mday]
	_mov	ecx, DAYS_PER_WEEK
	xor	edx, edx
	div	ecx
	dec	edx
	mov	ecx, [tm_struct.tm_wday]
	sub	ecx, edx	; subtract remainder from mday
	_cmp	ecx, 0		; make sure it isn't negative
	jge	.wday_nonnegative
	_add	ecx, DAYS_PER_WEEK 	; modulo 6  (0-6 wdays)
.wday_nonnegative:

	;; Note each mday is followed by one whitespace,
	;; so the ones digit of the mdays are separated
	;; by 3 bytes.
	inc	ecx
	_mov	edi, month_buf.month_days
	dec	edi		; offset of ones digit of 1st day
	dec	edi
.next_wday:
	add	edi, byte 3
	loop	.next_wday


	;; Now edi points to the first day of the month
	;; in the month buffer.
	;; Next we find out how many days are in the month.
	_mov	esi, mon_yday
	mov	eax, [is_leap_year]
	_cmp	eax, 1
	jnz	.not_leap_year2
	_add	esi, mon_yday_len
.not_leap_year2:
	mov	ecx, [tm_struct.tm_mon]
	xor	eax, eax
	xor	edx, edx
	lodsw			; load the 1st zero
	xchg	edx, eax	; move to edx
	inc	ecx		; extra zero at beginning, hrm..
.next_mon_yday:
	lodsw
	xchg	eax, edx
	loop	.next_mon_yday

	sub	edx, eax
	inc	edx
	mov	ecx, edx
	dec	ecx

	;; Finally, we loop through and fill in the days
	_mov	ebx, 1		; num of digits - 1
.next_mday:
	mov	eax, edx	; num days in month
	sub	eax, ecx
	call	int2str
	add	edi, byte 3
	loop	.next_mday

	sys_write STDOUT, month_buf, month_buf_len
	sys_exit_true

int2str:
	;; convert integer to string
	;; REQUIRES: integer in eax, string destination in edi,
	;;   (number of digits - 1) in ebx
	pusha
	std

	mov	ecx, ebx
	_mov	ebx, 10
.next_digit:
	xor	edx,edx
	div	ebx
	xchg	eax, edx
	add	al, '0'
	stosb			; ones
	xchg	eax, edx
	loop	.next_digit

	test	eax,eax
	jz	.skip_leading_zero
	add	al, '0'
	stosb
.skip_leading_zero:
	cld
	popa
	ret

;; from nc.asm
StrToLong:
	push	eax
	xor	eax,eax
	xor	edx,edx
.next:
	lodsb
	sub	al,'0'
	jb	.ret
	add	edx,edx
	lea	edx,[edx+edx*4]
	add	edx,eax
	jmps	.next
.ret:
	pop	eax
	ret

UDATASEG

timeval_struct B_STRUC timeval, .tv_sec, .tv_usec
	timeval_struct_len	equ	$ - timeval_struct

tm_struct B_STRUC tm, .tm_mday, .tm_mon, .tm_year, .tm_wday
	tm_struct_len	equ	$ - tm_struct

is_leap_year	resd	1

END
