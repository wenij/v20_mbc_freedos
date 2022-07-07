\ LMTICKER.F
\
\ Implementation of LMI timer variables.  Uses DOS
\ interrupt 1C to decrement timer variables (10 max) at
\ a rate of 54.9254 ms.
\
\ WARNING: this code alters the DOS interrupt vectors.
\ Use at your own risk!
\
\ ---------------------------------------------------------
\
\ A timer variable may be any address representing a single
\ cell e.g. normal VARIABLE, or STATUS field in an LMI-style
\ multitasker.
\
\ TIK# max number of timer variables (default = 10)
\
\ TIKTAB is the timer address table.  Each cell contains:
\ -1    unused
\  0    end of list
\ addr  timer variable address (see TICKER)
\
\ INITVEC redirects DOS interrupt 1C to point to INT_1C.
\ Must be run once at start-up.
\
\ RESETVEC restores the old interrupt vector.  Use before
\ exiting forth or deleting any definitions!
\
\ TICKER add/enable timer variable addr.  If success, ior
\ is 0 and the single-precision number at addr is
\ decremented once each time tick. If count is 0 or -1,
\ it is unchanged.
\
\ -TICKER disables the timer variable at addr.
\
\ ---------------------------------------------------------

forth definitions hex

0A constant TIK#  \ max timer variables

create TIKTAB  tik# 1+ cells allot

tiktab tik# 1+ cells erase

2variable OLD_1C  \ old interrupt vector

label INT_1C ( -- )
  bx push  di push  ds push
  cs ax mov  ax ds mov
  tiktab cell- # di mov
1 $:  2 # di add  0 [di] bx mov  \ get cell contents
  bx bx or  3 $ jz           \ 0 = no more
  -1 # bx cmp  1 $ jz        \ -1 = skip
\  DP ) bx cmp  2 $ jnb       \ timer addr in dictionary?
  -1 # 0 [bx] cmp  1 $ jz    \ count = -1 ?
  -1 # 0 [bx] test  1 $ jz   \ count = 0 ?
  0 [bx] dec  1 $ ju         \ decr count
2 $:  -1 # 0 [di] mov  1 $ ju
3 $:  ds pop  di pop  bx pop
  cs: OLD_1C [] far jmp      \ DOS interrupt handler
end-code

\ Add/enable timer variable addr
code TICKER ( addr -- ior )
  bx pop  si push
  tiktab # si mov  tik# # cx mov
1 $:  lods  ax ax or  2 $ jz
  bx ax cmp  3 $ jz  ax inc  2 $ jz
  1 $ loop
  -1 # bx mov  si pop  bx push  next
2 $:  bx -2 [si] mov
3 $:  bx bx xor  si pop  bx push  next
end-code

\ Disable timer variable
code -TICKER ( addr -- )
  bx pop  si push  tiktab # si mov
1 $:  lods  ax ax or  2 $ jz
  bx ax cmp  1 $ jnz
  -1 # -2 [si] mov
2 $:  si pop  next
end-code

variable INTFLG  0 intflg !

\ point INT_1C vector to forth
code INITVEC ( -- )
  0a5a5 # intflg ) cmp  1 $ jz
  0a5a5 # intflg ) mov
  351C # ax mov  21 int
  bx old_1c ) mov  es old_1c cell+ ) mov
  int_1c # dx mov  251C # ax mov  21 int  1 $: next
end-code

\ restore old INT_1C vector
code RESETVEC ( -- )
  0A5A5 # intflg ) cmp  1 $ jnz
  0 # intflg ) mov
  old_1c ) dx lds  251C # ax mov  21 int
  cs ax mov  ax ds mov  1 $:  next
end-code

decimal

\ ---------------------------------------------------------

0 [if] ( test)

cr cr ." Running Ticker demo " cr

variable TIMER1  \ create a timer variable

182 timer1 !     \ set timer var. for 10 sec count

: t. cr timer1 ? ;  \ display current count

timer1 ticker drop  \ add timer var. to ticker table

initvec           \ revector DOS 1C interrupt

t. 1000 ms  t. 1000 ms  t. 1000 ms  t. 1000 ms
t. 1000 ms  t. 1000 ms  t. 1000 ms  t. 1000 ms
t. 1000 ms  t. 1000 ms  t. 1000 ms  t. 1000 ms
t.

resetvec          \ restore DOS 1C interrupt

cr cr ." Done "

[then]

\ end
