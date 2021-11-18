; Mighty knights


.macro TRANSITION_PLAYER_STATE ARGS NEWSTATE, SFX
  LOAD_BYTES state, NEWSTATE, frame, 0
  .IF NARGS == 2
    ld hl,SFX
    .IF SFX == slash_sfx
      ld c,SFX_CHANNEL3
    .ENDIF
    .IF SFX == jump_sfx
      ld c,SFX_CHANNEL2
    .ENDIF
    call PSGSFXPlay
  .ENDIF
.endm

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Mighty Knights Library" free
; -----------------------------------------------------------------------------


.ends