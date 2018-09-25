START ORG $1000


* Set screen resolution to 400x400
RES
        LEA SCREENSIZE,A0
        MOVE.L A0,D1 ; Move the screen width into D1.
        MULS $10000,D1 ; Shift to right-most bytes.
        ADD.L A0,D1 ; Move the screen height into D1.
        MOVE.B #33,D0
        TRAP #15 ; Set screen resolution.

* Draw border around the screen.
SCREEN  LEA  WHITE,A0 ; Set pen to White
	    MOVE.L A0,D1
	    MOVE.B #80,D0
	    TRAP #15

	    MOVE.L #0,D1 ; Draw border.
	    MOVE.L #0,D2
	    MOVE.L #400,D3
	    MOVE.L #400,D4
	    MOVE.B #90,D0
	    TRAP #15

        ; Push x and y on the stack.
        MOVE.L #5,D0
        MOVE.L #10,D1
        MOVE.L D0,-(A7)
        MOVE.L D1,-(A7)
        JSR SNAKE
        ADD.W #8,A7

        ; Push x and y on the stack.
        MOVE.L #10,D0
        MOVE.L #10,D1
        MOVE.L D0,-(A7)
        MOVE.L D1,-(A7)
        JSR SNAKE
        ADD.W #8,A7

        BRA END

* Draw snake body part
* Uses x, y on the stack for the position.
* Position on the screen is x * SQUARESIZE, y * SQUARESIZE.
SNAKE   LEA FUCHSIA,A0 ; Set pen and fill color to Fuchsia
	    MOVE.L A0,D1
	    MOVE.B #80,D0
	    TRAP #15
	    MOVE.B #81,D0
	    TRAP #15
	    
	    MOVE.L 8(A7),D5 ; Pop x and y off the stack.
	    MOVE.L 4(A7),D6
        
        LEA SQUARESIZE,A0 ; Draw a rectangle at x * SQUARESIZE, y * SQUARESIZE
                          ; with size SQUARESIZE, SQUARESIZE.
        MOVE.L A0,D7
        MOVE.L D5,D1      ; Calculate left position
        MULS D7,D1
        MOVE.L D6,D2      ; Calculate top position
        MULS D7,D2
        MOVE.L D1,D3      ; Calculate right position
        ADD.L D7,D3
        MOVE.L D2,D4      ; Calculate bottom position
        ADD.L D7,D4
	    MOVE.B #87,D0
	    TRAP #15
	    
	    RTS

END     MOVE.B #9,D0
        TRAP #15

SCREENSIZE EQU 400
SQUARESIZE EQU 10
BLACK   EQU $00000000
MAROON  EQU $00000080
GREEN   EQU $00008000
OLIVE   EQU $00008080
NAVY    EQU $00800000
PURPLE  EQU $00800080
TEAL    EQU $00808000
GRAY    EQU $00808080
RED     EQU $000000FF
LIME    EQU $0000FF00
YELLOW  EQU $0000FFFF
BLUE    EQU $00FF0000
FUCHSIA EQU $00FF00FF
AQUA    EQU $00FFFF00
LTGRAY  EQU $00C0C0C0
WHITE   EQU $00FFFFFF
	  
	    END START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
