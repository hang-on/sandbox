; Mighty knights


.macro TRANSITION_PLAYER_STATE ARGS NEWSTATE SFX
  LOAD_BYTES state, NEWSTATE, frame, 0
  .IF NARGS == 2
    ld hl,SFX
    ld c,SFX_CHANNEL3
    call PSGSFXPlay
  .ENDIF
.endm

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Mighty Knights Library" free
; -----------------------------------------------------------------------------


.ends