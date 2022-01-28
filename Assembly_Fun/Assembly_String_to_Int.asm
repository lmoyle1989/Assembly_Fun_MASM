TITLE Low-Level I/O Demonstration     (Program6A_Moyle_Lucas.asm)

; Author: Lucas Moyle
;
; Description:	This program demonstrates basic integer->string and string->integer conversions from user input using MASM assembly language.
;				The program will prompt the user for 10 integers that will each be accepted as 8-bit array char strings. Each string will be validated to contain only
;				decimal digits and then converted into an integer and stored in an array of 10 32-bit integers. The program will then calculate the sum and
;				average of the array and store those values in memory locations. The program will then convert the values in the array, and the sum and average, back
;				into 8-bit strings and display them as strings.
; Note:			All procedure parameters are passed using their offsets on the stack.

INCLUDE Irvine32.inc

MAXSTRINGSIZE		= 32
MAXINTARRAYSIZE		= 10
ASCIICONST			= 48
ASCIIMAX			= 57


;Macro - getString
;Descrip:	Prompts the user for a string input and stores it in a location passed to it by reference
;Receives:	Respectively- offset of the array of BYTES that will store the string, offset of a DWORD that stores the size of that string, offset of the prompt message
;Returns:	User input as a string (max 32 chars) and the size of that string
;Precons:	String <= 32 chars long
;Registers:	eax, ebx, ecx, edx

getString MACRO inputOffset, inputSizeOffset, promptOffset

	push	eax
	push	ebx
	push	ecx
	push	edx
	mov		edx, promptOffset
	call	WriteString
	mov		edx, inputOffset
	mov		ecx, MAXSTRINGSIZE
	mov		ebx, inputSizeOffset
	call	ReadString
	mov		[ebx], eax
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax

ENDM


;Macro - displayString
;Descrip:	Simply macro for printing a string passed to it by reference
;Receives:	Offset of the string to be printed
;Returns:	NA
;Precons:	NA
;Registers:	edx

displayString MACRO stringOffset

	push	edx
	mov		edx, stringOffset
	call	WriteString
	pop		edx

ENDM


.data

intro_1			BYTE	"Low-Level I/O Procedures Demo", 0
intro_2			BYTE	"Written by: Lucas Moyle", 0

outro_1			BYTE	"Thank you for testing my program, goodbye.", 0

instruct_1		BYTE	"Enter 10 unsigned decimal integers.", 0
instruct_2		BYTE	"Each number must fit in a 32 bit register.", 0
instruct_3		BYTE	"After inputting, the program will list the numbers and display their sum and average.", 0

input_prompt	BYTE	"Enter an integer: ", 0
error_prompt	BYTE	"Invalid input, please try again.", 0

avg_label		BYTE	"The average of the numbers is: ", 0
sum_label		BYTE	"The sum of the numbers is: ", 0
array_label		BYTE	"You entered the following numbers: ", 0

stringIn		BYTE	MAXSTRINGSIZE+1 DUP(0)
stringOut		BYTE	MAXSTRINGSIZE+1 DUP(0)

stringInSize	DWORD	?
intOut			DWORD	?

intArray		DWORD	MAXINTARRAYSIZE DUP(?)
intArraySum		DWORD	?
intArrayAvg		DWORD	?


.code

main PROC
	
	push	OFFSET instruct_1
	push	OFFSET instruct_2
	push	OFFSET instruct_3
	push	OFFSET intro_1
	push	OFFSET intro_2
	call	introduction				;print introduction and user instructions

	push	OFFSET intOut
	push	OFFSET intArray
	call	FillIntArray				;prompt the user for 10 integers and put them into an array, ReadVal is a sub-procedure of FillIntArray

	push	OFFSET intArraySum
	push	OFFSET intArrayAvg
	push	OFFSET intArray
	call	ArrayCalc					;calculate the sum and average of the array and store the values
	
	push	OFFSET stringOut
	push	OFFSET avg_label
	push	OFFSET sum_label
	push	OFFSET array_label
	push	OFFSET intArraySum
	push	OFFSET intArrayAvg
	push	OFFSET intArray
	call	DisplayArrayValues			;display the array, the array sum, and the array avg as strings, WriteVal is a sub-procedure of DisplayArrayValues

	push	OFFSET outro_1
	call	goodbye						;print goodbye message

	exit	

main ENDP


;Procedure - Introduction
;Descrip:	Prints greeting and program instructions to terminal
;Receives:	Offsets of strings to be printed, passed on the stack
;Returns:	NA
;Precons:	NA
;Registers:	edx, ebp

introduction PROC
	
	push	ebp
	mov		ebp, esp
	mov		edx, [ebp+12]
	call	WriteString
	call	CrLf
	mov		edx, [ebp+8]
	call	WriteString
	call	CrLf
	mov		edx, [ebp+24]
	call	WriteString
	call	CrLf
	mov		edx, [ebp+20]
	call	WriteString
	call	CrLf
	mov		edx, [ebp+16]
	call	WriteString
	call	CrLf
	pop		ebp
	ret		20

introduction ENDP


;Procedure - ReadVal
;Descrip:	Prompts the user for a 32-bit integer and receives it as a string of 8-bit chars. Validates that all chars are decimal digits and then converts
;			and stores the string as a 32-bit integer. Sub-procedure of FillIntArray procedure.
;Receives:	Offsets of strings for user prompts, offset of the size of the string to be converted, offset of the string itself, offset of the memory location
;			where the converted 32-bit integer will be stored.
;Returns:	32-bit integer that was input as a string of 8-bit chars.
;Precons:	Needs a string of known size that has been verified to contain only ascii characters with ascii values that correspond to 0-9.
;Registers:	eax, ebx, ecx, edx, esi, edi, ebp

ReadVal PROC

	push		ebp
	mov			ebp, esp

	InputLoopTop:
	getString	[ebp+12], [ebp+16], [ebp+20]	;get the input string and its length into variables
	CLD											;set up for LODSB
	mov			esi, [ebp+12]					;move the string into esi so we can manipulate it
	push		eax
	mov			eax, [ebp+16]					;move the address of our string size to eax
	mov			ecx, [eax]						;move the string size at that address into ecx
	pop			eax
	cmp			ecx, 9							;we're going to check here if the number is 1 billion or greater- I realize the max for a 32bit int is 4 billion-something but this is close enough
	jg			InvalidInput					

	ValidateLoop:
	mov		eax, 0								;clear out the whole eax register
	LODSB										;move the first element of the string into al
	cmp		al,	ASCIICONST						;check if al has an ascii value that does not correspond to a decimal number (0=48, 9=57) 
	jl		InvalidInput
	cmp		al, ASCIIMAX
	jg		InvalidInput
	loop	ValidateLoop
	jmp		ValidIntInput						;if we get here it means that only decimal digits have been entered

	InvalidInput:
	push	edx
	mov		edx, [ebp+24]
	call	WriteString
	call	CrLf
	pop		edx
	jmp		InputLoopTop

	ValidIntInput:						
	mov		esi, [ebp+12]			;now that we know that the string is only composed of decimal character digits, we can covert the string to a number
	push	eax
	mov		eax, [ebp+16]
	mov		ecx, [eax]				;we want to loop for the string size for each digit
	pop		eax
	add		esi, ecx				;we are starting from the LAST element of the string array this time and moving to the left when we convert
	dec		esi						;the last element of the array is esi + stringsize-1
	mov		ebx, 0					;ebx will be our accumulator for the string->number conversion
	mov		edi, 1					;we're using edi here as the place value multiplier because I can't use edx because 32bit mul stores the answer in edx:eax
	
	ConversionLoop:
	STD								;set our direction flag to backward for each digit
	mov		eax, 0					;ensure eax is clear since LODSB only deals with al
	LODSB
	sub		eax, ASCIICONST			;change the ascii value of the string array element to the number's actual value
	mul		edi						;we are going in the order of increasing place value this time so start with 1 and multiply it by 10 for each loop
	add		ebx, eax
	mov		eax, edi
	push	ebx
	mov		ebx, 10					;push and pop ebx really quick so we can multiply edi by 10
	mul		ebx
	mov		edi, eax
	pop		ebx
	loop	ConversionLoop

	mov		eax, [ebp+8]			;lastly, move our converted integer to the memory location that was passed as a paramater, we will put it into the array in the calling procedure
	mov		[eax], ebx

	pop		ebp
	ret		20

ReadVal ENDP


;Procedure - FillIntArray
;Descrip:	Prompts the user for an unsigned 32-bit integer 10 times and puts them into an array. Uses the ReadVal proc to get and validate user input.
;Receives:	The memory location of the variable that will hold the integer before it is placed into the array, offset of the array to be filled
;Returns:	Array of 10 32-bit unsigned integers.
;Precons:	Everything needed for ReadVal.
;Registers:	eax, ebx, ecx, esi, ebp

FillIntArray PROC

	push	ebp
	mov		ebp, esp

	mov		ecx, MAXINTARRAYSIZE		;now we want to put our converted numbers into an array, the array has constant size
	mov		esi, [ebp+8]

	FillArrayLoopTop:
	push	esi							;esi and ecx need to get pushed here and popped after the ReadVal
	push	ecx
	
	push	OFFSET error_prompt			
	push	OFFSET input_prompt
	push	OFFSET stringInSize
	push	OFFSET stringIn
	push	OFFSET intOut
	call	ReadVal
	
	pop		ecx
	pop		esi
	mov		eax, [ebp+12]				;the integer from ReadVal should be in ebp+12 which is the memory location for IntOut
	mov		ebx, [eax]					
	mov		[esi], ebx					;put that integer into the array
	add		esi, 4						;the int array is an array of DWORDS so we need to increment by 4
	loop	FillArrayLoopTop

	pop		ebp
	ret		8

FillIntArray ENDP


;Procedure - ArrayCalc
;Descrip:	Calculates the sum and average of an array of 10 32-bit integers.
;Receives:	Memory locations of the place where calculations will be stored, offset of the array to be calculated.
;Returns:	Sum and average of the array.
;Precons:	Filled array of 10 32-bit unsigned integers
;Registers:	eax, ebx, ecx, esi, ebp

ArrayCalc PROC

	push	ebp
	mov		ebp, esp
	
	mov		ecx, MAXINTARRAYSIZE
	mov		esi, [ebp+8]
	mov		ebx, 0

	SumLoop:
	add		ebx, [esi]				;iterate through the integer array and add the numbers. we're using ebx as the accumulator
	add		esi, 4
	loop	SumLoop

	mov		eax, [ebp+16]
	mov		[eax], ebx				;store our sum in a parameter

	mov		eax, ebx
	cdq
	mov		ebx, MAXINTARRAYSIZE
	div		ebx						;divide the sum by our array size of 10
	
	mov		ebx, [ebp+12]
	mov		[ebx], eax				;store our average in a parameter

	pop		ebp
	ret		12

ArrayCalc ENDP


;Procedure - WriteVal
;Descrip:	Converts and 32-bit integer into a string of 8-bit chars and displays it. Sub-procedure of DisplayArrayValues.
;Receives:	The memory location of the string where the converted numbers will be stored, offset of the number to be converted
;Returns:	An 8-bit char string representation of a 32-bit integer.
;Precons:	A validated 32-bit unsigned integer has been stored somewhere
;Registers:	eax, ebx, ecx, edx, esi, edi, ebp

WriteVal PROC

	push	ebp
	mov		ebp, esp
	push	esi
	push	ecx

	mov		al, 0					;Fill the output string with 0's to ensure it terminates with one
	mov		edi, [ebp+12]
	mov		ecx, MAXSTRINGSIZE
	inc		ecx						;ensure the 33rd string element (max is 32) is zero
	CLD
	REP STOSB

	mov		edi, [ebp+12]
	mov		ecx, 10					;we need to iterate through 10 times so we can divide 1 billion by 10, 10 times
	mov		ebx, 1000000000			;32-bit integers are the max so the highest place value is billions
	mov		esi, 0					;we're going to use esi as a bool here b/c ive run out of registers

	push	ebx						
	mov		ebx, [ebp+8]			;move the number we want to convert to a string into eax via ebx temporarily
	cdq
	mov		eax, [ebx]
	pop		ebx
	cmp		eax, 0					;check for special 0 case here
	je		ZeroCaseInput

	DigitConvertLoopTop:
	div		ebx						;divde our target number by ebx which will go thru place values from high-to-low
	cmp		esi, 0					;if we've found the first nonzero digit we want to print all subsequent digits even if they are zero
	jne		DigitFound
	cmp		eax, 0					;check for the first non-zero digit
	jne		DigitFound

	BackToConvertLoop:
	push	eax
	push	edx
	mov		eax, ebx
	mov		ebx, 10
	cdq
	div		ebx						;divide ebx (our divisor) by 10 to iterate through place values on each loop
	mov		ebx, eax				
	pop		edx
	pop		eax
	mov		eax, edx				;move the remainder into eax and repeat loop
	mov		edx, 0					;clear edx for the next remainder
	loop	DigitConvertLoopTop	
	jmp		NumberConverted

	DigitFound:
	push	ebx
	mov		ebx, eax				;save eax in ebx temporarily
	add		eax, ASCIICONST			;convert the single digit to its ascii code 
	CLD
	STOSB							;put it in the string array
	mov		eax, ebx				;restore eax
	pop		ebx
	mov		esi, 1					;Once we have found the first non-zero digit (left-to-right) set esi to 1 (our "bool") which will ensure that subsequent 0's get added
	jmp		BackToConvertLoop

	NumberConverted:
	displayString [ebp+12]			;finally, call our displayString macro and print out our number as an ascii string
	pop		ecx
	pop		esi
	pop		ebp
	ret		8

	ZeroCaseInput:
	push	ebx	
	mov		ebx, eax
	add		eax, ASCIICONST
	CLD
	STOSB
	mov		eax, ebx
	pop		ebx
	jmp		NumberConverted

WriteVal ENDP


;Procedure - DisplayArrayValues
;Descrip:	Displays the contents, sum, and average of an array of 10 32-bit integers in the form of 10 8-bit char array strings.
;Receives:	Offsets of strings for labels of calculations, offset of the array, offsets of the sum and average
;Returns:	NA
;Precons:	ArrayCalc proc has been performed on the same array that is passed to this proc
;Registers:	eax, ecx, edx, esi, ebp

DisplayArrayValues PROC

	push	ebp
	mov		ebp, esp

	mov		ecx, MAXINTARRAYSIZE	;we want to print the array before sum/avg which has 10 elements
	mov		esi, [ebp+8]
	mov		edx, [ebp+20]
	call	WriteString				;print prompt
	call	CrLf
	
	DisplayLoop:
	push	[ebp+32]
	push	esi
	call	WriteVal				;print the array elements as strings by calling our WriteVal proc by passing the integer array offset and a string to put the converted characters in to
	
	cmp		ecx, 1					;if we are on the last iteration of the loop we don't want to print ", " so skip the next few lines
	je		LastArrayElement
	push	eax
	mov		al, ','
	call	WriteChar
	mov		al, ' '
	call	WriteChar
	pop		eax
	
	LastArrayElement:
	add		esi, 4					;increment our array pointer by 4 since it is an array of DWORDS
	loop	DisplayLoop				
	call	CrLf

	mov		edx, [ebp+24]			;print our sum prompt
	call	WriteString
	
	push	[ebp+32]				
	push	[ebp+16]
	call	WriteVal				;print the sum as a string by calling WriteVal
	call	CrLf

	mov		edx, [ebp+28]			;print our avg prompt
	call	WriteString

	push	[ebp+32]
	push	[ebp+12]
	call	WriteVal				;print the avg as a string by calling WriteVal
	call	CrLf

	pop		ebp
	ret		28

DisplayArrayValues ENDP


;Procedure - Goodbye
;Descrip:	Thanks the user for testing the program, idicating that it is finished
;Receives:	Offset of the goodbye message
;Returns:	NA
;Precons:	Rest of the program has run successfully
;Registers:	edx, ebp

goodbye PROC

	push	ebp
	mov		ebp, esp
	mov		edx, [ebp+8]
	call	WriteString
	call	CrLf
	pop		ebp
	ret		4

goodbye ENDP


END main
