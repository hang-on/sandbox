
.equ MINION_DEACTIVATED $ff
.equ MINION_IDLE 0
.equ MINION_MOVING 1
.equ MINION_MAX 3

.struct minion
  state db
  y db
  x db
  direction db
  index db
  timer db
  frame db
  hspeed db
  vspeed db
.endst

.ramsection "Ram section for library being developed" slot 3
  random_number db
  minions INSTANCEOF minion 3
.ends

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------
  process_minions:
    ;
    ld ix,minions
    ld b,MINION_MAX
    -:
      ld a,(ix+minion.state)
      cp MINION_MOVING
      call z,@move
      ld de,_sizeof_minion
      add ix,de
    djnz -
  ret
    @move:
      ld a,(ix+minion.x)
      add a,(ix+minion.hspeed)
      ld (ix+minion.x),a
    ret

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
    scf   ; Set carry = failure (no deactivated minion to spawn).
  ret
    @activate:  
      ld a,MINION_IDLE
      ld (ix+minion.state),a
      call get_random_number
      bit 0,a
      jp z,+
        ; Spawn a minion at the left side, facing right.
        ld a,RIGHT
        ld (ix+minion.direction),a
        ld a,FLOOR_LEVEL
        ld (ix+minion.y),a
        ld a,0
        ld (ix+minion.x),a
        ld a,1
        ld (ix+minion.hspeed),a
        jp ++
      +:
        ld a,LEFT
        ld (ix+minion.direction),a
        ld a,FLOOR_LEVEL
        ld (ix+minion.y),a
        ld a,250
        ld (ix+minion.x),a
        ld a,-1
        ld (ix+minion.hspeed),a
      ++:
      or a    ; Reset carry = succes.
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
    ; In: hl = ptr. to init data.
    ld de,minions
    ld bc,_sizeof_minion_init_data
    ldir
  ret
.ends

.bank 0 slot 0
