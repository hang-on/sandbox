; main.asm
;.sdsctag 1.0, "Sandbox", "YYY", "hang-on Entertainment"
; -----------------------------------------------------------------------------
; GLOBAL DEFINITIONS
; -----------------------------------------------------------------------------
.include "sms_constants.asm"
.include "core.asm"

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
.include "psglib.inc"
.include "vdp_lib.asm"
.include "animations_lib.asm"
.include "actors_lib.asm"
.include "mighty_knights_lib.asm"
.include "sub_workshop.asm"
.include "sub_tests.asm"        
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
  ;
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
    ld b,demo_palette_end-demo_palette
    ld hl,demo_palette
    call load_cram

    .ifdef TEST_MODE
      jp test_bench
    .endif

    ;ld a,2
    ;ld hl,mockup_background_tiles
    ;ld de,BACKGROUND_BANK_START
    ;ld bc,mockup_background_tiles_end - mockup_background_tiles
    ;call load_vram

    ;ld a,2
    ;ld hl,mockup_background_tilemap
    ;ld de,NAME_TABLE_START
    ;ld bc,VISIBLE_NAME_TABLE_SIZE
    ;call load_vram

    ;call initialize_acm
    
    ;INITIALIZE_ACTOR arthur, 0, 167, 56
    ;.equ PLAYER_ACM_SLOT 0
    
    ;ld a,IDLE
    ;ld hl,arthur.motor
    ;ld (hl),a
    ;ld a,TRUE
    ;ld (arthur.state_changed),a

    ;ld a,PLAYER_ACM_SLOT
    ;ld hl,arthur_idle
    ;call set_animation


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
    ;call blast_tiles
    
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



    ;call process_animations

    ;ld a,PLAYER_ACM_SLOT            ; Let the actor "arthur" be represented
    ;ld hl,arthur                    ; by the animation currently playing in
    ;call draw_actor                 ; animation control matrix' PLAYER_ACM_SLOT

  jp main_loop
.ends
.bank 2 slot 2
 ; ----------------------------------------------------------------------------
.section "Demo assets" free
; -----------------------------------------------------------------------------

  demo_palette:
    .db $23 $00 $11 $12 $17 $1B $2E $19 $14 $10 $35 $38 $3D $3F $2A $15
    .db $23 $00 $11 $12 $17 $1B $2E $19 $14 $10 $35 $38 $3D $3F $2A $15
    demo_palette_end:


.ends