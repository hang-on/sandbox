; tiny_games.asm.
;

.macro RESET_VARIABLES ARGS VALUE
  ; Set one or more byte-sized vars in RAM with the specified value.
  ld a,VALUE
  .rept NARGS-1
    .shift
    ld (\1),a
  .endr
.endm

.macro RESET_BLOCK ARGS VALUE, START, SIZE
  ; Reset af block of RAM of SIZE bytes to VALUE, starting from label START.
  ld a,VALUE
  ld hl,START
  .rept SIZE
    ld (hl),a
    inc hl
  .endr
.endm

.macro LOAD_BYTES
  ; IN: Pair of byte-sized variable and value to load
  .rept (NARGS/2)
    ld a,\2
    ld (\1),a
    .shift
    .shift
  .endr
.endm

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Tiny Games Library" free
; -----------------------------------------------------------------------------

  function_at_hl:
    ; Emulate a call (hl) function.
    jp (hl)


  is_reset_pressed:
    ld a,(input_ports+1)
    and %00010000
    ret nz            ; Return with carry flag reset
    scf
  ret                 ; Return with carry flag set.

  is_button_1_pressed:
    ld a,(input_ports)
    and %00010000
    ret nz            ; Return with carry flag reset
    scf
  ret                 ; Return with carry flag set.

  is_button_2_pressed:
    ld a,(input_ports)
    and %00100000
    ret nz            ; Return with carry flag reset
    scf
  ret                 ; Return with carry flag set.


  is_dpad_pressed:
    ld a,(input_ports)
    and %00001111   ; Isolate the dpad bits.
    cpl             ; Invert bits; now 1 = keypress!
    and %00001111   ; Get rid of garbage from cpl in last four bits.
    cp 0            ; Now, is any dpad key preseed?
    ret z           ; No, then return with carry flag reset (by the AND).
    scf             ; Yes, then set carry flag and...
  ret               ; Return with carry flag set.

  is_left_or_right_pressed: ; might be buggy!!
    ld a,(input_ports)
    and %00001100   ; Isolate the bits.
    cpl             ; Invert bits; now 1 = keypress!
    and %00001100   ; Get rid of garbage 
    cp 0            ;
    ret z           ; No, then return with carry flag reset (by the AND).
    scf             ; Yes, then set carry flag and...
  ret               ; Return with carry flag set.


  is_left_pressed:
    ld a,(input_ports)
    and %00000100
    ret nz          ; Return with carry flag reset
    scf
  ret               ; Return with carry flag set.

  is_right_pressed:
    ld a,(input_ports)
    and %00001000
    ret nz          ; Return with carry flag reset
    scf
  ret               ; Return with carry flag set.


  lookup_byte:
    ; IN: a = value, hl = look-up table (ptr).
    ; OUT: a = converted value.
    ld d,0
    ld e,a
    add hl,de
    ld a,(hl)
  ret

  lookup_word:
    ; IN: a = value, hl = look-up table (ptr).
    ; OUT: hl = converted value (word).
    add a,a
    ld d,0
    ld e,a
    add hl,de
    ld a,(hl)
    ld b,a
    inc hl
    ld a,(hl)
    ld h,a
    ld l,b
  ret

  offset_byte_table:
    ; Offset base address (in HL) of a table of bytes or words. 
    ; Entry: A  = Offset to apply.
    ;        HL = Pointer to table of values (bytes or words).  
    ; Exit:  HL = Offset table address.
    ; Uses:  A, HL
    add a,l
    ld l,a
    ld a,0
    adc a,h
    ld h,a
  ret
  

  offset_word_table:
    add a,a              
    add a,l
    ld l,a
    ld a,0
    adc a,h
    ld h,a
  ret

  offset_custom_table:
    ; IN: A = Table index, HL = Base address of table, 
    ;     B = Size of table item.
    ; OUT: HL = Address of item at specified index.
    cp 0
    ret z    
    ld d,0
    ld e,b
    ld b,a
    -:
      add hl,de
    djnz -
  ret

  spr_2x2:
    ; spr id x y 
    ; IN: A = id, index in the sprite tile bank.
    ;     D = y, E = x (screen position - upper left corner).
    ld c,a
    call add_sprite
    ld a,8
    add e
    ld e,a
    inc c
    call add_sprite
    ld a,32
    add c
    ld c,a
    ld a,8
    add d
    ld d,a
    call add_sprite
    dec c
    ld a,e
    sub 8
    ld e,a
    call add_sprite
  ret


  tick_counter:
    ; Decrement a counter (byte) in ram. Reset the counter when it reaches 0, 
    ; and return with carry flag set. Counter format in RAM (word): cc rr, 
    ; where cc is the current counter value and rr is the reset value.
    ; IN: HL = Pointer to counter + reset value.
    ; OUT: Value in counter is decremented or reset, carry set or reset.
    ; Uses: A, HL.
    ld a,(hl)                 ; Get counter.
    dec a                     ; Decrement it ("tick it").
    jp nz,+                   ; Is it 0 now?
      inc hl                  ; If so, point to reset value.
      ld a,(hl)               ; Load it into A.
      dec hl                  ; Point to counter value
      ld (hl),a               ; Load reset value into counter value.
      scf                     ; Set carry flag.
      ret                     ; Return with carry set.
    +:              
    ld (hl),a                 ; Else, load the decremented value into counter.
    or a                      ; Reset carry flag.
  ret                         ; Return with carry reset.


.ends