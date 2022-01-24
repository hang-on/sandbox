; boss_lib.asm

.equ BOSS_DEACTIVATED 0
.equ BOSS_ACTIVATED 1

.ramsection "Boss ram section" slot 3
  boss_state db
  boss_y db
  boss_x db
  boss_height db
  boss_width db
  boss_dir db
  boss_index db
  boss_anim_counter dw
  boss_life db

  boss_behavior_counter dw
.ends

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Boss" free
; -----------------------------------------------------------------------------
  initialize_boss:
    LOAD_BYTES boss_state, BOSS_DEACTIVATED
    LOAD_BYTES boss_y, FLOOR_LEVEL+16, boss_x, 225
    LOAD_BYTES boss_dir, LEFT
    LOAD_BYTES boss_height, 24, boss_width, 16
    LOAD_BYTES boss_index, 117

    ld a,(current_level)
    cp 1
    jp nz,+
      LOAD_BYTES boss_state, BOSS_ACTIVATED
    +:

  ret
  ; ---------------------------------------------------------------------------
  
  draw_boss:
    ld a,(boss_state)
    cp BOSS_DEACTIVATED
    ret z

    ld a,(boss_y)
    ld d,a
    ld a,(boss_x)
    ld e,a
    ld a,(boss_index)
    call spr_3x3

    ; Place the tip of the weapon if boss is attacking...

  ret
  ; ---------------------------------------------------------------------------

  update_boss:

  ret

.ends
