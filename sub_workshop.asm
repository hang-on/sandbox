
.ramsection "Ram section for library being developed" slot 3

  my_looping_bytestream dsb 10

.ends


.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------

  init_looping_bytestream:
    ; Initialize a block in RAM to work as a looping bytestream.
    ; In: hl = Ptr. to init data.
    ;     de = Ptr. to looping bytestream.
    inc hl
    ld a,(hl)
    add a,2
    ld b,a
    ld c,0
    dec hl
    ldir
  ret

  get_next_byte:    
    push hl
      ld a,(hl)
      ld d,0
      ld e,a
      add hl,de
      inc hl
      inc hl
      ld a,(hl)
    pop hl
    push af
      ld a,(hl) 
      inc hl
      ld b,(hl)
      dec hl
      cp b
      jp nz,+
        xor a
        ld (hl),a
        jp ++   
      +:
        inc (hl)
      ++:
    pop af
  ret


.ends

