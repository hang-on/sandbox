; The brute

.equ BRUTE_DEACTIVATED $ff
.equ BRUTE_ACTIVATED 0
.equ BRUTE_HURTING 1

; Sprite sheet indexes:
.equ BRUTE_WALKING_LEFT_0 85
.equ BRUTE_WALKING_LEFT_1 87
.equ BRUTE_WALKING_RIGHT_0 21
.equ BRUTE_WALKING_RIGHT_1 23
.equ BRUTE_HURTING_LEFT 89
.equ BRUTE_HURTING_RIGHT 25
.equ BRUTE_SWORD_LEFT 180
.equ BRUTE_SWORD_RIGHT 148

.equ BRUTE_DIRECTION_COUNTER_INIT_VALUE 90


.ramsection "Brute ram section" slot 3
  brute_state db
  brute_y db
  brute_x db
  brute_dir db
  brute_index db
  brute_hspeed db
  brute_timer db

  brute_spawn_counter dw
  brute_spawn_chance db
  brute_hurt_counter db
  brute_attack_counter dw
  brute_direction_counter dw


.ends

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Brute" free
; -----------------------------------------------------------------------------
  ; INIT:
  initialize_brute:
    LOAD_BYTES brute_state, BRUTE_DEACTIVATED
    LOAD_BYTES brute_spawn_chance, 10
    RESET_BLOCK 50, brute_spawn_counter, 2
    LOAD_BYTES brute_index, $55
    LOAD_BYTES brute_y, FLOOR_LEVEL, brute_x, 180
    LOAD_BYTES brute_hspeed, -1
    LOAD_BYTES brute_hurt_counter, 10
    LOAD_BYTES brute_dir, LEFT
    LOAD_BYTES brute_timer, 9
    RESET_BLOCK 20, brute_attack_counter, 2
    RESET_BLOCK BRUTE_DIRECTION_COUNTER_INIT_VALUE, brute_direction_counter, 2

  ret
  ; --------------------------------------------------------------------------- 
  ; DRAW:
  draw_brute:
    ld a,(brute_state)
    cp BRUTE_DEACTIVATED
    ret z

    ld a,(brute_y)
    ld d,a
    ld a,(brute_x)
    ld e,a
    ld a,(brute_index)
    call spr_2x2
    
    ; Place the sword:
    ld a,(brute_dir)
    cp LEFT
    jp nz,+
      ld hl,@left
      jp ++      
    +:
      ld hl,@right
    ++:
    ld a,(brute_y)
    add a,(hl)
    ld d,a
    ld a,(brute_x)
    inc hl
    add a,(hl)
    ld e,a
    inc hl
    ld a,(hl)
    ld c,a
    call add_sprite
  ret
    @left:
      .db 8, -8, BRUTE_SWORD_LEFT
    @right:
      .db 8, 16, BRUTE_SWORD_RIGHT
  ; --------------------------------------------------------------------------- 
  ; UPDATE:
  process_brute:
    ld a,(brute_state)
    cp BRUTE_DEACTIVATED
    jp nz,+
      ld a,(end_of_map)       ; If Brute is deactivated...
      cp FALSE                ; And we are NOT at the map's end...
      call z,@roll_for_spawn  ; Then roll to see if the Brute respawns.
      ret
    +:
    call @clip_at_borders
    call @check_collision
    call @reorient
    call @move            
    call @animate
    call @hurt
  ret
    @clip_at_borders:
      ld a,(brute_dir)
      cp LEFT
      jp nz,+
        ; Facing left - check if over left limit.
        ld a,(brute_x)
        cp LEFT_LIMIT
        call c,deactivate_brute
        ret
      +:
        ; Facing right - check if over right limit.
        ld a,(brute_x)
        cp RIGHT_LIMIT+1
        call nc,deactivate_brute
    ret
    @check_collision:
      ; Axis-aligned bounding box.
      ld a,(state)        ; Only check for collision if player
      cp ATTACKING        ; is attacking og jump-attacking.
      jp z,+
      cp JUMP_ATTACKING
      jp z,+
        ret
      +:
      ld a,(brute_state)  ; Don't check if Brute is already hurting.
      cp BRUTE_HURTING
      ret z

      ld iy,killbox_y     ; Put the player's killbox in IY.

      ; Test 1.
      ld a,(iy+1)         
      add a,(iy+3)
      ld b,a
      ld a,(brute_x)
      cp b
      ret nc
        ; Test 2.
        ld a,(brute_x)
        add a,16
        ld b,a
        ld a,(iy+1)
        cp b
        ret nc
          ;Test 3.
          ld a,(iy+0)
          add a,(iy+2)
          ld b,a
          ld a,(brute_y)
          cp b
          ret nc
            ; Test 4.
            ld a,(brute_y)
            add a,16
            ld b,a
            ld a,(iy+0)
            cp b
            ret nc
      ; Fall through to collision! Hurt the brute.
      ld hl,hurt_sfx
      ld c,SFX_CHANNELS2AND3                  
      call PSGSFXPlay              
      ;      
      ld a,BRUTE_HURTING
      ld (brute_state),a
      ld a,10
      ld (brute_hurt_counter),a
      ld a,(brute_dir)
      cp RIGHT
      jp nz,+
        ; Looking right
        ld a,BRUTE_HURTING_RIGHT
        ld (brute_index),a
        ret
      +:
        ; Looking left
        ld a,BRUTE_HURTING_LEFT
        ld (brute_index),a
    ret 
    @reorient:
      ld hl,brute_direction_counter
      call tick_counter
      ret nc
        ; Counter is up - time to reorient Brute.
        ld a,(brute_x)
        ld b,a
        ld a,(player_x)
        sub b
        jp nc,+
          ; Brute is right of the player, face brute left.
          ld a,LEFT
          ld (brute_dir),a
          ld a,BRUTE_WALKING_LEFT_0
          ld (brute_index),a
          ret
        +:
          ; Brute is left of the player, face brute right.
          ld a,RIGHT
          ld (brute_dir),a
          ld a,BRUTE_WALKING_RIGHT_0
          ld (brute_index),a
    ret

    @hurt:
      ld a,(brute_state)
      cp BRUTE_HURTING
      ret nz
      
      ld a,(brute_hurt_counter)
      dec a
      ld (brute_hurt_counter),a
      call z,deactivate_brute
    ret

    @move:
      ld a,(brute_state)
      cp BRUTE_HURTING
      ret z

      ld hl,brute_x
      ld a,(brute_dir)
      cp LEFT
      jp nz,+
        dec (hl)  ; Move left.
        jp ++
      +:          
        inc (hl)  ; Move right.
      ++:
    ret

    @animate:
      ld a,(brute_state)
      cp BRUTE_HURTING
      ret z
      ;
      ld a,(brute_timer)
      dec a
      jp nz,+
        call @@update_index
        ld a,9                    ; Load timer reset value.
      +:
      ld (brute_timer),a      ; Reset the timer.
    ret
      @@update_index:
        ld a,(brute_dir)
        cp RIGHT
        jp nz,++
          ; Facing right
          ld a,(brute_index)
          cp BRUTE_WALKING_RIGHT_0
          jp nz,+
            ld a,BRUTE_WALKING_RIGHT_1
            ld (brute_index),a
            ret
          +:
          ld a,BRUTE_WALKING_RIGHT_0
          ld (brute_index),a
          ret
        ++:
        ; Facing left
        ld a,(brute_index)
        cp BRUTE_WALKING_LEFT_0
        jp nz,+
          ld a,BRUTE_WALKING_LEFT_1
          ld (brute_index),a
          ret
        +:
        ld a,BRUTE_WALKING_LEFT_0
        ld (brute_index),a
      ret
    @roll_for_spawn:
      ld hl,brute_spawn_counter
      call tick_counter
      jp nc,+                   ; Skip forward if the counter is not up.
        ld a,(brute_spawn_chance)
        add a,5
        ld (brute_spawn_chance),a
        ld b,a
        call get_random_number  ; Counter is up - get a random number 0-255.
        cp b                   ; Roll under the spawn chance.
        jp nc,+
          call spawn_brute     ; OK.
          ld a,5
          ld (brute_spawn_chance),a
      +:
    ret

  deactivate_brute:  
      ld a,BRUTE_DEACTIVATED
      ld (brute_state),a
      ld a,(end_of_map)
      cp TRUE
      jp z,+
        ld a,TRUE
        ld (scroll_enabled),a ; FIXME: This should not be set from within here.?
      +:
  ret

  spawn_brute:
    ; Spawn the brute.
      ld a,BRUTE_ACTIVATED
      ld (brute_state),a
      ; Spawn a minion on the right side, facing left.
      ld a,LEFT
      ld (brute_dir),a
      ld a,FLOOR_LEVEL
      ld (brute_y),a
      ld a,250
      ld (brute_x),a
      ld a,-1
      ld (brute_hspeed),a
      ld a,BRUTE_WALKING_LEFT_0
      ld (brute_index),a
      ld a,200
      ld (brute_direction_counter),a

      ld a,9
      ld (brute_timer),a
      ld a,FALSE
      ld (scroll_enabled),a

  ret

.ends

