
.ramsection "Ram section for library being developed" slot 3

.ends


.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------

  get_next_byte:    
    call @get_byte
    
  ret

  @get_byte:
    ld a,(hl)
    ld d,0
    ld e,a
    add hl,de
    inc hl
    inc hl
    ld a,(hl)
  ret


.ends

