
.ramsection "Ram section for library being developed" slot 3

  my_word_counter dsb 4
.ends

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------

  tick_word_counter:
    ; Decrement a counter (word) in ram. Reset the counter when it reaches 0, 
    ; and return with carry flag set. Counter format in RAM (word): cc rr, 
    ; where cc is the current counter value and rr is the reset value.
    ; IN: HL = Pointer to counter (cc cc) + reset value (rr rr). Both LSB.
    ; OUT: Value in counter is decremented or reset, carry set or reset.
    ; Uses:
    ld a,(hl)                 ; Get counter.
    dec a                     ; Decrement it ("tick it").
    jp nz,+                   ; Is it 0 now?
      inc hl
      ld a,(hl)
      cp 0
      jp nz,++
        ; Counter is 0000, reset to value and return with carry.
        push hl
        pop de
        dec de
        inc hl
        ldi
        ldi
        scf
        ret
      ++:
      dec a
      ld (hl),a
      inc hl
      ld a,(hl)
      dec hl
      dec hl
      ld a,(hl)
      ret
    +:              
    ld (hl),a                 ; Else, load the decremented value into counter.
    or a                      ; Reset carry flag.
  ret                         ; Return with carry reset.





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