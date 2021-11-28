; tiny_games.asm.
; General library of definitions, macros and functions.

.equ ENABLED $ff
.equ DISABLED 0
.equ TRUE $ff
.equ FALSE 0

; -----------------------------------------------------------------------------
.macro FILL_MEMORY args value
; -----------------------------------------------------------------------------
;  Fills work RAM ($C001 to $DFF0) with the specified value.
  ld    hl, $C001
  ld    de, $C002
  ld    bc, $1FEE
  ld    (hl), value
  ldir
.endm
; -----------------------------------------------------------------------------
.macro RESTORE_REGISTERS
; -----------------------------------------------------------------------------
  ; Restore all registers, except IX and IY
  pop iy
  pop ix
  pop hl
  pop de
  pop bc
  pop af
.endm
; -----------------------------------------------------------------------------
.macro SAVE_REGISTERS
; -----------------------------------------------------------------------------
  ; Save all registers, except IX and IY
  push af
  push bc
  push de
  push hl
  push ix
  push iy
.endm
; -----------------------------------------------------------------------------
.macro SELECT_BANK_IN_REGISTER_A
; -----------------------------------------------------------------------------
  ; Select a bank for slot 2, - put value in register A.
  .ifdef USE_TEST_KERNEL
    ld (test_kernel_bank),a
  .else
    ld (SLOT_2_CONTROL),a
  .endif
.endm
; -----------------------------------------------------------------------------
.macro RESET_VARIABLES ARGS VALUE
; -----------------------------------------------------------------------------
  ; Set one or more byte-sized vars in RAM with the specified value.
  ld a,VALUE
  .rept NARGS-1
    .shift
    ld (\1),a
  .endr
.endm
; -----------------------------------------------------------------------------
.macro RESET_BLOCK ARGS VALUE, START, SIZE
; -----------------------------------------------------------------------------
  ; Reset af block of RAM of SIZE bytes to VALUE, starting from label START.
  ld a,VALUE
  ld hl,START
  .rept SIZE
    ld (hl),a
    inc hl
  .endr
.endm
; -----------------------------------------------------------------------------
.macro LOAD_BYTES
; -----------------------------------------------------------------------------
  ; Load byte-sized variables with matching values. Useful for initializing. 
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

  get_random_number:
    ; SMS-Power!
    ; Returns an 8-bit pseudo-random number in a
    .ifdef TEST_MODE
      ld a,(random_number)
      ret
    .endif
    push hl
      ld hl,(rnd_seed)
      ld a,h         ; get high byte
      rrca           ; rotate right by 2
      rrca
      xor h          ; xor with original
      rrca           ; rotate right by 1
      xor l          ; xor with low byte
      rrca           ; rotate right by 4
      rrca
      rrca
      rrca
      xor l          ; xor again
      rra            ; rotate right by 1 through carry
      adc hl,hl      ; add RandomNumberGeneratorWord to itself
      jr nz,+
        ld hl,$733c  ; if last xor resulted in zero then re-seed.
      +:
      ld a,r         ; r = refresh register = semi-random number
      xor l          ; xor with l which is fairly random
      ld (rnd_seed),hl
    pop hl
  ret              ; return random number in a

  function_at_hl:
    ; Emulate a call (hl) function.
    jp (hl)

  get_word:
    ; Get the 16-bit value (word) at the address pointed to by HL.
    ; In: Pointer in HL.
    ; Out: Word pointed to in HL.
    ; Uses: DE, HL.
    ld e,(hl)
    inc hl
    ld d,(hl)
    ex de,hl
  ret

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
    .ifdef TEST_MODE
      ; Use the fake SAT...
      ld b,a
      ld a,(fake_sat_index)
      ld hl,fake_sat_y
      call offset_byte_table
      ld (hl),d
      ld a,(fake_sat_index)
      ld hl,fake_sat_xc
      call offset_word_table
      ld (hl),e
      inc hl
      ld (hl),b
      ld hl,fake_sat_index
      inc (hl)
    .else
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
    .endif
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