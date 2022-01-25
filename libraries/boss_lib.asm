; boss_lib.asm

.equ BOSS_DEACTIVATED 0
.equ BOSS_WALKING 1
.equ BOSS_IDLE 2
.equ BOSS_ATTACKING 3

; Sprite sheet indexes:
.equ BOSS_WALKING_LEFT_0 117
.equ BOSS_WALKING_LEFT_1 120
.equ BOSS_WALKING_RIGHT_0 21
.equ BOSS_WALKING_RIGHT_1 24


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
    LOAD_BYTES boss_index, BOSS_WALKING_LEFT_0
    RESET_COUNTER boss_anim_counter, 11


    .ifdef SPAWN_BOSS_INSTANTLY
      LOAD_BYTES boss_state, BOSS_WALKING
    .endif

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
    ld a,(boss_state)
    cp BOSS_DEACTIVATED
    ret z
    
    call @reorient
    call @move
    call @animate 
  ret
    @reorient:
      ld a,(boss_x)
      ld b,a
      ld a,(player_x)
      sub b
      jp nc,+
        ; Boss is right of the player, face boss left.
        ld a,(boss_dir)
        cp LEFT
        ret z
        ld a,LEFT
        ld (boss_dir),a
        ld a,BOSS_WALKING_LEFT_0
        ld (boss_index),a
        ret
      +:
        ; Boss is left of the player, face boss right.
        ld a,(boss_dir)
        cp RIGHT
        ret z
        ld a,RIGHT
        ld (boss_dir),a
        ld a,BOSS_WALKING_RIGHT_0
        ld (boss_index),a
    ret


    @move:
      ld a,(boss_state)
      cp BOSS_WALKING
      ret nz

      ld a,(odd_frame)
      cp TRUE
      ret nz

      ; Do not crazy-flip the boss when he is on the player.
      ld a,(boss_x)
      ld hl,player_x
      cp (hl)
      ret z

      ld hl,boss_x
      ld a,(boss_dir)
      cp LEFT
      jp nz,+
        dec (hl)  ; Move left.
        jp ++
      +:          
        inc (hl)  ; Move right.
      ++:
    ret

    @animate:
      ld hl,boss_anim_counter
      call tick_counter
      call c,@@update_index
    ret
      @@update_index:
        ld a,(boss_dir)
        cp RIGHT
        jp nz,++
          ; Facing right
          ld a,(boss_index)
          cp BOSS_WALKING_RIGHT_0
          jp nz,+
            ld a,BOSS_WALKING_RIGHT_1
            ld (boss_index),a
            ret
          +:
          ld a,BOSS_WALKING_RIGHT_0
          ld (boss_index),a
          ret
        ++:
        ; Facing left
        ld a,(boss_index)
        cp BOSS_WALKING_LEFT_0
        jp nz,+
          ld a,BOSS_WALKING_LEFT_1
          ld (boss_index),a
          ret
        +:
        ld a,BOSS_WALKING_LEFT_0
        ld (boss_index),a
      ret


.ends
