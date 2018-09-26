START           ORG $0

* Constants
SCREEN_SIZE     EQU 400
TILE_SIZE       EQU 10
GRID_WIDTH      EQU 40
GRID_HEIGHT     EQU 40
BLACK           EQU $00000000
MAROON          EQU $00000080
GREEN           EQU $00008000
OLIVE           EQU $00008080
NAVY            EQU $00800000
PURPLE          EQU $00800080
TEAL            EQU $00808000
GRAY            EQU $00808080
RED             EQU $000000FF
LIME            EQU $0000FF00
YELLOW          EQU $0000FFFF
BLUE            EQU $00FF0000
FUCHSIA         EQU $00FF00FF
AQUA            EQU $00FFFF00
LTGRAY          EQU $00C0C0C0
WHITE           EQU $00FFFFFF

* Set screen resolution to 400x400
RES     LEA SCREEN_SIZE,A0
        MOVE.L A0,D1 ; Move the screen width into D1.
        ASL #4,D1 ; Shift over to the right-most bytes.
        ADD.L A0,D1 ; Move the screen height into D1.
        MOVE.B #33,D0
        TRAP #15 ; Set screen resolution.

* Enable keyboard input
        MOVE.W #$0103,D1
        MOVE.B #62,D0
        TRAP #15

* Initialize the board state.
* The board will be a GRID_WIDTHxGRID_HEIGHT grid.
* Each grid position can have three states:
*   0 (empty)
*   1 (snake)
*   2 (food)
* We start by setting them all to empty.
* Memory layout: $1000 -> ...
* Row by row.
        LEA GRID_HEIGHT,A0 ; Get grid constants
        MOVE.W A0,D2
        LEA GRID_WIDTH,A0
        MOVE.W A0,D3

        MOVE.W #$1000,A0 ; Address to write to
        MOVE.W #0,D0 ; y counter
INIT_GRIDY   ; y loop
        MOVE.W #0,D1 ; x counter
INIT_GRIDX   ; x loop
        MOVE.W #0,(A0) ; Write a 0 into the grid
        ADDA #$2,A0 ; Increment address for next spot
        ADDI #1,D1 ; Increment x
        CMP D1,D3
        BNE INIT_GRIDX ; Break out of the x loop?
        ADDI #1,D0 ; Increment y
        CMP D0,D2
        BNE INIT_GRIDY ; Break out of the y loop?

* Initialize snake body memory.
* Snake length at $2000 starts at 0.
* Ring buffer start location at $2002 starts at $2004.

        MOVE.W #$2000,A0
        MOVE.W #0,(A0)
        
        MOVE.W #$2002,A0
        MOVE.W #$2004,(A0)
        ; Add a snake body at 0, 0
        MOVE.W #0,-(A7)
        MOVE.W #0,-(A7)
        MOVE.W #0,-(A7)
        JSR ADD_SNAKE_BODY
        ADD.W #6,A7

* Draw the border.
        LEA  WHITE,A0 ; Set pen to White
        MOVE.L A0,D1
        MOVE.B #80,D0
        TRAP #15

        MOVE.L #0,D1 ; Draw an empty rectangle with a white border.
        MOVE.L #0,D2
        MOVE.L #402,D3
        MOVE.L #402,D4
        MOVE.B #90,D0
        TRAP #15

        BRA GAME_LOOP

* Subroutine RENDER_GRID() - Render the grid.
RENDER_GRID
        LEA GRID_HEIGHT,A0 ; Get grid constants
        MOVE.W A0,D2
        LEA GRID_WIDTH,A0
        MOVE.W A0,D3

        MOVE.W #$1000,A1 ; Address to read from
        MOVE.W #0,D0 ; y counter
RENDER_GRIDY   ; y loop
        MOVE.W #0,D1 ; x counter
RENDER_GRIDX   ; x loop
        MOVE.W D1,-(A7)
        MOVE.W D0,-(A7)
        MOVE.W (A1),-(A7)
        ; DRAW_TILE uses all the data registers, so we have to copy out our D2-D3 to the stack too.
        MOVE.W D2,-(A7)
        MOVE.W D3,-(A7)
        JSR DRAW_TILE
        ; Read D0-D4 back from the stack.
        MOVEM.W 6(A7),D0
        MOVEM.W 8(A7),D1
        MOVEM.W (A7),D3
        MOVEM.W 2(A7),D2
        ADD.W #10,A7

        ADDA #$2,A1 ; Increment address for next spot
        ADDI #1,D1 ; Increment x
        CMP D1,D3
        BNE RENDER_GRIDX ; Break out of the x loop?
        ADDI #1,D0 ; Increment y
        CMP D0,D2
        BNE RENDER_GRIDY ; Break out of the y loop?

        RTS

* Subroutine DRAW_TIME(x, y, tile_type) - Draws tile type at x, y.
* tile_type can be one of 0 (empty), 1 (snake), 2 (food)
DRAW_TILE
        CLR D2
        CLR D5
        CLR D6
        MOVE.W 12(A7),D5 ; Get x, y.
        MOVE.W 10(A7),D6
        MOVE.W 8(A7),D2 ; Get tile_type.

        CMP #1,D2
        BEQ SNAKE_STYLE
        CMP #2,D2
        BEQ FOOD_STYLE
        BRA EMPTY_STYLE

EMPTY_STYLE
        LEA BLACK,A0 ; Set pen and fill color to Black
        MOVE.L A0,D1
        MOVE.B #80,D0
        TRAP #15
        MOVE.B #81,D0
        TRAP #15
        BRA _DRAW_TILE

SNAKE_STYLE
        LEA FUCHSIA,A0 ; Set pen and fill color to Fuchsia
        MOVE.L A0,D1
        MOVE.B #80,D0
        TRAP #15
        MOVE.B #81,D0
        TRAP #15
        BRA _DRAW_TILE

FOOD_STYLE
        LEA RED,A0 ; Set pen and fill color to Red
        MOVE.L A0,D1
        MOVE.B #80,D0
        TRAP #15
        MOVE.B #81,D0
        TRAP #15
        BRA _DRAW_TILE

_DRAW_TILE
        LEA TILE_SIZE,A0 ; Draw a rectangle at x * SQUARESIZE + 1, y * SQUARESIZE + 1
                         ; with size SQUARESIZE, SQUARESIZE.
        MOVE.L A0,D7
        MOVE.L D5,D1      ; Calculate left position
        MULS D7,D1
        ADDI #1,D1
        MOVE.L D6,D2      ; Calculate top position
        MULS D7,D2
        ADDI #1,D2
        MOVE.L D1,D3      ; Calculate right position
        ADD.L D7,D3
        MOVE.L D2,D4      ; Calculate bottom position
        ADD.L D7,D4
        MOVE.B #87,D0
        TRAP #15
        
        RTS

* Subroutine ADD_SNAKE_BODY(x, y, remove_tail) - Adds a snake body part at (x, y) and adds it to the head of the snake in memory.
* If the remove word is 1, it will remove the tail of the snake too.
* The snake body parts are stored in the grid, but we also need to store the order that the snake parts are in
* relative to each other so that we can move them in unison, and add dynamically.
* To do this, we use a ring buffer in memory to represent a list of pointers to snake parts.
* The ring buffer is of size GRID_WIDTH*GRID_HEIGHT.
* At $2000, the length of the snake is stored (word).
* At $2002, the position of the snake's head is stored.
* [0, 0] -> [1, 0] -> [2, 0]
* tail                head
* [0, 0] -> [1, 0] -> [2, 0] -> [3, 0]
*           ^                   head
* The buffer's size is GRID_WIDTH*GRID_HEIGHT.
* Each position in the buffer stores the address of the snake body in the grid.
ADD_SNAKE_BODY
        MOVE.W 4(A7),D3 ; Get remove_tail
        MOVE.W 6(A7),D1 ; Get x, y
        MOVE.W 8(A7),D0
        LEA GRID_WIDTH,A0 ; Get grid width
        MOVE.W A0,D2
        MULS D1,D2 ; Compute the position in memory of that x, y address on the grid.
        ADD D0,D2
        ASL #1,D2 ; Multiple by 2 because we're using words (2 bytes).
        ADDI #$1000,D2
        MOVE.W D2,A0 ; Address to write to
        MOVE.W #1,(A0)

        ; Get the length of the snake.
        MOVE.W #$2000,A0
        MOVE.W (A0),D0
        
        ; Get the ring buffer's start position.
        MOVE.W #$2002,A0
        MOVE.W (A0),D1

        CMP #1,D3
        BEQ REMOVE_TAIL

        ; Increment the length of the snake.
        ADDI #1,D0
        MOVE.W #$2000,A0
        MOVE.W D0,(A0)
        BRA ADD_TO_BUFFER

REMOVE_TAIL
        ; Delete the snake body from the board at the ring buffer's start position (the tail of the snake).
        MOVE.W D1,A1
        MOVE.W (A1),A2
        MOVE.W #0,(A2)

        ; Increment the ring buffer's start position.
        ADDI #2,D1
        MOVE.W D1,(A0)

ADD_TO_BUFFER
        ; Note: Possible overflow.

        ; Write the new snake part's address into the list at the ring buffer's location + (length - 1).
        SUBI #1,D0
        ASL #1,D0
        ADD D0,D1
        MOVE.W D1,A0
        MOVE.W D2,(A0)

        RTS

* Subroutine MOVE_SNAKE() - Moves the entire snake in whatever direction its moving.
MOVE_SNAKE
        ; Get keys and store in D7.
        MOVE.L #'W'<<24+'A'<<16+'S'<<8+'D',D1 ; check for keypress (w,a,s,d).

        MOVE.B #19,D0
        TRAP   #15

        MOVE.L D1,D7

        ; Get the head of the snake's x and y.
        ; Get the snake's length.
        MOVE.W #$2000,A0
        MOVE.W (A0),D0

        ; Get the ring buffer's start position.
        MOVE.W #$2002,A0
        MOVE.W (A0),D1

        ; Get the memory address of the snake head in the grid from the buffer.
        SUBI #1,D0
        ASL #1,D0
        ADD D0,D1
        MOVE.W D1,A0
        MOVE.W (A0),D0

        ; Extract x and y from the grid address.
        SUBI #$1000,D0
        ASR #1,D0 ; Divide by 2 because we're using words (2 bytes).
        LEA GRID_WIDTH,A0 ; Get grid width
        MOVE.W A0,D1
        DIVS D1,D0 ; Divide by grid width.
        ; Remainder is the x, result is the y.
        ; Remainder in upper 16 bits.
        MOVE.L D0,D1 ; y
        SWAP D1
        CLR D1 ; Clear upper 16 bits.
        SWAP D1

        SWAP D0 ; x

        BTST.L #24,D7
        BNE W_PRESSED
        BTST.L #16,D7
        BNE A_PRESSED
        BTST.L #8,D7
        BNE S_PRESSED
        BTST.L #0,D7
        BNE D_PRESSED
        ; Default to moving right for now.
        ADDI #1,D0 ; Increment x to move right
        BRA PROCESS_MOVEMENT
W_PRESSED
        SUBI #1,D1 ; Decrement y to move up
        BRA PROCESS_MOVEMENT
A_PRESSED
        SUBI #1,D0 ; Decrement x to move left
        BRA PROCESS_MOVEMENT
S_PRESSED
        ADDI #1,D1 ; Increment y to move down
        BRA PROCESS_MOVEMENT
D_PRESSED
        ADDI #1,D0 ; Increment x to move right
        BRA PROCESS_MOVEMENT
PROCESS_MOVEMENT
        ; Assuming snake direction is right for now.
        MOVE.W D0,-(A7)
        MOVE.W D1,-(A7)
        MOVE.W #1,-(A7)
        JSR ADD_SNAKE_BODY
        ADD.W #6,A7

* Subroutine GAME_LOOP() - Runs the main game loop.
GAME_LOOP
        JSR RENDER_GRID
        JSR MOVE_SNAKE
        BRA GAME_LOOP

STOP    MOVE.B #9,D0
        TRAP #15
        
        END START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~