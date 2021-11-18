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

  move_dummy:

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
      ld a,MOVING
      ld (dummy_state),a
      RESET_BLOCK DUMMY_MOVE_COUNTER, dummy_anim_counter, 2
    +:

    ld a,(dummy_y)
    ld d,a
    ld a,(dummy_x)
    ld e,a
    ld a,$8a
    call spr_2x2
  
  ret

.ends