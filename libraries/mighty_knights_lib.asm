; Mighty knights


.macro TRANSITION_PLAYER_STATE ARGS NEWSTATE, SFX, CHANNEL
  ; Perform the standard actions when the player's state transitions:
  ; 1) Load new state into state variable, 2) reset animation frame and
  ; 3) (optional) play a sound effect.
  LOAD_BYTES state, NEWSTATE, frame, 0      ; Set the state and frame variables.
  .IF NARGS == 3                            ; Is an SFX pointer and channel provided?
    ld hl,SFX                               ; If so, point HL to the SFX-data.
    ld c,CHANNEL                            ; Set the requested channel.
    call PSGSFXPlay                         ; Play it.
  .ENDIF
.endm

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Mighty Knights Library" free
; -----------------------------------------------------------------------------


.ends