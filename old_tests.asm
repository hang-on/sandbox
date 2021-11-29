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
    ASSERT_A_EQUALS MINION_MOVING

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

    ; Test 11: Move minion left
    jp +
      minion_test_data_c:
        .db MINION_MOVING
        ;   y    x    d     i  t  f  h   v
        .db 127, 250, LEFT, 0, 0, 0, -1, 0
        .db MINION_DEACTIVATED
        .db 0 0 0 0 0 0 0 0
        .db MINION_DEACTIVATED
        .db 0 0 0 0 0 0 0 0
    +:
    ld hl,minion_test_data_c
    call initialize_minions
    ld ix,minions.1
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 250
    ld a,(ix+minion.hspeed)
    ASSERT_A_EQUALS -1
    call process_minions
    ld ix,minions.1
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 249

    ; Test 12: Move 2 minions left
    jp +
      minion_test_data_d:
        .db MINION_MOVING
        ;   y    x    d     i  t  f  h   v
        .db 127, 250, LEFT, 0, 0, 0, -1, 0
        .db MINION_DEACTIVATED
        .db 0 0 0 0 0 0 0 0
        .db MINION_MOVING
        ;   y    x    d     i  t  f  h   v
        .db 127, 120, LEFT, 0, 0, 0, -1, 0
    +:
    ld hl,minion_test_data_d
    call initialize_minions
    call process_minions
    ld ix,minions.1
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 249
    ld ix,minions.3
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 119
    call process_minions
    ld ix,minions.1
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 248
    ld ix,minions.3
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 118
    ld ix,minions.2
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 0

    ; Test 13: Jump 1 minion left
    jp +
      minion_test_data_e:
        .db MINION_MOVING
        ;   y    x    d     i  t  f  h   v
        .db 127, 250, LEFT, 0, 0, 0, -1, -1
        .db MINION_DEACTIVATED
        .db 0 0 0 0 0 0 0 0
        .db MINION_IDLE
        ;   y    x    d     i  t  f  h  v
        .db 127, 120, LEFT, 0, 0, 0, 0, 0
    +:
    ld hl,minion_test_data_e
    call initialize_minions
    call process_minions
    ld ix,minions.1
    ld a,(ix+minion.x)
    ASSERT_A_EQUALS 249
    ld a,(ix+minion.y)
    ASSERT_A_EQUALS 126




    ld hl,anim_init
    ld de,anim_0
    call init_looping_bytestream
           

  anim_0 dsb MINION_FRAMES+2


  anim_init:
    .db 0 15 $86 $86 $86 $86 $86 $86 $86 $86 $88 $88 $88 $88 $88 $88 $88 $88

.equ MINION_FRAMES 16

; -----------------------------------------------------------------------------
.section "Looping Bytestreams" free
; -----------------------------------------------------------------------------
  ; A looping bytestream is a simple 8-bit table with a header that consists
  ; of an index and a threshold. The index is automatically incremented on
  ; every read from the stream, and when it reaches the threshold, it is
  ; reset (thus it loops). After it is initialized, the stream can be inter-
  ; faced with a function that will read and return the next byte from the 
  ; stream, and increment or reset (to 0) the internal index as necessary.

  init_looping_bytestream:
    ; Initialize a block in RAM to work as a looping bytestream.
    ; Init data must have the following format:
    ; header [ii tt] stream[ bb bb bb...], where ii is the starting index,
    ; tt is the threshold (the loop point) and bb is a array of bytes the size
    ; of tt+1.
    ; In:   hl = Ptr. to init data.
    ;       de = Ptr. to looping bytestream.
    inc hl            ; Step forward to threshold.
    ld a,(hl)         ; Get threshold value.
    add a,3           ; Account for the bytestream's 2-byte header, and 0.
    ld b,0            ; Set up BC as a counter, least significant byte first.            
    ld c,a            ; The threshold value will control the LDIR below.
    dec hl            ; Step backwards to index (start of looping bytestream).
    ldir              ; Load the required amount of initialization data.
  ret                 

  get_next_byte:
    ; Get the next byte in the stream. Then increment or reset (loop) the
    ; bytestream index.
    ; In:   hl = Ptr. to looping bytestream.
    ; Out:  a = byte from stream.   
    push hl           ; Save the bytestream pointer for later.
      ld a,(hl)       ; Get the current index.
      ld d,0          ; Load DE with the index
      ld e,a          ; 
      add hl,de       ; Offset HL by [index] number of bytes.
      inc hl          ; Account for the first header byte (index).
      inc hl          ; Account for the second header byte (loop threshold).
      ld a,(hl)       ; Get the byte from the bytestream.
    pop hl            ; Restore the original bytestream pointer.
    push af           ; Save the bytestream byte.
      ld a,(hl)       ; Get the current index.
      inc hl          ; Point to the loop threshold.
      ld b,(hl)       ; Load B with the loop threshold.
      dec hl          ; Point back to the current index.
      cp b            ; Is the current index = the loop threshold?
      jp nz,+         ; 
        xor a         ; Yes, time to reset the index. 
        ld (hl),a     ; Reset index.
        jp ++         ; 
      +:              ; No, just increment the index.
        inc (hl)      ; Increment index pointed to by HL.
      ++:             ;
    pop af            ; Restore the bytestream byte to A.
  ret


.ends



; Old data:
  my_word:
    .dw $1234

; For testing looping bytestreams:

 ; Ramsection:
  my_looping_bytestream dsb 10

  data_0:
    .db 0, 7, 1, 2, 3, 4, 5, 6, 7, 8

  data_1:
    .db 1, 7, 1, 2, 3, 4, 5, 6, 7, 8

  data_3:
    .db 7, 7, 1, 2, 3, 4, 5, 6, 7, 8



; -----------------------------------------------------------------------------
; Old tests:

; Test get_word
    ld hl,my_word
    call get_word
    ASSERT_HL_EQUALS $1234

    ld hl,data_0
    ld de,my_looping_bytestream
    call init_looping_bytestream
    ld hl,my_looping_bytestream
    call get_next_byte
    ASSERT_A_EQUALS 1

    ld hl,data_0
    ld de,my_looping_bytestream
    call init_looping_bytestream
    ld hl,my_looping_bytestream
    call get_next_byte
    ld hl,my_looping_bytestream
    call get_next_byte
    ASSERT_A_EQUALS 2

    ld hl,data_1
    ld de,my_looping_bytestream
    call init_looping_bytestream
    ld hl,my_looping_bytestream
    call get_next_byte
    ASSERT_A_EQUALS 2

    ld hl,data_3
    ld de,my_looping_bytestream
    call init_looping_bytestream
    ld hl,my_looping_bytestream
    call get_next_byte
    ASSERT_A_EQUALS 8

    ld hl,data_3
    ld de,my_looping_bytestream
    call init_looping_bytestream
    ld hl,my_looping_bytestream
    call get_next_byte
    ld hl,my_looping_bytestream
    call get_next_byte    
    ASSERT_A_EQUALS 1

    ld hl,data_3
    ld de,my_looping_bytestream
    call init_looping_bytestream
    ld hl,my_looping_bytestream
    call get_next_byte
    ld hl,my_looping_bytestream
    call get_next_byte    
    ld hl,my_looping_bytestream
    call get_next_byte    
    ASSERT_A_EQUALS 2

    ld hl,data_0
    ld de,my_looping_bytestream
    call init_looping_bytestream
    ld hl,my_looping_bytestream
    ASSERT_HL_POINTS_TO_STRING 10, data_0



