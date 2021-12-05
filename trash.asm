

    ; Clear the top two rows with that special tile.
    ld hl,NAME_TABLE_START
    call setup_vram_write
    ld b,32*2
    -:
      ld a,$fa ; Tilebank index of special tile.
      out (DATA_PORT),a
      ld a,%00000001
      out (DATA_PORT),a
    djnz -


     metatile_lut:
    .rept 90 INDEX COUNT
      .dw $2000+(COUNT*$40) ; Address of top-left tile
      .dw $2400+(COUNT*$40) ; Address of bottom-left tile
      .dw $2020+(COUNT*$40) ; Address of top-right tile
      .dw $2420+(COUNT*$40) ; Address of bottom-right tile
    .endr
    
  ;load_column_xx:
    .rept 20 INDEX COUNT
      ld hl,$3880+COUNT*64
      call setup_vram_write
      ld a,(column_buffer+COUNT)
      out (DATA_PORT),a   
      ld a,%00000001
      out (DATA_PORT),a
    .endr


    ; Write first half of meta tile to name table.
    ld hl,$3802
    call setup_vram_write
    ld a,0    
    out (DATA_PORT),a   
    ld a,%00000001
    out (DATA_PORT),a
    
    ld hl,$3842
    call setup_vram_write
    ld a,32    
    out (DATA_PORT),a   
    ld a,%00000001
    out (DATA_PORT),a


    ; Write first half of meta tile to name table.
    ld hl,$3882
    call setup_vram_write
    ld a,$40    
    out (DATA_PORT),a   
    ld a,%00000001
    out (DATA_PORT),a
    
    ld hl,$38C2
    call setup_vram_write
    ld a,$60   
    out (DATA_PORT),a   
    ld a,%00000001
    out (DATA_PORT),a


    ld hl,test_anim_counter
    call tick_counter
        ; Count down to next frame.
    jp nc,+
      ld hl,test_frame
      inc (hl)
    +:
    ; Reset/loop animation if last frame expires. 
    ld hl,test_frame
    ld a,_sizeof_attacking_frame_to_index_table
    call reset_hl_on_a
    
    ld a,(test_frame)
    ld hl,attacking_frame_to_index_table
    call lookup_byte
    ld de,$8080
    call spr_2x2
    ld a,(test_frame)
    cp 1
    jp c,+
      ld c,32
      ld d,$88
      ld e,$90
      call add_sprite
    +:
  test_anim_counter dw
  test_frame db

  
    ; test
    ld a,0
    ld (test_frame),a
    ld a,ANIM_COUNTER_RESET
    ld (test_anim_counter),a
    ld (test_anim_counter+1),a

