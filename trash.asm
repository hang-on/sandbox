
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

