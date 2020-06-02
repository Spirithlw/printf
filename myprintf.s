
section .text
NS              equ 10 

global _start


;=========================================================================
;syscall write string macro
;expects:       rdx   - string length
;               rsi   - string adress
;destroy:       rax, rdi
;returns:       rcx
;=========================================================================

%macro          WRITE_STR 0

                mov rax, 1
                mov rdi, 1
                syscall

                %endmacro

;=========================================================================
;exit
;expects:       %1 - exit code
;destroy:       rax, rdi
;=========================================================================

%macro          EXIT 1

                mov rax, 0x3C
                mov rdi, %1
                syscall

                %endmacro                

;================================================================
;printf function
;expexts:   [rsp+8] - addres of format string
;           [rsp+8(i+1)] - arguments
;destroy:   
;returns:   none
;======================================================================

printf:
                xor rbx, rbx
                mov rdi, [rsp+8]
                lea rax,  [rsp+16]

.cycle:         mov bl, [rdi]   
                cmp bl, '%'
                jne .ussym

                call prcnt      

                jmp .cycle

.ussym:         cmp bl, 0
                je .exit

                push rax 
                push rdi
                push bx

                call writech

                pop bx
                pop rdi 
                pop rax

                inc rdi
                jmp .cycle

.exit:
                ret

;=========================================================================
;% handler
;expects:       rax - addres of argument
;               rdi - addres of %
;destroy:       rax, rdi, rbx, rcx, r8, rsi, rdx
;returns:       rdi - new symbol
;               rax - addres of new argument
;=========================================================================
prcnt:
                inc rdi
                mov bl, [rdi]
                
                cmp bl, '%'
                je perc

                cmp bl, 'b'
                jb err
                cmp bl, 'x'
                ja err

                sub bl, 'b'
                mov rdx, [jmptable + 8*rbx ]
                jmp rdx

char:           push rax
                push rdi
                
                mov rcx, [rax]
                push rcx
                call writech
                pop rcx

                pop rdi
                pop rax 

                inc di
                add rax, 8
                ret  

str:            mov rdx, [rax]

                push rax
                push rdi

                push rdx
                call strlen
                pop rdx

                pop rdi
                pop rax

                mov rsi, [rax]
                mov rdx, rcx

                push rax
                push rdi
                WRITE_STR
                pop rdi
                pop rax

                inc di
                add rax, 8
                ret

bin:            mov rsi, [rax]
                push rax
                push rsi
                call bintrns
                pop r8

                mov rcx, 64
                push rdi
                call numout

                pop rdi
                pop rax
 
                inc di
                add rax, 8  
                ret                

oct:            mov rsi, [rax]
                push rax
                push rsi
                call octtrns
                pop r8

                mov rcx, 21
                push rdi
                call numout

                pop rdi
                pop rax
 
                inc di
                add rax, 8  
                ret

dec:            mov rsi, [rax]
                push rax
                push rsi
                call dectrns
                pop r8

                mov rcx, 20
                push rdi
                call numout

                pop rdi
                pop rax
 
                inc di
                add rax, 8
                ret

hex:            mov rsi, [rax]
                push rax
                push rsi
                call hextrns
                pop r8

                mov rcx, 16
                push rdi
                call numout

                pop rdi
                pop rax
 
                inc di
                add rax, 8  
                ret

perc:           push rax
                push rdi
                
                push bx
                call writech
                pop bx
                pop rdi
                pop rax

                inc rdi
                ret                

err:            mov rsi, errstr
                mov rdx, 31

                push rdi 
                push rax

                push errstr
                WRITE_STR
                pop rax
                
                pop rax
                pop rdi

                inc rdi
                ret

                ret

;=========================================================================
;print char func
;expects:        [rsp+8] - char 
;destroy:       rax, rdx, rdi, rsi
;returns:
;=========================================================================

writech:                         
                lea rsi, [rsp+8]        
                mov rdx, 1

                WRITE_STR

                ret

;=========================================================================
;strlen function
;expects:   [rsp+8] - string addres
;destroy:   rax, rdi
;returns:   rcx - length 
;=========================================================================

strlen:
                mov rdi, [rsp+8]

                xor rcx, rcx
                not rcx
                xor rax, rax


                cld
                repne scasb

                sub rdi, [rsp+8]
                dec rdi
                mov rcx, rdi
                ret

;=========================================================================
;writes number in buffer in bin form
;expects:       [rsp+8] - number
;destroy:       rax, rcx, rdx
;returns:       rsi - buffer addres
;=========================================================================

bintrns:        
                std
                mov rax, [rsp + 8]
                mov rcx, 64                             

.cycle:         mov rdx, 1
                and dl, al
                
                mov dl, [numbstring + rdx]               
                mov [outbuf + rcx - 1], dl    

                shr rax, 1    
                loop .cycle

                mov rsi, outbuf

                ret

;=========================================================================
;writes number in buffer in oct form
;expects:       [rsp+8] - number
;destroy:       rax, rcx, rdx
;returns:       rsi - buffer addres
;=========================================================================

octtrns:
                std
                mov rax, [rsp + 8]
                mov rcx, 21                             

.cycle:         mov rdx, 7
                and dl, al
                
                mov dl, [numbstring + rdx]               
                mov [outbuf + rcx - 1], dl    

                shr rax, 3    
                loop .cycle

                mov rsi, outbuf

                ret                
;=========================================================================
;writes number in buffer in hex form
;expects:       [rsp+8] - number
;destroy:       rax, rcx, rdx
;returns:       rsi - buffer addres
;=========================================================================

hextrns:
                std
                mov rax, [rsp + 8]
                mov rcx, 16                             

.cycle:         mov rdx, 15
                and dl, al
                
                mov dl, [numbstring + rdx]               
                mov [outbuf + rcx - 1], dl    

                shr rax, 4    
                loop .cycle

                mov rsi, outbuf

                ret  

;=========================================================================
;writes number in buffer in dec form
;expects:       [rsp+8] - number
;destroy:       rax, rcx, rdx
;returns:       rsi - buffer addres
;=========================================================================

dectrns:
                mov rax, [rsp + 8]
                mov rcx, 20
                mov rsi, 10                             

.cycle:          xor rdx, rdx
                div rsi
                mov dl, [numbstring + rdx]               
                mov [outbuf + rcx - 1], dl        
                loop .cycle

                mov rsi, outbuf

                ret

;=========================================================================
;writes string with number, without first zeroes
;expects:       rsi - string adress
;               rcx - length
;destroy:       rcx, rax, rdi
;returns:       none
;=========================================================================                

numout:
                mov rdi, outbuf
                mov al, '0'

                cld
                repe scasb                             

                dec rdi
                mov rsi, rdi

                inc rcx
                mov rdx, rcx
                
                WRITE_STR
                ret                

section .data
outbuf:         times 64 db 0

numbstring:     db "0123456789ABCDEF"
errstr:         db "Error, unknown format specifier"

jmptable        dq bin
                dq char
                dq dec
                times ('n' - 'd') dq err
                dq oct
                times ('r' - 'o') dq err
                dq str
                times ('w' - 's') dq err
                dq hex