
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
START           ORG $0

* Constants
SCREEN_SIZE     EQU 640
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

* Set screen resolution to SCREEN_SIZExSCREEN_SIZE (min: 640x480)
RES     LEA SCREEN_SIZE,A0
        MOVE.L A0,D1 ; Move the screen width into D1.
        SWAP D1     ; Move the screenwidth into upper 16 bits of D1
        ADD.L A0,D1 ; Move the screen height into lower 16 bits of D1.
        MOVEQ #33,D0
        TRAP #15 ; Set screen resolution.

* Enable keyboard input
        MOVE.W #$0103,D1
        MOVEQ #62,D0
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
        MULS D3,D2 ; Compute how many steps would be in loop

        MOVE.W #$1000,A0 ; Address to write to
BOARD_STATE_LOOP ; There always will be at least one iteration
        MOVE.W #0,(A0)+ ; Write a 0 into the grid
        SUBQ #1,D2 ; Decrement number of remaining steps
        BNE BOARD_STATE_LOOP ; Branch if number of remaining steps is greater than 0

        ; Initialize time since spawned food to 0.
        MOVE.W #$992,A0
        MOVE.L #0,(A0)

        ; Default to moving right.
        MOVE.W #$998,A0
        MOVE.W #3,(A0)

        ; Initialize snake body memory.
        ; Snake length at $2000 starts at 0.
        ; Ring buffer start location at $2002 starts at $2004.

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

        ; Draw the border.
        LEA  WHITE,A0 ; Set pen to White
        MOVE.L A0,D1
        MOVEQ #80,D0
        TRAP #15

        MOVE.L #0,D1 ; Draw an empty rectangle with a white border.
        MOVE.L #0,D2
        MOVE.L #402,D3
        MOVE.L #402,D4
        MOVEQ #90,D0
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
        MOVE.W (A1),D4
        MOVEM.W D1/D0/D4/D2/D3,-(A7)
        ; DRAW_TILE uses all the data registers, so we have to copy out our D2-D3 to the stack too.
        JSR DRAW_TILE
        ; Read D0-D4 back from the stack.
        MOVEM.W (A7),D3/D2/D4/D0/D1
        ADD.W #10,A7

        ADDA #$2,A1 ; Increment address for next spot
        ADDQ #1,D1 ; Increment x
        CMP D1,D3
        BNE RENDER_GRIDX ; Break out of the x loop?
        ADDQ #1,D0 ; Increment y
        CMP D0,D2
        BNE RENDER_GRIDY ; Break out of the y loop?

        RTS

* Subroutine DRAW_TIME(x, y, tile_type) - Draws tile type at x, y.
* tile_type can be one of 0 (empty), 1 (snake), 2 (food)
DRAW_TILE
        MOVE.W 4(A7),D6
        MOVE.W 6(A7),D5 ; Get x, y.
        MOVE.W 12(A7),D2 ; Get tile_type.

        CMP #1,D2
        BEQ SNAKE_STYLE
        CMP #2,D2
        BEQ FOOD_STYLE
        BRA EMPTY_STYLE

EMPTY_STYLE
        LEA BLACK,A0 ; Set pen and fill color to Black
        MOVE.L A0,D1
        MOVEQ #80,D0
        TRAP #15
        MOVEQ #81,D0
        TRAP #15
        BRA _DRAW_TILE

SNAKE_STYLE
        LEA FUCHSIA,A0 ; Set pen and fill color to Fuchsia
        MOVE.L A0,D1
        MOVEQ #80,D0
        TRAP #15
        MOVEQ #81,D0
        TRAP #15
        BRA _DRAW_TILE

FOOD_STYLE
        LEA RED,A0 ; Set pen and fill color to Red
        MOVE.L A0,D1
        MOVEQ #80,D0
        TRAP #15
        MOVEQ #81,D0
        TRAP #15
        BRA _DRAW_TILE

_DRAW_TILE
        LEA TILE_SIZE,A0 ; Draw a rectangle at x * SQUARESIZE + 1, y * SQUARESIZE + 1
                         ; with size SQUARESIZE, SQUARESIZE.
        MOVE.L A0,D7
        MOVE.L D5,D1      ; Calculate left position
        MULS D7,D1
        ADDQ #1,D1
        MOVE.L D6,D2      ; Calculate top position
        MULS D7,D2
        ADDQ #1,D2
        MOVE.L D1,D3      ; Calculate right position
        ADD.L D7,D3
        MOVE.L D2,D4      ; Calculate bottom position
        ADD.L D7,D4
        MOVEQ #87,D0
        TRAP #15
        
        RTS

* Subroutine GET_GRID_OBJ(x, y) - Returns the value on the grid at x, y.
* Puts the result into D7.
GET_GRID_OBJ
        MOVE.W 4(A7),D1 ; Get x, y
        MOVE.W 6(A7),D0
        LEA GRID_WIDTH,A0 ; Get grid width
        MOVE.W A0,D2
        MULS D1,D2 ; Compute the position in memory of that x, y address on the grid.
        ADD D0,D2
        ASL #1,D2 ; Multiple by 2 because we're using words (2 bytes).
        ADDI #$1000,D2
        MOVE.W D2,A0 ; Address to read from
        MOVE.W (A0),D7 ; Return result in D7
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
        ADDQ #1,D0
        MOVE.W #$2000,A0
        MOVE.W D0,(A0)
        BRA ADD_TO_BUFFER

REMOVE_TAIL
        ; Delete the snake body from the board at the ring buffer's start position (the tail of the snake).
        MOVE.W D1,A1
        MOVE.W (A1),A2
        MOVE.W #0,(A2)

        ; Increment the ring buffer's start position.
        ADDQ #2,D1
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

        MOVEQ #19,D0
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
        CLR D1 ; Clear lower 16 bits.
        SWAP D1

        SWAP D0 ; x

        ; Read direction from memory.
        ; Directions:
        ;  0 = up
        ;  1 = left
        ;  2 = down
        ;  3 = right
        MOVE.W #$998,A0
        MOVE.W (A0),D2

        BTST.L #24,D7
        BNE W_PRESSED
        BTST.L #16,D7
        BNE A_PRESSED
        BTST.L #8,D7
        BNE S_PRESSED
        BTST.L #0,D7
        BNE D_PRESSED
        ; If no key pressed, continue moving in the same direction.
        BRA PROCESS_MOVEMENT
W_PRESSED
        MOVEQ #0,D2
        BRA UPDATE_DIR
A_PRESSED
        MOVEQ #1,D2
        BRA UPDATE_DIR
S_PRESSED
        MOVEQ #2,D2
        BRA UPDATE_DIR
D_PRESSED
        MOVEQ #3,D2
        BRA UPDATE_DIR
UPDATE_DIR
        ; Update direction in memory.
        MOVE.W D2,(A0)
PROCESS_MOVEMENT
        ; Update x and y based on direction.
        CMP #0,D2
        BEQ MOVING_UP
        CMP #1,D2
        BEQ MOVING_LEFT
        CMP #2,D2
        BEQ MOVING_DOWN
        BRA MOVING_RIGHT
MOVING_UP
        SUBQ #1,D1
        BRA FINISHED_MOVING
MOVING_LEFT
        SUBQ #1,D0
        BRA FINISHED_MOVING
MOVING_DOWN
        ADDQ #1,D1
        BRA FINISHED_MOVING
MOVING_RIGHT
        ADDQ #1,D0
        BRA FINISHED_MOVING
FINISHED_MOVING
        MOVE.W D0,-(A7)
        MOVE.W D1,-(A7)
        JSR GET_GRID_OBJ
        ADD.W #4,A7

        MOVE.W #1,D2
        CMP #2,D7 ; There is food at where we're moving to.
        BNE ADD_HEAD
        MOVE.W #0,D2
ADD_HEAD
        MOVE.W D0,-(A7)
        MOVE.W D1,-(A7)
        MOVE.W D2,-(A7)
        JSR ADD_SNAKE_BODY
        ADD.W #6,A7
        RTS

* Subroutine ADD_FOOD() - Adds food onto the grid.
ADD_FOOD
        MOVEQ #8,D0
        TRAP #15
        MOVE.L D1,D0
        MOVE.L #$992,A0
        MOVE.L D0,D3
        SUB.L (A0),D3
        CMP #500,D3
        BRA ACTUALLY_ADD_FOOD
        RTS
ACTUALLY_ADD_FOOD
        MOVE.L D0,(A0)
        ; Compute a random address to start searching for where to place the food.
        ; The food cannot be placed on top of the snake.
        LEA GRID_HEIGHT,A0 ; Get grid constants
        MOVE.W A0,D2
        LEA GRID_WIDTH,A0
        MOVE.W A0,D3
        MULS D3,D2 ; Multiply WIDTH * HEIGHT to get total grid spaces.
        MOVE.W D2,D3 ; Store total amount of different indicies.
        ASL #1,D2 ; Multiply by 2 for words.
        ADDI #$1000,D2 ; Get end position.
        DIVS D3,D1 ; Divide time / total different indicies.
        CLR D1
        SWAP D1 ; Get remainder.
        ASL #1,D1 ; Multiply by 2 for words.
        ADDI #$1000,D1 ; Get address in grid offset randomly (but in bounds).
        MOVE.W D1,A0
        MOVE.B #0,D7 ; Put a 0 in D7, which means we haven't done one full search sweep yet.
SEARCH_LOOP
        MOVE.W (A0),D0
        CMP #0,D0 ; Space is empty.
        BEQ VALID_SPACE
        ADDQ #2,A0 ; Increment the search address.
        CMP D2,A0 ; Check if search address goes out of bounds.
        BLT SEARCH_LOOP
        CMP #1,D7
        BEQ NO_VALID_SPACES ; Already done one full loop
        MOVE.W #$1000,A0 ; Back to start.
        MOVE.B #1,D7 ; Gone back to start once.
        BRA SEARCH_LOOP
NO_VALID_SPACES
        RTS
VALID_SPACE
        MOVE.W #2,(A0) ; Put the food in that space.
        RTS

* Subroutine GAME_LOOP() - Runs the main game loop.
GAME_LOOP
        JSR RENDER_GRID
        JSR MOVE_SNAKE
        JSR ADD_FOOD
        BRA GAME_LOOP

STOP    MOVEQ #9,D0
        TRAP #15
        
        END START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
