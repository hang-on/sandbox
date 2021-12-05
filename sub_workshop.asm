
.ramsection "Ram section for library being developed" slot 3

.ends

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------

  mockup_dashboard:
    .db $fc $fc $e6 $e7 $e8 $e5 $e9 $ed $fa $fa $fa $fa $fa $fa $fc $fc $fc
    .db $ea $eb $e6 $e7 $e8 $e5 $e9 $ed $fa $fa $fa $fa $fa $fa
    .db $fc $fc $fc $e0 $e1 $e2 $e3 $e4 $e5
    .db $ee $ef $ef $ef $ef $ef $ef $ef $ef $ef $ef $ef $ef $f0 $f1 $fc 
    .db $e2 $eb $ec $e9 $ed $fa $fa $fc
  __:

  copy_string_to_nametable:
    ; hl = string to copy (source)
    ; c = length of string (len)
    ; b = nametable index (destination)
    ; a = use tiles spritebank? true/false
    push af
      push hl
        ld hl,NAME_TABLE_START
        ld a,b
        cp 0
        jp z,+
          -:    ; Apply offset per index.
            inc hl
            inc hl
          djnz -
        +:
        call setup_vram_write
      pop hl
    pop af
    cp TRUE
    jp nz,+
      ; Use tiles in sprite bank.
      ld b,c
      -:
      ld a,(hl)
        out (DATA_PORT),a
        push ix
        pop ix
        xor a
        out (DATA_PORT),a
        inc hl
      djnz -
      ret
    +:
      ; Use tiles in background bank 
      ld a,(hl)
        out (DATA_PORT),a
        push ix
        pop ix
        ld a,%00000001
        out (DATA_PORT),a
        inc hl
      djnz -
  ret

.ends