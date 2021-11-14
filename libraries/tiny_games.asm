; tiny_games.asm.
;

.macro RESET_VARIABLES ARGS VALUE
  ; Set one or more byte-sized vars in RAM with the specified value.
  ld a,VALUE
  .rept NARGS-1
    .shift
    ld (\1),a
  .endr
.endm

.macro RESET_BLOCK ARGS VALUE, START, SIZE
  ; Reset af block of RAM of SIZE bytes to VALUE, starting from label START.
  ld a,VALUE
  ld hl,START
  .rept SIZE
    ld (hl),a
    inc hl
  .endr
.endm

.macro LOAD_BYTES
  ; IN: Pair of byte-sized variable and value to load
  .rept (NARGS/2)
    ld a,\2
    ld (\1),a
    .shift
    .shift
  .endr
.endm

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