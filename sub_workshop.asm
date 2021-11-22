
.ramsection "Ram section for library being developed" slot 3

 

.ends


.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------


.ends

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Looping Bytestreams" free
; -----------------------------------------------------------------------------
  ; A looping bytestream is a simple 8-bit table with a header that consists
  ; of an index and a threshold. The index is automatically incremented on
  ; every read from the stream, and when it reaches the threshold, it is
  ; reset (thus it loops). After it is initialized, the stream can be inter-
  ; faced with a function that will read and return the next byte from the 
  ; stream, and increment or reset the internal index as necessary.

  init_looping_bytestream:
    ; Initialize a block in RAM to work as a looping bytestream.
    ; Init data must have the following format:
    ; header [ii tt] stream[ bb bb bb...], where ii is the starting index,
    ; tt is the threshold (the loop point) and bb is a array of bytes the size
    ; of tt+1.
    ; In:   hl = Ptr. to init data.
    ;       de = Ptr. to looping bytestream.
    inc hl            ; Step forward to threshold.
    ld a,(hl)         ; Get threshold value.
    add a,2           ; Account for the bytestream's 2-byte header.
    ld b,a            ; Set up BC as a counter, least significant byte first.            
    ld c,0            ; The threshold value will control the LDIR below.
    dec hl            ; Step backwards to index (start of looping bytestream).
    ldir              ; Load the required amount of initialization data.
  ret                 

  get_next_byte:
    ; Get the next byte in the stream. Then increment or reset (loop) the
    ; bytestream index.
    ; In:   hl = Ptr. to looping bytestream.
    ; Out:  a = byte from stream.   
    push hl           ; Save the bytestream pointer for later.
      ld a,(hl)       ; Get the current index.
      ld d,0          ; Load DE with the index
      ld e,a          ; 
      add hl,de       ; Offset HL by [index] number of bytes.
      inc hl          ; Account for the first header byte (index).
      inc hl          ; Account for the second header byte (loop threshold).
      ld a,(hl)       ; Get the byte from the bytestream.
    pop hl            ; Restore the original bytestream pointer.
    push af           ; Save the bytestream byte.
      ld a,(hl)       ; Get the current index.
      inc hl          ; Point to the loop threshold.
      ld b,(hl)       ; Load B with the loop threshold.
      dec hl          ; Point back to the current index.
      cp b            ; Is the current index = the loop threshold?
      jp nz,+         ; 
        xor a         ; Yes, time to reset the index. 
        ld (hl),a     ; Reset index.
        jp ++         ; 
      +:              ; No, just increment the index.
        inc (hl)      ; Increment index pointed to by HL.
      ++:             ;
    pop af            ; Restore the bytestream byte to A.
  ret


.ends
