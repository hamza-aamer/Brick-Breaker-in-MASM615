.model small
.stack 0200h
.data
	Bricks db 2CH,20H,28H,23H,28H,20H,2CH
		   db 20H,2CH,2FH,35H,2FH,2CH,20H
		   db 35H,27H,2CH,28H,2CH,27H,35H
		   db 20H,2CH,2FH,35H,2FH,2CH,20H
		   db 2CH,20H,28H,23H,28H,20H,2CH

	GridRows equ 5
	MinRows equ 2							;Do Not Change
	AutoMove equ Direction					;"Direction" = True, "0" = False
	SpecialBrickColor equ 0Fh				;Set Special Brick Color
	BonusBrickColor equ 03h					;Set Bonus Brick Color
	BonusBrickLevel equ 2
	NoOfBricks equ GridRows * lengthof Bricks
	FixedBrickColor equ 020h				;Set Fixed Brick Color
	FixedBricksLevel equ 3					;Set Lowest Level for Fixed Bricks
	Iterations equ 0100h			
	;BarColor equ 08h
	InitialStack equ 0200h					;Necessary for Clearing Stack
	BonusBricks equ 5

	bgColor db 0B0h
	BarColor db 6Dh
	BrickCount db NoOfBricks
	HeartColor db 04h
	UpperLimit db 0
	LowerLimit db 0
	
	BBActive db 0
	
;Ball Variables		  
	xPosBall dw 0;30;175;300
	yPosBall dw 0;160;98;174
	xDirection dw 0
	yDirection dw 0
	Collision db 0

;Bar Variables
	xPosBar dw 0
	yPosBar dw 0
	BarLength db 0
	BarHeight db 0
	Direction dw 0
	
;Brick Variables	
	Xaxis dw 0
	Yaxis dw 0
	xPixels dw 0
	yPixels dw 0
	
;Iteration Variables
	Looptemp1 db 0
	Looptemp2 db 0
	Retstore dw 0
	Bool db 0
	
;Game Control Variables
	GameInProgress db 1;1;Explicit
	PauseFlag db 0
	SInputkey db 0
	AInputkey db 0
	ScoreCpy db 0
	BeepType dw 0
	Level db 0			;Explicit
	Score db 0
	Lives db 0			;Explicit
	
	
;Text Variables
	InputPrompt db "Press Any Key To Continue$"
	HSPrompt db "Enter 000 to Display HighScore$"
	GameWon db "Congratulations, You Won!$" 
	UsernameStr db "Username$"
	GameOverStr db "Game Over$"
	LevelClearStr db "Cleared "
	LevelStr db "Level 0$"
	ScoreStr db "Score $"
	
;FileHandling Variables
    Name_Of_File db "1high.txt",0
	Name_Of_File2nd db "2high.txt",0
	var1 dw ?
	var2 dw ?
   
	currScore db 0
	temp db 100 dup (0)
	prevhighstr db 1000 dup (0)
	prevhighdec db 00
	prevhighuser db 100 dup (0)
		
	prev2highstr db 1000 dup (0)
	prev2highdec db 00

;Instruction Variables
	Instruct db "Move Slider using Left-Right Arrow Key", 10,10
			 db	" A Life is lost if Ball hits the Bottom", 10
			 db "       You Have 4 Lives per Level      ", 10, 10
			 db	" Level 1: Bricks Take 1 Hit to destroy ", 10
			 db "         +1 Score per Brick            ", 10,10
			 db	" Level 2: Bricks Take 2 Hits to Destroy", 10
			 db "         +2 Score per Brick            ", 10,10
			 db	" Level 3: Bricks Take 3 Hits to Destroy", 10
			 db "         +3 Score per Brick            ", 10,10,10   
			 db	" Bonus Brick: Makes all Bricks one Hit ", 10
			 db	" Special Brick: Destroys 5 Random Brick$",10

;Menu Variables	
	Welcome db "Welcome to Brick Breaker!$"
	DevelopedBy db "By 21I-0415,1366$"
	EnterNamePrompt db "Enter your Name :$"
	GameName db "Brick Breaker!$"
	Option1 db "New Game$"
	Option2 db "Resume$"
	Option3 db "Instructions$"
	Option4 db "HighScores$"
	Option5 db "Exit$"
	Option6 db "Restart$"
	Option7 db "Select Level$"
	
	LevelOp1 db "Level 1$"
	LevelOp2 db "Level 2$"
	LevelOp3 db "Level 3$"

	Fin db "    $"
	Fou db "===>$"

	UserName db 20 dup("$")
	Decision db 1
	Selected db 1

.code
	mov ax, @data
	mov ds, ax
	mov ax, 0
	jmp Main
	
	
;Main Game Control Code
Main:
;================;
	mov ah, 00h
	mov al, 13h
	int 10h
;================;
	call TitleScreen
Setup:
	call MenuScreen
	call OptionSelected
Reset:
	call InitializeGame
	
	mov ah, 0Ch
	mov al, bgColor
	call ColorBackGround
	
	call DisplayLevel
	call DisplayScore
	call GridSetup
	call ShowLife
	call MakeBar
	
	Cycles:
		call Delay
		call MoveBall
		call MoveBar 
		call InputControl
		call PauseGame

		call DetectBarContact
		call ReflectBall
		
		call DetectCollision
		call CollisionImpact
		call SpecialEffect
		
		cmp GameInProgress, 1
		jne GameOver
		mov cx, Iterations
	Loop Cycles
		
	GameOver:
	call DisplayGameEnd
	call DisplayPrompt

	.if (GameInProgress == 0)
		call ClearStack
		jmp Setup
	.else 
		jmp Reset
	.endif
	
Return:
	mov ah, 04ch
	int 21h

;===================================;

StrToNum proc
	push ax
	push bx
	
	mov bl, 10
	mov ax, 0
	
	mov al, byte ptr[si]
	sub al, 30h
	mul bl
	inc si
	
	add al, byte ptr[si]
	sub al, 30h
	mul bl
	inc si
	
	add al, byte ptr[si]
	sub al, 30h
	
	mov byte ptr[di], al	
	
	pop bx
	pop ax
ret	
StrToNum endp

get2ndhighestscore proc
	push ax
	push si
	push dx
	
	mov ah, 3DH
	mov al, 02
	mov dx, offset Name_Of_File2nd
	int 21h
	mov var2,ax

	mov ah,3fh
	mov cx,1000
	mov dx,offset prev2highstr
	mov bx,var2
	int 21h

	mov ah, 3Eh
	mov bx, var2
	int 21h

	mov ah, 02h
	mov dh, 15
	mov dl, 10
	mov bx, 0
	int 10h
	
	mov si, offset prev2highstr + 4
	mov dx, si
	mov ah,09h
	int 21h
	
	mov ah, 02h
	mov dh, 15
	mov dl, 22
	mov bx, 0
	int 10h
	mov si, offset prev2highstr + 3
	mov byte ptr[si], '$'
	lea dx, offset prev2highstr
	mov ah, 09h
	int 21h
	mov byte ptr[si], ' '
	

	mov si, offset prevhighstr
	mov di, offset currScore
	call StrToNum

	mov ah, 02h
	mov dh, 15
	mov dl, 30
	mov bx, 0
	int 10h
	mov dl, currScore
	.if(currScore < 21)
		mov dl, 31h
	.elseif(currScore < 63)
		mov dl, 32h
	.else
		mov dl, 33h
	.endif
	
	mov currScore, 0
	mov ah, 02h
	int 21h
	
	mov ah,0
	pop dx
	pop si
	pop ax
ret
get2ndhighestscore endp

gethighestscore proc
	push ax
	push si
	push dx
	
	mov ah, 3DH
	mov al, 02
	mov dx, offset Name_Of_File
	int 21h
	mov var1,ax

	mov ah,3fh
	mov cx,1000
	mov dx,offset prevhighstr
	mov bx,var1
	int 21h

	mov ah, 3Eh
	mov bx, var1
	int 21h
	
	mov ah, 02h
	mov dh, 12
	mov dl, 10
	mov bx, 0
	int 10h
	
	mov si, offset prevhighstr + 4
	mov dx, si
	mov ah,09h
	int 21h
	
	mov ah, 02h
	mov dh, 12
	mov dl, 22
	mov bx, 0
	int 10h
	mov si, offset prevhighstr + 3
	mov byte ptr[si], '$'
	lea dx, offset prevhighstr
	mov ah, 09h
	int 21h
	mov byte ptr[si], ' '
	
	
	mov si, offset prevhighstr
	mov di, offset currScore
	call StrToNum

	mov ah, 02h
	mov dh, 12
	mov dl, 30
	mov bx, 0
	int 10h
	mov dl, currScore
	.if(currScore < 21)
		mov dl, 31h
	.elseif(currScore < 63)
		mov dl, 32h
	.else
		mov dl, 33h
	.endif
	
	mov ah, 02h
	int 21h
	
	mov currScore, 0
	mov ah,0
	pop dx
	pop si
	pop ax
ret
gethighestscore endp

DisplayHS proc
	
	StayOnHSScreen:
		mov ah, 01h
		int 16h
		jz StayOnHSScreen
		
		mov ah, 00h
		int 16h
		mov SInputkey, ah
		mov AInputkey, al
		.if(AInputkey == 27)
			mov Bool, 1
		.elseif(AInputKey == 13)
			mov Bool, 1
		.endif
		
	cmp Bool, 0
	je StayOnHSScreen
	mov AInputkey, 0
	mov SInputkey, 0
	mov Bool, 0
ret
DisplayHS endp

HScrTopBar proc
	mov xPixels, 220
	mov yPixels, 30
	mov xAxis, 50
	mov yAxis, 50
	mov bl, 2ch
	mov al, 04h
	mov ah, 0Ch
	call GridBrick
	
	mov ah, 02h
	mov dh, 8
	mov dl, 20
	mov bx, 0
	int 10h
	lea dx, offset ScoreStr
	mov ah, 09h
	int 21h
	
	mov ah, 02h
	mov dh, 8
	mov dl, 28
	mov bx, 0
	int 10h
	mov si, offset LevelStr
	mov byte ptr[si+5], '$'
	lea dx, offset LevelStr
	mov ah, 09h
	int 21h
	mov byte ptr[si+5], ' '
	
	mov ah, 02h
	mov dh, 8
	mov dl, 8
	mov bx, 0
	int 10h
	lea dx, offset UsernameStr
	mov ah, 09h
	int 21h
ret
HScrTopBar endp

HighScoreScreen proc
	mov bgColor, 0FFh
	call ColorBackground
	
	mov xPixels, 220
	mov yPixels, 100
	mov xAxis, 50
	mov yAxis, 50
	mov bl, 2ch
	mov al, 06h
	mov ah, 0Ch
	call GridBrick
	
	mov ah, 02h
	mov dh, 1
	mov dl, 15
	mov bx, 0
	int 10h
	lea dx, offset Option4
	mov ah, 09h
	int 21h
	
	call HScrTopBar
	
	;mov ah, 02h
	;mov dh, 12
	;mov dl, 10
	;mov bx, 0
	;int 10h
	;lea dx, offset UserName
	;mov ah, 09h
	;int 21h
	
	call ClearRegisters
	call gethighestscore
	
	;mov ah, 02h
	;mov dh, 15
	;mov dl, 10
	;mov bx, 0
	;int 10h
	;lea dx, offset UserName
	;mov ah, 09h
	;int 21h
	
	call ClearRegisters
	call get2ndhighestscore
	call DisplayHS
	
	mov bgColor, 0B0h
	call ColorBackground
ret
HighScoreScreen endp

InstructionsScreen proc
	mov bgColor,0FFh
	call ColorBackground
	
	mov ah, 02h
	mov dh, 1
	mov dl, 3
	mov bx, 0
	int 10h
	
	lea dx, offset Option3
	mov ah, 09h
	int 21h
	
	mov xPixels, 310
	mov yPixels, 160
	mov xAxis, 5
	mov yAxis, 30
	mov bl, 2ch
	mov al, 06h
	mov ah, 0Ch
	call GridBrick
	
	mov ah, 02h
	mov dh, 5
	mov dl, 1
	mov bx, 0
	int 10h
	
	lea dx, offset Instruct
	mov ah, 09h
	int 21h

	StayOnInsScreen:
		mov ah, 01h
		int 16h
		jz StayOnInsScreen
		
		mov ah, 00h
		int 16h
		mov SInputkey, ah
		mov AInputkey, al
		.if(AInputkey == 27)
			mov Bool, 1
		.elseif(AInputKey == 13)
			mov Bool, 1
		.endif
		
	cmp Bool, 0
	je StayOnInsScreen
	
	mov AInputKey, 0
	mov SInputKey, 0
	mov bgColor, 0B0h
	call ClearRegisters
ret
InstructionsScreen endp

;============================================;
;Brick Grid Initial Values
;Starting Point of Grid (xAxis, yAxis)
;Brick Size: Length(xPixels), Height(yPixels)
Initialize proc
	mov Xaxis , 43
	mov Yaxis , 37
	mov xPixels , 30
	mov yPixels , 10
ret
Initialize endp

InitializeGame proc
	inc Level
	mov bgColor, 0B0h
	mov HeartColor, 04h
	mov Lives, 4
	mov	GameInProgress, 1
	mov BarHeight, 5
	;mov BarLength, 90
	mov BarColor, 6Dh
	mov bl, Score
	mov ScoreCpy, bl
	
	mov xPosBar, 150
	mov yPosBar, 193
	
	.if(Level == 1)
		mov BarLength, 75
	.elseif(level == 2)
		mov BarLength, 50
	.elseif(Level == 3)
		mov BarLength, 50
	.endif
	
	;mov ax, 15
	;mov bl, Level
	;mul bl
	;;.if(Level != 3)
	;sub BarLength, al
	;.endif
	
	mov xPosBall, 50;190;200;45;105;150;22
	mov yPosBall, 150;130;115;180;160;30;96;30;160
	mov xDirection, 2;0
	mov yDirection, -2
	
	mov al, 2
	add al, Level
	mov bl, lengthof Bricks
	mul bl
	mov BrickCount, al
	
	cmp Level, 3
	jne Init1
		call FixedBricks
		sub BrickCount, al

	Init1:
	call ClearRegisters
ret
InitializeGame endp

ClearStack proc
	pop RetStore
	
	.while(sp != InitialStack)
		pop di
	.endw
	
	push RetStore
ret
ClearStack endp

GameStartup proc
	mov Lives, 4
	mov Level, 0
	mov Score, 0
	mov Collision, 0
	mov BarColor, 6Dh
ret
GameStartup endp

OptionSelected proc
	.if(Decision == 1)
		mov Decision, 0
		call ClearStack
		call GameStartup
		jmp Reset
	.elseif(Decision == 2)
		call ClearStack
		mov Score, 0
		call LevelScreen
	.elseif(Decision == 3)
		call InstructionsScreen
		call ClearStack
		jmp Setup
	.elseif(Decision == 4)
		call HighScoreScreen
		call ClearStack
		jmp Setup
	.elseif(Decision == 5)
		pop dx
		jmp Return
	.endif
ret
OptionSelected endp

LevelSelectDisp proc
	mov bgColor, 03Fh
	call ColorBackground
	call DisplayLevel1
	call DisplayLevel2
	call DisplayLevel3
	mov bgColor, 0B0h
ret
LevelSelectDisp endp

SelectionEffect proc
	mov Lives, 5
	.if(Selected == 1)
		mov Level, 0
	.elseif (Selected == 2)
		mov Level, 1
	.elseif (Selected == 3)
		mov Level, 2
	.endif
	mov Score, 0
	call ClearStack
	call ClearRegisters
	mov Selected, 0
	jmp Reset
ret
SelectionEffect endp

LevelScreen proc
	pop dx
	mov Bool, 0
	mov Selected, 1
	call LevelSelectDisp 
	
	StayOnLvlScreen:
		mov ah, 01h
		int 16h
		jz StayOnLvlScreen
		
		mov ah, 00h
		int 16h
		mov SInputkey, ah
		mov AInputkey, al
	
		call LevelSelectControl
		call LevelSelectDisp 
	cmp Bool, 0
	je StayOnLvlScreen

	mov Bool, 0
	call SelectionEffect
	jmp Reset
LevelScreen endp

LevelSelectControl proc	
	CheckEnterRes:
	cmp AInputkey, 13
	jne SkipResume
		;mov PauseFlag, 0
		mov Bool, 1
		jmp ControlsChecked
		
	SkipResume:
	cmp SInputkey, 50h
	jne CheckUpInput
		.if(Selected != 3)
		inc Selected
		.endif
		jmp ControlsChecked
	
	CheckUpInput:
	cmp SInputkey, 48h;
	jne ControlsChecked
		.if(Selected != 1)
		dec Selected
		.endif
		jmp ControlsChecked
		
	ControlsChecked:
	mov AInputkey, 0
	mov SInputkey, 0
ret
LevelSelectControl endp

DisplayLevel1 proc
	.if(Selected == 1)
		mov bl, 2CH
	.else
		mov bl, 0Fh
	.endif
	call MenuRectInit
	mov al, 12h
	mov ah, 0Ch
	call GridBrick

	mov ah, 02h
	mov dh, 6
	mov dl, 17
	mov bx, 0
	int 10h
	lea dx, offset LevelOp1
	mov ah, 09h
	int 21h
ret
DisplayLevel1 endp

DisplayLevel2 proc
	.if(Selected == 2)
		mov bl, 2CH
	.else
		mov bl, 0Fh
	.endif

	call MenuRectInit
	add yAxis, 30
	mov al, 12h
	mov ah, 0Ch
	call GridBrick
	
	mov ah, 02h
	mov dh, 10
	mov dl, 17
	mov bx, 0
	int 10h
	lea dx, offset LevelOp2
	mov ah, 09h
	int 21h
ret
DisplayLevel2 endp

DisplayLevel3 proc
	.if(Selected == 3)
		mov bl, 2CH
	.else
		mov bl, 0Fh
	.endif
	call MenuRectInit
	add yAxis, 60
	mov al, 12h
	mov ah, 0Ch
	call GridBrick

	mov ah, 02h
	mov dh, 14
	mov dl, 17
	mov bx, 0
	int 10h
	lea dx, offset LevelOp3
	mov ah, 09h
	int 21h

ret
DisplayLevel3 endp

FixedBricks proc
	mov ax, 0
	mov si, offset Bricks
	mov cx, lengthof Bricks * GridRows
	Counter:
		cmp byte ptr[si], FixedBrickColor
		jne SkipInc
			inc al			
		SkipInc:
		inc si
	Loop Counter
ret
FixedBricks endp

ShowLife proc
	mov xAxis, 140
	mov yAxis, 4
	mov cl, Lives
	mov ch, 0
	
	LivesLoop:
		call PrintHeart
		add xAxis, 15
	Loop LivesLoop
	
ret
ShowLife endp

PauseMenuControl proc
	cmp AInputkey, 27
	jne CheckEnterRes
		mov PauseFlag, 0
		jmp ControlsChecked
	
	CheckEnterRes:
	cmp AInputkey, 13
	jne SkipResume
		mov PauseFlag, 0
		mov Bool, 1
		jmp ControlsChecked
		
	SkipResume:
	cmp SInputkey, 50h
	jne CheckUpInput
		.if(Selected != 4)
		inc Selected
		.endif
		jmp ControlsChecked
	
	CheckUpInput:
	cmp SInputkey, 48h;
	jne ControlsChecked
		.if(Selected != 1)
		dec Selected
		.endif
		jmp ControlsChecked
		
	ControlsChecked:
	mov AInputkey, 0
	mov SInputkey, 0
ret
PauseMenuControl endp

MenuRectInit proc
	mov xPixels, 100
	mov yPixels, 22
	mov xAxis, 110
	mov yAxis, 45
ret
MenuRectInit endp

Pausemenu proc
	mov bgColor, 0B8h
	call ColorBackGround	;Call Pause Menu Screen
	
	call DisplayUserName
	call NewGameOption
	call ResumeOption
	call RestartOption
	call ExitOption

	call ClearRegisters
	mov bgColor, 0B0h
ret
PauseMenu endp

NewGameOption proc
	.if(Selected == 1)
		mov bl, 2CH
	.else
		mov bl, 0Fh
	.endif
	call MenuRectInit
	mov al, 12h
	mov ah, 0Ch
	call GridBrick

	mov ah, 02h
	mov dh, 6
	mov dl, 16
	mov bx, 0
	int 10h
	lea dx, offset Option1
	mov ah, 09h
	int 21h

ret
NewGameOption endp

ResumeOption proc
	.if(Selected == 2)
		mov bl, 2CH
	.else
		mov bl, 0Fh
	.endif

	call MenuRectInit
	add yAxis, 30
	mov al, 12h
	mov ah, 0Ch
	call GridBrick
	
	mov ah, 02h
	mov dh, 10
	mov dl, 17
	mov bx, 0
	int 10h
	lea dx, offset Option2
	mov ah, 09h
	int 21h
	
ret
ResumeOption endp

RestartOption proc
	.if(Selected == 3)
		mov bl, 2CH
	.else
		mov bl, 0Fh
	.endif
	call MenuRectInit
	add yAxis, 60
	mov al, 12h
	mov ah, 0Ch
	call GridBrick

	mov ah, 02h
	mov dh, 14
	mov dl, 17
	mov bx, 0
	int 10h
	lea dx, offset Option6
	mov ah, 09h
	int 21h

ret
RestartOption endp

ExitOption proc
	.if(Selected == 4)
		mov bl, 2CH
	.else
		mov bl, 0Fh
	.endif
	call MenuRectInit
	add yAxis, 90
	mov al, 12h
	mov ah, 0Ch
	call GridBrick
	
	mov ah, 02h
	mov dh, 18
	mov dl, 18
	mov bx, 0
	int 10h
	lea dx, offset Option5
	mov ah, 09h
	int 21h
ret
ExitOption endp

PauseOptionSelected proc
	.if(Selected == 1)
		call ClearStack
		call GameStartup
		mov AInputKey, 0
		mov SInputKey, 0
		jmp Reset
	.elseif(Selected == 3)
		call ClearStack
		mov al, ScoreCpy
		mov Score, al
		dec Level
		jmp Reset
	.elseif(Selected == 4)
		call ClearStack
		mov Selected, 0
		mov AInputKey, 0
		mov SInputkey, 0
		mov Score, 0
		jmp Setup
	.endif
ret
PauseOptionSelected endp

PauseGame proc
	push ax
	cmp PauseFlag, 0
	je Resume
		call SaveGame
		call ClearRegisters
		call PauseMenu
		RemainPaused:
			mov ah, 01h
			int 16h
			jz RemainPaused
			
			mov ah, 00h
			int 16h
			mov SInputkey, ah
			mov AInputkey, al
	
		call PauseMenuControl	
		call PauseMenu
		cmp PauseFlag, 0
		jne RemainPaused
		
		.if(Bool == 1)
			call PauseOptionSelected
		.endif
		
		mov bgColor, 0B0h
		call ColorBackground
		call LoadGame
		call MakeBar
		call MoveBall
		call DisplayScore
		call DisplayLevel
		call ShowLife
		mov Bool, 0
	Resume:
	pop ax
ret
PauseGame endp

SaveScore proc
	;call HighScorePrompt
	;mov al, Score
	call UpdateScore
	call ClearRegisters
ret
SaveScore endp

;Display Game End Screen
;Changes BackGround Color
;Displays Game Over Msg and Score
DisplayGameEnd proc

	;Background Color Change Code
	mov ah, 06h
	mov bh, 0
	mov al, 0
	mov bh, 07Fh
	mov dl, 80
	mov dh, 80
	mov cx, 0
	int 10h
	
	mov ah, 0Ch
	mov xAxis, 20
	mov yAxis, 20
	mov xPixels, 280
	mov yPixels, 160
	call MakeBrick
	
	mov ah, 02h
	mov bx, 0
	mov dh, 10
	mov dl, 14
	
	cmp GameInProgress, 0
	je GameOverMsg; 
		
		mov dl, 13
		int 10h
		lea dx, offset LevelClearStr
		mov ah, 09h
		int 21h
		jmp ScoreDisplay
	
	cmp GameInProgress, 0
	jne GameOverMsg
	;Game Over Display Code
	GameOverMsg:
	mov dl, 15
	int 10h
	lea dx, offset GameOverStr
	mov ah, 09h
	int 21h
	
	mov al, Score
	mov currScore, al
	call UpdateScore
	mov currScore, 0
	;call SaveScore
	
	ScoreDisplay:
	;Score Display Code
	mov ah, 02h
	mov bx, 0
	mov dh, 12
	mov dl, 15
	int 10h

	lea dx, offset ScoreStr
	mov ah, 09h
	int 21h

	mov si, offset Score
	call OutputNum

	cmp Level, 3
	jne Continue
		cmp BrickCount, 0
		jne Continue 
			mov ah, 02h
			mov dh, 20
			mov dl, 8
			int 10h
			lea dx, offset GameWon
			mov ah, 09h
			int 21h
			mov GameInProgress, 0
			
			mov al, Score
			mov currScore, al
			call UpdateScore
			mov currScore, 0
			;call SaveScore
	
	Continue:
	cmp GameInProgress, 0
	jne NextLevel
		call ClearStack
		jmp Setup
		;pop dx
		;jmp Return
		
	NextLevel:
	mov GameInProgress, 1
ret
DisplayGameEnd endp

SaveGame proc
	pop RetStore 

	call Initialize
	
	mov bl, 14
	mov al, Level
	mul bl
	;add al, 50
	add ax, 20
	mov ah, 0h
	add yAxis, ax			;Working Here
	mov dx, yAxis
	
	mov bl, 00h
	mov bh, MinRows		;Changed here (2)
	add bh, Level
	mov Looptemp2 , bh			;No of Rows(Explicit)
	SaveL2:
		mov xAxis, 285
		mov cx, xAxis
		mov Looptemp1, lengthof Bricks/2 + 1
		SaveL1:
			mov ah, 0Dh
			int 10h
			;mov ah, 0Ch
			mov SInputkey, al
			;call MakeBrick
			
			sub cx, xPixels
			sub cx, 4
			mov xAxis, cx
			
			mov ah, 0Dh
			int 10h	
			;mov ah, 0Ch
			mov AInputkey, al
			;call MakeBrick

			mov al, AInputkey
			mov ah, SInputkey
			push ax
			
			sub cx, xPixels
			sub cx, 4
			mov xAxis, cx
			
			dec Looptemp1
		cmp Looptemp1, 0
		jne SaveL1
		
		sub dx, yPixels
		sub dx, 4
		mov yAxis, dx
		
		dec Looptemp2
	cmp Looptemp2,0
	jne SaveL2
	
	push RetStore
ret
SaveGame endp

GetRows proc
	cmp Level, 1
	jne Level2C
		mov bh, 3
		jmp RowsSet
		
	Level2C:
		mov bh, 4
		jmp RowsSet
		
	Level3C:
		mov bh, 5
		
	RowsSet:
ret
GetRows endp

LoadGame proc
	pop RetStore
	
	call Initialize
	mov cx, xAxis

	mov bl, 00h
	mov bh, MinRows					;Changed here
	add bh, Level
	mov Looptemp2 , bh			;No of Rows(Explicit)
	LoadL2:
		mov xAxis, cx
		mov Looptemp1, lengthof Bricks/2 + 1
		LoadL1:
			pop dx
			mov SInputkey, dh
			mov AInputkey, dl
			
			mov ah, 0Ch
			mov bl, 00h
			mov al, AInputkey
			.if(al == SpecialBrickColor) || (al == BonusBrickColor)
				mov bl, 02Ch
			.endif
			call LoadBrick
			
			mov dx, xPixels
			add dx, 4
			add xAxis, dx
			
			cmp SInputkey, 0B0h
			jne SkipSecond
				mov bl, bgColor
			SkipSecond:
			mov bl, 00h
			mov ah, 0Ch
			mov al, SInputkey
			.if(al == SpecialBrickColor) || (al == BonusBrickColor)
				mov bl, 02Ch
			.endif
			call LoadBrick
			

			mov dx, xPixels
			add dx, 4
			add xAxis, dx
			
			dec Looptemp1
		cmp Looptemp1, 0
		jne LoadL1
		
		mov dx, yPixels
		add dx, 4
		add yAxis, dx
	
		dec Looptemp2
	cmp Looptemp2,0
	jne LoadL2	
	
	push RetStore
ret
LoadGame endp

LoadBrick proc
	push bx
	push xAxis
	push yAxis
	mov xPixels, 30
	mov yPixels, 10
	
	cmp al, bgColor
	jne PrintRegular
		mov bl, bgColor
		call GridBrick
		jmp BrickLoaded

	mov bl, 00h		
	.if(al == SpecialBrickColor)
		mov bl, 0Eh
	.elseif(al == BonusBrickColor)
		mov bl, 0Eh
	.endif
	
	PrintRegular:
	call GridBrick
	
	BrickLoaded:
	pop yAxis
	pop xAxis
	pop bx

ret
LoadBrick endp

SpecialEffect proc
	cmp Level, 3
	jne EffectComplete
	
	cmp AInputKey, 1
	jne EffectComplete
	
	mov xPixels, 30
	mov yPixels, 10
	mov Looptemp1, 5
	cmp BrickCount,5
	jg RandomBreak
		call Initialize
		mov xPixels, 200
		mov yPixels, 100
		mov al, bgColor
		call MakeBrick
		mov BrickCount, 0
		mov GameInProgress, 2
		jmp EffectComplete

	RandomBreak:
		call GetRandomBrick
		mov cx, xAxis
		mov dx, yAxis
		add cx, 4
		add dx, 4
		
		;FindNearest:
			mov ah, 0Dh
			int 10h
			cmp al, bgColor
			je RandomBreak
			
			cmp Level, FixedBricksLevel
			jne BreakBrick
			cmp al, FixedBrickColor
			je RandomBreak
			
		BreakBrick:
		mov al, bgColor
		mov bl, bgColor
		mov ah, 0Ch
		call GridBrick
		
		push dx
		mov dl, Level
		add Score, dl
		pop dx		
		dec BrickCount
		call DisplayScore
		;call MoveBall
		;call MoveBar
		dec looptemp1
	cmp looptemp1, 0
	jne RandomBreak
	
	EffectComplete:
	mov AInputKey, 0
ret
SpecialEffect endp

GetRandomBrick proc
	push cx
	push dx
	push ax

	call Initialize
	mov UpperLimit, lengthof Bricks
	mov LowerLimit, 0
	
	mov ax, 0
	mov bl, 34
	call RandomNumber
	mov ax, 0
	mov al, SInputkey
	dec al
	mul bl
	mov cx, ax
	add xAxis, cx
	
	mov bl, 14
	mov UpperLimit, MinRows
	mov ax, 0
	mov al, Level
	add UpperLimit, al
	
	call RandomNumber	
	mov ax, 0
	mov al, SInputkey
	dec al
	mul bl
	mov dx, ax
	add yAxis, dx
	
	mov cx, xAxis
	mov dx, yAxis
	add cx, 4
	add dx, 4
	call FindEdge
	
	pop ax
	pop cx
	pop dx
ret
GetRandomBrick endp

CreateSpecialBrick proc

	Location:	
		call GetRandomBrick
		mov cx, xAxis
		mov dx, yAxis
	
		add cx, 2
		add dx, 2
		mov ah, 0Dh
		int 10h
		sub cx, 2
		sub dx, 2
	cmp al, FixedBrickColor
	je Location
	
	mov al, SpecialBrickColor
	mov xPixels, 30
	mov yPixels, 10
	mov ah, 0Ch
	call GridBrick

ret
CreateSpecialBrick endp

CreateBonusBrick proc
	
	BBLocation:	
		call GetRandomBrick
		mov cx, xAxis
		mov dx, yAxis
		
		add cx, 2
		add dx, 2
		mov ah, 0Dh
		int 10h
		sub cx, 2
		sub dx, 2
	cmp al, FixedBrickColor
	je BBLocation
	cmp al, SpecialBrickColor
	je BBLocation
	
	mov al, BonusBrickColor
	mov xPixels, 30
	mov yPixels, 10
	mov ah, 0Ch
	call GridBrick
	
	mov BBActive, 0
ret
CreateBonusBrick endp


;UpperLimit
;LowerLimit
;Result: ax
RandomNumber proc
	push cx
	push dx
	push ax
	
	mov ah , 00h
	int 1Ah
	mov ax, dx
	mov dx, 0
	mov ah, 0
	
	cmp UpperLimit , al
	ja Resume1
		mov cl , UpperLimit
		div cl
		mov al , ah
	Resume1:
	
	LR:
		mov si , 0
		cmp LowerLimit , al
		jb Resume2
			add al , UpperLimit
			mov si , 1
		Resume2:
	cmp si , 0
	jne LR

	mov SInputkey, al
	pop ax
	pop dx
	pop cx
ret
RandomNumber endp

;Draws Horizontal Line
;Starting Point: (xAxis,yAxis)
;Length: xPixels 
Horizontal proc	
	push xPixels
	
	mov cx, xAxis
	L1:
		int 10h
		inc cx
		dec xPixels		
	cmp xPixels, 0
	jne L1
	
	pop xPixels
ret
Horizontal endp

;Draws Vertical Line
;Starting Point: (xAxis,yAxis)
;Length: yPixels 
Vertical proc
	push yPixels
	
	mov dx, yAxis
	L1:
		int 10h
		inc dx
		dec yPixels		
	cmp yPixels, 0
	jne L1
	
	pop yPixels
ret
Vertical endp

;Draws Filled Rectangle
;Starting Point: (xAxis,yAxis)
;Size: xPixels * yPixels 
MakeBrick proc
	push dx
	push cx
	
	mov bx, xPixels
	mov cx, xAxis
	L1:
		mov dx, yAxis
		call Vertical
		inc cx
		dec bx
	cmp bx, 0
	jne L1
		
	pop cx
	pop dx
ret
MakeBrick endp

;Colors Background with bgColor
;Draws Purple Bar on Top 
;UnderLine Bar with Black Line
ColorBackground proc
	mov ah, 06h
	mov bh, 0
	mov al, 0
	mov bh, bgColor
	mov dl, 80
	mov dh, 80
	mov cx, 0
	int 10h
	
	mov al, 05h
	mov ah, 0Ch
	mov xAxis, 0
	mov yAxis, 0
	mov xPixels, 320
	mov yPixels, 20
	call MakeBrick

	mov al, 00h
	mov dx, 20
	call Horizontal
	
	call ClearRegisters
ret
ColorBackground endp

;Black Border To Regular Brick
GridBrick proc
	push xAxis
	push yAxis
	
	push ax
	dec xAxis
	dec yAxis
	add xPixels, 2
	add yPixels, 2
	mov al, bl
	call MakeBrick			;Black Brick of Larger Size
	sub xPixels, 2
	sub yPixels, 2
	inc xAxis
	inc yAxis
	pop ax
	
	cmp bl, bgColor
	je SkipColorBrick
		call MakeBrick		;Actual Brick
	
	SkipColorBrick:
	pop yAxis
	pop xAxis
ret
GridBrick endp

;Draws Somewhat Circular Shaped Ball
;Starting Points (xPosBall, yPosBall)
MakeBall proc
	push cx
	push dx
	
	mov cx, xPosBall
	mov dx, yPosBall
	mov ah, 0Ch
	
;Horizontal Rectangle
	mov xPixels, 6
	mov yPixels, 4
	mov xAxis, cx
	mov yAxis, dx
	
	inc yAxis
	call MakeBrick
	
;Vertical Rectangle
	mov xPixels, 4
	mov yPixels, 6
	mov xAxis, cx
	mov yAxis, dx

	inc xAxis
	call MakeBrick
	
	pop dx
	pop cx
ret
MakeBall endp

;Pushes Frequently Used Registers to Stack
;Wastes Cycles 0FFFFh + 0FFh
Delay proc
	push ax
	push bx
	push cx
	push dx
	
	cmp Level, 1
	jne Level2
	
	Level1:
	mov cx, 0FFFFh
	L1: Loop L1	
	jmp DelayExit
	
	cmp Level, 2
	jne Level3
	
	Level2:
	mov cx, 0CFFFh
	L2: Loop L2	
	jmp DelayExit
	
	Level3:
	mov cx, 05FFFh
	L3: Loop L3
	
	DelayExit:
	pop dx
	pop cx
	pop bx
	pop ax
ret
Delay endp

;Draws Entire Grid of Bricks
;No. of Columns are Automatic
;Need to Define No. of Rows
;Looptemp1 for Outter Loop
;Looptemp2 for Inner Loop
GridSetup proc
	push ax

	call Initialize
	mov ah, 0Ch
	mov al, 0Bh
	mov cx, xAxis
	mov dx, yAxis
	
	mov bl, 00h
	mov si, offset Bricks
	mov bh, MinRows				;Changed here
	add bh, Level
	mov Looptemp2 , bh			;No of Rows(Explicit)
	L2:
		mov xAxis, cx
		mov Looptemp1, lengthof Bricks
		L1:
			mov al, [si]
			call GridBrick		;UnComment Upper Line, call MakeBrick 
			
			mov dx, xPixels
			add dx, 4
			add xAxis, dx
			inc si
			dec Looptemp1
		cmp Looptemp1, 0
		jne L1
		
		mov dx, yPixels
		add Yaxis, dx
		add Yaxis, 4
		
		dec Looptemp2
	cmp Looptemp2,0
	jne L2

	cmp Level, 3
	jne NoSpecialBrick
		call CreateSpecialBrick
	NoSpecialBrick:
	
	cmp Level, BonusBrickLevel
	jl NoBonusBrick
		call CreateBonusBrick
	NoBonusBrick:
	
	
	pop ax
ret
GridSetup endp

;Draws bgColor Ball At current Ball Pos
;Draws White Ball at Updated Ball Pos
MoveBall proc
	push cx
	mov al, bgColor
	call MakeBall
	
	call SetDirection
	
	mov cx, xDirection
	add xPosBall, cx
	mov cx, yDirection
	add yPosBall, cx
	
	mov al, 0Fh
	call MakeBall
	pop cx
ret
MoveBall endp

;Sets Ball Movement Direction
;Purely to Reflect Ball from Walls
;Additional Functionality:
;Reduces Lives Upon ball Collision with Bottom
SetDirection proc
	mov cx, xPosBall
	mov dx, yPosBall
	add dx, yDirection
	
	cmp dx, 192				;Reflect from Bottom
	jl LowerNotHit
		;Game Over Code Here
		call RemoveLife
		neg yDirection
		jmp SkipUpDown
		
	LowerNotHit:
	cmp dx, 22				;Reflect from Top
	jg SkipUpDown
		neg yDirection
	
	SkipUpDown:
	add cx, xDirection
	cmp cx, 314				;Reflect from Right
	jl RightNotHit
		neg xDirection
		jmp SkipLeftRight
		
	RightNotHit:
	cmp cx, 0				;Reflect from Left
	jg SkipLeftRight
		neg xDirection
		
	SkipLeftRight:
ret
SetDirection endp

;Keyboard Input Effect
;Saves InputVal into Slider Bar Direction
SetInputImpact proc
	cmp SInputkey, 4Dh		;Right Arrow Key
	jne NoMoveRight
		mov Direction, 3		;Bar Movement Speed
		jmp MovementChecked

	NoMoveRight:
	cmp SInputkey, 4Bh		;Left Arrow Key
	jne NoMoveLeft
		mov Direction, -3
		jmp MovementChecked
		
	NoMoveLeft:
	cmp AInputkey, 27
	jne MovementChecked
		mov PauseFlag, 1
		
	MovementChecked:
	mov SInputkey, 0
	mov AInputkey, 0
ret
SetInputImpact endp

;Detects KeyBoard Input
;Upon Input Determines Implication
InputControl proc
	push ax
	
	mov ah, 01h
	int 16h
	jz NoInput
	
	mov ah, 00h
	int 16h
	mov SInputkey, ah
	mov AInputkey, al
	
	call SetInputImpact
	
	NoInput:
	pop ax
ret
InputControl endp

;Checks Ball Contact with Brick
;Specifically for Bricks above Ball
;Collision = 1 -> Top Left Edge Hit
;Collision = 2 -> Top Right Edge Hit
CheckTop proc
	push cx
	push dx
	
	cmp yDirection, 0
	jge NoUpContact
	
	sub dx, 2				;Check Pixels Above Left Edge of Ball
	int 10h
	cmp al, bgColor
	je CheckTR
		mov Collision, 1
		jmp NoUpContact
		
	CheckTR:
	add cx, 5				;Check Pixels Above Right Edge of Ball
	int 10h
	cmp al, bgColor
	je NoUpContact
		mov Collision, 2
		
	NoUpContact:
	pop dx
	pop cx
ret
CheckTop endp

;Checks Ball Contact with Brick
;Specifically for Bricks Below Ball
;Collision = 3 -> Bottom Left Edge Hit
;Collision = 4 -> Bottom Right Edge Hit
CheckBottom proc
	push cx
	push dx
	
	cmp yDirection, 0
	jle NoDownContact
	
	add dx, 8				;Check Pixels Below Left Edge of Ball
	int 10h
	cmp al, bgColor
	je CheckBR
		mov Collision, 3
		jmp NoDownContact
		
	CheckBR:
	add cx, 5				;Check Pixels Below Right Edge of Ball
	int 10h
	cmp al, bgColor
	je NoDownContact
		mov Collision, 4
	
	NoDownContact:
	pop dx
	pop cx
ret
CheckBottom endp

;Checks Ball Contact with Brick
;Specifically for Bricks Left of Ball
;Collision = 1X -> Upper Left Edge Hit
;Collision = 2X -> Lower Left Edge Hit
CheckLeft proc
	push cx
	push dx
	
	cmp xDirection, 0
	jge NoLeftContact
	
	sub cx, 2						;Check Pixels Upper Left Edge of Ball
	int 10h
	cmp al, bgColor
	je CheckLT
		add Collision, 10h
		jmp NoLeftContact
		
	CheckLT:
	add dx, 5					;Check Pixels Lower Left Edge of Ball
	int 10h
	cmp al, bgColor
	je NoLeftContact
		add Collision, 20h
	NoLeftContact:
	pop dx
	pop cx
ret
CheckLeft endp

;Checks Ball Contact with Brick
;Specifically for Bricks Right Ball
;Collision = 3X -> Upper right Edge Hit
;Collision = 4X -> Lower Right Edge Hit
CheckRight proc
	push cx
	push dx
	
	cmp xDirection, 0
	jle NoRightContact
	
	add cx, 8					;Check Pixels Upper Right Edge of Ball
	int 10h
	cmp al, bgColor
	je CheckRT
		add Collision, 30h
		jmp NoRightContact
		
	CheckRT:
	add dx, 5					;Check Pixels Lower Right Edge of Ball
	int 10h
	cmp al, bgColor
	je NoRightContact
		add Collision, 40h
	NoRightContact:
	pop dx
	pop cx
ret
CheckRight endp

;Ball-Brick Collision Control 
;Calls all 4 Ball Sides Checks
;Max Hits: One per Instant
;Collision= 5 -> Collision with Slider Bar
DetectCollision proc
	push cx
	push dx
	
	cmp Collision, 5
	je SkipBrickDetect		;Do Not Check Ball-Brick Hit 
	mov Collision, 0
	
	mov cx, xPosBall
	mov dx, yPosBall
	mov ah, 0Dh
	mov bh, 0
	
	call CheckTop
	cmp Collision, 0
	jne CheckedAll
	
	call CheckBottom
	cmp Collision, 0
	jne CheckedAll
	
	call CheckLeft
	cmp Collision, 10
	jge CheckedAll
	
	call CheckRight
	cmp Collision, 10
	jge CheckedAll

	SkipBrickDetect:
	mov Collision, 0
	CheckedAll:
	pop dx
	pop cx
ret
DetectCollision endp

BonusBar proc
	push ax
	push bx
	push cx
	push dx

	mov BBActive, BonusBricks
	mov BarColor, 0Ch
	add BarLength, 20
	
	mov cx, xPosBar
	mov dx, 0
	mov dl, BarLength
	add cx, dx
	cmp cx, 320
	jl BoundsClear
		sub xPosBar, 20
		;mov Direction, -3
	BoundsClear:
	
	;call Make
	pop dx
	pop cx
	pop bx
	pop ax
ret
BonusBar endp

RemoveBonusBar proc
	push ax
	push bx
	push cx
	push dx

	;mov bl, bgColor
	;sub xPosBar, 5
	;add BarLength, 10
	;call MakeBar
	;add xPosBar, 5
	;sub BalLength, 10
	
	mov bl, Level
	sub Score, bl
	inc BrickCount
	
	mov bl, bgColor
	mov BarColor, bl
	add BarLength, 6
	call MakeBar
	
	sub BarLength, 26
	mov BarColor, 6Dh
	call MakeBar
	
	pop dx
	pop cx
	pop bx
	pop ax


ret
RemoveBonusBar endp

;Finds Top Left Edge of Brick
FindEdge proc
	push ax
	LClear:						;Left Edge Finder
		mov ah, 0Dh
		int 10h
		cmp al, bgColor
		je ExitLClear
			dec cx
	jmp LClear
	ExitLClear:
	
	add cx,2
	UClear:						;Upper Edge Finder
		mov ah, 0Dh
		int 10h
		cmp al, bgColor
		je EdgeFound
			dec dx
	jmp UClear
	
	EdgeFound:
	add dx,2
	mov xAxis, cx
	mov yAxis, dx
	pop ax
ret
FindEdge endp

CheckLevelEffect proc

	add cx, 2
	add dx, 2
	mov ah, 0Dh
	int 10h

	sub cx, 2
	sub dx, 2
	cmp al, BarColor 
	jne CheckBonus
		push bx
		mov bl, BarColor
		mov AInputKey, bl
		pop bx
		jmp ColorSet
		
	CheckBonus:
	cmp al, BonusBrickColor
	jne CheckActiveBonus
		call BonusBar
		mov al, bgColor
		mov bl, bgColor
		jmp ColorSet
	
	CheckActiveBonus:
	cmp BBActive, 0
	je CheckLevel1
		.if(Level == 3) && (al == FixedBrickColor)
			jmp CheckLevel2
		.elseif(Level == 3) && (al == SpecialBrickColor)
			mov Bool, 5
		.endif
		dec BBActive
		cmp BBActive, 0
		jne KeepActivate
			call RemoveBonusBar
		KeepActivate:
		
		.if(Bool == 5)
		jmp CheckLevel2
		.endif
		mov al, bgColor
		mov bl, bgColor
		jmp ColorSet
				
	CheckLevel1:
	cmp Level, 1
	jne CheckLevel2
		mov al, bgColor
		mov bl, bgColor
		jmp ColorSet

	CheckLevel2:
	add al, 24
	mov bl, 00h
				
	cmp Level, 2
	jne CheckLevel3
		cmp al, 4Eh
		jle ColorSet
			mov al, bgColor
			mov bl, bgColor
		jmp ColorSet

	CheckLevel3:
	mov AInputkey, 0
	cmp Level, 3
	jne ColorSet
		BBNotActive:
		cmp al, SpecialBrickColor + 24
		jne NotSpecial
			mov AInputkey, 1
			mov al, bgColor
			mov bl, bgColor
			jmp ColorSet
				
		NotSpecial:
		cmp al, FixedBrickColor + 24
		jne RegularBrick
			mov al, FixedBrickColor
			mov bl, 00h
			jmp ColorSet
			
		RegularBrick:
		cmp al, 67h
		jle ColorSet
			mov al, bgColor
			mov bl, bgColor
			
	ColorSet:
ret
CheckLevelEffect endp

;Covers Hit Brick with bgColor Brick
;Updates Score and Checks Level Won
DestroyBrick proc
	push cx
	push dx

	call FindEdge
	call CheckLevelEffect
	mov ah, BarColor
	cmp AInputkey, ah
	jne Destroy
		mov xDirection, 3
		mov yDirection, -2
		mov AInputKey, 0
		pop bx
		jmp SkipEnd
	
	Destroy:
	mov xPixels, 30
	mov yPixels, 10
	mov ah, 0Ch
	call GridBrick					;Hide Hit Brick with bgColor
	mov BeepType, 1000
	call SoundBeep
	
	NoSpecialEffect:
	cmp al, bgColor
	jne SkipEnd
		dec BrickCount
		mov al, Level				;Update Score
		add Score, al
		call DisplayScore
	
		cmp BrickCount, 0			;Check ALl Brick Destoryed
		jne SkipEnd
			mov GameInProgress, 2
	SkipEnd:
	pop dx
	pop cx
ret
DestroyBrick endp

;Adjusts xBallPos, yBallPos 
;According to Collision Type
;Places Pixel Location Into Brick
;Calls Destroy Brick Function
CollisionImpact proc
	push ax
	push cx
	
	mov dx, 0
	mov ax, 0
	mov dl, 10h
	mov al, Collision
	div dl
	
	mov dx, yPosBall
	mov cx, xPosBall
	
	cmp ah, 1				;Top Left Hit Type
	jne CheckTR
		neg yDirection
		sub dx, 10
		call DestroyBrick
		jmp CheckComplete

	CheckTR:
	cmp ah, 2				;Top Right Hit Type
	jne CheckBL
		neg yDirection
		sub dx, 10
		add cx, 7;5
		call DestroyBrick
		jmp CheckComplete

	CheckBL:
	cmp ah, 3				;Bottom Left Hit Type
	jne CheckBR
		neg yDirection
		add dx, 8
		call DestroyBrick
		jmp CheckComplete

	CheckBR:
	cmp ah, 4				;Bottom Right Hit Type
	jne CheckLT
		neg yDirection
		add dx, 8;7
		add cx, 7;5
		call DestroyBrick
		jmp CheckComplete

	CheckLT:				;Upper Left Hit Type
	cmp al, 1
	jne CheckLB
		neg xDirection
		sub cx, 25
		call DestroyBrick
		jmp CheckComplete

	CheckLB:
	cmp al, 2				;Lower Left Hit Type
	jne CheckRT
		neg xDirection
		sub cx, 25
		add dx, 5
		call DestroyBrick
		jmp CheckComplete

	CheckRT:
	cmp al, 3				;Upper Right Hit Type
	jne CheckRB
		neg xDirection
		add cx, 7
		call DestroyBrick
		jmp CheckComplete

	CheckRB:
	cmp al, 4				;Lower Right Hit Type
	jne CheckComplete
		neg xDirection
		add cx, 7
		add dx, 5
		call DestroyBrick
		jmp CheckComplete

		
	CheckComplete:
	mov Collision, 0		;Clear Collision Type
	pop cx
	pop ax
ret
CollisionImpact endp

;Bar Movement Left Right Check
;Limits Bar from going Out of Screen
BarBoundsCheck proc
	push cx
	push ax
	mov ax, 0
	add cx, Direction
	mov al, BarLength
	sub ax, 320
	neg ax
	
	cmp cx, ax		;Right Side
	jl RightClear
		mov Direction, 0
	
	RightClear:
	cmp cx, 0				;Left Side
	jg ClearToMove
		mov Direction, 0
	
	ClearToMove:
	pop ax
	pop cx
ret
BarBoundsCheck endp

;Draws Rectangular Bar
;Length = BarLength
;Heigth = BarHeight
MakeBar proc
	push bx
	
	mov bx, xPosBar
	mov xAxis, bx
	mov bx, yPosBar
	mov yAxis, bx
	
	mov bx, 0
	mov bl, BarLength
	mov xPixels, bx
	mov bl, BarHeight
	mov yPixels, bx
	mov ah, 0Ch
	mov al, BarColor
	call MakeBrick
	
	pop bx
ret
MakeBar endp

;Draws Square of Bar Color on Side of Bar Movement
;Draws Square of bgColor on Opposite Side
;Square Length = Bar Movement Direction
;Square Height = Bar Heigth
MoveBar proc
	push cx
	push dx
	
	mov cx, xPosBar
	call BarBoundsCheck			;Bar Movement Limit Check
	cmp Direction, 0
	je NoMovement
	
	mov dx, yPosBar
	mov xAxis, cx
	mov yAxis, dx
	mov cx, 0
	mov cl, BarHeight
	mov yPixels, cx
	mov cx, Direction
	mov xPixels, cx

	cmp Direction, 0
	jl BarMovedLeft				;Right Movement 
	
		mov al, bgColor			;bgColor on Left
		call MakeBrick
		
		mov cx, 0
		mov cl, BarLength
		add xAxis, cx
		mov al, BarColor
		call MakeBrick			;Bar Color on Right
		jmp NoMovement
	
	BarMovedLeft:
	cmp Direction, 0
	jg NoMovement				;Left Movement
		
		neg cx
		mov xPixels, cx
		mov al, BarColor
		call MakeBrick			;bgColor on Right

		mov cx, 0
		mov cl, BarLength
		add xAxis, cx
		mov al, bgColor
		call MakeBrick			;Bar Color on Left

	NoMovement:
	mov cx, Direction 
	add xPosBar, cx				;Retaining Movement
	mov cx, AutoMove
	mov Direction, cx			;Clear Input
	pop dx	
	pop cx
ret
MoveBar endp


DetectEdgeBarContact proc
	mov dx, yPosBall
	mov si, yPosBar
	add dx, yDirection
	add dx, 5
	cmp dx, si
	jl DetectionComplete

	mov cx, xPosBall
	mov si, xPosBar
	mov dl, BarLength
	mov dh, 0
	
	add cx, xDirection
	add si, Direction
	
	cmp xDirection, 0
	jl CheckRightEdge
		add cx, 6
		cmp cx, si
		jl DetectionComplete
			add si, dx
			cmp cx, si
			jg DetectionComplete
				mov Collision, 6
				jmp DetectionComplete
	CheckRightEdge:
		sub cx, 3
		add si, dx
		cmp cx, si
		jg DetectionComplete
			sub si, dx
			cmp cx, si
			jl DetectionComplete
				mov Collision, 7

	DetectionComplete:
ret
DetectEdgeBarContact endp


;Checks Ball Collision with Bar
;Uses Bar Positioning to Detect Contact
DetectBarContact proc
	push cx
	push dx
	
	mov cx, xPosBall
	mov dx, yPosBall
	mov si, xPosBar
	add dx, 7
	add dx, yDirection
	
	cmp dx, yPosBar
	jl NoNormalImpact
	
		mov dx, 0
		mov dl, BarLength
		sub cx, si
		
		cmp cx, 0
		jl CheckLeftEdge
			cmp cx, dx
			jg CheckLeftEdge
				mov Collision, 5
				jmp NoNormalImpact
				
		CheckLeftEdge:
		add cx, 5
		sub dx, 5
		cmp cx, 0
		jl SideWaysHit
			cmp cx, dx
			jg SideWaysHit
				mov Collision, 5
				jmp NoNormalImpact
	
	SideWaysHit:
		call DetectEdgeBarContact 	
	
	NoNormalImpact:
	pop dx
	pop cx
ret
DetectBarContact endp

;Ball Reflection from Bar
;Splits Bar Length int 5 Sections
;Ball Angle depends on Section Hit
ReflectBall proc
	push cx
	push ax
	push dx
	cmp Collision, 5
	jne MoveLeft
	
	mov yDirection, -2
	
	mov ax, 0
	mov al, BarLength
	mov cl, 5
	div cl

	mov dl, 0
	mov dh, al
	mov cx, xPosBall
	mov si, xPosBar				
	sub cx, si					;Bar Position - Ball Position
	add cx, 3					;Detection From Mid of ball
	
	add dl, dh
	cmp cl, dl					;Left Most Section of Bar
	jg Type2Reflection
		mov xDirection, -1
		jmp NoBarHit	
		
	Type2Reflection:			;Left Section of Bar
	add dl, dh
	cmp cl, dl
	jg Type3Reflection
		mov xDirection, -1
		jmp NoBarHit
			
	Type3Reflection:			;Middle Section of Bar
	add dl, dh
	cmp cl, dl		
	jg Type4Reflection
		mov xDirection, 0
		jmp NoBarHit

	Type4Reflection:			;Right Section of Bar
	add dl, dh
	cmp cl, dl		
	jg Type5Reflection
		mov xDirection, 1
		jmp NoBarHit
	
	Type5Reflection:			;Right Most Section of Bar
		mov xDirection, 1
		jmp NoBarHit
	
	MoveLeft:
	cmp Collision, 6
	jne RightSideHit
		mov yDirection, -1
		mov xDirection, -2
		jmp NoBarHit
	
	RightSideHit:
	cmp Collision, 7
	jne NoBarHit
		mov yDirection, -1
		mov xDirection, 2
		jmp NoBarHit
	
	
	NoBarHit:
	mov Collision, 0
	pop dx
	pop ax
	pop cx
ret
ReflectBall endp

;2 Digit Number Output
;si Contains Address of Number to Output

OutputNum Proc
	push ax
	push dx

	mov ax, 0
	mov al, [si]
	mov bl, 10
	div bl
	
	mov cl, ah
	mov ah, 0
	div bl
	
	mov dh, ah
	mov bh, al
	
	mov ah, 02h
	mov dl, bh
	add dl, 30h
	int 21h
	
	mov dl, dh
	add dl, 30h
	int 21h
	
	mov dl, cl
	add dl, 30h
	int 21h

	pop dx
	pop ax
	ret
OutputNum endp

;Display Updated Score
DisplayScore proc
	mov ah, 02h
	mov bx, 0
	mov dh, 1
	mov dl, 1
	int 10h
	
	lea dx, offset ScoreStr
	mov ah, 09h
	int 21h
	
	mov si, offset Score
	call OutputNum
	
ret
DisplayScore endp

ClearRegisters proc
	mov ax, 0
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov si, 0
	mov di, 0
ret
ClearRegisters endp

DisplayLevel proc
	mov ah, 02h
	mov bx, 0
	mov dh, 1
	mov dl, 32
	int 10h
	
	mov cl, 30h
	add cl, Level
	mov si, offset LevelStr
	mov [si+6] , cl
	
	lea dx, [si]
	mov ah, 09h
	int 21h
	call ClearRegisters
ret
DisplayLevel endp

RemoveLife proc
	push ax
	push bx
	dec Lives							;Comment Out For Infinite Lives

	mov ax, 15
	mov bx, 0
	mov bl, Lives
	mul bl
	
	add ax, 140
	mov xAxis, ax
	mov yAxis, 4
	mov xPixels, 15
	mov yPixels, 15
	mov ah, 0Ch
	mov al, 05h
	call MakeBrick
	
	cmp Lives, 0
	jne GameNotOver
		mov GameInProgress, 0
	GameNotOver:
	
	mov BeepType, 20000
	call SoundBeep
	pop bx
	pop ax
ret
RemoveLife endp

DisplayPrompt proc
	mov ah, 02h
	mov bx, 0
	mov dh, 20
	mov dl, 8
	int 10h

	lea dx, offset InputPrompt
	mov ah, 09h
	int 21h
	
	WaitForInput: 
		mov ah, 01h
		int 16h
	jz WaitForInput
	
	cmp GameInProgress,0 
	je EndGame
	
	cmp Level, 3
	jl EndGame
		mov GameInProgress, 0
		cmp BrickCount, 0
		jne EndGame
			mov GameInProgress, 3
	EndGame:
ret
DisplayPrompt endp

DisplayUserName proc
	mov ah, 02h
	mov dh, 1
	mov dl, 10
	int 10h
	lea dx, UserName
	mov ah, 09h
	int 21h

ret
DisplayUserName endp

TitleScrGraphics proc
	push cx
	push dx
	push bx
	push ax
	
	mov cx, 200
	mov dx, 80
	mov xAxis, cx
	mov yAxis, dx
	mov xPixels, 100
	mov yPixels, 70
	mov al, 00h
	mov bl, 0Fh
	mov ah, 0Ch
	call GridBrick
	
	mov yAxis, 83
	mov xPixels, 10
	mov yPixels, 5
	mov al, 06h
	mov looptemp1, 5
	L1:
		mov looptemp2, 8 
		mov xAxis, 203
		L2:
			call GridBrick
			add xAxis, 12
			add cx, 12
			
			dec looptemp2
		cmp looptemp2, 0
		jne L2
			
		add yAxis, 6
		add dx, 6
		dec looptemp1
	cmp looptemp1, 0
	jne L1
	
	pop ax
	pop bx
	pop dx
	pop cx
ret
TitleScrGraphics endp

Titlescreen proc
	call ColorBackground
	call ClearRegisters
	
	mov ah,02h
	mov dh, 5
	mov dl, 7
	int 10h
	lea dx, Welcome
	mov ah, 09h
	int 21h
	
	mov ah,02h
	mov dh, 7
	mov dl, 10
	int 10h
	lea dx, DevelopedBy
	mov ah, 09h
	int 21h
	
	mov ah,02h
	mov dh, 12
	mov dl, 4
	int 10h
	lea dx, EnterNamePrompt
	mov ah, 09h
	int 21h
		
	mov si, offset UserName
	StayInMenuScreen:
		mov ah, 00h
		int 16h
		cmp al, 13
		je EndTitleScreen
		
		mov [si],al
		mov ah, 02h
		mov bx, 00h
		mov dh, 12
		mov dl, 23
		int 10h
		
		lea dx, UserName
		mov ah, 09h
		int 21h
		
		inc si
	jmp StayInMenuScreen
	
	EndTitleScreen:
ret
Titlescreen endp

Menuscreen proc

	call ColorBackground
	call ClearRegisters
	call DisplayUserName
	call TitleScrGraphics


	mov ah, 02h
	mov dh, 5
	mov dl, 7
	int 10h
	lea dx, GameName
	mov ah, 09h
	int 21h
	
	mov ah, 02h
	mov dh, 10
	mov dl, 10
	int 10h
	lea dx, Option1
	mov ah, 09h
	int 21h
	
	mov ah,02h
	mov dh, 12
	mov dl, 10
	int 10h
	lea dx, Option7
	mov ah, 09h
	int 21h
	
	mov ah, 02h
	mov dh, 14
	mov dl, 10
	int 10h
	lea dx, Option3
	mov ah, 09h
	int 21h
	
	mov ah, 02h
	mov dh, 16
	mov dl, 10
	int 10h
	lea dx, Option4
	mov ah, 09h
	int 21h
	
	mov ah, 02h
	mov dh, 18
	mov dl, 10
	int 10h
	lea dx, Option5
	mov ah, 09h
	int 21h
	
	call Selection
	
	StayInMenuScreen:
		call ClearRegisters
		mov ah, 00h
		int 16h
	
		cmp ah, 48H
		jne next1
		sub Decision, 1	
		.if (Decision == 0)
		mov al, 5
		mov Decision,al
		.endif
		call Selection
		
		next1:
			cmp ah, 50H
			jne next2
			add Decision, 1
			.if (Decision == 6)
			mov al, 1
			mov Decision, al
			.endif
			call Selection
		
		next2:
	cmp al, 13
	je ExitMenuScreen
	jmp StayInMenuScreen

	ExitMenuScreen:
	call ClearRegisters
ret
Menuscreen endp

Selection proc

	mov ah,02h
	mov dh, 10
	mov dl, 5
	int 10h
	lea dx, Fin
	mov ah, 09h
	int 21h

	mov ah,02h
	mov dh, 12
	mov dl, 5
	int 10h
	lea dx, Fin
	mov ah, 09h
	int 21h
	
	mov ah,02h
	mov dh, 14
	mov dl, 5
	int 10h
	lea dx, Fin
	mov ah, 09h
	int 21h
	
	mov ah,02h
	mov dh, 16
	mov dl, 5
	int 10h
	lea dx, Fin
	mov ah, 09h
	int 21h
	
	mov ah,02h
	mov dh, 18
	mov dl, 5
	int 10h
	lea dx, Fin
	mov ah, 09h
	int 21h

	mov bl, Decision
	mov ah, 02h

	mov dl, 5
	.if (bl==1)
	mov dh, 10
	.elseif (bl==2)
	mov dh, 12
	.elseif (bl==3)
	mov dh, 14
	.elseif (bl==4)
	mov dh, 16
	.elseif (bl==5)
	mov dh, 18
	.endif
	
	int 10h
	lea dx, Fou
	mov ah, 09h
	int 21h
	call ClearRegisters
ret
Selection endp

SoundBeep proc
        push ax
        push bx
        push cx
        push dx
		
		call ClearRegisters
		
        mov al, 182         ; Prepare the speaker for the
        out 43h, al 
        mov ax, 400         ; Frequency number (in decimal) for middle C

        out 42h, al         ; Output low byte
        mov al, ah          ; Output high byte
        out 42h, al 
        in  al, 61h         ; Turn on note (get value from port 61h)

        or  al, 00000011b   ; Set bits 1 and 0
        out 61h, al         ; Send new value
        mov bx, 2           ; Pause for duration of note
	Pause1:
        mov cx, BeepType
	Pause2:
        dec cx
        jne pause2
        dec bx
        jne pause1
        in  al, 61h         ; Turn off note (get value from port 61h)

        and al, 11111100b   ; Reset bits 1 and 0
        out 61h, al         ; Send new value

        pop dx
        pop cx
        pop bx
        pop ax
ret
SoundBeep endp

UpdateScore proc

	mov currscore,al
	mov ah, 3DH
	mov al, 02
	mov dx, offset Name_Of_File
	int 21h
	mov var1,ax

	mov ah,3fh
	mov cx,1000
	mov dx,offset prevhighstr
	mov bx,var1
	int 21h

	mov ah, 3Eh
	mov bx, var1
	int 21h

	mov ah,3ch
	mov cx,0
	mov dx,offset Name_Of_File
	int 21h

	mov si,offset prevhighstr
	mov dx,0
	mov bx,0
	mov cx,0
	mov cl,10

	mov bx,0
	mov bl,[si]
	sub bl,'0'
	mov al,bl
	mul cx
	inc si

	mov bx,0
	mov bl,[si]
	sub bl,'0'
	add al,bl
	mul cx
	inc si

	mov bx,0
	mov bl,[si]
	sub bl,'0'
	add al,bl

	mov prevhighdec,al

	.if (currscore>al)

		mov di,offset prevhighuser
		inc si
		inc si
		mov al,[si]
		
		.while (al!='$')
			mov bl,[si]
			mov [di],bl
			inc di
			inc si
			mov al,[si]
		.endw
		mov bl,'$'
		mov [di],bl

		push ax
		push bx
		push cx
		push dx
						
		mov ah, 3DH
		mov al, 02
		mov dx, offset Name_Of_File2nd
		int 21h
		mov var2,ax


		mov ah,3ch
		mov cx,0
		mov dx,offset Name_Of_File2nd
		int 21h
				

		mov si,offset prev2highstr
		mov al,prevhighdec
		mov bl,100
		div bl
		add al,'0'
		mov [si],al
		mov al,ah
		mov ah,0
		mov bl,10
		div bl
		add al,'0'
		inc si
		mov [si],al
		inc si
		add ah,'0'
		mov [si],ah
				
				
		inc si
		mov al,' '
		mov [si],al
		inc si
		mov di,offset prevhighuser
		mov al,[di]
	
		.while (al!='$')
			mov [si],al				
			inc si
			inc di
			mov al,[di]
		.endw
		mov bl,'$'
		mov [si],bl				
				

		mov ah, 3DH
		mov al, 01
		mov dx, offset Name_Of_File2nd
		int 21h
		mov var2,ax

		mov cx,0
		mov dx,0
		mov ah,42h
		mov al,2
		int 21h
		mov ah,40h
		mov bx,var2
		mov cx,20
		mov dx,offset prev2highstr
		int 21h

		mov ah, 3Eh
		mov bx, var2
		int 21h
				

		pop ax
		pop bx
		pop cx
		pop dx

		mov si,offset prevhighstr
		mov al,currscore
		mov bl,100
		div bl
		add al,'0'
		mov [si],al
		mov al,ah
		mov ah,0
		mov bl,10
		div bl
		add al,'0'
		inc si
		mov [si],al
		inc si
		add ah,'0'
		mov [si],ah

		inc si
		mov al,' '
		mov [si],al
		inc si
		mov di,offset UserName
		mov al,[di]
		
		.while (al!='$')
			mov [si],al				
			inc si
			inc di
			mov al,[di]
		.endw
		mov bl,'$'
		mov [si],bl

	.elseif (currscore<al)

	mov ah, 3DH
	mov al, 02
	mov dx, offset Name_Of_File2nd
	int 21h
	mov var2,ax

	mov ah,3fh
	mov cx,1000
	mov dx,offset prev2highstr
	mov bx,var2
	int 21h

	mov ah, 3Eh
	mov bx, var2
	int 21h

	mov ah,3ch
	mov cx,0
	mov dx,offset Name_Of_File2nd
	int 21h

	mov si,offset prev2highstr
	mov dx,0
	mov bx,0
	mov cx,0
	mov cl,10

	mov bx,0
	mov bl,[si]
	sub bl,'0'
	mov al,bl
	mul cx
	inc si

	mov bx,0
	mov bl,[si]
	sub bl,'0'
	add al,bl
	mul cx
	inc si

	mov bx,0
	mov bl,[si]
	sub bl,'0'
	add al,bl

	.if (currscore>al)

		mov si,offset prev2highstr
		mov al,currscore
		mov bl,100
		div bl
		add al,'0'
		mov [si],al
		mov al,ah
		mov ah,0
		mov bl,10
		div bl
		add al,'0'
		inc si
		mov [si],al
		inc si
		add ah,'0'
		mov [si],ah

			
		inc si
		mov al,' '
		mov [si],al
		inc si
		mov di,offset UserName
		mov al,[di]

		.while (al!='$')
			mov [si],al				
			inc si
			inc di
			mov al,[di]
		.endw
		
		mov bl,'$'
		mov [si],bl
	
	.endif

		mov ah, 3DH
		mov al, 01
		mov dx, offset Name_Of_File2nd
		int 21h
		mov var2,ax

		mov cx,0
		mov dx,0
		mov ah,42h
		mov al,2
		int 21h
		mov ah,40h
		mov bx,var2
		mov cx,20
		mov dx,offset prev2highstr
		int 21h


		mov ah, 3Eh
		mov bx, var2
		int 21h

	.endif


	mov ah, 3DH
	mov al, 01
	mov dx, offset Name_Of_File
	int 21h
	mov var1,ax

	mov cx,0
	mov dx,0
	mov ah,42h
	mov al,2
	int 21h
	mov ah,40h
	mov bx,var1
	mov cx,20
	mov dx,offset prevhighstr
	int 21h


	mov ah, 3Eh
	mov bx, var1
	int 21h

ret
updatescore endp


PrintHeart proc
	push cx
	push dx

	;black Outline of Heart
	mov ah, 0Ch
	mov al,0
	mov HeartColor, al 
	mov cx, xAxis
	mov dx, yAxis
	add cx, 2
	
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	add cx, 4
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	mov cx, xAxis
	inc dx
	inc cx
	int 10h
	add cx, 4
	int 10h
	add cx, 2
	int 10h
	add cx, 4
	int 10h
	mov cx, xAxis
	inc dx
	int 10h
	add cx, 6
	int 10h
	add cx, 6
	int 10h
	inc dx
	mov cx, xAxis
	int 10h
	add cx, 12
	int 10h
	inc dx
	mov cx, xAxis
	int 10h
	add cx, 12
	int 10h
	inc dx
	mov cx, xAxis
	int 10h
	add cx, 12
	int 10h
	inc dx
	mov cx, xAxis
	inc cx
	int 10h
	inc cx
	inc dx
	int 10h
	inc cx
	inc dx
	int 10h
	inc cx
	inc dx
	int 10h
	inc cx
	inc dx
	int 10h
	inc cx
	inc dx
	int 10h
	dec dx
	inc cx
	int 10h
	dec dx
	inc cx
	int 10h
	dec dx
	inc cx
	int 10h
	dec dx
	inc cx
	int 10h
	dec dx
	inc cx
	int 10h
	dec dx
	inc cx
	
	;Red Filling of the Heart
	mov ah, 0Ch
	mov al,4
	mov HeartColor, al
	mov cx, xAxis
	mov dx, yAxis
	inc dx
	add cx, 2
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	add cx, 4
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc dx
	mov cx, xAxis
	inc cx
	int 10h
	add cx, 3
	int 10h
	inc cx
	int 10h
	add cx, 2
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc dx
	mov cx, xAxis
	inc cx
	int 10h
	add cx, 2
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc dx
	mov cx, xAxis
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc dx
	mov cx, xAxis
	inc cx
	int 10h
	add cx, 2
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc cx 
	int 10h
	inc dx
	mov cx,xAxis
	add cx, 2
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc dx
	mov cx, xAxis
	add cx, 3
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc dx
	mov cx, xAxis
	add cx, 4
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc dx
	mov cx, xAxis
	add cx, 5
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	inc dx
	mov cx, xAxis
	add cx, 6
	int 10h
	;white part of the PrintHeart
	mov ah, 0Ch
	mov al, 15
	mov HeartColor,al
	mov cx,xAxis
	mov dx,yAxis
	add cx, 2
	add dx, 2
	int 10h
	inc cx
	int 10h
	inc dx
	dec cx
	int 10h
	add dx, 2
	int 10h
	
	pop dx
	pop cx
ret
PrintHeart endp
end