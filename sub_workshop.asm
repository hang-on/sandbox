
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
          call @check_collision
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

    @check_collision:
      ; Axis aligned bounding box:
      ;    if (rect1.x < rect2.x + rect2.w &&
      ;    rect1.x + rect1.w > rect2.x &&
      ;    rect1.y < rect2.y + rect2.h &&
      ;    rect1.h + rect1.y > rect2.y)
      ;    ---> collision detected!
      ; ---------------------------------------------------
      ; IN: IX = Pointer to minion struct. (rect 1)
      ;     IY = Pointer to killbox struct (y, x, height, width of rect2.)
      ; OUT:  Carry set = collision / not set = no collision.
      ;
      ; rect1.x < rect2.x + rect2.width
      ;
      ld a,(state)
      cp ATTACKING
      jp z,+
      cp JUMP_ATTACKING
      jp z,+
        ret
      +:
      ld iy,killbox_y

      ld a,(iy+1)
      add a,(iy+3)
      ld b,a
      ld a,(ix+minion.x)
      cp b
      ret nc
        ; rect1.x + rect1.width > rect2.x
        ld a,(ix+minion.x)
        add a,16
        ld b,a
        ld a,(iy+1)
        cp b
        ret nc
          ; rect1.y < rect2.y + rect2.height
          ld a,(iy+0)
          add a,(iy+2)
          ld b,a
          ld a,(ix+minion.y)
          cp b
          ret nc
            ; rect1.y + rect1.height > rect2.y
            ld a,(ix+minion.y)
            add a,16
            ld b,a
            ld a,(iy+0)
            cp b
            ret nc
      call deactivate_minion
    ret ; Return with carry set.


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
      ld a,(ix+minion.timer)
      dec a
      jp nz,+
        call @@update_index
        ld a,5                    ; Load timer reset value.
      +:
      ld (ix+minion.timer),a      ; Reset the timer.
    ret
      @@update_index:
        ld a,(ix+minion.direction)
        cp RIGHT
        jp nz,++
          ; Facing right
          ld a,(ix+minion.index)
          cp $80
          jp nz,+
            ld a,$82
            ld (ix+minion.index),a
            ret
          +:
          ld a,$80
          ld (ix+minion.index),a
          ret
        ++:
        ; Facing left
        ld a,(ix+minion.index)
        cp $86
        jp nz,+
          ld a,$88
          ld (ix+minion.index),a
          ret
        +:
        ld a,$86
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
      ld a,5
      ld (ix+minion.timer),a
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
