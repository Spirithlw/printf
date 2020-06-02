section .text

%include        "myprintf.s"

global _start

_start:                
                push 80
                push 95
                push str_test
                call printf
                push NS
                call writech

                EXIT 0

section .data
str_test:     db "check 123 %d %x", 0
