  .ramsection "Test kernel" slot 3
    ; For faking writes to vram.
    ; 7 bytes! - update RESET macro if this changes!
      test_kernel_source dw
      test_kernel_bank db
      test_kernel_destination dw
      test_kernel_bytes_written dw
  .ends

.macro RESET_TEST_KERNEL
  ld hl,test_kernel_source
  ld a,0
  .rept 7
    ld (hl),a
    inc hl
  .endr
.endm

.macro SET_RANDOM_NUMBER
  ld a,\1
  ld (random_number),a
.endm

.macro ASSERT_A_EQUALS
  cp \1
  jp nz,exit_with_failure
  nop
.endm

.macro ASSERT_A_EQUALS_NOT
  cp \1
  jp z,exit_with_failure
  nop
.endm

.macro ASSERT_HL_EQUALS ; (value)
  push de
  push af
  ld de,\1
  ld a,d
  cp h
  jp nz,exit_with_failure
  ld a,e
  cp l
  jp nz,exit_with_failure
  pop af
  pop de
.endm

.macro ASSERT_TOP_OF_STACK_EQUALS ; (list of bytes to test)
  ld hl,0
  add hl,sp
  .rept NARGS
    ld a,(hl)
    cp \1
    jp nz,exit_with_failure
    inc hl
    ;inc sp                    ; clean stack as we proceed.
    .SHIFT
  .endr
.endm

.macro ASSERT_TOP_OF_STACK_EQUALS_STRING ARGS LEN, STRING
  ; Parameters: Pointer to string, string length. 
  ld de,STRING                ; Comparison string in DE
  ld hl,0                     ; HL points to top of stack.
  add hl,sp       
  .rept LEN                   ; Loop through given number of bytes.
    ld a,(hl)                 ; Get byte from stack.
    ld b,a                    ; Store it.
    ld a,(de)                 ; Get comparison byte.
    cp b                      ; Compare byte on stack with comparison byte.
    jp nz,exit_with_failure   ; Fail if not equal.
    inc hl                    ; Point to next byte in stack.
    inc de                    ; Point to next comparison byte.
  .endr
  ;.rept LEN                   ; Clean stack to leave no trace on the system.
  ;  inc sp        
  ;.endr
.endm

.macro ASSERT_HL_POINTS_TO_STRING ARGS LEN, STRING
  ; Parameters: Pointer to string, string length. 
  ld de,STRING                ; Comparison string in DE
  .rept LEN                   ; Loop through given number of bytes.
    ld a,(hl)                 ; Get byte
    ld b,a                    ; Store it.
    ld a,(de)                 ; Get comparison byte.
    cp b                      
    jp nz,exit_with_failure   ; Fail if not equal.
    inc hl                    ; Point to next byte.
    inc de                    ; Point to next comparison byte.
  .endr
.endm

.macro ASSERT_CARRY_SET 
  jp nc,exit_with_failure
  nop
.endm

.macro ASSERT_CARRY_RESET 
  jp c,exit_with_failure
  nop
.endm


.macro CLEAN_STACK
  .rept \1
    inc sp
  .endr
.endm

.ramsection "Fake VRAM stuff" slot 3
  fake_sat_y dsb 64
  fake_sat_xc dsb 128
.ends
; -----------------------------------------------------------------------------
; Definitions:
;
.

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Test data" free
  ; Put data here.

    minion_test_data_5:
      .db MINION_IDLE
      .db 0 0 0 0 0 0 0 0
      .db MINION_DEACTIVATED
      .db 0 0 0 0 0 0 0 0
      .db MINION_DEACTIVATED
      .db 0 0 0 0 0 0 0 0
    __:

    minion_test_data_b:
      .db MINION_IDLE
      .db 0 0 0 0 0 0 0 0
      .db MINION_IDLE
      .db 0 0 0 0 0 0 0 0
      .db MINION_IDLE
      .db 0 0 0 0 0 0 0 0
    __:


.ends

; -----------------------------------------------------------------------------
.section "tests" free
  test_bench:
    ; These are the tests:
    
    ;Test Init
    ld hl,minion_init_data
    call initialize_minions
    ld ix,minions
    ld a,(ix+minion.state)
    ASSERT_A_EQUALS MINION_DEACTIVATED
    
    ;Test Init_2
    ld hl,minion_init_data
    call initialize_minions
    ld ix,minions.3.state
    ld a,(ix+minion.state)
    ASSERT_A_EQUALS MINION_DEACTIVATED

    ;Test Init_3
    ld hl,minion_init_data
    call initialize_minions
    ld ix,minions.3.state
    ld a,(ix+minion.y)
    ASSERT_A_EQUALS 0

    ; Test 4: spawn minion in slot 
    ld hl,minion_init_data
    call initialize_minions
    call spawn_minion
    ld ix,minions.1
    ld a,(ix+minion.state)
    ASSERT_A_EQUALS MINION_IDLE

    ;Test 5: Init 
    ld hl,minion_test_data_5
    call initialize_minions
    ld ix,minions
    ld a,(ix+minion.state)
    ASSERT_A_EQUALS MINION_IDLE

    ;Test 6: Spawn 
    ld hl,minion_test_data_5
    call initialize_minions
    call spawn_minion
    ld ix,minions.2
    ld a,(ix+minion.state)
    ASSERT_A_EQUALS MINION_IDLE
    ld ix,minions.3
    ld a,(ix+minion.state)
    ASSERT_A_EQUALS MINION_DEACTIVATED

   ;Test 7: Failed spawn (all idle)
    ld hl,minion_test_data_b
    call initialize_minions
    call spawn_minion
    ASSERT_CARRY_SET

    ; Test 8: Spawn facing left
    ld hl,minion_test_data_5
    call initialize_minions
    SET_RANDOM_NUMBER 0
    call spawn_minion
    ld ix,minions.2
    ld a,(ix+minion.direction)
    ASSERT_A_EQUALS LEFT

    ; Test 9: Spawn facing right, in the left side.
    ld hl,minion_test_data_5
    call initialize_minions
    SET_RANDOM_NUMBER 1
    call spawn_minion
    ld ix,minions.2
    ld a,(ix+minion.direction)
    ASSERT_A_EQUALS RIGHT
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 0

    ; Test 10: Spawn facing left, in the right side.
    ld hl,minion_test_data_5
    call initialize_minions
    SET_RANDOM_NUMBER 0
    call spawn_minion
    ld ix,minions.2
    ld a,(ix+minion.direction)
    ASSERT_A_EQUALS LEFT
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 250


  ; ------- end of tests --------------------------------------------------------
  exit_with_succes:
    ld a,7
    ld b,BORDER_COLOR
    call set_register
  -:
    nop
  jp -

  exit_with_failure:
    ld a,4
    ld b,BORDER_COLOR
    call set_register
  -:
    nop
  jp -
 

.ends
