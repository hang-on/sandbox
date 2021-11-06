; tiny_games.asm.
;
.bank 0 slot 0
.section "Tiny Games Library" free

  spr_2x2:
    ; spr id x y 
    ; IN: A = id, index in the sprite tile bank.
    ;     D = y, E = x (screen position - upper left corner).
    ld c,a
    call add_sprite
    ld a,8
    add e
    ld e,a
    inc c
    call add_sprite
    ld a,32
    add c
    ld c,a
    ld a,8
    add d
    ld d,a
    call add_sprite
    dec c
    ld a,e
    sub 8
    ld e,a
    call add_sprite
  ret

  reset_hl_on_a:
    ; hl = byte-sized var, a = reset threshold.
    ; If value in hl == a, then reset a. 
    ; Uses a,b
    ld b,a
    ld a,(hl)
    cp b
    jp nz,+
      xor a
      ld (hl),a
    +:
  ret

  lookup_a:
    ; IN: a = value, hl = look-up table (ptr).
    ; OUT: a = converted value.
    ld d,0
    ld e,a
    add hl,de
    ld a,(hl)
  ret


.ends