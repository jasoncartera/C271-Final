TITLE String Primitives and Macros     (Proj6_carterja.asm)

; Author: Jason Carter
; Last Modified: 3/1/2021
; OSU email address: carterja@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: March 14, 2021
; Description: 
;

INCLUDE Irvine32.inc

; ---------------------------------------------------------
; 
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
;
;----------------------------------------------------------
mDisplayString	MACRO	outString
	MOV		EDX, outString
	CALL	WriteString

ENDM


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
	MOV		ECX, 10						; Loop counter
	MOV		EDI, OFFSET numArr			; Set array start to EDI

	_L1:
		PUSH	OFFSET	 usrLen
		PUSH	OFFSET   prompt2
		PUSH	OFFSET   error
		PUSH	OFFSET   prompt1
		PUSH	OFFSET   usrString
		PUSH	SIZEOF   usrString
		PUSH	OFFSET   usrValue
		CALL	ReadVal
		; Store value in array
		MOV		EAX, usrValue
		MOV		[EDI], EAX
		ADD		EDI, 4						; Go to next part of array
	LOOP	_L1

	CALL	CrLf
	; Display message 
	mDisplayString	OFFSET displayMsg

	; Loop counter to display numbers
	MOV		ECX, 10						; Loop counter
	MOV		ESI, OFFSET numArr			; Start of array
	
	_L2:
		MOV		EAX, [ESI]
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
		ADD		ESI, 4					; Increment array
	LOOP	_L2

	CALL	CrLf

	; Sum Array
	MOV		EBX, 0						; Sum accumulator
	MOV		ECX, 10						; Counter for array size
	MOV		ESI, OFFSET numArr
	CLD
	_L5:
		LODSD	
		ADD		EBX, EAX
	LOOP	_L5

	MOV		sum, EBX

	mDisplayString	OFFSET sumMsg

	; Call WriteVal to write sum value
	PUSH	OFFSET usrLen
	PUSH	sum
	CALL	numDigits
	
	PUSH	sum
	PUSH	usrLen
	PUSH	OFFSET outString
	CALL	WriteVal

	CALL	CrLf

	; Calculate Average
	MOV		EBX, 10
	MOV		EAX, sum
	CDQ
	IDIV	EBX
	MOV		average, EAX

	PUSH	OFFSET usrLen
	PUSH	average
	CALL	numDigits

	mDisplayString	OFFSET avgMsg

	PUSH	average
	PUSH	usrLen
	PUSH	OFFSET outString
	CALL	WriteVal

	CALL CrLf

	Invoke ExitProcess,0	; exit to operating system
main ENDP


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
; Name: ReadVale
; Reads a value from a string input, converts string input to an integer, and validates if
; the input is valid (no letters, symbols). This procedure only works on 32 bit integers. 
; 
; Preconditions: macro mGetString must be defined and used. usrValue must be a declared SDWORD
;				 Prompt1, error and promp2 must be declared in the data segment. 
;				 usrString must be declared as a buffer. usrLen must be declared to store the 
;			     number of bytes read. 
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

	; Three different invalids because of different stack operations to test for invalid
	_invalid1:
		POP		ECX
		POP		EAX
		POPFD
		JMP		_invalid
	_invalid2:	
		POPFD										; Restore status flags if invalid
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
; Preconditions: outString declared, length of user input, and user value converted to integer from ReadVal
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


; usrValue = [EBP+8] (value)
; usrLen = [EBP+12]  (reference)
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
