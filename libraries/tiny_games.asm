; tiny_games.asm.
;
.bank 0 slot 0
.section "Tiny Games Library" free

  spr:
    ; spr id x y w h
    ; IN: A = id, index in the sprite tile bank.
    ;     B = x, C = y (screen position - upper left corner).
    ;     D = w, E = h (composite sprite widht and height).
    ;     

    ld de,$1010
    ld c,1
    call add_sprite
    ld de,$1018
    ld c,2
    call add_sprite
    ld de,$1810
    ld c,33
    call add_sprite
    ld de,$1818
    ld c,34
    call add_sprite

  ret

.ends