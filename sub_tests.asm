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

.macro RESET_SLOW_COUNTER ARGS DATA SIZE
   ld hl,DATA
   ld de,my_slow_counter
   ld bc,SIZE
   ldir
.endm

.macro ADD_DATA
  jp +
    __:
      .rept NARGS
        .db \1
        .shift
      .endr
  +:
.endm

; -----------------------------------------------------------------------------
.section "tests" free
  test_bench:
    ; Test tick 1:
    ADD_DATA 255, 2
    RESET_SLOW_COUNTER _b, 2
    ld hl,my_slow_counter
    call tick_slow_counter
    ld hl,my_slow_counter
    ld a,(hl)
    ASSERT_A_EQUALS 254

    ; Test reset:
    ADD_DATA 00, 2
   RESET_SLOW_COUNTER _b, 2
   ld hl,my_slow_counter
   call tick_slow_counter
   ld hl,my_slow_counter
   ld a,(hl)
   ASSERT_A_EQUALS 255

    ; Test reset and dec cycle counter:
  ADD_DATA 1,2
   RESET_SLOW_COUNTER _b, 2
   ld hl,my_slow_counter
   call tick_slow_counter
   ld hl,my_slow_counter
   ld a,(hl)
   ASSERT_A_EQUALS 0
   ld a,(my_slow_counter+1)
   ASSERT_A_EQUALS 1

    ; Test carry set on counter up:
   ADD_DATA 1, 0, 3
   RESET_SLOW_COUNTER _b, 3
   ld hl,my_slow_counter
   call tick_slow_counter
   ASSERT_CARRY_SET
   
    ; Test carry reset on not counter up:
  ADD_DATA 1, 1, 3
   RESET_SLOW_COUNTER _b, 3
   ld hl,my_slow_counter
   call tick_slow_counter
   ASSERT_CARRY_RESET

  ; Test:
  ADD_DATA 1, 1, 3
  RESET_SLOW_COUNTER _b, 3
  ld hl,my_slow_counter
  call tick_slow_counter
  ADD_DATA 0, 0, 3
  ld hl,my_slow_counter
  ASSERT_HL_POINTS_TO_STRING 3,_b

  ; Test counter reset:
  ADD_DATA 1, 0, 3
  RESET_SLOW_COUNTER _b, 3
  ld hl,my_slow_counter
  call tick_slow_counter
  ADD_DATA 0, 3, 3
  ld hl,my_slow_counter
  ASSERT_HL_POINTS_TO_STRING 3, _b

  ; ------- end of tests --------------------------------------------------------
  .equ TEST_SUCCES 1      ; Palette colors.
  .equ TEST_FAILED 2

  exit_with_succes:
    ld a,TEST_SUCCES
    ld b,BORDER_COLOR
    call set_register
  -:
    nop
  jp -

  exit_with_failure:
    ld a,TEST_FAILED
    ld b,BORDER_COLOR
    call set_register
  -:
    nop
  jp -
 

.ends
