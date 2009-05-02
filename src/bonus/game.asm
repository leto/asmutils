;Copyright (C) 2001 Rudolf Marek <marekr2@fel.cvut.cz>
;
;$Id: game.asm,v 1.3 2006/02/09 07:47:34 konst Exp $
;
;0.01: 26-Jul-2001	initial release  (RM)
;
;So what does this program ? Actually it makes possible to execute 2 programs
;step by step in one address space. It is done via ptrace system call.
;These two programs have got only one purpose - seek & destroy the opponent
;program before another prog will do it. The alive status is detected via
;heart beats (inc some counter, every MAX_INSTRUCT_FOR_ONE_PLAYER).
;If this counter hasn't grown, the player is considered dead.
;The program takes as a parameter file names of these gladiators programs.
;See "game_player" macro at the end for an example of such program.
;It prints dots every round, when heart check is performed.
;If you have a better idea about name of this program, please let me know.
;I think it is stupid to call it ptrace_example.asm
;
;This progs needs two things:	1) Improve the code, specially the random gen
;				2) Try to write the gladiator code (heart beat
;				   ptr is in one register at startup,see source)
;******************************************************************************

%include "system.inc"

STACK_SIZE      equ 0x40
PLAYER_MAX_SIZE equ 0x1000
PLAYGROUND_SIZE equ 0xFFFF
FOUR_NOPS	equ 0x90909090
MAX_INSTRUCT_FOR_ONE_PLAYER equ 020

CODESEG

START:
    pop 	eax 	;how many args ?
    cmp 	eax,3	;are there at least 2 filenames ?
    jz .ok
    sys_write STDOUT,usage,usage_len ;no write the usage
.exit:
    sys_exit 255
.error:
    sys_write STDOUT,error_msg,error_msg_len ;no write the usage
    jmp short .exit
.ok:
			;Prepare the playground
    mov 	edi,play_ground
    mov 	ecx,PLAYGROUND_SIZE/4
    mov 	eax,FOUR_NOPS
    rep		stosd		;fill playground with NOPs
    sys_getpid			;get procs PID - used for pseudogen
				;PID in EAX 
				;a little pseudo random...
				;
    mov 	ebx,eax
    shl 	eax,16
    add 	eax,ebx	
    mov 	cl,al
    rcr 	eax,cl
    mov 	edi,0xDEADBEEF
    mov 	esi,0xBEEFDEAD 	;load some magic
    xor 	edi,eax	   	;XORed with PID
    xor 	esi,eax
    rcl 	edi,cl
    rcr 	esi,cl
    and 	edi,PLAYGROUND_SIZE ;mask values of random offsets to fit the playgound
    and 	esi,PLAYGROUND_SIZE ;and then load both "fighters" on random locations
    xchg 	edi,esi
    add 	edi,play_ground	  
    add 	esi,play_ground    
    pop 	eax 	;throw away our name
    mov 	ebp,player1_size
.get_file_name:
    pop 	ebx 		;ptr to first player file
				;last file
    or 		ebx,ebx
    jz .finish_reading
    sys_open EMPTY,NULL ;open the 1st fighter code
    test 	eax,eax
    js near .error
    mov 	ebx,eax
    sys_read EMPTY,edi,PLAYER_MAX_SIZE ;read it into MEM max 4Kb
    mov 	[ebp],eax
    sys_close ebx
    xchg 	esi,edi
    mov 	ebp,player1_size
    jmp short .get_file_name
    
    ;pop		 ebx 		;player 2 name
    ;sys_open EMPTY,NULL ;open 2nd the fighter code (file)
    ;test 	eax,eax
    ;js near .error
    ;mov 	ebx,eax
    ;sys_read EMPTY,esi,4096 ;load it to that random location in play_ground
    ;mov [player2_size],eax
    ;sys_close ebx
    
    ;xchg edi,esi
    ;push esi  ;PL2
    ;push edi  ;PL1
.finish_reading:
    push 	edi 	;here we pushed them in reverse order
    push 	esi
    sys_fork  		;makes a second "copy" of program - another process - child
			;parent will continue till wait and child will request the 
			;debugging
    or 		eax,eax ;zero is child
    jnz .wait
    mov 	dword [player1_size],eax 	;use this as ALIVE counter for players
    mov 	dword [player2_size],eax 	;in the copy, using EAX which is really zero
    sys_ptrace PT_TRACEME,NULL,NULL,NULL  	;request for parent to trace me
    mov 	eax,020 			;getpid
    int 	0x80
    sys_kill eax,019 				;stop the child process (itself)
    jmp $            				;wait a bit ...
						;till the first or second player to play
.wait:  					;parent will continue here
    mov 	[pid],eax   			;store the pid of child
    sys_wait4 -1,NULL,WUNTRACED,NULL 		;wait until child is ready to debug it
    mov 	ebp,player1_regs
    mov 	dword [player_regs_ptr],player2_regs
    sys_ptrace PT_GETREGS,[pid],EMPTY,ebp 	;get the regs of child
    pop 	dword [ebp+012*4] 		;set EIP=player 1 start
    mov 	dword [ebp+015*4],player1_stack_top ;set also the stack
    mov 	dword [ebp],player1_size 	;Alive counter PL1 in EBX the ptr
    mov 	dword [ebp+06*4],play_ground 	;Give them in EAX a start of arena
    xchg 	ebp,[player_regs_ptr]
    sys_ptrace PT_GETREGS,[pid],EMPTY,ebp 	;do the same for player 2
    pop 	dword [ebp+012*4] 		;EIP=player 2 start
    mov 	dword [ebp+015*4],player2_stack_top
    mov 	dword [ebp],player2_size 	;Alive counter PL2 in EAX the ptr
    mov 	dword [ebp+06*4],play_ground 	;Give them in EAX a start of arena
    xchg 	ebp,[player_regs_ptr] 		;restore the ebp pointer to first player info
					;EBP= player 1 regs EIP = on player 1 first instruction
    mov 	ecx,MAX_INSTRUCT_FOR_ONE_PLAYER*2 ;Fight for 10 instructions then check if Players ALIVE
				    		;Counters are OK
    xor 	eax,eax
    mov dword [player1_old_timer],eax
    mov dword [player2_old_timer],eax
.next_player:
    push 	ecx
    sys_ptrace PT_SETREGS,[pid],NULL,ebp
    sys_ptrace PT_SINGLESTEP,[pid],NULL,NULL 	;Could be EMPTY NULL
    sys_wait4 -1,NULL,WUNTRACED,NULL
    sys_ptrace PT_GETREGS,[pid],NULL,ebp
    xchg 	ebp,[player_regs_ptr]
    pop 	ecx
    loop .next_player  
    sys_write STDOUT,dot,1
    sys_ptrace PT_PEEKDATA,[pid],player1_size,ztest 	
    
    ;result in EAX
    ;as writen in man ptrace
    ;BUT also in data (last arg of call)
    ;?! Inform someone !?, because man 2 ptarece sayes:
    ;PTRACE_PEEKTEXT, PTRACE_PEEKDATA
    ;Reads  a  word  at the location addr in the child's
    ;memory, returning the word as  the  result  of  the
    ;ptrace call.  Linux does not have separate text and
    ;data address spaces, so the two requests  are  cur­
    ;rently equivalent.  (data is ignored.)
    ;...
    ;Linux 2.2.10             7 November 1999                        2									   
						
    mov 	eax,[ztest]
    mov 	bl,'2'
    cmp 	eax,[player1_old_timer]
    ;jb 		.player_dead
    ;jz 		.player_dead
    jna	.player_dead
    mov 	dword [player1_old_timer],eax
    sys_ptrace PT_PEEKDATA,[pid],player2_size,ztest ;result in EAX
    mov 	eax,[ztest]
    mov 	bl,'1'
    cmp 	eax,[player2_old_timer]
    ;jb .player_dead
    ;jz .player_dead
    jna	.player_dead
    mov 	dword [player2_old_timer],eax
    jmp near .next_player
.player_dead:
    mov 	byte [won_who],bl
    sys_ptrace PT_KILL,[pid],NULL,NULL ;kill the child 
    sys_wait4 -1,NULL,WUNTRACED,NULL
    sys_write STDOUT,won_text,won_size
    sys_exit 0
usage db "USAGE: game killer_prg_1 killer_prg_2",__n
db "Task of killer_prg is to erase its oponent in memory.",__n
db "(C) Rudolf Marek, 2001, "
usage_len equ $-usage

error_msg db "Unable to open the file with fighter code -- bad filename ?!",__n
error_msg_len equ $-error_msg
won_text db __n,"Player "
won_who DB 0, " has won !",__n
won_size EQU $-won_text
dot db "."

;DATASEG

UDATASEG
pid resd 1
player1_old_timer resd 1
player2_old_timer resd 1

player1_size resd 1 ;used in forked part as the ALIVE_COUNTER
player2_size resd 1
player1_regs resb 17*4
player2_regs resb 17*4 ;see ptrace.h in asm-arch
player_regs_ptr resd 1
;Players stack
player1_stack resd STACK_SIZE
player1_stack_top:
dummy resd 0
player2_stack resd STACK_SIZE
player2_stack_top:
dummy1 resd 0
space resb 20

;Battle arena ... :)
ztest resd 1
play_ground resb PLAYGROUND_SIZE

END

;
;here's an example of a gladiator program.
;put it into separate file (remove %macro framing),
;compile with 'nasm -f bin', and then use with the main program
;

%macro game_player 0

;This servers as the example of fighter code -- mainly it is stupid and only for testing
;Please this is your chance ! Write better and smaller one. You could send it to me
;if you wish. And maybe I will do some Best from the Best gallery :)

;EAX=Start of mem where to find the enemy 
;EBX=Alive counter has to be grown every 10th instructions
;

ORG 0h
BITS 32
START:
call .iq
.iq:
pop ebp    ;have address cur running
sub ebp,5  ;no it is allright
;call .printhex
;nop
mov edi,eax
mov eax,90909090h
.main_loop:
add edi,4
inc dword [ebx]
cmp dword [edi],eax
jz .main_loop
;found something
cmp edi,ebp
jb .enemy_spoted
push ebp
add ebp,SIZE
cmp edi,ebp
pop ebp
ja .enemy_spoted
jmp .main_loop
.enemy_spoted: ;DELETE from EDI....
inc dword [ebx]
push ebx
mov eax,4
mov edx,2
mov ecx,.co
add ecx,ebp
inc dword [ebx]
mov ebx,1
int 0x80
pop ebx
inc dword [ebx]
mov ecx,SIZE/4
mov eax,90909090h
.semhle:
inc dword [ebx]
stosd
loop .semhle
.won_loop:
inc dword [ebx]
jmp .won_loop
;>EAX
;<EDI
jmp $

.co db "AA"
STOP:
SIZE EQU STOP-START

%endmacro
