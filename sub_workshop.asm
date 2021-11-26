
.struct minion
  ; Specification of the minion struct.
  ; * see notes
  state db
  y db
  x db
  sprite_index db
  anim_timer db
  frame db
  frame_table dw
  hspeed db
  vspeed db
.endst


.equ MINION_DEACTIVATED $ff
.equ MINION_IDLE 0
.equ MINION_MAX 3

.ramsection "Ram section for library being developed" slot 3

  minions INSTANCEOF minion 3

.ends


.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------
  spawn_minion:
    ; Spawn a minion.
    ld ix,minions
    ld b,MINION_MAX
    -:
      ld a,(ix+minion.state)
      cp MINION_DEACTIVATED
      jp z,@activate
      ld de,_sizeof_minion
      add ix,de
    djnz -
  ret
    @activate:  
      ld a,MINION_IDLE
      ld (ix+minion.state),a
    ret
  ret
  
  minion_init_data:
    .rept MINION_MAX
      .db MINION_DEACTIVATED
      .rept _sizeof_minion-1
        .db 0
      .endr
    .endr
    __:

  initialize_minions:
    ; Set the state to deactivated, then set every remaining byte in the
    ; minion struct to 0.
    ld de,minions
    ld bc,_sizeof_minion_init_data
    ldir
  ret
.ends

.bank 0 slot 0
