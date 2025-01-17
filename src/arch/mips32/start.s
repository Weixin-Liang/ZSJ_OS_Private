.extern init_kernel
.globl start
.globl exception
.extern PGT_BaseAddr_ASID
.extern kernel_sp  # Defined in arch.c/arch.h
.extern tlb_ready_index
.extern exception_handler # Not used
.extern interrupt_handler # Not used
#.extern PGE_BaseAddr; # The base addr of Page Global Entry

.set noreorder
.set noat
.align 2    #4(2^2) bytes alignment

.org 0x0000 #0x8000_0000: Refill exception
exception:
	lui  $k0, 0x8000
	sltu $k0, $sp, $k0
	beq  $k0, $zero, refill_save_context
	move $k1, $sp
	la   $k0, kernel_sp
	j    refill_save_context
	lw   $sp, 0($k0)

	#TLB refill
	#la $k0, tlb_ready_index
	#lw $k0, 0($k0)
 	#mfc0 $k0, $4  # Context
 	#lw $k1, 0($k0)
 	#mtc0 $k1, $2  # EntryLo0 refill
 	#lw $k1, 4($k0)
 	#mtc0 $k1, $3  # EntryLo1 refill
 	#lw $k1, 8($k0)
 	#mtc0 $k1, $10 # EntryHi refill
 	#lw $k1, 12($k0)
 	#mtc0 $k1, $5  # PageMask refill
 	#nop #		CP0 hazard
 	#nop #  	CP0 hazard
 	#tlbwr
 	#eret

.org 0x0180 #0x8000_0180: most of the exception
	lui $k0, 0x8000
	sltu $k0, $sp, $k0 #if $sp < 0x8000_0000, exception_save_context
	beq $k0, $zero, exception_save_context
	move $k1, $sp
	la  $k0, kernel_sp	
	j exception_save_context
	lw  $sp, 0($k0)

.org 0x0200 #0x8000_0200: interrupt, a special kind of exception
	lui $k0, 0x8000
	sltu $k0, $sp, $k0
	beq $k0, $zero, interrupt_save_context
	move $k1, $sp
	la  $k0, kernel_sp
	lw  $sp, 0($k0)

# From view of Process scheduling:
# 
# 
# The following function also works as Dispatcher. (Maybe we need a new module in the future)	
# It is the module that gives control of the CPU to the process selected 
# by the short-term scheduler. It receives control in kernel mode as 
# the result of an interrupt or system call. The functions of a dispatcher involve the following:
# 
# Context switches, in which the dispatcher saves the state (also known as context) 
# of the process or thread that was previously running; the dispatcher then loads 
# the initial or previously saved state of the new process.	
# 
# Switching to user mode. (Unimplemented)
# Jumping to the proper location in the user program to restart that program indicated by its new state.(Unimplemented)
# 
# The time it takes for the dispatcher to stop one process and start another is known as the dispatch latency.
# 
refill_save_context:
	addiu $sp, $sp, -128
	sw $at, 4($sp)
	sw $v0, 8($sp)
	sw $v1, 12($sp)
	sw $a0, 16($sp)
	sw $a1, 20($sp)
	sw $a2, 24($sp)
	sw $a3, 28($sp)
	sw $t0, 32($sp)
	sw $t1, 36($sp)
	sw $t2, 40($sp)
	sw $t3, 44($sp)
	sw $t4, 48($sp)
	sw $t5, 52($sp)
	sw $t6, 56($sp)
	sw $t7, 60($sp)
	sw $s0, 64($sp)
	sw $s1, 68($sp)
	sw $s2, 72($sp)
	sw $s3, 76($sp)
	sw $s4, 80($sp)
	sw $s5, 84($sp)
	sw $s6, 88($sp)
	sw $s7, 92($sp)
	sw $t8, 96($sp)
	sw $t9, 100($sp)
	sw $gp, 112($sp)
	sw $k1, 116($sp)
	sw $fp, 120($sp)
	sw $ra, 124($sp)
	mfc0 $a0, $12
	mfc0 $a1, $13
	mfc0 $a2, $14
	mfhi $t3
	mflo $t4
	sw $a2, 0($sp) # EPC
	sw $t3, 104($sp) # HI
	sw $t4, 108($sp) # LO

# 	jump to do_refill
	move $a2, $sp
	addi $sp, $sp, -32 
	jal  do_refill		# Refill exception service routine
	nop
	addi $sp, $sp, 32
	j    restore_context
	nop


interrupt_save_context:
	#the order of layout of the regs saving in the stack is important.
	#if you change this, you need to change struct contex as well
	#must be consistent with (\zjunix\include\zjunix\pc.h)
	addiu $sp, $sp, -128
	sw $at, 4($sp)
	sw $v0, 8($sp)
	sw $v1, 12($sp)
	sw $a0, 16($sp)
	sw $a1, 20($sp)
	sw $a2, 24($sp)
	sw $a3, 28($sp)
	sw $t0, 32($sp)
	sw $t1, 36($sp)
	sw $t2, 40($sp)
	sw $t3, 44($sp)
	sw $t4, 48($sp)
	sw $t5, 52($sp)
	sw $t6, 56($sp)
	sw $t7, 60($sp)
	sw $s0, 64($sp)
	sw $s1, 68($sp)
	sw $s2, 72($sp)
	sw $s3, 76($sp)
	sw $s4, 80($sp)
	sw $s5, 84($sp)
	sw $s6, 88($sp)
	sw $s7, 92($sp)
	sw $t8, 96($sp)
	sw $t9, 100($sp)
	sw $gp, 112($sp)
	sw $k1, 116($sp)
	sw $fp, 120($sp)
	sw $ra, 124($sp)
	mfc0 $a0, $12
	mfc0 $a1, $13
	mfc0 $a2, $14
	mfhi $t3
	mflo $t4
	sw $a2, 0($sp) # EPC
	sw $t3, 104($sp) # HI
	sw $t4, 108($sp) # LO

# 	jump to do_interrupts
	move $a2, $sp
	addi $sp, $sp, -32 
	jal do_interrupts
	nop
	addi $sp, $sp, 32

restore_context:
	#the order of layout of the regs saving in the stack is important.
	#if you change this, you need to change struct contex as well
	#must be consistent with (\zjunix\include\zjunix\pc.h)
	lw $a2, 0($sp) # EPC
	lw $t3, 104($sp) # HI
	lw $t4, 108($sp) # LO
	mtc0 $a2, $14
	mthi $t3
	mtlo $t4
	lw $at, 4($sp)
	lw $v0, 8($sp)
	lw $v1, 12($sp)
	lw $a0, 16($sp)
	lw $a1, 20($sp)
	lw $a2, 24($sp)
	lw $a3, 28($sp)
	lw $t0, 32($sp)
	lw $t1, 36($sp)
	lw $t2, 40($sp)
	lw $t3, 44($sp)
	lw $t4, 48($sp)
	lw $t5, 52($sp)
	lw $t6, 56($sp)
	lw $t7, 60($sp)
	lw $s0, 64($sp)
	lw $s1, 68($sp)
	lw $s2, 72($sp)
	lw $s3, 76($sp)
	lw $s4, 80($sp)
	lw $s5, 84($sp)
	lw $s6, 88($sp)
	lw $s7, 92($sp)
	lw $t8, 96($sp)
	lw $t9, 100($sp)
	lw $gp, 112($sp)
	lw $k1, 116($sp)
	lw $fp, 120($sp)
	lw $ra, 124($sp)	
	move $sp, $k1
	eret

exception_save_context:
	#the order of layout of the regs saving in the stack is important.
	#if you change this, you need to change struct contex as well
	#must be consistent with (\zjunix\include\zjunix\pc.h)
	addiu $sp, $sp, -128
	sw $at, 4($sp)
	sw $v0, 8($sp)
	sw $v1, 12($sp)
	sw $a0, 16($sp)
	sw $a1, 20($sp)
	sw $a2, 24($sp)
	sw $a3, 28($sp)
	sw $t0, 32($sp)
	sw $t1, 36($sp)
	sw $t2, 40($sp)
	sw $t3, 44($sp)
	sw $t4, 48($sp)
	sw $t5, 52($sp)
	sw $t6, 56($sp)
	sw $t7, 60($sp)
	sw $s0, 64($sp)
	sw $s1, 68($sp)
	sw $s2, 72($sp)
	sw $s3, 76($sp)
	sw $s4, 80($sp)
	sw $s5, 84($sp)
	sw $s6, 88($sp)
	sw $s7, 92($sp)
	sw $t8, 96($sp)
	sw $t9, 100($sp)
	sw $gp, 112($sp)
	sw $k1, 116($sp)
	sw $fp, 120($sp)
	sw $ra, 124($sp)
	mfc0 $a0, $12
	mfc0 $a1, $13
	mfc0 $a2, $14
	mfhi $t3
	mflo $t4
	sw $a2, 0($sp) # EPC
	sw $t3, 104($sp) # HI
	sw $t4, 108($sp) # LO

# jump to do_exceptions
	move $a2, $sp
	addi $sp, $sp, -32
	jal do_exceptions       #arch/mips32/exec.c
	                        #void do_exceptions(unsigned int status, unsigned int cause, context* pt_context)
							#$a0 = status, $a1 = cause, $a2 = $sp(pt_context is a stack pointer)
	nop
	addi $sp, $sp, 32

	j restore_context
	nop

.org 0x1000
start:
	lui $sp, 0x8100     #ghost number, the initial stack
	la $gp, _gp 		# _gp is defined in kernel.ld
	j init_kernel
	nop
