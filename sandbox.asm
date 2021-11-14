; Sandbox.
;.sdsctag 1.0, "Sandbox", "YYY", "hang-on Entertainment"
; -----------------------------------------------------------------------------
; GLOBAL DEFINITIONS
; -----------------------------------------------------------------------------
.include "libraries/sms_constants.asm"
.include "libraries/core.asm"

.equ SFX_BANK 3
.equ MUSIC_BANK 3

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
  attack_counter dw
  player_y db
  player_x db
  jump_counter db

  dummy_y db
  dummy_x db
  hspeed db
  vspeed db

  tile_buffer dsb 20
  metatile_buffer dsb 10
  map_head dw
  nametable_head db
  metatile_halves db    ; Convert left or right half of the metatile to tiles.
  

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
    ld bc,_sizeof_sprite_tiles
    call load_vram

    ld a,2
    ld hl,level_1_tiles
    ld de,BACKGROUND_BANK_START
    ld bc,_sizeof_level_1_tiles
    call load_vram


    .equ LEFT 1
    .equ RIGHT 0
    .equ IDLE 0
    .equ WALKING 1
    .equ ATTACKING 2
    .equ JUMPING 3
    .equ ANIM_COUNTER_RESET 4
    .equ PLAYER_WALKING_SPEED 1
    .equ PLAYER_JUMPING_HSPEED 2
    
    RESET_VARIABLES 0, frame, state, direction, jump_counter, hspeed, vspeed
    LOAD_BYTES player_y, 135, player_x, 60
    RESET_BLOCK ANIM_COUNTER_RESET, anim_counter, 2
    RESET_BLOCK _sizeof_attacking_frame_to_index_table*ANIM_COUNTER_RESET, attack_counter, 2
    LOAD_BYTES dummy_y, 135, dummy_x, 200

    RESET_BLOCK $0e, tile_buffer, 20
    LOAD_BYTES metatile_halves, 0, nametable_head, 0

    
    ; Init map head.
    ld hl,level_1_map
    ld a,l
    ld (map_head),a
    ld a,h
    ld (map_head+1),a

    ; Read a column.
    ld hl,map_head
    call get_word
    ld de,metatile_buffer
    ld bc,10
    ldir
    ; Forward map head.
    ld hl,map_head
    call get_word
    ld de,10
    add hl,de
    ld a,l
    ld (map_head),a
    ld a,h
    ld (map_head+1),a

    ; Write a column of sprite indexes to the name table.
    ; 1. Convert either the left or right half of the meta tiles in the 
    ; metatile buffer to tile indexes, and load them into the tile buffer.
    ; 2. Copy the tile buffer to the name table column at the name table head.
    
    ld a,(metatile_halves)
    cp 0
    jp nz,+
      call convert_left_half_of_metatile_column
      jp ++
    +:
      call convert_right_half_of_metatile_column
    ++:
    ld a,(metatile_halves)
    cpl
    ld (metatile_halves),a

    call load_column_0

    ;call convert_left_half_of_metatile_column
    ;call load_column_1
    ;call convert_right_half_of_metatile_column
    ;call load_column_2

    ; Add jump/call table to call the right column function,
    ; depending on var: active_name_table_column
    ; also keep where we are in the map: active_map_column


    ;call load_column_xx
    ;call load_column_2




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
    ld a,MUSIC_BANK
    SELECT_BANK_IN_REGISTER_A
    call PSGFrame
    ld a,SFX_BANK
    SELECT_BANK_IN_REGISTER_A
    call PSGSFXFrame
    ld a,2
    SELECT_BANK_IN_REGISTER_A
    call refresh_sat_handler

    ; Set input_ports (word) to mirror current state of ports $dc and $dd.
    in a,(INPUT_PORT_1)
    ld (input_ports),a
    in a,(INPUT_PORT_2)
    ld (input_ports+1),a

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

    RESET_VARIABLES 0, vspeed, hspeed

    ld a,(state)
    cp IDLE ; is state = idle?
    jp z,handle_idle_state
    cp WALKING ; is state = walking?
    jp z,handle_walking_state
    cp ATTACKING
    jp z,handle_attacking_state
    cp JUMPING
    jp z,handle_jumping_state
    ; Fall through to idle (default).

    handle_idle_state:
      call is_button_1_pressed
      jp nc,+
        LOAD_BYTES state, ATTACKING, frame, 0
        ld hl,slash_sfx
        ld c,SFX_CHANNEL3
        call PSGSFXPlay
      +:
      call is_left_or_right_pressed
      jp nc,+
        ; Directional input - switch from idle to walking.
        LOAD_BYTES state, WALKING, frame, 0
        jp _f
      +:
      call is_button_2_pressed
      jp nc,+
        LOAD_BYTES state, JUMPING, frame, 0
        ld hl,jump_sfx
        ld c,SFX_CHANNEL2
        call PSGSFXPlay
        jp _f
      +:
      jp _f

    handle_walking_state:
      call is_button_1_pressed
      jp nc,+
        LOAD_BYTES state, ATTACKING, frame, 0
        ld hl,slash_sfx
        ld c,SFX_CHANNEL3
        call PSGSFXPlay
        jp _f
      +:
      call is_left_or_right_pressed
      jp c,+
        ; Not directional input.
        LOAD_BYTES state, IDLE, frame, 0
        jp _f
      +:
      call is_button_2_pressed
      jp nc,+
        LOAD_BYTES state, JUMPING, frame, 0
        ld hl,jump_sfx
        ld c,SFX_CHANNEL2
        call PSGSFXPlay
        jp _f
      +:
      ld a,(direction)
      cp RIGHT
      ld a,PLAYER_WALKING_SPEED
      jp z,+
        neg
      +:
      ld (hspeed),a
      jp _f

    handle_attacking_state:
      ld hl,attack_counter
      call tick_counter
      jp nc,+
        LOAD_BYTES state, IDLE, frame, 0
      +:
    jp _f

    handle_jumping_state:
      ld a,(jump_counter)
      ld hl,jump_counter_to_vspeed_table
      call lookup_byte
      ld (vspeed),a

      ld a,(jump_counter)
      inc a
      cp 32
      jp nz,+
        LOAD_BYTES state, IDLE, frame, 0, jump_counter, 0
        jp _f
      +:
      ld (jump_counter),a
      
      call is_left_or_right_pressed
      jp nc,+ 
        ld a,(jump_counter)
        ld hl,jump_counter_to_hspeed_table
        call lookup_byte
        ld b,a      
        ld a,(direction)
        cp RIGHT
        ld a,b
        jp z,+
          neg
        +:
        ld (hspeed),a
      +:
    jp _f

    __: ; End of player state checks. 

    ; Apply this frame's h and v speed to the player y,x
    ld a,(vspeed)
    ld b,a
    ld a,(player_y)
    add a,b
    ld (player_y),a
    ld a,(hspeed)
    ld b,a
    ld a,(player_x)
    add a,b
    ld (player_x),a
    
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
    ld b,a
    ld a,(frame)
    cp b
    jp nz,+
      xor a
      ld (frame),a
    +:

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
      ld a,(player_y)
      ld d,a
      ld a,(player_x)
      ld e,a
    pop af
    add a,b                           ; Apply offset (0 or ONE_ROW)
    
    call spr_2x2

    ld a,(state)
    cp ATTACKING
    jp nz,_f
      ld a,(frame)
      cp 1
      jp c,_f
        ld a,(direction)
        cp RIGHT
        jp nz,+
          ld c,32
          ld a,(player_y)
          add a,8
          ld d,a
          ld a,(player_x)
          add a,16
          ld e,a
          call add_sprite
          jp _f
        +:
          ld c,64
          ld a,(player_y)
          add a,8
          ld d,a
          ld a,(player_x)
          sub 8
          ld e,a
          call add_sprite

    __:

    ; Put the test dummy on
    ld a,(dummy_y)
    ld d,a
    ld a,(dummy_x)
    ld e,a
    ld a,65
    call spr_2x2


  jp main_loop
.ends
.bank 1 slot 1
 ; ----------------------------------------------------------------------------
.section "Tables" free
; -----------------------------------------------------------------------------
  nametable_head_to_column_loader:
    ; To be indexed by the variable name_table_head.
    .dw load_column_0
    .dw load_column_1
    .dw load_column_2
    .dw load_column_3
    .dw load_column_4
    .dw load_column_5
    .dw load_column_6
    .dw load_column_7
    .dw load_column_8
    .dw load_column_9
    .dw load_column_10
    .dw load_column_11
    .dw load_column_12
    .dw load_column_13
    .dw load_column_14
    .dw load_column_15
    .dw load_column_16
    .dw load_column_17
    .dw load_column_18
    .dw load_column_19
    .dw load_column_20
    .dw load_column_21
    .dw load_column_22
    .dw load_column_23
    .dw load_column_24
    .dw load_column_25
    .dw load_column_26
    .dw load_column_27
    .dw load_column_28
    .dw load_column_29
    .dw load_column_30
    .dw load_column_31



  ; Convert left half of a column of metatiles to tiles in the buffer.
  convert_left_half_of_metatile_column:
    .rept 10 INDEX COUNT
      ld a,(metatile_buffer+COUNT)
      ld hl,top_left_corner ;
      call lookup_byte      ; 
      ld (tile_buffer+(COUNT*2)),a
      ld a,(metatile_buffer+COUNT)
      ld hl,bottom_left_corner
      call lookup_byte      
      ld (tile_buffer+(COUNT*2)+1),a
    .endr
  ret

  ; Convert right half of a column of metatiles to tiles in the buffer.
  convert_right_half_of_metatile_column:
    .rept 10 INDEX COUNT
      ld a,(metatile_buffer+COUNT)
      ld hl,top_right_corner ;
      call lookup_byte      ; 
      ld (tile_buffer+(COUNT*2)),a
      ld a,(metatile_buffer+COUNT)
      ld hl,bottom_right_corner
      call lookup_byte      
      ld (tile_buffer+(COUNT*2)+1),a
    .endr
  ret
  
  top_left_corner:
  ; ID 0 1 2 3 4 5  6  7  8  9  10 11 12 13 14 15
   .db 0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30
  ; ID 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 
   .db 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94
  ; ID 32  33  34  35  36  37  38  39  40  41  42  43  44  45  46  47 
   .db 128 130 132 134 136 138 140 142 144 146 148 150 152 154 156 158

  bottom_left_corner:
    .rept 16 INDEX COUNT
      ; ID 0-15
      .db 32+(COUNT*2)
    .endr 
    .rept 16 INDEX COUNT
      ; ID 16-31
      .db 96+(COUNT*2)
    .endr 
    .rept 16 INDEX COUNT
      ; ID 32-47
      .db 160+(COUNT*2)
    .endr 

  top_right_corner:
    .rept 16 INDEX COUNT
      ; ID 0-15
      .db 1+(COUNT*2)
    .endr 
    .rept 16 INDEX COUNT
      ; ID 16-31
      .db 65+(COUNT*2)
    .endr 
    .rept 16 INDEX COUNT
      ; ID 32-47
      .db 129+(COUNT*2)
    .endr 

  bottom_right_corner:
    .rept 16 INDEX COUNT
      ; ID 0-15
      .db 33+(COUNT*2)
    .endr 
    .rept 16 INDEX COUNT
      ; ID 16-31
      .db 97+(COUNT*2)
    .endr 
    .rept 16 INDEX COUNT
      ; ID 32-47
      .db 161+(COUNT*2)
    .endr 


  ; Unrolled loops to quickly load a name table column from the buffer.
  .macro COLUMN_LOADER ARGS ADDRESS
    load_column_\@:
      .rept 20 INDEX COUNT
        ld hl,ADDRESS+COUNT*64
        ld a,l
        out (CONTROL_PORT),a
        ld a,h
        or VRAM_WRITE_COMMAND
        out (CONTROL_PORT),a
        ld a,(tile_buffer+COUNT)
        out (DATA_PORT),a   
        ld a,%00000001
        out (DATA_PORT),a
      .endr
    ret
  .endm
  .rept 32 INDEX COLUMN
    COLUMN_LOADER $3880+(COLUMN*2)
  .endr

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
    __:

  level_1_tiles:
    .include "data/village_tiles.inc"
    __:
  
  level_1_map:
    .incbin "data/village_tilemap.bin"
    __:

  idle_frame_to_index_table:
    .db 1 1 3 3 5 7 7 
    __:

  walking_frame_to_index_table:
    .db 1 9 11 13 11 9  
    __:
  
  attacking_frame_to_index_table:
    .db 13 15 17
    __:

  jumping_frame_to_index_table:
    .db 1
    __:

  state_to_frame_table:
    .dw idle_frame_to_index_table
    .dw walking_frame_to_index_table
    .dw attacking_frame_to_index_table
    .dw jumping_frame_to_index_table
    __:

  state_to_frames_total_table:
    .db _sizeof_idle_frame_to_index_table
    .db _sizeof_walking_frame_to_index_table
    .db _sizeof_attacking_frame_to_index_table
    .db _sizeof_jumping_frame_to_index_table

  jump_counter_to_vspeed_table:
    .db -5, -4, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -2, -2, -1, -1 
    .db 1 1 2 2 3 3 3 3 3 3 3 3 3 3 4 5 

  jump_counter_to_hspeed_table:
    .db 4 3 3 2 2 2 2 2 2 2 2 2 2 2 2 2
    .db 2 2 2 2 2 2 2 2 2 2 2 2 1 1 1 1    

  tile_buffer_data:
    .db $80 $a0
    .db $82 $a2
    .db $82 $a2
    .db $82 $a2
    .db $82 $a2
    .db $82 $a2
    .db $82 $a2
    .db $82 $a2
    .db $00 $20
    .db $40 $60


.ends
.bank 3 slot 2
 ; ----------------------------------------------------------------------------
.section "Sound effects" free
; -----------------------------------------------------------------------------
  slash_sfx:
    .incbin "data/slash.psg"

  jump_sfx:
    .incbin "data/jump.psg"

.ends