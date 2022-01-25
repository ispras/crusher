 B .
 B .
 B .
 B .
 B .
 B .
 B .
 B .

.global entry
entry:
 LDR R0, =stack_top
 MOV SP, R0
 BL c_entry
