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
	MOV		stringLength, EAX

ENDM

;----------------------------------------------------------
;
;----------------------------------------------------------
mDisplayString	MACRO	usrString
	MOV		EDX, usrString
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
usrString		BYTE	13 DUP(?)
usrLen			DWORD	?
usrValue		SDWORD	0

.code
main PROC
	
	PUSH	OFFSET description
	PUSH	OFFSET intro
	PUSH	OFFSET author
	CALL	introduction
	
	PUSH	OFFSET	 usrLen
	PUSH	OFFSET   prompt2
	PUSH	OFFSET   error
	PUSH	OFFSET   prompt1
	PUSH	OFFSET   usrString
	PUSH	SIZEOF   usrString
	PUSH	OFFSET   usrValue
	CALL	ReadVal

	PUSH	usrValue
	PUSH	usrLen
	CALL	WriteVal

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
; the input is valid (no letters, symbols).
; 
; Preconditions: macro mGetString must be defined and used. Prompt1, error and promp2 must be declared
;				 in the data segment. usrString must be declared as a buffer. usrLen 
;				 must be declared to store the number of bytes read. 
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

	mGetString	[EBP+20], [EBP+16], [EBP+12], [EBP+32]
	

	_newPrompt:
	MOV		ESI, [EBP+16]						; Load usrString to ESI
	MOV		ECX, [EBP+32]						; Load length of string to ECX
	MOV		EBX, [EBP+12]						; Load size of string

	CLD
	LODSB										; Load first char to AL, if + or -, continue to next char
	CMP		AL, 43
	JE		_sign
	CMP		AL, 45
	JE		_sign
	MOV		ESI, [EBP+16]						; If not + or -, reload ESI 
	JMP		_Start

	_sign:
	DEC		ECX
	
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
	PUSH	ECX
	MOV		EDX, [EBP+8]
	MOV		EAX, [EDX]							; Move usrValue to EAX
	MOV		ECX, 10
	MOV		EDX, 0
	IMUL	ECX									; Multiply usrValue by 10 to account for places
	CMP		EDX, 0
	JNE		_invalid							; Check if EDX is used, implying EAX is extended
	MOV		EDX, [EBP+8]						; MUL modifies EDX, so must restore to usrValue
	MOV		[EDX], EAX							
	POP		ECX									; Restore registers
	POP		EAX
	ADD		[EDX], EAX							; Add integer value to user total
	JO		_invalid							; If addition sets carry flag, result is invalid. first
	POPFD										; Restore status flags 
	LOOP	_Start
	JMP		_End

	_invalid:	
	POPFD										; Restore status flags if invalid
	MOV		EDX, [EBP+24]
	CALL	WriteString
	MOV		EDX, [EBP+8]
	MOV		EBX, 0
	MOV		[EDX], EBX							; Restore usrValue to 0
	mGetString [EBP+28], [EBP+16], [EBP+12], [EBP+32]									
	JMP		_newPrompt

	_End:
	MOV		ESI, [EBP+16]
	LODSB	
	CMP		AL, 45							; Test if value is negative
	JNE		_leaveProc	
	MOV		EBX, -1
	MOV		EDX, [EBP+8]
	MOV		EAX, [EDX]
	IMUL	EBX
	MOV		EDX, [EBP+8]
	MOV		[EDX], EAX


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
; to print the ascii character to output.
;
; Preconditions:
;
; Postcondtions:
;
; Receives: usrLen = [ebp+8]
;			usrValue = [ebp+12]
;
; Returns: 
;------------------------------------------------------------------------
WriteVal PROC
PUSH	EBP
MOV		EBP, ESP

POP		EBP
RET 8
WriteVal ENDP


END main
