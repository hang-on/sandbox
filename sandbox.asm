; Sandbox - working title for a new take on "Mighty Knights".
.sdsctag 1.0, "Title", "Description", "hang-on Entertainment"
; -----------------------------------------------------------------------------
; GLOBAL DEFINITIONS
; -----------------------------------------------------------------------------
.include "libraries/sms_constants.asm"

; Remove comment to enable unit testing
;.equ TEST_MODE
.ifdef TEST_MODE
  .equ USE_TEST_KERNEL
.endif

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

  anim_counter dw
  frame db
  direction db
  state db
  attack_counter dw
  
  ; Note - this order is expected!
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

    RESET_VARIABLES 0, frame, direction, jump_counter, hspeed, vspeed
    LOAD_BYTES player_y, 127, player_x, 60, state, IDLE
    LOAD_BYTES player_height, 16, player_width, 15
    RESET_BLOCK ANIM_COUNTER_RESET, anim_counter, 2
    RESET_BLOCK _sizeof_attacking_frame_to_index_table*ANIM_COUNTER_RESET, attack_counter, 2

    LOAD_BYTES killbox_y, 0, killbox_x, 0
    LOAD_BYTES killbox_height, SWORD_HEIGHT, killbox_width, SWORD_WIDTH

    RESET_BLOCK $0e, tile_buffer, 20
    LOAD_BYTES metatile_halves, 0, nametable_head, 0
    LOAD_BYTES hscroll_screen, 0, hscroll_column, 0, column_load_trigger, 0
    LOAD_BYTES vblank_finish_high, 0, vblank_finish_low, 255
    LOAD_BYTES scroll_enabled, TRUE
    LOAD_BYTES odd_frame, TRUE

    LOAD_BYTES accept_button_1_input, FALSE, accept_button_2_input, FALSE


    ; Seed the randomizer
    ld hl,my_seed
    ld a,(hl)
    ld (rnd_seed),a
    inc hl
    ld a,(hl)
    ld (rnd_seed+1),a
    jp +
      my_seed:
      .dbrnd 2, 0, 255
    +:

    ; Initialize the minions.
    call initialize_minions

    ; Initialize the items.
    call initialize_items

    ; Initialize the brute.
    call initialize_brute

    ; Make solid block special tile in SAT.
    ld a,2
    ld bc,CHARACTER_SIZE
    ld hl,solid_block
    ld de,START_OF_UNUSED_SAT_AREA
    call load_vram

    ; Clear the bottom two rows with that special tile.
    ld hl,NAME_TABLE_START+(32*22*2)
    call setup_vram_write
    ld b,32*2
    -:
      ld a,$fa ; Tilebank index of special tile.
      out (DATA_PORT),a
      ld a,%00000001
      out (DATA_PORT),a
    djnz -

    ld hl,mockup_dashboard
    ld a,TRUE
    ld b,0
    ld c,_sizeof_mockup_dashboard
    call copy_string_to_nametable

    ; Level data:
    ld hl,level_1_map+_sizeof_level_1_map
    ld a,l
    ld b,h
    ld hl,end_of_map_data
    ld (hl),a
    inc hl
    ld (hl),b
    
    ; Init map head.
    ld hl,level_1_map
    call initialize_map
    ; Draw a full screen 
    ld b,32
    call draw_columns

    ; Fill the blanked column.
    call next_metatile_half_to_tile_buffer
    call tilebuffer_to_nametable
    
    ; Score:
    ld hl,score
    call reset_score


    ei
    halt
    halt
    xor a
    ld (vblank_counter),a
    
    ld a,ENABLED
    call set_display
    
  jp main_loop
    vdp_register_init:
    .db %01100110  %10100000 $ff $ff $ff
    .db $ff $fb $f0 $00 $00 $ff

    mockup_dashboard:
      .db $fc $fc $e6 $e7 $e8 $e5 $e9 $ed $fa $fa $fa $fa $fa $fa $fc $fc $fc
      .db $ea $eb $e6 $e7 $e8 $e5 $e9 $ed $fa $fa $fa $fa $fa $fa
      .db $fc $fc $fc $e0 $e1 $e2 $e3 $e4 $e5
      .db $ee $ef $ef $ef $ef $ef $ef $ef $ef $ef $ef $ef $ef $f0 $f1 $fc 
      .db $e2 $eb $ec $e9 $ed $fa $fa $fc
    __:

  ; ---------------------------------------------------------------------------
  main_loop:
    call wait_for_vblank
    
    ; Begin vblank critical code (DRAW) ---------------------------------------
      
    call load_sat

    ld a,(column_load_trigger)
    cp 0
    jp z,+
      xor a
      ld (column_load_trigger),a
      call tilebuffer_to_nametable
    +:

    ; Sync the vdp-scroll with the ram-mirror.
    ld a,(hscroll_screen)
    ld b,HORIZONTAL_SCROLL_REGISTER
    call set_register 

    ; Update the score
    ; We access VRAM here!
    ld ix,score
    ld hl,SCORE_ADDRESS
    call fast_print_score


    ; Quick and dirty vblank profiling.
    ; Note: A high value of $DA means vblank finishes between 218-223.
    in a,V_COUNTER_PORT                 ; Get the counter. 
    ld b,a                              ; Store in B.
    ld a,(vblank_finish_low)            ; Get the current lowest value.
    cp b                                ; Compare to counter value.
    jp c,+                              ; Is counter > lowest value? 
      ld a,b                            ; No, we got a new lowest. Get counter.
      ld (vblank_finish_low),a          ; Store in ram.
      jp ++                             ; Skip next part.
    +:                                  ; Not new lowest - maybe new highest?
      ld a,(vblank_finish_high)         ; Get the current highest value. 
      cp b                              ; Compare to counter value.
      jp nc,++                          ; Is counter > highest value?
        ld a,b                          ; Yes = new highest! Get counter.
        ld (vblank_finish_high),a       ; Store in ram.
    ++:                                 ;

    ; End of critical vblank routines. ----------------------------------------
 
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
    call refresh_input_ports

    ld a,(odd_frame)                ; Get value, either TRUE or FALSE.
    cpl                             ; Invert (TRUE -> FALSE, FALSE -> TRUE).
    ld (odd_frame),a                ; Store value.


    ; Seed the random number generator with button 1.
    call is_button_1_pressed
    jp nc,+
      call get_random_number
    +:

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

    ld a,(state)
    cp IDLE ; is state = idle?
    jp z,handle_idle_state
    cp WALKING ; is state = walking?
    jp z,handle_walking_state
    cp ATTACKING
    jp z,handle_attacking_state
    cp JUMPING
    jp z,handle_jumping_state
    cp JUMP_ATTACKING
    jp z,handle_jump_attacking_state
    ; Fall through to error
    -:
      nop ; STATE ERROR
    jp -

    handle_idle_state:      
      call is_button_1_pressed
      jp nc,+
        ld a,(accept_button_1_input)
        cp TRUE
        jp nz,+
          TRANSITION_PLAYER_STATE ATTACKING, slash_sfx
          jp _f
      +:
      call is_left_or_right_pressed
      jp nc,+
        ; Directional input - switch from idle to walking.
        LOAD_BYTES state, WALKING, frame, 0
        jp _f
      +:
      call is_button_2_pressed
      jp nc,+
        ld a,(accept_button_2_input)
        cp TRUE
        jp nz,+
          TRANSITION_PLAYER_STATE JUMPING, jump_sfx
          jp _f
      +:
      jp _f

    handle_walking_state:
      call is_button_1_pressed
      jp nc,+
        ld a,(accept_button_1_input)
        cp TRUE
        jp nz,+
          TRANSITION_PLAYER_STATE ATTACKING, slash_sfx
        jp _f
      +:
      call is_left_or_right_pressed
      jp c,+
        ; Not directional input.
        TRANSITION_PLAYER_STATE IDLE
        jp _f
      +:
      call is_button_2_pressed
      jp nc,+
        ld a,(accept_button_2_input)
        cp TRUE
        jp nz,+
          TRANSITION_PLAYER_STATE JUMPING, jump_sfx
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
        TRANSITION_PLAYER_STATE IDLE
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
        TRANSITION_PLAYER_STATE IDLE
        LOAD_BYTES jump_counter, 0
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

      call is_button_1_pressed
      jp nc,+
        ld a,(accept_button_1_input)
        cp TRUE
        jp nz,+
          TRANSITION_PLAYER_STATE JUMP_ATTACKING, slash_sfx
      +:
    jp _f

    handle_jump_attacking_state:
      ld a,(jump_counter)
      ld hl,jump_counter_to_vspeed_table
      call lookup_byte
      ld (vspeed),a

      ld a,(jump_counter)
      inc a
      cp 32
      jp nz,+
        ld a,(attack_counter)
        cp 0
        jp nz,@continue_with_attack
          ; If not attacking, continue with idle.
          TRANSITION_PLAYER_STATE IDLE        
          LOAD_BYTES jump_counter, 0
          jp _f
        @continue_with_attack:
          ; if attacking
          TRANSITION_PLAYER_STATE ATTACKING        
          LOAD_BYTES jump_counter, 0
          jp _f
      +:
      ld (jump_counter),a
      
      ld hl,attack_counter
      call tick_counter
      jp nc,+
        TRANSITION_PLAYER_STATE JUMPING
      +:

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

    ; State of buttons 1 and 2 to differentiate keydown/keypress.
    ld a,FALSE
    ld (accept_button_1_input),a
    ld (accept_button_2_input),a
    call is_button_1_pressed
    jp c,+
      ld a,TRUE
      ld (accept_button_1_input),a
    +:
    call is_button_2_pressed
    jp c,+
      ld a,TRUE
      ld (accept_button_2_input),a
    +:

    ld a,FALSE
    ld (is_scrolling),a
    ld a,(scroll_enabled)
    cp TRUE
    jp nz,+    
      ; Check if screen should scroll instead of right movement.
      ld a,(player_x)
      cp SCROLL_POSITION
      jp c,+
        ; Player is over the scroll position
        ld a,(hspeed)
        bit 7,a             ; Negative value = walking left
        jp nz,+ 
        cp 0                ; Zero = no horizontal motion.
        jp z,+
          ADD_TO SCORE_ONES, 2
          
          xor a
          ld (hspeed),a
          ; Scroll instead
          ld a,TRUE
          ld (is_scrolling),a
          ld a,(hscroll_screen)
          dec a                     
          ld (hscroll_screen),a
          
          ld a,(hscroll_column)
          inc a                     
          ld (hscroll_column),a
          cp 8
          jp nz,+
            xor a
            ld (hscroll_column),a
            ; Load new column
            call next_metatile_half_to_tile_buffer
            ld hl,column_load_trigger               ; Load on next vblank.
            inc (hl)
    +:

    ; End of map check.
    ld a,(end_of_map)
    cp TRUE
    jp z,+
      
      ld hl,(end_of_map_data)
      ex de,hl
      ld hl,(map_head)
      sbc hl,de
      jp c,+
        ld a,FALSE
        ld (scroll_enabled),a
        ld (spawn_minions),a
        ld a,TRUE
        ld (end_of_map),a
    +:

    ; Check if player is about to exit the left side of the screen.
    ld a,(player_x)
    cp LEFT_LIMIT
    jp nc,+
      ld a,(hspeed)
      bit 7,a             ; Positive value = walking right
      jp z,+ 
      cp 0                ; Zero = no horizontal motion.
      jp z,+
        xor a
        ld (hspeed),a
    +:

    ; Check if player is about to exit the right side of the screen.
    ld a,(player_x)
    cp RIGHT_LIMIT
    jp c,+
      ld a,(hspeed)
      bit 7,a             ; Negative value = walking left
      jp nz,+ 
      cp 0                ; Zero = no horizontal motion.
      jp z,+
        xor a
        ld (hspeed),a
    +:


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

    LOAD_BYTES killbox_y, 0, killbox_x, 0
    ; Add the sword sprite on the relevant player states.
    ld a,(state)
    cp ATTACKING
    jp z,+
    cp JUMP_ATTACKING
    jp z,+
    jp _f
    +:
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
          ld (killbox_y),a
          ld a,(player_x)
          add a,16
          ld e,a
          ld (killbox_x),a
          call add_sprite
          jp _f
        +:
          ld c,64
          ld a,(player_y)
          add a,8
          ld d,a
          ld (killbox_y),a
          ld a,(player_x)
          sub 8
          ld e,a
          ld a,(killbox_width)
          ld b,a
          ld a,(player_x)
          sub b
          ld (killbox_x),a
          call add_sprite
    __:

    ; Minions
    ld hl,spawner
    call tick_counter
    jp nc,+++                   ; Skip forward if the counter is not up.
      ld a,(brute_state)
      cp BRUTE_DEACTIVATED
      jp z,+
        ld b,60
        jp ++
      +:
        ld b,75
      ++:
      call get_random_number  ; Counter is up - get a random number 0-255.
      cp b                   ; Roll under the spawn chance.
      jp nc,+++
        call spawn_minion     ; OK, spawn a minion.
    +++:
    call process_minions
    call draw_minions

    ; Items
    call process_items
    call draw_items

    ; Brute
    call process_brute
    call draw_brute



  jp main_loop
.ends
.bank 1 slot 1
 ; ----------------------------------------------------------------------------
.section "Bank 1" free
; -----------------------------------------------------------------------------

.ends

.bank 2 slot 2
 ; ----------------------------------------------------------------------------
.section "Demo assets" free
; -----------------------------------------------------------------------------

  solid_block:
    ; Filled with color 1 in the palette:
    .db $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00



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
    level_1_map_end:

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

  jump_attacking_frame_to_index_table:
    .db 13 15 17
    __:

  state_to_frame_table:
    .dw idle_frame_to_index_table
    .dw walking_frame_to_index_table
    .dw attacking_frame_to_index_table
    .dw jumping_frame_to_index_table
    .dw jump_attacking_frame_to_index_table
    __:

  state_to_frames_total_table:
    .db _sizeof_idle_frame_to_index_table
    .db _sizeof_walking_frame_to_index_table
    .db _sizeof_attacking_frame_to_index_table
    .db _sizeof_jumping_frame_to_index_table
    .db _sizeof_jump_attacking_frame_to_index_table

  jump_counter_to_vspeed_table:
    .db -5, -4, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -2, -2, -1, -1 
    .db 1 1 2 2 3 3 3 3 3 3 3 3 3 3 4 5 

  jump_counter_to_hspeed_table:
    .db 4 3 3 2 2 2 2 2 2 2 2 2 2 2 2 2
    .db 2 2 2 2 2 2 2 2 2 2 2 2 1 1 1 1


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



.ends