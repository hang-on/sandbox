; boss_lib.asm

.equ BOSS_DEACTIVATED 0
.equ BOSS_WALKING 1
.equ BOSS_IDLE 2
.equ BOSS_ATTACKING 3

; Sprite sheet indexes:
.equ BOSS_WALKING_LEFT_0 117
.equ BOSS_WALKING_LEFT_1 120
.equ BOSS_ATTACKING_LEFT 123
.equ BOSS_ATTACKING_RIGHT 27
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

  boss_counter db
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
    LOAD_BYTES boss_counter, 100

    call get_random_number
    and %00000111
    ld b,a
    ld a,(boss_counter)
    add a,b
    ld (boss_counter),a


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
    ld a,(boss_state)
    cp BOSS_ATTACKING
    ret nz
      ld a,(boss_dir)
      cp LEFT
      jp nz,++
        ld c,180
        ld a,(boss_y)
        sub 8
        ld d,a
        ld a,(boss_x)
        sub 8
        ld e,a
        call add_sprite
        ret          
      ++:
        ld c,148
        ld a,(boss_y)
        sub 8
        ld d,a
        ld a,(boss_x)
        add 24
        ld e,a
        call add_sprite
        ret          

  ret
  ; ---------------------------------------------------------------------------

  update_boss:
    ld a,(boss_state)
    cp BOSS_DEACTIVATED
    ret z
    
    call @animate 
    call @handle_walking
    call @handle_idle
    call @handle_attacking
    call @reorient
    call @move

  ret
    @handle_walking:
      ld a,(boss_state)
      cp BOSS_WALKING
      ret nz

      ld a,(boss_counter)
      dec a
      jp nz,+
        LOAD_BYTES boss_state, BOSS_IDLE
        call get_random_number
        and %00001111               ; Setup a random period for idle.
        add a,40
        ld (boss_counter),a
        ld a,(boss_dir)
        cp LEFT
        jp nz,++
          ld a,BOSS_WALKING_LEFT_0
          jp +++          
        ++:
          ld a,BOSS_WALKING_RIGHT_0
        +++:
        ld (boss_index),a
        ret
      +:
      ; Counter is not up yet.
      ld (boss_counter),a
    ret

    @handle_idle:
      ld a,(boss_state)
      cp BOSS_IDLE
      ret nz

      ld a,(boss_counter)
      dec a
      jp nz,+
        ; Switch to attack or walking?
        call get_random_number
        cp 200
        jp c,++
          ; Switch to walking.
          LOAD_BYTES boss_state, BOSS_WALKING
          call get_random_number
          and %00000111               ; Setup a random period for walking.
          add a,100
          ld (boss_counter),a
          ret
        ++:
          ; Switch to attacking
          LOAD_BYTES boss_state, BOSS_ATTACKING
          LOAD_BYTES boss_counter, 15
          ld a,(boss_dir)
          cp LEFT
          jp nz,++
            ld a,BOSS_ATTACKING_LEFT
            jp +++          
          ++:
            ld a,BOSS_ATTACKING_RIGHT
          +++:
          ld (boss_index),a
          ret
      +:
      ; Counter is not up yet.
      ld (boss_counter),a
    ret

    @handle_attacking:
      ld a,(boss_state)
      cp BOSS_ATTACKING
      ret nz

      ld a,(boss_counter)
      dec a
      jp nz,+
        ; Counter up, back to walking
        LOAD_BYTES boss_state,BOSS_WALKING
        LOAD_BYTES boss_counter, 100
        ld a,(boss_index)
        sub 6
        ld (boss_index),a
        ret
      +:
      ld (boss_counter),a
    ret

    @reorient:
      ld a,(boss_state)
      cp BOSS_ATTACKING
      ret z

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
      ld a,(boss_state)
      cp BOSS_WALKING
      ret nz
      
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
