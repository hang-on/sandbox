; Mighty knights


.macro TRANSITION_PLAYER_STATE ARGS NEWSTATE, SFX
  ; Perform the standard actions when the player's state transitions:
  ; 1) Load new state into state variable, 2) reset animation frame and
  ; 3) (optional) play a sound effect.
  LOAD_BYTES state, NEWSTATE, frame, 0      ; Set the state and frame variables.
  .IF NARGS == 2                            ; Is an SFX pointer provided?
    ld hl,SFX                               ; If so, point HL to the SFX-data.
    ld c,SFX_CHANNELS2AND3                  ; Set the channel.
    call PSGSFXPlay                         ; Play the SFX with PSGlib.
  .ENDIF
.endm

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Mighty Knights Library" free
; -----------------------------------------------------------------------------

  detect_collision:
    ; IN: IX = y,x,height,width rect 1
    ;     IY = y,x,height,width rect2

    ; Horizontal checks:
    ; rect1.x < rect2.x + rect2.width
    ld a,(iy+1)
    add a,(iy+3)
    ld b,a
    ld a,(ix+1)
    cp b
    ret nc
    ; rect1.x + rect1.width > rect2.x
    ld a,(ix+1)
    add a,(ix+3)
    ld b,a
    ld a,(iy+1)
    cp b
    ret nc
    ; Vertical checks:
    ; rect1.y < rect2.y + rect2.height
    ld a,(iy+0)
    add a,(iy+2)
    ld b,a
    ld a,(ix+0)
    cp b
    ret nc
    ; rect1.y + rect1.height > rect2.y
    ld a,(ix+0)
    add a,(ix+2)
    ld b,a
    ld a,(iy+0)
    cp b
    ret nc

  ret ; Return with carry set.



  move_dummy:
    call is_reset_pressed
    jp nc,+
      ld a,HURTING
      ld (dummy_state),a
      RESET_BLOCK DUMMY_HURT_COUNTER, dummy_anim_counter, 2
      ld hl,dummy_x
      inc (hl)
      inc (hl)
    +:

    ; Detect collsion
    ld a,(state)
    cp ATTACKING
    jp z,+
    cp JUMP_ATTACKING
    jp z,+
      jp ++
    +:
      ld ix,killbox_y
      ld iy,dummy_y
      call detect_collision
      jp nc,++
        ; Collsion detected
        ld a,HURTING
        ld (dummy_state),a
        RESET_BLOCK DUMMY_HURT_COUNTER, dummy_anim_counter, 2
        ld hl,dummy_x
        inc (hl)
        inc (hl)
    ++:





    ld hl,dummy_x
    dec (hl)
    ; Count down to next frame.
    ld hl,dummy_anim_counter
    call tick_counter
    jp nc,++
      ld a,(dummy_frame)
      inc a
      cp DUMMY_MOVING_FRAMES
      jp nz,+
        xor a
      +:
      ld (dummy_frame),a
    ++:

    ld a,(dummy_y)
    ld d,a
    ld a,(dummy_x)
    ld e,a
    ld a,(dummy_frame)
    cp 0
    jp nz,+
      ld a,DUMMY_MOVING_FRAME_0
      jp ++
    +:
      ld a,DUMMY_MOVING_FRAME_1
    ++:
    call spr_2x2
  ret

  hurt_dummy:
    ld hl,dummy_anim_counter
    call tick_counter
    jp nc,+
      ld a,DEACTIVATED
      ld (dummy_state),a
    +:
    ld a,(dummy_y)
    ld d,a
    ld a,(dummy_x)
    ld e,a
    ld a,$8a
    call spr_2x2
  
  ret

.ends