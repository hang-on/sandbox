
.equ MINION_DEACTIVATED $ff
.equ MINION_ACTIVATED 0
.equ MINION_MAX 3


.struct minion
  state db
  y db
  x db
  direction db
  index db
  timer db
  frame db
  hspeed db
  vspeed db
.endst

.ramsection "Ram section for library being developed" slot 3
  random_number db
  minions INSTANCEOF minion 3
.ends

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------
  draw_minions:
    ; Put non-deactivated minions in the SAT buffer.
    ld ix,minions
    ld b,MINION_MAX
    -:                          ; For all non-deactivated minions, do...
      push bc                   ; Save loop counter.
        ld a,(ix+minion.state)
        cp MINION_DEACTIVATED
        jp z,+
          ld d,(ix+minion.y)
          ld e,(ix+minion.x)
          ld a,(ix+minion.index); FIXME: Depending on direction and state!
          call spr_2x2          ; + animation...
        +:
        ld de,_sizeof_minion    
        add ix,de               ; Point ix to next minion.
      pop bc                    ; Restore loop counter.
    djnz -                      ; Process next minion.
  ret

  process_minions:
    ld ix,minions
    ld b,MINION_MAX
    -:                          ; For all non-deactivated minions, do...
      push bc                   ; Save loop counter.
        ld a,(ix+minion.state)
        cp MINION_DEACTIVATED
        jp z,+
          call @check_limit
          call @move            ; Apply h- and vspeed to x and y.
          call @animate
          ; ...
        +:
        ld de,_sizeof_minion    
        add ix,de               ; Point ix to next minion.
      pop bc                    ; Restore loop counter.
    djnz -                      ; Process next minion.
  ret
    @check_limit:
      ld a,(ix+minion.direction)
      cp LEFT
      jp nz,+
        ; Facing left - check if over left limit.
        ld a,(ix+minion.x)
        cp LEFT_LIMIT
        call c,deactivate_minion
        ret
      +:
        ; Facing right - check if over right limit.
        ld a,(ix+minion.x)
        cp RIGHT_LIMIT+1
        call nc,deactivate_minion
    ret

    @move:
      ld a,(is_scrolling)
      cp TRUE
      jp nz,+
        ld a,(ix+minion.x)
        add a,(ix+minion.hspeed)
        sub 1
        ld (ix+minion.x),a
        jp ++
      +: 
        ld a,(ix+minion.x)
        add a,(ix+minion.hspeed)
        ld (ix+minion.x),a
      ++:
      ld a,(ix+minion.y)
      add a,(ix+minion.vspeed)
      ld (ix+minion.y),a
    ret

    @animate:
      ;ld a,20
      ;ld (ix+minion.timer),a
      ld a,(ix+minion.timer)
      dec a
      jp nz,+
        call @@update_index
        ld a,20
      +:
      ld (ix+minion.timer),a
    ret
      @@update_index:
        ld a,$88
        ld (ix+minion.index),a
      ret

  deactivate_minion:  
      ld a,MINION_DEACTIVATED
      ld (ix+minion.state),a
  ret

  spawn_minion:
    ; Spawn a minion.
    ld ix,minions
    ld b,MINION_MAX
    -:
      ld a,(ix+minion.state)
      cp MINION_DEACTIVATED
      jp z,@activate
      ld de,_sizeof_minion
      add ix,de
    djnz -
    scf   ; Set carry = failure (no deactivated minion to spawn).
  ret
    @activate:  
      ld a,MINION_ACTIVATED
      ld (ix+minion.state),a
      call get_random_number
      bit 0,a
      jp z,+
        ; Spawn a minion at the left side, facing right.
        ld a,RIGHT
        ld (ix+minion.direction),a
        ld a,FLOOR_LEVEL
        ld (ix+minion.y),a
        ld a,0
        ld (ix+minion.x),a
        ld a,2
        ld (ix+minion.hspeed),a
        ld a,$80
        ld (ix+minion.index),a
        jp ++
      +:
        ; Spawn a minion on the right side, facing left.
        ld a,LEFT
        ld (ix+minion.direction),a
        ld a,FLOOR_LEVEL
        ld (ix+minion.y),a
        ld a,250
        ld (ix+minion.x),a
        ld a,-2
        ld (ix+minion.hspeed),a
        ld a,$86
        ld (ix+minion.index),a
      ++:
      or a    ; Reset carry = succes.
    ret
  ret
  
  minion_init_data:
    .rept MINION_MAX
      .db MINION_DEACTIVATED
      .rept _sizeof_minion-1
        .db 0
      .endr
    .endr
    __:

  initialize_minions:
    ; In: hl = ptr. to init data.
    ld de,minions
    ld bc,_sizeof_minion_init_data
    ldir
  ret
.ends

.bank 0 slot 0
