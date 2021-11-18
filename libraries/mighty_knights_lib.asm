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


.ends