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

  lookup_byte:
    ; IN: a = value, hl = look-up table (ptr).
    ; OUT: a = converted value.
    ld d,0
    ld e,a
    add hl,de
    ld a,(hl)
  ret

  lookup_word:
    ; IN: a = value, hl = look-up table (ptr).
    ; OUT: hl = converted value (word).
    add a,a
    ld d,0
    ld e,a
    add hl,de
    ld a,(hl)
    ld b,a
    inc hl
    ld a,(hl)
    ld h,a
    ld l,b
  ret

  tick_counter:
    ; hl = counter + reset value.
    ; set carry on count down.
    ld a,(hl)
    dec a
    jp nz,+
      inc hl
      ld a,(hl)
      dec hl
      ld (hl),a
      scf
      ret
    +:
    ld (hl),a
    or a
  ret

.ends