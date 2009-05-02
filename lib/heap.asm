;Ver 0.0.5 (C) Rudolf Marek 2001 - First release candidate
;Use at your own risc !!!!
;Send comments, bugreports, BUG_FIXes to my email:
; marekr2@fel.cvut.cz
;
;$Id: heap.asm,v 1.1 2001/07/20 07:04:30 konst Exp $

;The heap manager 
;-+-+-+-+-+-+-+-+-
; My English at your own risc !!!
;
;The prelude
;-----------
;   My goal was to write non-trivial heap manager, which will find
; quickly free memory, will be fast and use very little memory.
; As you can imagine, this  is quite hard task for implementation.
;
;My Ideas
;--------
;   If you want to find somthing quickly it must be in tree
; The tree is dynamically changing according to situation, and
; you can search in in by nLog(n), this is fine but such dynamical
; trees requires dynamical manager which is a quite recursive problem 
; So I have chosen compromise - the heap manager can quickly find 
; simmilar blocks of memory - and then choose the best one.
; The idea is simple - we can differ the blocks by its sizes
; if you take a look at the binary representaion, you can find
; highest bit which indicates that the number ___lies___ in some 
; interval if it has highest 10th bit set it is not bigger than
; 2^11 and it is not smaller then 2^10. So I decied to make
; more trees according to our needs. 1) to found highest bit
; set, this  will show up a catehegory == tree of requested size.
; 2) somehow get through the tree -- at the leaf you will have
; simmilar memory blocks from one interval - the closest possible
; to requsted size
; 3) Choose the best one and you are done !
; 
; The implementation
; ------------------
;    To cathegoriese somehow the sizes of free blocks which we have,
; we can basicaly, as written above, use the tree or linear list. I have
; chosen following: First look at the highest bit to catch the size 
; cathegory similar to example above. In heapmgr it is the tree_head field.
; So we can cathegories the sizes from 0 - 2^11 2^11 to 2^12 etc ...
; to make some more precise resolution between sizes we can use the tree.
; So in tree_head is a ptr to tree which looks like this:
;                 
;		    |tree_head + 0|     |tree head + 4|
;                       |                     |
;         -------------------               ......
;        |    |    |    |    |
;         -------------------  
;          |    |
;          |    +------------------+                   
;         -------------------      |
;        |    |    |    |    |    ----------
;         -------------------     ..........
;
; Each sub_tree has 4 next, and it has 4 levels. Now I will tell you why ... :)
; If you take a look to binary number(size) like 00000000010001000100b you will see
; that it will go to first field in tree_head so we have a ptr to tree. Now how to
; go through it ? Answer is simple if we find second highest bit we will
; know that the number is higher then some another and lies in some interval.
; Let the bits in number itself to choose how to get through the TREE !
; Group the bits by four, if some bit from the fourths is set go to the subtree on
; that position. Then make new group of four and do it again. To get reasonable
; resolution I use 4 levels it means 12 bits to choose for the tree. As the 
; result at the leafs will contain blocks with very simmilar sizes ...
; ANd we got it.... we can make only RCR on the size ... no CMPs and we 
; are quite fast .... But it can happen that in the leaf there is no
; suitable block - we must go up and go to "bigger" cathegory to find
; a block - this is simple just go up and find a cathegory with higher
; bit set ... then go again down the tree choosing "smallest" cathegories
; in "bigger" one ...
; This sounds nice but we have the tree and the trees have to be done 
; dynamically and we are writing the dynamical memory manager ... 
;The solution is
; 1) try to do it recoursively (it wont be worknig anyway - and I not so crazy as I hope :)
; 2) Allocate some "window" of memory and manage the memory there in 
; another way. In my case it is the bitmask in that window. Each bit of
; the bitmask indicates if on address (which can be easilly computed
; from bit position) is free or used. To make such bitmask not so big
; we can use bigger "alloc unit" let say 4 pointers (in case so big is
; our tree entry) *** If you read this up here you are probbably very
; brave or you can't understand the code bellow :))

;HEAP manager for Linux
;-----------------------
; The code should work somehow but some better testing should take place....
; Still too experimental, but hope its for most cases working ...
;
;Whishlist & TODO's 
;See ALSO todo in CODE itself :)
;remove this stupid freed_count and do it as last_new_bigger_tree....
;Internal memory subsytem
;maximum memmory to allocate is 16Kb .... maybe...
;it depends on bt type instruction....
;smallest alloc unit is 16 bytes = one alloc unit
; hmm jestli jich tam je 15 or 16 v tom listu ....ebx...
;doresit last_block... done
;
;********************************************************************************
;* H E A P Manager for Linux 							*
;* .get_mem IN: eax = number of bytes to allocate				*
;*         OUT: eax =ptr to allocated memory					*
;* .free_mem:  IN eax=ptr to memory to be freed       				*
;********************************************************************************

%assign MAX_MEM_PACKETS 20h
%assign MIN_ALLOC_UNIT 016
%assign PTR_SIZE  04
%assign MAX_TREES  22
%assign NUM_LEVELS  04
%assign MAX_PTRS_IN_LINEAR_LIST 16 ;in alloc unit that means in one is 4 ptrs
%include "system.inc"
%assign PACKET_SIZE 32*1024 ;in bytes
%assign MEM_BLOCK_HEADER_SIZE (4+4+4+4)
CODESEG
nop
START:
;mov ecx,201h
;xor eax,eax
;znova:
;add eax,4
;push eax
;call .get_mem
;pop eax
;loop .znova


call .engine_start
;mov eax
sys_exit 0

.engine_start:
mov edi,tree_head
mov eax,1
call .get_mem
push eax
mov eax,10
call .get_mem 
push eax
mov eax,32
call .get_mem 
push eax
mov eax,1025
call .get_mem 
pop eax 
nop
call .free_mem
;int 3
mov eax,3
call .get_mem 
mov eax,3333
call .get_mem 
push eax
mov eax,20
call .get_mem 
pop eax
;int 3
nop
call .free_mem
mov eax,20
call .get_mem 
mov eax,30
call .get_mem 
call .printhex

sys_exit 0

ret

;end test prg
.printhex:
	pusha
	mov  	edi,space
	sub	esp,4
	mov	ebp,esp
	mov	[edi],word "0x"
	inc	edi
	inc	edi
	mov	esi,edi
	push	esi
	mov     [ebp],eax
	_mov	ecx,16	;10 - decimal
	_mov	esi,0
.l1:
        inc     esi
	xor	edx,edx
	mov	eax,[ebp]
	div	ecx
	mov	[ebp],eax
        mov     al,dl

;dec convertion
;	add	al,'0'
;hex convertion
	add	al,0x90
	daa
	adc	al,0x40
	daa

        stosb
	xor	eax,eax
	cmp	eax,[ebp]
	jnz	.l1
        stosb
	pop	ecx
	xchg	ecx,esi
        shr	ecx,1
	jz	.l3
	xchg	edi,esi
	dec	esi
	dec	esi
.l2:
        mov	al,[edi]
	xchg	al,[esi]
	stosb
	dec     esi
	loop    .l2
.l3:
	add	esp,4
	mov byte [space+10],0ah
	mov edi,space-1
.ll6:
	inc edi
	cmp byte [edi],0
	jz .finn
	sys_write STDOUT,edi,1
	jmp short .ll6
    	.finn:
	sys_write STDOUT,space+10,1
	popa
	ret
	
;********************************************************************************
;Dealoc routine EAX points to block we want to deallocate, already
;sub-ed, EAX is poining to the header of block
;this routine also merges around standing free blocks
;TODO: test if the next/prev free block follows immediately
;********************************************************************************

.dealloc_routine: ;EAX points to header of that block
    pushad
    inc 	dword [freed_block] ;ting about better solution
    mov 	dword [eax+0Ch],0 ;mark free
    mov 	ecx,[eax+4]       ;ptr to previous block
    cmp		dword [ecx+0Ch],0 ;prev block is free ?
    jnz .no_merge_previous
.merge_it:            
    cmp 	eax,[last_block]  ;is it last block we have to change it ....
    jnz 	.is_not_last
    mov 	[last_block],ecx
.is_not_last:
    add 	dword [ecx],MEM_BLOCK_HEADER_SIZE ;add new size to the block
    mov 	edx,[eax]
    add 	[ecx],edx 
    mov 	ebp,[eax+8] ;read old next ptr 
    mov 	[ecx+8],ebp ;put in new 
    mov 	ebp,[ecx+8]  
    or 		ebp,ebp ;last ?
    jz .is_last
    mov 	[ebp+4],ecx ;update previous in next block
.is_last:
    mov 	eax,ecx          ;this is our new block
.no_merge_previous:
    mov 	ecx,[eax+8] ;look at next block
    cmp 	dword [ecx+0Ch],0 ;next block is free
    jnz .no_merge_next
    xchg 	eax,ecx ;merges the next block
    jmp short .merge_it
.no_merge_next:
    push 	eax
    mov 	eax,[eax]
    call .find_linear_list ;slect right branch in tree & makes room for ptr
    pop 	eax
;int 3
    call .put_ptr_in_linear_list ;edi ptr to list eax ptr to put
    popad
    ret    
;********************************************************************************
;Freemem only calles the delocation routine, by calling its addres from
;the block header
;it subs EAX to point on block header 
;********************************************************************************

.free_mem: ;EAX
    push 	eax
    sub 	eax,MEM_BLOCK_HEADER_SIZE
    call [eax+0Ch] ;call the addres in header EAX should point to HEADER maybe it can be changed
    pop 	eax
    ret

;********************************************************************************
;Get_mem should work as written above EAX=requested size =>EAX ptr to memory
;It will first calls .try_to_find_free_block_in_tree, ESI is nonzero if
;such block was found,(ptr to such block) else we have to allocate new memory. It also
;handles operations with block like splitting, testing if can be 
;used whole etc ...
;********************************************************************************

.get_mem: ;EAX number of bytes ;out EAX pointer
    push 	ebx
    push 	ecx
    push 	edx
    push 	ebp
    push 	edi
    push 	esi
    and 	eax,0FFFFFFFCh ;align to 4 bytes min. 
    add 	eax,4		;is not working good 
    call .try_to_find_free_block_in_tree 
;IN esi is ptr to ptr to smallest usable block
;in EDX is its size
;edi+ebx*4 ptr linear list	
    or 		esi,esi
    jnz .split_block ;some suitable block found....
    mov 	ecx,eax
;no we havent suitable block need new mem 
    sys_brk 0	;request the end of allocated mem for program
    nop
    push 	eax
    add 	eax,MEM_BLOCK_HEADER_SIZE ;dont 4get for space for header
    add 	eax,ecx ;the size wee need
    sys_brk eax 
    nop
    pop 	eax
    ;in EAX is a block PTR
    mov edi,	[last_block] ;it will be the last one because it is new ...
    or 		edi,edi
    jnz 	.ok_another
    mov dword 	[last_block],eax   ;for first time it is other
    mov 	dword [first_block],eax
    xor 	edi,edi
    jmp 	short .fill_rest
.ok_another:
    mov dword 	[edi+8],eax ;write in last block that we have next
.fill_rest:
    mov dword 	[eax+4],edi ;write to new previous
    mov dword 	[eax],ecx ;size
    mov 	dword [eax+8],0 ;next
    mov 	dword [eax+0Ch],.dealloc_routine
    mov 	[last_block],eax
    add 	eax,MEM_BLOCK_HEADER_SIZE ;this addres we will return
    jmp short .done_alloc
.whole_block_win:
    mov 	eax,[esi]	;we have requested the same size that has free block itself
    mov 	dword [esi],0   ;or is too small for another header TODO: cleanUP of lin. list 
    add 	eax,MEM_BLOCK_HEADER_SIZE ;this addr we return
    jmp short .done_alloc
.split_block: ;ok we have room for both new header + data +old now free space
	      ;esi the ptr to ptr to that block
	      ;eax the desired size
	      ;edx this size we have
    cmp 	edx,eax ;hmm have same size intnterresing ... 
    jz .whole_block_win
;int 3
    sub 	edx,eax  ;this is the size of rest block
    sub 	edx,MEM_BLOCK_HEADER_SIZE
;int 3
;cmp edx,MEM_BLOCK_HEADER_SIZE ;too small for block header
    jb .whole_block_win ;no room for next free block use it whole
    jz .whole_block_win
    mov 	edi,[esi] ;this is ptr to that block that we want to split
    mov 	dword [esi],0 ;delete the entry fm linear list
		 ;TODO: cleanup....
		;edi ptr to that block
    mov 	dword [edi+0CH],.dealloc_routine
    mov 	dword [edi],eax ;update size
    mov 	ebp, [edi+8] ;read the next field
    mov 	esi,edi
    add 	edi,MEM_BLOCK_HEADER_SIZE
    push 	edi ;store the addres of the block this will return to caller
    add 	eax,edi ;here will be new table
    cmp esi,[last_block] ;update the last block entry if nessecarry (can you spell it ?? please..)
    jnz .not_last
    mov [last_block],eax
.not_last:
    mov 	dword [esi+8],eax ;eax points to new block in this case it is next
    mov 	dword [eax],edx   ;its new size
    mov 	dword [eax+4],esi ;ptr to old one
    mov 	dword [eax+8],ebp ;next ptr take it fm old one
    mov 	dword [eax+0CH],0 ;mark free
    
;hope all is OK....
;now put the rest block in the list
    push 	eax
    mov 	eax,edx
    call .find_linear_list ;makes hash through the "tree" 
		      ;ebp EA EDI filled with [ebp]
    pop 	eax
    call .put_ptr_in_linear_list ;edi ptr to list
    pop 	eax ;this is allocated for us.... remember ? push edi ...
.done_alloc:
    pop 	esi
    pop 	edi
    pop 	ebp
    pop 	edx
    pop 	ecx
    pop 	ebx
ret    

;********************************************************************************
;.put_ptr_in_linear_list, as written above we have this special tree, and
; the leafs of tree are linear lists of free usable blocks. This routine
; will place the ptr in EAX in such linear list, creating new if full
; the linear list starts at offset specified by EDI 
;********************************************************************************

.put_ptr_in_linear_list: ;edi start of the list eax ptr to put
    xor 	ebx,ebx
.small_loop_combo:
    cmp 	dword [edi+ebx*4],0 ;free entry ?
    jz .looks_good
    inc 	ebx ;no look at the next one ...
    cmp 	ebx,MAX_PTRS_IN_LINEAR_LIST-2 ;m
    jnz .small_loop_combo
    lea 	esi,[edi+MAX_PTRS_IN_LINEAR_LIST*4] ;read next list ptr
    cmp 	dword [esi],0 ;is there ??
    jz .make_new_list ;no DIY
    mov 	edi,esi ;hmm is three lets try to find some free entry there
    jmp .put_ptr_in_linear_list
.make_new_list: ;have to make new one
    push 	eax
    mov 	eax,4
    call .get_int_mem ;allocate internal memory
    pop 	ebx
    mov 	[eax],ebx ;put the ptr to first entry...
    jmp short .put_ptr_in_linear_list_end
.looks_good:
    mov 	[edi],eax ;ok this is free
.put_ptr_in_linear_list_end:
ret


;********************************************************************************
;.prepare_tree_search, it will test the size of wanted memory, decide
; which tree to test & take, also it prepares the size of wanted memory
;for hash fuction. It will use low 12bits, this size depends on how
;many levels the tree has, in our case hope it is 4
;in EAX, goes size of wanted memory, EBP points to ptr to the tree, EDI=[EBP] 
;********************************************************************************

.prepare_tree_search:
    mov 	ecx,eax ;in eax the size of requsted memory
    mov 	edx,eax
    xor 	ebx,ebx ;instruction bsr can have undef regs ...
    bsr 	ebx,edx ;find the highest bit put it in ebx
    mov 	ecx,ebx
    cmp 	ebx,10
    ja .do_sub  ;it is smaller than 2048 bytes... jump to ready_to_do_it
    xor 	ebx,ebx
    jmp short .ready_to_do_it
.do_sub:
    sub 	ebx,10 ;offset to lookup table
		;ECX offset of first bit set
.ready_to_do_it:		
    shl 	edx,13h ;hash low 12 bits	    
    lea 	ebp,[tree_head+ebx*4] ;find the top of tree which depends on the mem size
    mov 	edi,[ebp] ;in edi is the ptr
    xor 	esi,esi
ret

;********************************************************************************
;.try_to_find_free_block_in_tree this routine tries to find smallest usable
;block of memory as fast as possible. first it find the tree in which are
;very similar free memory blocks, it hash through it as written above
;resulting that we have linear list of ptrs to very similar blocks
;if such block nonexists it will go one level up of tree, trying to find
;another blocks of memory - the bigger ones (its possition in tree makes
;difference in size - see above :). If it fails finally it will choose
;another tree in "bigger" cathegory (tree_head)
;in ESI is the pointer to such block, else NULL, we have to alloc new mem
;********************************************************************************

   
.try_to_find_free_block_in_tree: ;EAX wanted size or bigger
    call .prepare_tree_search    
    mov dword [store_bp],ebp ;save ebp
    mov dword [store_sp],esp ;save esp ...
    or 		edi,edi
    jnz .have_tree ;the tree is non existing ...
    
    ;TODO: find fist bigger tree... slip it directly...
    ;int 3
    jmp .try_another_tree
    ;jmp short .get_out_of_here

.have_tree:
    inc 	esi  ;inc the level of tree
;int 3
    xor 	ebx,ebx
.xbig_loop:
    inc 	esi  ;the level of tree
    push 	ebp  ;save the state  
    push 	edi
    push 	esi
    push 	ebx
    _mov  	ebx,3
    mov 	ecx,ebx
.xok_is_there:  ;edi points on tree entry (4 ptrs to sub_tree) 
    rcl 	edx,1 ;hash through the tree somehow
    jc .xhave_highest
    dec 	ebx  ;lower the ptr in tree entry
loop .xok_is_there
.xhave_highest:
    lea 	ebp,[edi+ebx*4] ;we have the subtree    
    cmp dword 	[ebp],0
    jz .try_find_bigger ;unfortunately we havent the requested size lets see if have bigger
    mov 	edi,[ebp] ;so far so good ...
    cmp 	esi,NUM_LEVELS ;are we still in tree ?
    jnz .xbig_loop
.find_smallest_usable:
;int 3
;in EDI we have right ptr to linear list but don't have idea if it fits somehow
;EAX we wanted and [edi]..[edi+4*3] we have   [edi+10H] is ptr to next lin list
    xor 	edx,edx
    dec 	edx ;biggest usable block try then to find smaller one
    xor 	esi,esi
.another_block:
    xor 	ebx,ebx ;prepare the index in the list
    dec 	ebx
.smycka:
    inc 	ebx ;next index
    mov 	ecx,[edi+ebx*4] ;read the entry
    or 		ecx,ecx ;NULL ptr ?
    jz .no_notice ;is_zero
    mov 	ecx,[ecx] ;read the size of memory_block
    cmp 	ecx,eax   ;does this block fit ?	   
    jb .no_notice         ;is too small
    jz near .whole_block  ;fits byte to byte
;    push 	eax       ;save the size and try if the header fits for free space 
;    add 	eax,MEM_BLOCK_HEADER_SIZE
;    cmp 	ecx,eax
;    pop 	eax
;    jb 	.no_notice 
;    jz 	.whole_block
    cmp 	ecx,edx ;is it the best choose ?
    ja .no_notice       ;no we have smaller ...
    mov 	edx,ecx ;no this one is smaller
    lea 	esi,[edi+ebx*4] ;save also its addres
.no_notice: 
    cmp 	ebx,MAX_PTRS_IN_LINEAR_LIST-2 ;it is last entry in linear list ?
    jnz .smycka
    inc 	ebx
    mov 	edi,[edi+ebx*4] ;is there another list ?
    or 		edi,edi
    jnz .another_block ;yes try that one
;ESI = 0 if no suitable found	
;LETs try another category
    or 		esi,esi
    jz .try_find_bigger ;unfortunatelly we havent so big block in this list ...
    jmp short .get_out_of_here
.whole_block:
    mov 	edx,ecx
    lea 	esi,[edi+ebx*4] ;this is what we need exit imm
.get_out_of_here:
    mov		 esp,[store_sp] ;return the stack ptr...
ret

.try_find_bigger:
    cmp 	esi,2 ;have some upper tree ?
    ja .ok_tree_exists  
    jmp short .try_another_tree
.ok_tree_exists: ;yes we have the subtree in which is certainly bigger block ... lets quicky
    ;int 3       ;find the smallest - done by surfing in tree
    inc 	ebx ;bigger ebx in tree entry means that subtree has bigger free blocks
    cmp 	ebx,3 ;hmm have only 4 ptr for subtree
    ja .jump_on_prev_level ;jump level up
    cmp dword 	[edi+ebx*4],0 ;hmm nothing try bigger
    jz .ok_tree_exists
    lea		ebp,[edi+ebx*4]  ;next subtree  
    mov 	edi,[ebp]        ;the ptr of subtree
    inc 	esi ;mozna nekam jinam
    cmp 	esi,NUM_LEVELS   ;are we still in tree ?
    ;int 3
    ja near .find_smallest_usable;no this is linear list jump there ..
    xor 	ebx,ebx
    dec 	ebx
    jmp short .ok_tree_exists ;no lets go down in tree ...
.jump_on_prev_level: ;mean only to restore previous state
    pop 	ebx
    pop 	esi
    pop 	edi
    pop 	ebp
    or 		esi,esi
    jz .get_out_of_here ;but we are upstaires allready
    jmp short .ok_tree_exists
;ret
.try_another_tree:
    xor 	esi,esi
    cmp 	dword [freed_block],0 ;thing about better solution
    jz .get_out_of_here 
    mov 	ebp,[store_bp] ;in ebp is the tree_HEAD+something
.try_another_tree_loop:
    add 	ebp,4 
    cmp 	ebp,tree_head+(MAX_TREES*PTR_SIZE)-4
    ja .get_out_of_here
    cmp 	dword [ebp],0
    jz .try_another_tree_loop
    ;int 3
    xor 	ebx,ebx
    xor 	esi,esi
    inc 	esi
    inc 	esi
    dec 	ebx
    mov 	edi,[ebp]
    jmp .ok_tree_exists

;********************************************************************************
;find_linear_list this routine makes room for the block of just freed memory
; -- this block we want to put in the tree chosen by .prepare_tree_search
;is such subtree isnt exiting we will create it
;the result is the ptr to linear list, with the help of put_ptr_in....
;we can store there that we have a free block
;EDI points to that list 
;********************************************************************************
 
.find_linear_list:
    call .prepare_tree_search ;do nessecarry preparations :)    
    inc 	esi           ;sadly this routine is nearly the same 
.big_loop:                    ;only allocate the entry when it is isnt existing
    _mov  	ebx,3
    mov 	ecx,ebx
    inc 	esi  ;the level of tree
    or 		edi,edi
jnz .ok_is_there
    call .alloc_entry ;ebp ptrs to room for ptr
.ok_is_there:  ;edi points on that inode
    rcl 	edx,1
    jc .have_highest
    ;;;jc .have_highest_move
    dec 	ebx
loop .ok_is_there
.have_highest:
    lea 	ebp,[edi+ebx*4]
    mov 	edi,[ebp]
    cmp 	esi,NUM_LEVELS
    jnz .big_loop
;we have here a field of ptr FIXED size will be 16*4 bytes 
;****
    or 		edi,edi  ;is not yet used ?
jnz .ok_used
    call .alloc_linear_list ;ebp ptrs to room for ptr - alocate the linear list 
.ok_used:  ;edi points on that inode
nop
nop ;BUG in ALD ?!
nop
nop
nop
ret

;********************************************************************************
;.alloc_linear_list - this routine takes memory from get_int_mem and returns
;& write the pointer to linear list - also the list is filled with 0's == free
;EDI =>ptr to list in [ebp] writes the EDI
;********************************************************************************

.alloc_linear_list:
push eax
push ecx
mov eax,MAX_PTRS_IN_LINEAR_LIST/4 ;lets get 16 pointers free
jmp short .ok_is_in_tree ;jump directly to alloction
.alloc_entry:            ;it allocates one tree entry
push eax
push ecx
;push edi
mov eax,1
;cmp esi,NUM_LEVELS
;jna .ok_is_in_tree
;mov eax,MAX_PTRS_IN_DATA_CHUNK/4 ;lets get 16 pointers free
.ok_is_in_tree:
call .get_int_mem ;get internal mem 
mov [ebp],eax     ;save it to that address is prepared in find_tree & friends
mov edi,eax       ;zero the area
xor eax,eax
rep
stosd
mov edi,[ebp]     ;edi points to new memory
;pop edi
pop ecx
pop eax
ret

;********************************************************************************
;.alloc_new_packet this routine takes some free memory and make it internal
; in this "window" we can allocate the trees and lists dynamicaly
; this "window"="packet" has a bitmask which specifies which part are used 
; /freed. The allocation "unit" is 4 PTRs == 16 bytes
; this routine is used by .get_int_mem
;********************************************************************************

.alloc_new_packet: 		;this allocates new "packet" of internal memory 
;cmp dword [ebp],0 ;test if it is allocated but full packet
;jnz .not_add ;if full then add and make new entry
;add ebp,8
;.not_add:
push eax
sys_brk 0
mov [ebp],eax  		;save it 
add eax,PACKET_SIZE     ;dont4get to say to system ...
sys_brk eax
mov edi,[ebp]		;this is the new "packet" ptr
mov ecx,(PACKET_SIZE/(MIN_ALLOC_UNIT)) ;save the size of "packet" in alloc units
mov [ebp+4],ecx
sub dword [ebp+4],(PACKET_SIZE/(MIN_ALLOC_UNIT*32))/4 ;reserve some for the bitmask
shr ecx,5 ;multiply ecx*2^5 == mark all as free
push edi
xor eax,eax
dec eax ;Fs means all free in bitmask
rep
stosd
pop edi
;natvrdo
mov dword [edi],11111111111111110000000000000000b ;dirty & nasty say that this amout of mem
pop eax						;is used by the bitfield itself
jmp short .sem ;because it is no proc can return directly ...


;********************************************************************************
;.get_int_mem it is managing the memory "window" packet -- it bitmask
;if is some memory for tree requested it will find free mem in that
;bitmask - it finds continuos are of 1s, then it coputes the addres of such
;block and returns the ptr to free mem
;in case the window is full in will create new one
;*******************************************************************************

.get_int_mem:  ;EAX how much mem chunks do we want (one is 16 bytes of memory)
    push 	ebx
    push 	ecx 
    push 	esi
    push 	ebp
    push 	edi    
    mov 	ebp,int_mem_list-8 ;prepare first list of in memory
.try_another:    
    add 	ebp,8
;mov edi,[ebp+4]
;or edi,edi
    cmp 	dword [ebp],0 ;it isnt allocated yet == no "packet"
    jz .alloc_new_packet
.sem:
    cmp 	[ebp+4],eax ;is it free for requested block ?
    jb .try_another
    xor 	esi,esi     ;yes we have now the ptr in edi to that block which start with bitmask
    mov 	edi,[ebp]
    sub 	esi,4
.next_mask:
    add 	esi,4       ;now in each dword try to find free space == 1 bit
.next_mask_aux:
    cmp 	esi,(PACKET_SIZE/(32*MIN_ALLOC_UNIT))*4 ;maybe +4 are we still in bitmask ???
    jz  .try_another ;no this is bad we havent so large continous block fallback to another
    cmp 	dword [esi+edi],0 ;packet 
    jz .next_mask ;this dword is all full
    xor 	ebx,ebx    
.find_first_free_blk:     
    xor 	ecx,ecx
    dec 	ecx
.find_loop:      ;in dword find bit which is 1 and the count should be the size of requsted blk
    inc 	ecx
    bt 		[edi+esi],ecx
    jnc .find_loop 
    ;in ecx is the first pos of bit set = free
    push 	ecx ;save this pos
.search_loop:
    inc 	ebx ;one is at last free
    cmp 	ebx,eax ;do we have the requested size (amount of continous bit set) 
    jz .ok_got_it ;on stack is first tested bit
    inc 	ecx ;try next bit
    cmp 	ecx,32 ;we can cross the dword but have to make sure we arent out from bitmask
    jb .no_boundary_cross
    push 	ecx
    shr 	ecx,5
    shl 	ecx,2
    add 	ecx,esi
    cmp 	ecx,(PACKET_SIZE/(32*MIN_ALLOC_UNIT))*4
    pop 	ecx
    jb .no_boundary_cross
    pop 	ecx
    jmp .try_another
.no_boundary_cross:
    bt 		[edi+esi],ecx ;try if this bit is set == 1 == free
    jc .search_loop 
    shr 	ecx,5 ;/32
    shl 	ecx,2 ;did we crossed the boundary ??
    or 		ecx,ecx
    jnz .no_add
    add 	ecx,4 ;THIS is BAD better to MUL 4*ECX
.no_add:    
    add 	esi,ecx
    pop 	ecx ;throw the stack away
    jmp short .next_mask_aux ;try next dword
    ;in eax first free
.ok_got_it:
    pop 	ebx  ;the start pos of firts free == 1 == set bit
    push 	ebx ;save it on stack
    mov 	ecx,eax ;in eax it is the size of requested blocl
    sub dword  [ebp+4],eax ;dec the total free block
.mark_used:
    btc 	[edi+esi],ebx ;set the bits starting from ESI+EBX
    jnc .error        ;if it is 0 some bug occured 
    inc 	ebx       
    loop .mark_used   ;do it for whole size of block
    pop 	eax      ;use the satrtbit position in EAX and in EBP the dword offset
    mov 	ebp,esi  ;and compute the addres of free block in memory
;mov edx,eax
    shl 	eax,4
    xor 	ebx,ebx
    shr 	esi,2
    jz .ok
    mov 	ecx,esi
;mov ebx,1
.small_loop:
    add 	ebx,32
    loop .small_loop
    shl 	ebx,4
.ok:
    add 	eax,ebx
;mov ebx,eax
;mov edx,eax ;navic
    add 	eax,edi
;mov edi,esi
    pop 	edi
    pop 	ebp
    pop 	esi
    pop 	ecx
    pop 	ebx
    ret

;********************************************************************************
;.free_int_mem will free the internal memory - it will first find the window
; in which it is allocated, second it will complent bits in bitmask from
; used to free
;********************************************************************************

.free_int_mem:  ;edi the memory, eax=howmuch to free
    push 	ebx
    push 	ecx 
    push 	esi
    push 	ebp
    push 	edi    
    mov 	ebp,int_mem_list-8
.try_another_packet:    ;have to find in which region of "packets" the block is presented
    add 	ebp,8
    mov 	ebx,[ebp]
    add 	ebx,PACKET_SIZE
    cmp 	edi,ebx
    ja .try_another_packet
    cmp 	edi,[ebp]
    jb .try_another_packet
    mov 	esi,[ebp]
    sub 	edi,esi  ;now compute the space in bitmask in which we have to complement bits
    shr 	edi,4
    mov 	ebx,edi
    shr 	ebx,5
    shl 	ebx,5
    sub 	ebx,edi
    not 	ebx
    inc 	ebx
    shr 	edi,5
    mov 	ecx,eax
.clear_bits:    
    btc [edi*4+esi],ebx ;time to mark again as FREE
    jc .error
    inc 	ebx
    loop .clear_bits
    add 	[ebp+4],eax  ;add this to free mem in block
    pop 	edi
    pop 	ebp
    pop 	esi
    pop 	ecx
    pop 	ebx
    ret
.error:
    sys_write STDOUT,error_msg,error_msg_len
    sys_exit 255

error_msg db "Internal memory allocation error, unable to load COMMAND, exiting :(",__n
error_msg_len equ $-error_msg    

;*********************************************
;the memory for the caller looks like this
; XXXX is returned address
;*********************************

;mem_block
;struc:
;size DD 0 +0
;prev_ptr  +4
;next_ptr  +8 
;dealoc routine +C
;XXXX: DATA

;>EAX
;<EDI


 
UDATASEG
freed_block resd 1
store_sp resd 1
store_bp resd 1
space resb 16
first_block resd 1
last_block  resd 1
tree_head resd MAX_TREES ;22
int_mem_list resd (MAX_MEM_PACKETS)*2

;each packet consist of this:
;bit_fields: resd   
;bir mask : 1 free
;	    0 used
END

