TITLE String Primitives and Macros     (Proj6_carterja.asm)

; Author: Jason Carter
; Last Modified: 3/6/2021
; OSU email address: carterja@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: March 14, 2021
; Description: Project 6 prompts a user for 10 numbers. The program converts the string input to signed integer values.
;			   The program then stores the integers in an array. The program converts each integer in the array to a string
;			   and displays the entered numbers. Finally the sum and average are calculated. 
;

INCLUDE Irvine32.inc

; ---------------------------------------------------------
; Name: mGetString
;
; Prompts a user for a string and stores the string.
;
; Preconditions: Do not use EDX, ECX, EAX, or EDI as arugment. User string must
;                no exceed 13 characters, including the null terminator. 
;
; Postconditions: None
;
; Receives:
; prompt = string address
; usrString = offset of empty byte array to store user input
; stringSize = Buffer size of usrString
; stringLength = offset to data label which will store length of string inputed in bytes
;
; Returns: 
; usrString = populated string from input
; stringLength = length of input string in bytes
;----------------------------------------------------------
mGetString	MACRO	prompt, usrString, stringSize, stringLength
	MOV		EDX, prompt
	CALL	WriteString
	MOV		EDX, usrString
	MOV		ECX, stringSize
	CALL	ReadString
	MOV		EDI, stringLength
	MOV		[EDI], EAX

ENDM

;----------------------------------------------------------
; Name: mDisplayString
;
; Displays a given string
; 
; Preconditions: do not use EDX as an argument. Must have string initalized to write to output.
;
; Receives: outString = address of string to display
;
; Returns: nothing
;----------------------------------------------------------
mDisplayString	MACRO	outString
	MOV		EDX, outString
	CALL	WriteString

ENDM

; Maximum numbers to enter 
MAX = 10

.data

intro			BYTE	"PROJECT 6: Designing low-level I/O procedures",13,10,0
author			BYTE	"Written by: Jason Carter",13,10,13,10,0
description		BYTE	"Provide 10 signed decimal integers.",13,10,
						"Each number needs to fit inside a 32 bit register. After you finish entering numbers",13,10,
						"I will display a list of the integers, their sum, and their average.",13,10,13,10,0
prompt1			BYTE	"Please enter a signed number: ",0
error			BYTE	"You did not enter a signed number or your number was too big.",10,13,0
prompt2			BYTE	"Please try again: ",0
displayMsg		BYTE	"You entered the following numbers:",13,10,0
sumMsg			BYTE	"The sum of the numbers is: ",0
avgMsg			BYTE	"The rounded average is: ",0
goodBye			BYTE	"Thanks for playing, goodbye!",13,10,0
usrString		BYTE	13 DUP(?)
usrLen			DWORD	?
usrValue		SDWORD	0
outString		BYTE	13 DUP(?)
numArr			SDWORD	10 DUP(?)
sum				SDWORD	?
average			SDWORD	?

.code


main PROC
	; Introduction
	PUSH	OFFSET description
	PUSH	OFFSET intro
	PUSH	OFFSET author
	CALL	introduction

	; Loop for populating numArr
	MOV		ECX, 10						; Loop counter for 10 numbers
	MOV		EDI, OFFSET numArr			

	CLD
	_L1:
		PUSH	OFFSET	 usrLen
		PUSH	OFFSET   prompt2
		PUSH	OFFSET   error
		PUSH	OFFSET   prompt1
		PUSH	OFFSET   usrString
		PUSH	SIZEOF   usrString
		PUSH	OFFSET   usrValue
		CALL	ReadVal
		MOV		EAX, usrValue
		STOSD							; Store in array
		LOOP	_L1

	CALL	CrLf
	; Display message of entered numbers
	mDisplayString	OFFSET displayMsg

	MOV		ECX, MAX					; Loop counter for 10 numbers
	MOV		ESI, OFFSET numArr			; Start of array
	
	_L2:
		LODSD							; Load array
		MOV		usrValue, EAX

		; Get number of digits for WriteVal
		PUSH	OFFSET usrLen
		PUSH	usrValue
		CALL	numDigits

		; Call WriteVal
		PUSH	usrValue
		PUSH	usrLen
		PUSH	OFFSET outString
		CALL	WriteVal
		CMP		ECX, 1					; If ECX is 1, skip comma
		JE		_L4
		MOV		AL, 44					; Write a comma and space between each number
		CALL	WriteChar
		MOV		AL, 32
		CALL	WriteChar
	_L4:
		LOOP	_L2

	CALL	CrLf

	; Sum Array
	MOV		EBX, 0						; Sum accumulator
	MOV		ECX, MAX					; Counter for array size of 10 numbers
	MOV		ESI, OFFSET numArr
	CLD
	_L5:
		LODSD	
		ADD		EBX, EAX
		LOOP	_L5

	MOV		sum, EBX

	mDisplayString	OFFSET sumMsg

	; Get number of digits in sum
	PUSH	OFFSET usrLen
	PUSH	sum
	CALL	numDigits
	
	; Call WriteVal to conver sum to string
	PUSH	sum
	PUSH	usrLen
	PUSH	OFFSET outString
	CALL	WriteVal

	CALL	CrLf

	; Calculate Average
	MOV		EBX, MAX					; Sum divided by 10 for 10 numbers entered
	MOV		EAX, sum
	CDQ
	IDIV	EBX
	MOV		average, EAX

	; Determine number of digits in average
	PUSH	OFFSET usrLen
	PUSH	average
	CALL	numDigits

	mDisplayString	OFFSET avgMsg

	; Display average as a string
	PUSH	average
	PUSH	usrLen
	PUSH	OFFSET outString
	CALL	WriteVal

	CALL CrLf

	mDisplayString	OFFSET	goodBye

	Invoke ExitProcess,0	; exit to operating system
main ENDP

;------------------------------------------------------------------------
; Name: Introduction 
; 
; Displays strings introducing the program 
;
; Preconditions: Intro, author and description strings defined in .data
;
; Postconditions: None
;
; Receives: [ebp + 8] = offset to author 
;			[ebp + 12] = offset to intro
;			[ebp + 16] = offset to description
;		
; Returns: Nothing
;------------------------------------------------------------------------
introduction PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EDX
	MOV		EDX, [EBP+12]
	CALL	WriteString
	MOV		EDX, [EBP+8]
	CALL	WriteString
	MOV		EDX, [EBP+16]
	CALL	WriteString

	POP		EDX
	POP		EBP
	RET 12
introduction ENDP

;------------------------------------------------------------------------
; Name: ReadVal
; Reads a value from a string input, converts string input to an integer. Proc validates if
; the input is valid (no letters or symbols other than + and -). This procedure only works 
; if converting 32 bit signed integers. 
; 
; Preconditions: macro mGetString must be defined and used. 
;				 size of usrString is the buffer size for mGetString (13 bytes)
;				 usrValue must be a declared SDWORD
;				 Prompt1, error and promp2 must be declared strings
;				 usrString must be a BYTE array of characters
;				 usrLen must contain the length of the usrString
;
; Postconditions: None
;
; Receives: [ebp + 8] = offset of usrValue
;			[ebp + 12] = size of usrString
;			[ebp + 16] = offset of usrString
;			[ebp + 20] = offset of prompt1
;			[ebp + 24] = offset of error
;			[ebp + 28] = offset of prompt2
;			[ebp + 32] - length of usrString

;
; Returns: an integer stored in usrValue
;------------------------------------------------------------------------
ReadVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EAX
	PUSH	EDX
	PUSH	ECX
	PUSH	ESI
	PUSH	EDI
	PUSH	EBX

	MOV		EDX, [EBP+8]						; Set usrValue to 0
	MOV		EBX, 0
	MOV		[EDX], EBX
	
	mGetString	[EBP+20], [EBP+16], [EBP+12], [EBP+32]
	

	_newPrompt:
		MOV		ESI, [EBP+16]						; Load usrString to ESI
		MOV		EDI, [EBP+32]
		MOV		ECX, [EDI]							; Load length of string to ECX

		CLD
		LODSB										; Load first char to AL, if + or -, continue to next char
		CMP		AL, 43
		JE		_positive							; If positive
		CMP		AL, 45
		JE		_negative							; If negative value
		MOV		ESI, [EBP+16]						; If not + or -, reload ESI 
		JMP		_Start

	_negative:
		DEC		ECX
		MOV		EDI, 1								; Store sign in EDI for later
		MOV		EDX, [EBP+32]						; If - sign, subtract 1 from length
		DEC		DWORD PTR [EDX]
		JMP		_Start

	_positive:
		DEC		ECX
		MOV		EDX, [EBP+32]
		DEC		DWORD PTR [EDX]						; if + sign, subtract 1 from length
	
	_Start:
		LODSB										; puts start of string in AL
		CMP		AL, 48
		JGE		_L1									; If greater than or equal to 48, check if less than 57
		JMP		_invalid							; Otherwise reprompt

	_L1:
		CMP		AL, 57								; If greater than 57 not numeric
		JG		_invalid

	_Finish:
		SUB		AL, 48
		PUSHFD										; Preserve status flags to check OF
		PUSH	EAX									; Preserve AL
		PUSH	ECX									; Preserve counter
		MOV		EDX, [EBP+8]
		MOV		EAX, SDWORD PTR [EDX]				; Move usrValue to EAX
		MOV		ECX, 10
		IMUL	ECX									; Multiply usrValue by 10 to account for places
		; If invalid here, need to pop ECX and EAX
		JO		_invalid1							; Check for overflow
		MOV		EDX, [EBP+8]						; MUL modifies EDX, so must restore to usrValue
		MOV		[EDX], EAX							
		POP		ECX									; Restore registers
		POP		EAX
		CMP		EDI, 1								; If signed, subtract instead of add
		JE		_subtract
		ADD		[EDX], SDWORD PTR EAX				; Add integer value to user total
		JMP		_continue
	_subtract:
		SUB		[EDX], SDWORD PTR EAX
	_continue:
		JO		_invalid2							; If addition or subtraction sets carry flag, result is invalid.
		POPFD										; Restore status flags 
		LOOP	_Start
		JMP		_leaveProc

	; Invalid 1 resturs ECX and EAX and status flags before re-prompt
	_invalid1:
		POP		ECX						
		POP		EAX
		POPFD
		JMP		_invalid
	; Invalid 2 only restores status flags before re-prompt
	_invalid2:	
		POPFD										
	_invalid: 
		MOV		EDX, [EBP+24]
		CALL	WriteString
		MOV		EDX, [EBP+8]
		MOV		EBX, 0
		MOV		[EDX], EBX							; Restore usrValue to 0
		mGetString [EBP+28], [EBP+16], [EBP+12], [EBP+32]		
	JMP		_newPrompt

	_leaveProc:
	POP		EBX
	POP		EDI
	POP		ESI
	POP		ECX
	POP		EDX
	POP		EAX
	POP		EBP
	RET 28
ReadVal	ENDP

;------------------------------------------------------------------------
; Name: WriteVal
; 
; WriteVal converts a numeric value to a string of ascii characteres. Uses the macro mDisplayString
; to print the ascii character to output. Output string must be less than or = to 13 bytes including 
; the null terminator.
;
; Preconditions: outString declared as a byte array size 13 bytes
;				 length of user input must be the length of the string input converted to digit
;				 usrValue must be a SDWORD 
;
; Postcondtions: None.
;
; Receives: address of outString = [ebp+8]
;			usrLen = [ebp+12]
;			usrValue = [ebp+16]
;
; Returns: Output of user number as a string to console
;------------------------------------------------------------------------
WriteVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDI

	MOV		EAX, [EBP+16]						; Value from ReadVal
	MOV		EDI, [EBP+8]						; Output string
	MOV		ECX, [EBP+12]						; usrLen
	CMP		EAX, 0
	JNL		_positive
	MOV		AL, 45
	STOSB	
	MOV		EAX, [EBP+16]
	MOV		EBX, -1
	IMUL	EBX
	_positive:
		ADD		EDI, ECX							; Set EDI to last element of integer
		DEC		EDI									; Sub 1 to account for null terminator in usrLen
		MOV		EBX, 0								
		MOV		[EDI+1], EBX						; Insert null terminator
		STD											; Set direction flag

	_loop:
		CDQ
		MOV		EBX, 10								; Divisor	
		IDIV	EBX									; Remainder is last digit of number
		PUSH	EAX									; Store quotient for next operation
		MOV		EAX, EDX
		ADD		AL, 48
		STOSB
		POP		EAX
	LOOP	_loop

	mDisplayString	[EBP+8]

	CLD
	POP		EDI
	POP		ECX
	POP		EBX
	POP		EAX
	POP		EBP
	RET 12
WriteVal ENDP

;------------------------------------------------------------------------
; Name: numDigits
; 
; Returns the number of digits in an integer
;
; Preconditions:The integer is type SDWORD
;
; Postcondtions: None.
;
; Receives: usrValue = [EBP+8] 
;           usrLen = [EBP+12]
;
; Returns: Output of user number as a string to console
;------------------------------------------------------------------------

numDigits	PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	ECX
	PUSH	EAX
	PUSH	EBX

	MOV		ECX, 0
	MOV		EBX, 10
	MOV		EAX, [EBP+8]
	_L1:
		CDQ
		IDIV	EBX
		INC		ECX
		CMP		EAX, 0
		JNE		_L1

	; Number of digits 
	MOV		EAX, [EBP+12]
	MOV		[EAX], ECX				; Length of digit for WriteVal

	POP		EBX
	POP		EAX
	POP		ECX
	POP		EBP
	RET		8
numDigits	ENDP

END main
