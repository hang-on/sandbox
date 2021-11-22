

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



