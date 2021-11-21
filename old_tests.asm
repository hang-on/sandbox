; Old data:
  my_word:
    .dw $1234



; -----------------------------------------------------------------------------
; Old tests:

; Test get_word
    ld hl,my_word
    call get_word
    ASSERT_HL_EQUALS $1234
