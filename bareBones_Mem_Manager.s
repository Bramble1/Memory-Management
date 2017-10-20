#Program to manage memory usage FUNCTIONS - allocates and deallocates memory as requested.

.section .data

##variables##

heap_begin:			#points to beginning of the beginning of heap.
.long 0

current_break:			#points to the next address after break , after the last available mem address
.long 0



#CONSTANTS

.equ RESERVED,0		#Will be placed in the header of memory allocatedto show this address is being used
.equ UNRESERVED,1		#to mark space has been returned and available for allocation.



.section .text

#FUNCTIONS

#allocate_initialize#------------------------------------------------------------------------------------											   |
#												   |
#THis function will initialize and  sets heap_begin and current break				   |
#No parameters and no return value.								   |	
#---------------------------------------------------------------------------------------------------
.globl allocate_initialize
.type allocate_initinitialize,@function

allocate_initialize :
	pushl	%ebp
	movl	%esp,%ebp

	movl	$45,%eax			
	movl	$0,%ebx				
	int	$0X80				#interrupt

	incl	%eax				#increment 1 past the break, to get first unavailable address

	movl	%eax,current_break		#store the current break
	movl	%eax,heap_begin			#stpre begining of heap, as this is the first unavailable address

	movl	%ebp,%esp			#restore stack pointer and base pointer
	popl	%ebp
	ret

#Allocate#-----------------------------------------------------------------------------------------
# grab a section of memory. It checks to see if there are any free blocks,|
# and if not, it asks kernel for a new one.							   |	
#											           |
#--------------------------------------------------------------------------------------------------
.globl allocate_mem
.type allocate_mem,@function


allocate_mem:
	pushl	%ebp
	movl	%esp,%ebp

	movl	8(%ebp),%ecx			#the size requested for allocation argument from stack.
	movl	heap_begin,%eax			#current search location
	movl	current_break,%ebx		#will hold the current break

alloc_loop:				#we iterate through each memory region to find free page
     
	 cmpl	%ebx,%eax			#if equal more memory will be needed to accomdate request.
	 je	move_break			#we have to move the break position to make more room
	
	 movl 	4(%eax),%edx			
	 cmpl 	$RESERVED,0(%eax)	
	 je	next_address
	 
	 cmpl	%edx,%ecx			#if space is unmapped, compare to see if its big enough for request
	 jle	allocate_here			#go to allocate if big enough.

next_address:

	addl	$8,%eax				#obtaining next memory location to check that its unmapped
	addl	%edx,%eax

	jmp	alloc_loop		#loop

allocate_here:					

	movl	$RESERVED, 0(%eax)
	addl	$8,%eax				#move pass header to the usuable memory, thats what we will return

	movl	%ebp,%esp			#restore stack/base pointers
	popl	%ebp
	ret

move_break:					#not enough unmapped memory, KERNEL more MEM plez?

	addl	$8,%ebx				#space for  headers
	addl	%ecx,%ebx			#space for where the break should be
						#kernel request

	pushl	%eax				#saving
	pushl	%ecx
	pushl	%ebx

	movl	$45,%eax			#reset the break(%ebx has the requested break point to
	int	$0X80			#where we want it so enough space for mem, using ebx value)

	cmpl	$0,%eax				#check for error conditions, returns 0 if error
	je	error

	popl	%ebx				#restore sved registers
	popl	%ecx
	popl	%eax

	movl	$RESERVED, 0(%eax)		#flag memory space as unavailable as its now about to be
							#assigned and mapped to virtual memory.

	movl	%ecx,4(%eax)		#setting the size of the memory space

	addl	$8,%eax					#eax moved to start of usable mapped memory
							#eax also holds the return.

	movl	%ebx,current_break			#update the break
	movl	%ebp,%esp				#restore stack/base pointers
	popl	%ebp
	ret

error:
	movl	$0,%eax				#on error,we return zero
	movl	%ebp,%esp
	popl	%ebp
	ret

##Deallocate------------------------------------------------------------------------------------
#												|
#used to unallocate the mapped memory to unmapped, so making it unused after the programmer	|
#finished with it. Returns nothing.								|
#-----------------------------------------------------------------------------------------------
.globl deallocate_mem
.type deallocate_mem,@function
deallocate_mem:

	movl	4(%esp),%eax				#obtaining target address
	subl	$8,%eax					#position pointer to begining of mem
	movl	$UNRESERVED,0(%eax)			#set flag as available

	ret
	 
	

	
