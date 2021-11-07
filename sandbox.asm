; Sandbox.
;.sdsctag 1.0, "Sandbox", "YYY", "hang-on Entertainment"
; -----------------------------------------------------------------------------
; GLOBAL DEFINITIONS
; -----------------------------------------------------------------------------
.include "libraries/sms_constants.asm"
.include "libraries/core.asm"

; Remove comment to enable unit testing
;.equ TEST_MODE
.ifdef TEST_MODE
  .equ USE_TEST_KERNEL
.endif

; -----------------------------------------------------------------------------
.memorymap
; -----------------------------------------------------------------------------
  defaultslot 0
  slotsize $4000
  slot 0 $0000
  slot 1 $4000
  slot 2 $8000
  slotsize $2000
  slot 3 $c000
.endme
.rombankmap ; 128K rom
  bankstotal 8
  banksize $4000
  banks 8
.endro
;
; Hierarchy: Most fundamental first. 
.include "libraries/psglib.inc"
.include "libraries/vdp_lib.asm"
.include "libraries/misc_lib.asm"
.include "libraries/tiny_games.asm"
; -----------------------------------------------------------------------------
.ramsection "System variables" slot 3
; -----------------------------------------------------------------------------
  temp_byte db                  ; Temporary variable - byte.
  temp_word db                  ; Temporary variable - word.
  ;
  vblank_counter db
  hline_counter db
  pause_flag db
  input_ports dw
  ;  
  critical_routines_finish_at db
.ends

; -----------------------------------------------------------------------------
.ramsection "Game variables" slot 3
; -----------------------------------------------------------------------------
  anim_counter dw
  frame db
  direction db
  state db
.ends

.org 0
.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Boot" force
; -----------------------------------------------------------------------------
  boot:
  di
  im 1
  ld sp,$dff0
  ;
  ; Initialize the memory control registers.
  ld de,$fffc
  ld hl,initial_memory_control_register_values
  ld bc,4
  ldir
  FILL_MEMORY $00
  ;
  jp init
  ;
  initial_memory_control_register_values:
    .db $00,$00,$01,$02
.ends
.org $0038
; ---------------------------------------------------------------------------
.section "!VDP interrupt" force
; ---------------------------------------------------------------------------
  push af
  push hl
    in a,CONTROL_PORT
    bit INTERRUPT_TYPE_BIT,a  ; HLINE or VBLANK interrupt?
    jp z,+
      ld hl,vblank_counter
      jp ++
    +:
      ld hl,hline_counter
    ++:
  inc (hl)
  pop hl
  pop af
  ei
  reti
.ends
.org $0066
; ---------------------------------------------------------------------------
.section "!Pause interrupt" force
; ---------------------------------------------------------------------------
  push af
    ld a,(pause_flag)
    cpl
    ld (pause_flag),a
  pop af
  retn
.ends
; -----------------------------------------------------------------------------
.section "main" free
; -----------------------------------------------------------------------------
  init:
  ; Run this function once (on game load/reset). 
    ;
    call PSGInit
    ;
    call clear_vram
    ld hl,vdp_register_init
    call initialize_vdp_registers
    ;
    ld a,1
    ld b,BORDER_COLOR
    call set_register
    ;
    ld a,0
    ld b,32
    ld hl,sweetie16_palette
    call load_cram

    .ifdef TEST_MODE
      jp test_bench
    .endif

    ld a,2
    ld hl,sprite_tiles
    ld de,$0000
    ld bc,sprite_tiles_end - sprite_tiles
    call load_vram

    .equ IDLE 0
    .equ WALKING 1
    .equ ANIM_COUNTER_RESET 4
    xor a
    ld (frame),a
    ld a,IDLE
    ld (state),a
    ld a,RIGHT
    ld (direction),a
    ld a,ANIM_COUNTER_RESET
    ld (anim_counter),a
    ld (anim_counter+1),a


    ei
    halt
    halt
    xor a
    ld (vblank_counter),a
    
    ld a,ENABLED
    call set_display
    
  jp main_loop
    vdp_register_init:
    .db %00100110  %10100000 $ff $ff $ff
    .db $ff $fb $f0 $00 $00 $ff
  ; ---------------------------------------------------------------------------
  main_loop:
    call wait_for_vblank
     ; -------------------------------------------------------------------------
    ; Begin vblank critical code (DRAW).
    call load_sat
    
    ld hl,critical_routines_finish_at
    call save_vcounter
    ;
    ; -------------------------------------------------------------------------
    ; Begin general updating (UPDATE).
    call PSGFrame
    call PSGSFXFrame
    call refresh_sat_handler

    ; Set input_ports (word) to mirror current state of ports $dc and $dd.
    in a,(INPUT_PORT_1)
    ld (input_ports),a
    in a,(INPUT_PORT_2)
    ld (input_ports+1),a

    ;debug:
    ;ld a,%11110111
    ;ld (input_ports),a

    .equ LEFT 1
    .equ RIGHT 0
    ; Set the player's direction depending on controller input (LEFT/RIGHT).
    ld a,(direction)
    cp LEFT
    jp z,+
    cp RIGHT
    jp z,++
    +: ; Player is facing left.
      call is_right_pressed
      jp nc,+
        ld a,RIGHT
        ld (direction),a
      +:
      jp +++
    ++: ; Player is facing right.
      call is_left_pressed
      jp nc,+
        ld a,LEFT
        ld (direction),a
      +:
    +++:
    
    ld a,(state)
    cp IDLE ; is state = idle?
    jp z,handle_idle_state
    cp WALKING ; is state = walking?
    jp z,handle_walking_state
    ; Fall through to idle (default).

    handle_idle_state:
      call is_left_or_right_pressed
      jp nc,+
        ; Directional input - switch from idle to walking.
        ld a,WALKING
        ld (state),a
        xor a
        ld (frame),a
      +:
      jp _f

    handle_walking_state:
      call is_left_or_right_pressed
      jp c,+
        ; Not directional input.
        ld a,IDLE
        ld (state),a
        xor a
        ld (frame),a
      +:
      jp _f


    __: ; End of player state checks. 
    

    ; Count down to next frame.
    ld hl,anim_counter
    call tick_counter
    jp nc,+
      ld hl,frame
      inc (hl)
    +:
    ; Reset/loop animation if last frame expires. 
    ld a,(state)
    ld hl,state_to_frames_total_table
    call lookup_byte
    ld hl,frame
    call reset_hl_on_a

    ; Put the sprite tiles in the SAT buffer. 
    ld a,(state)
    ld hl,state_to_frame_table
    call lookup_word
    ld a,(frame)
    call lookup_byte
    ld b,0
    push af
      .equ ONE_ROW_OFFSET 64
      ; Offset to left-facing tiles if necessary.
      ld a,(direction)
      ld b,0
      cp RIGHT
      jp z,+
        ld b,ONE_ROW_OFFSET
      +:
    pop af
    add a,b                           ; Apply offset (0 or ONE_ROW)
    
    ld de,$1010
    call spr_2x2

  jp main_loop
.ends
.bank 2 slot 2
 ; ----------------------------------------------------------------------------
.section "Demo assets" free
; -----------------------------------------------------------------------------

  sweetie16_palette:
    .db $23 $00 $11 $12 $17 $1B $2E $19 $14 $10 $35 $38 $3D $3F $2A $15
    .db $23 $00 $11 $12 $17 $1B $2E $19 $14 $10 $35 $38 $3D $3F $2A $15

  sprite_tiles:
    .include "data/sprite_tiles.inc"
    sprite_tiles_end:

  idle_frame_to_index_table:
    .db 1 3 5 7 
    __:

  walking_frame_to_index_table:
    .db 1 9 11 13 11 9  
    __:

  state_to_frame_table:
    .dw idle_frame_to_index_table, walking_frame_to_index_table
    __:

  state_to_frames_total_table:
    .db _sizeof_idle_frame_to_index_table
    .db _sizeof_walking_frame_to_index_table



.ends