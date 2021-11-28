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
  ; Use to test writes to the SAT buffer
  fake_sat_index db
  fake_sat_y dsb 64
  fake_sat_xc dsb 128
.ends
.macro RESET_FAKE_SAT
  ld hl,fake_sat_index
  ld b,1+64+128
  xor a
  -:
    ld (hl),a
    inc hl
  djnz -
.endm


; -----------------------------------------------------------------------------
; Definitions:
;
.

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Test data" free
  ; Put data here.


.ends

; -----------------------------------------------------------------------------
.section "tests" free
  test_bench:
    ; Test 1: Do not process deactivated minions.
    jp +
      minion_test_data_a:
        .db MINION_ACTIVATED
        ;   y    x    d     i  t  f  h   v
        .db 127, 250, LEFT, 0, 0, 0, -1, 0
        .db MINION_DEACTIVATED
        .db 0 0 0 0 0 0 0 0
        .db MINION_DEACTIVATED
        ;   y    x    d     i  t  f  h  v
        .db 127, 120, LEFT, 0, 0, 0, -1, 0
    +:
    ld hl,minion_test_data_a
    call initialize_minions
    call process_minions
    ld ix,minions.1
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 249
    ld ix,minions.3
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 120

    ; Test 2: Deactivate minion over limit.
    jp +
      minion_test_data_b:
        .db MINION_ACTIVATED
        ;   y    x             d     i  t  f  h   v
        .db 127, LEFT_LIMIT-1, LEFT, 0, 0, 0, -1, 0
        .db MINION_DEACTIVATED
        .db 0 0 0 0 0 0 0 0
        .db MINION_DEACTIVATED
        ;   y    x    d     i  t  f  h  v
        .db 127, 120, LEFT, 0, 0, 0, -1, 0
    +:
    ld hl,minion_test_data_b
    call initialize_minions
    call process_minions
    ld ix,minions.1
    ld a,(ix+minion.state)
    ASSERT_A_EQUALS MINION_DEACTIVATED

    ; Test 3: Do not Deactivate minion on limit.
    jp +
      minion_test_data_c:
        .db MINION_ACTIVATED
        ;   y    x           d     i  t  f  h   v
        .db 127, LEFT_LIMIT, LEFT, 0, 0, 0, -1, 0
        .db MINION_DEACTIVATED
        .db 0 0 0 0 0 0 0 0
        .db MINION_DEACTIVATED
        ;   y    x    d     i  t  f  h  v
        .db 127, 120, LEFT, 0, 0, 0, -1, 0
    +:
    ld hl,minion_test_data_c
    call initialize_minions
    call process_minions
    ld ix,minions.1
    ld a,(ix+minion.state)
    ASSERT_A_EQUALS MINION_ACTIVATED

    ; Test 4: Deactivate minion over right limit.
    jp +
      minion_test_data_d:
        .db MINION_ACTIVATED
        ;   y    x              d      i  t  f  h  v
        .db 127, RIGHT_LIMIT+1, RIGHT, 0, 0, 0, 1, 0
        .db MINION_DEACTIVATED
        .db 0 0 0 0 0 0 0 0
        .db MINION_DEACTIVATED
        ;   y    x    d     i  t  f  h  v
        .db 127, 120, LEFT, 0, 0, 0, -1, 0
    +:
    ld hl,minion_test_data_d
    call initialize_minions
    call process_minions
    ld ix,minions.1
    ld a,(ix+minion.state)
    ASSERT_A_EQUALS MINION_DEACTIVATED

    ; Test 5: Put an activated minion in the SAT buffer.
    jp +
      minion_test_data_e:
        .db MINION_ACTIVATED
        ;   y    x            d      i    t  f  h  v
        .db 127, RIGHT_LIMIT, RIGHT, $86, 0, 0, 1, 0
        .db MINION_DEACTIVATED
        .db 0 0 0 0 0 0 0 0
        .db MINION_DEACTIVATED
        ;   y    x    d     i  t  f  h  v
        .db 127, 120, LEFT, 0, 0, 0, -1, 0
      
        str_e:
          .db RIGHT_LIMIT+1, $86
    +:
    RESET_FAKE_SAT
    ld hl,minion_test_data_e
    call initialize_minions
    call process_minions
    call draw_minions
    ld hl,fake_sat_xc
    ASSERT_HL_POINTS_TO_STRING 2, str_e 
    ld hl,fake_sat_y
    ld a,(hl)
    ASSERT_A_EQUALS 127 

    ; Test 6: Put an activated minion in the SAT buffer.
    jp +
      minion_test_data_f:
        .db MINION_ACTIVATED
        ;   y    x            d      i    t  f  h  v
        .db 127, RIGHT_LIMIT, RIGHT, $86, 0, 0, 1, 0
        .db MINION_DEACTIVATED
        .db 0 0 0 0 0 0 0 0
        .db MINION_ACTIVATED
        ;   y    x    d     i  t  f  h  v
        .db 127, 120, LEFT, $86, 0, 0, -1, 0
      
        str_f1:
          .db RIGHT_LIMIT+1, $86
        str_f2:
          .db 119, $86

    +:
    RESET_FAKE_SAT
    ld a,(fake_sat_index)
    ASSERT_A_EQUALS 0
    ld hl,minion_test_data_f
    call initialize_minions
    call process_minions
    ld a,(fake_sat_index)
    ASSERT_A_EQUALS 0
    call draw_minions
    ld a,(fake_sat_index)
    ASSERT_A_EQUALS 2
    ld hl,fake_sat_xc
    ASSERT_HL_POINTS_TO_STRING 2, str_f1 
    ld hl,fake_sat_y
    ld a,(hl)
    ASSERT_A_EQUALS 127 
    ld hl,fake_sat_y+1
    ld a,(hl)
    ASSERT_A_EQUALS 127 
    ld hl,fake_sat_y+2
    ld a,(hl)
    ASSERT_A_EQUALS 0
    ld hl,fake_sat_xc+2
    ld a,(hl)
    ASSERT_A_EQUALS 119 
    inc hl
    ld a,(hl)
    ASSERT_A_EQUALS $86 


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
