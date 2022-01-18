; Sandbox - working title for a new take on "Mighty Knights".
.sdsctag 1.0, "Sandbox", "Description", "hang-on Entertainment"
; -----------------------------------------------------------------------------
; GLOBAL DEFINITIONS
; -----------------------------------------------------------------------------
.include "libraries/sms_constants.asm"

; Remove comment to enable unit testing
;.equ TEST_MODE
.ifdef TEST_MODE
  .equ USE_TEST_KERNEL
.endif

; Comment to turn music on
.equ MUSIC_OFF

.equ SFX_BANK 3
.equ MUSIC_BANK 3

.equ SCROLL_POSITION 152
.equ LEFT_LIMIT 10
.equ RIGHT_LIMIT 240
.equ FLOOR_LEVEL 127

.equ LEFT 1
.equ RIGHT 0
; 
.equ IDLE 0
.equ WALKING 1
.equ ATTACKING 2
.equ JUMPING 3
.equ JUMP_ATTACKING 4

.equ ANIM_COUNTER_RESET 4
.equ PLAYER_WALKING_SPEED 1
.equ PLAYER_JUMPING_HSPEED 2

.equ SWORD_HEIGHT 4
.equ SWORD_WIDTH 4

; Game states:
.equ LOAD_LEVEL 0
.equ RUN_LEVEL 1
.equ INITIAL_GAMESTATE LOAD_LEVEL

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
.include "libraries/map_lib.asm"
.include "libraries/input_lib.asm"
.include "libraries/tiny_games.asm"
.include "libraries/score_lib.asm"
.include "libraries/minions_lib.asm"
.include "libraries/items_lib.asm"
.include "libraries/brute_lib.asm"
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
  ;  

.ends

; -----------------------------------------------------------------------------
.ramsection "Game variables" slot 3
; -----------------------------------------------------------------------------
  vblank_finish_low db
  vblank_finish_high db
  odd_frame db
  rnd_seed dw
  game_state db

; Player variables. Note - this order is expected!
  anim_counter dw
  frame db
  direction db
  state db
  attack_counter dw
  
  player_y db
  player_x db
  player_height db
  player_width db
  ; ------------
  jump_counter db
  hspeed db
  vspeed db

  ; Note - this order is expected!
  killbox_y db
  killbox_x db
  killbox_height db
  killbox_width db
  ; ----------------


  is_scrolling db
  hscroll_screen db ; 0-255
  hscroll_column db ; 0-7
  column_load_trigger db ; flag
  scroll_enabled db
  end_of_map_data dw

  accept_button_1_input db
  accept_button_2_input db
  


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
    
    ld a,INITIAL_GAMESTATE
    ld (game_state),a
    
  jp main_loop
    game_state_jump_table:
    .dw initialize_level, run_level  

    
    vdp_register_init:
    .db %01100110  %10100000 $ff $ff $ff
    .db $ff $fb $f0 $00 $00 $ff

  ; ---------------------------------------------------------------------------
  main_loop:
    ld a,(game_state)   ; Get current game state - it will serve as JT offset.
    add a,a             ; Double it up because jump table is word-sized.
    ld h,0              ; Set up HL as the jump table offset.
    ld l,a
    ld de,game_state_jump_table ; Point to JT base address (see footer.inc).
    add hl,de           ; Apply offset to base address.
    ld a,(hl)           ; Get LSB from table.
    inc hl              ; Increment pointer.
    ld h,(hl)           ; Get MSB from table.
    ld l,a              ; HL now contains the address of the state handler.
    jp (hl)             ; Jump to this handler - note, not call!
    
    
.ends

.bank 0 slot 0
  .section "Game states" free
    .include "game_states/level.asm"
  .ends

.bank 1 slot 1
 ; ----------------------------------------------------------------------------
.section "Bank 1" free
; -----------------------------------------------------------------------------

.ends

.bank 2 slot 2
 ; ----------------------------------------------------------------------------
.section "Level 1 assets" free
; -----------------------------------------------------------------------------
  sprite_tiles:
    .include "data/sprite_tiles.inc"
    __:

  level_1_tiles:
    .include "data/village_tiles.inc"
    __:
  
  level_1_map:
    .incbin "data/village_tilemap.bin"
    level_1_map_end:



.ends
.bank 3 slot 2
 ; ----------------------------------------------------------------------------
.section "Sound effects" free
; -----------------------------------------------------------------------------
  slash_sfx:
    .incbin "data/slash.psg"

  jump_sfx:
    .incbin "data/jump.psg"

  hurt_sfx:
    .incbin "data/hurt.psg"

  item_sfx:
    .incbin "data/item.psg"

  village_on_fire:
    .incbin "data/village_on_fire.psg"



.ends