; Items

.equ ITEM_DEACTIVATED $ff
.equ ITEM_ACTIVATED 0
.equ APPLE 0
.equ TOMATO 1
.equ JUG 2
.equ GOLD 3

.equ ITEM_MAX 3


.struct item
  state db
  y db
  x db
  index db
  timer db
.endst

.ramsection "Items ram section" slot 3
  items INSTANCEOF item 3
  item_spawner dw
  spawn_items db
  item_pool db
  item_pool_counter db
.ends

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Items" free
; -----------------------------------------------------------------------------
  ; INIT:
  initialize_items:
    ; In: hl = ptr. to init data.
    RESET_BLOCK 60, item_spawner, 2
    LOAD_BYTES item_pool, 0, item_pool_counter, 0
    ld hl,item_init_data
    ld de,items
    ld bc,_sizeof_item_init_data
    ldir
    LOAD_BYTES spawn_items, TRUE
  ret
    item_init_data:
      .rept ITEM_MAX
        .db ITEM_DEACTIVATED
        .rept _sizeof_item-1
          .db 0
        .endr
      .endr
      __:
  ; --------------------------------------------------------------------------- 
  ; DRAW:
  draw_items:
    ; Put non-deactivated items in the SAT buffer.
    ld ix,items
    ld b,ITEM_MAX
    -:                          ; For all non-deactivated items, do...
      push bc                   ; Save loop counter.
        ld a,(ix+item.state)
        cp ITEM_DEACTIVATED
        jp z,+
          ld d,(ix+item.y)
          ld e,(ix+item.x)
          ld a,(ix+item.index); FIXME: Depending on direction and state!
          call spr_2x2          ; + animation...
        +:
        ld de,_sizeof_item    
        add ix,de               ; Point ix to next item.
      pop bc                    ; Restore loop counter.
    djnz -                      ; Process next item.
  ret
  ; --------------------------------------------------------------------------- 
  ; UPDATE:
  process_items:
    ld ix,items
    ld b,ITEM_MAX
    -:                          ; For all non-deactivated items, do...
      push bc                   ; Save loop counter.
        ld a,(ix+item.state)
        cp ITEM_DEACTIVATED
        jp z,+
          call @check_limit
          call @check_collision
          call @move
          ; ...
        +:
        ld de,_sizeof_item    
        add ix,de               ; Point ix to next item.
      pop bc                    ; Restore loop counter.
    djnz -                      ; Process next item.    
  ret

    @check_limit:
      ld a,(ix+item.x)
      cp LEFT_LIMIT
      call c,deactivate_item
    ret
    @check_collision: 
      ; Axis aligned bounding box:
      ;    if (rect1.x < rect2.x + rect2.w &&
      ;    rect1.x + rect1.w > rect2.x &&
      ;    rect1.y < rect2.y + rect2.h &&
      ;    rect1.h + rect1.y > rect2.y)
      ;    ---> collision detected!
      ; ---------------------------------------------------
      ; IN: IX = Pointer to item struct. (rect 1)
      ;     IY = Pointer to arthur (y, x, height, width of rect2.)
      ; OUT:  Carry set = collision / not set = no collision.
      ;
      ; rect1.x < rect2.x + rect2.width
      ;
      ld iy,player_y

      ld a,(iy+1)
      add a,(iy+3)
      ld b,a
      ld a,(ix+item.x)
      cp b
      ret nc
        ; rect1.x + rect1.width > rect2.x
        ld a,(ix+item.x)
        add a,16
        ld b,a
        ld a,(iy+1)
        cp b
        ret nc
          ; rect1.y < rect2.y + rect2.height
          ld a,(iy+0)
          add a,(iy+2)
          ld b,a
          ld a,(ix+item.y)
          cp b
          ret nc
            ; rect1.y + rect1.height > rect2.y
            ld a,(ix+item.y)
            add a,16
            ld b,a
            ld a,(iy+0)
            cp b
            ret nc
      ; Collision! 
      ld hl,item_sfx
      ld c,SFX_CHANNELS2AND3                  
      call PSGSFXPlay                         ; Play the SFX with PSGlib.
      ;      
      ld a,ITEM_DEACTIVATED
      ld (ix+item.state),a
    ret 
    
    @move:
      ld a,(is_scrolling)
      cp TRUE
      ret nz
        ld a,(ix+item.x)
        sub 1
        ld (ix+item.x),a
    ret


  deactivate_item:  
      ld a,ITEM_DEACTIVATED
      ld (ix+item.state),a
  ret

  spawn_item:
    ld a,(spawn_items)
    cp TRUE
    ret nz
    ld a,(item_pool)
    cp 0
    ret z

    ; Spawn a item.
    ld hl,item_pool
    dec (hl)

    ld ix,items
    ld b,ITEM_MAX
    -:
      ld a,(ix+item.state)
      cp ITEM_DEACTIVATED
      jp z,@activate
      ld de,_sizeof_item
      add ix,de
    djnz -
    scf   ; Set carry = failure (no deactivated item to spawn).
  ret
    @activate:  
      ld a,ITEM_ACTIVATED
      ld (ix+item.state),a
      call get_random_number
      and %01111111
      add a,80
      ld (ix+item.x),a
      call get_random_number
      and %00011111
      add a,24
      ld b,a
      ld a,FLOOR_LEVEL
      sub b
      ld (ix+item.y),a
      call get_random_number
      and %00000011
      add a,a
      add a,$8c
      ld (ix+item.index),a
    ret



.ends

