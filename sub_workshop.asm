
.ramsection "Ram section for library being developed" slot 3

  my_slow_counter dsb 3
.ends

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------

  tick_slow_counter:
    ; xxx
    ld a,(hl)                 ; Get counter.
    dec a                     ; Decrement it ("tick it").
    jp nz,+
      ld (hl),a
      ; Decrement the cycle counter.
      inc hl
      ld a,(hl)
      cp 0
      jp nz,++
        ;; Reset counter, set carry
        ; Add reset
        scf
        ret
      ++:
      dec a
      ld (hl),a
      ret
    +:
    ld (hl),a                 ;
    or a                      ; Reset carry. 
  ret                         ; 





  detect_collision:
    ; Axis-aligned bounding box.
    ;    if (rect1.x < rect2.x + rect2.w &&
    ;    rect1.x + rect1.w > rect2.x &&
    ;    rect1.y < rect2.y + rect2.h &&
    ;    rect1.h + rect1.y > rect2.y)
    ;    ---> collision detected!
    ; In: ix = y,x,h,w of box 1.
    ;     iy = y,x,h,w of box 2.
    ; Out: Carry is set if the boxes overlap.
    
    ; Test 1: rect1.x < rect2.x + rect2.w
    ld a,(iy+1)         
    add a,(iy+3)
    ld b,a
    ld a,(ix+1)
    cp b
    ret nc
      ; Test 2: rect1.x + rect1.w > rect2.x
      ld a,(ix+1)
      add a,(ix+3)
      ld b,a
      ld a,(iy+1)
      cp b
      ret nc
        ;Test 3: rect1.y < rect2.y + rect2.h
        ld a,(iy+0)
        add a,(iy+2)
        ld b,a
        ld a,(ix+0)
        cp b
        ret nc
          ; Test 4: rect1.h + rect1.y > rect2.y
          ld a,(ix+0)
          add a,(ix+2)
          ld b,a
          ld a,(iy+0)
          cp b
          ret nc
    ; Fall through to collision!
    scf
  ret

.ends