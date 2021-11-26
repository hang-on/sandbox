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
    ; Axis aligned bounding box:
    ;    if (rect1.x < rect2.x + rect2.w &&
    ;    rect1.x + rect1.w > rect2.x &&
    ;    rect1.y < rect2.y + rect2.h &&
    ;    rect1.h + rect1.y > rect2.y)
    ;    ---> collision detected!
    ; ---------------------------------------------------
    ; IN: IX = Pointer to y, x, height, width of rect 1.
    ;     IY = Pointer to y, x, height, width of rect2.
    ; OUT:  Carry set = collision / not set = no collision.
    ;
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

.ends

