init:
;
;  Set up segment registers for real mode
;

   mov ax,0x07C0
   mov ds,ax
   mov es,ax
   
;
;  Jump to the start of the program
;

   xor eax,eax
   mov ax,ds
   push eax
   push init_start
   retf

init_start:

   mov ax,0xb800
   mov gs,ax
   mov al,'1'
   mov [gs:1],al
   
   call read_os_data  
   jmp loader1

read_error:
   call newline
   mov ax,string_read_error
   call write_string
hang:
   jmp hang
   
write_string:
   push ax
   mov bx,ax
write_string_loop:
   mov al,[bx]
   cmp al,0
   je write_string_exit
   mov ah,0x0e
   int 0x10
   pop bx
   inc bx
   push bx
   jmp write_string_loop
write_string_exit:
   pop ax
   ret
   
write_dword:
   push dx
   mov ax,dx
   call write_word
   pop ax
   call write_word
   ret
   
write_word:
   push ax
   mov al,ah
   call write_byte
   pop ax
   call write_byte
   ret

write_byte:
   push ax
   ror al,4
   call write_digit
   pop ax
   call write_digit
   ret   
   
write_digit:
   and al,0x0f
   mov ah,0x0e
   cmp al,0x09
   jle write_digit_numeric
   add al,0x37
   int 0x10
   ret

write_digit_numeric:
   add al,0x30
   int 0x10
   ret

newline:
   push ax
   mov ax,0x0e0a
   int 0x10
   mov ax,0x0e0d
   int 0x10
   pop ax
   ret

string_banner:
   db "Hello",10,13,0

string_read_error:
   db "Error reading data",10,13,0

string_3:
   db "Initial Load Completed...",10,13,0

write_segment_registers:

   push ax

   push es
   push ss
   push ds
   push cs

   mov ax,string_cs
   call write_string
   pop ax
   call write_word

   mov ax,string_ds
   call write_string
   pop ax
   call write_word

   mov ax,string_ss
   call write_string
   pop ax
   call write_word

   mov ax,string_es
   call write_string
   pop ax
   call write_word

   call newline

   pop ax

   ret

write_index_registers:
   pop ax
   push ax
   push ax

   mov ax,sp
   push ax

   mov ax,bp
   push ax

   mov ax,si
   push ax

   mov ax,string_si
   call write_string
   pop ax
   call write_word

   mov ax,string_bp
   call write_string
   pop ax
   call write_word 

   mov ax,string_sp
   call write_string
   pop ax
   call write_word

   mov ax,string_ip
   call write_string
   pop ax
   call write_word
   call newline
   ret

write_registers:

   push dx
   push cx
   push bx
   push ax

   push dx
   push cx
   push bx
   push ax

   mov ax,string_ax
   call write_string
   pop ax
   call write_word

   mov ax,string_bx
   call write_string
   pop ax
   call write_word

   mov ax,string_cx
   call write_string
   pop ax
   call write_word

   mov ax,string_dx
   call write_string
   pop ax
   call write_word

   mov ax,string_newline
   call write_string
 
   call write_segment_registers
   call newline

   pop ax
   pop bx
   pop cx
   pop dx

   ret

string_ax:
  db "AX=",0
string_bx:
  db " BX=",0
string_cx:
  db " CX=",0
string_dx:
  db " DX=",0
string_newline:
  db 10,13,0

string_ds:
  db " DS=",0
string_cs:
  db "CS=",0
string_es:
  db " ES=",0
string_ss:
  db " SS=",0
string_bp:
  db " BP=",0
string_ip:
  db " IP=",0
string_si:
  db "SI=",0
string_sp:
  db " SP=",0
  
loader_size:
  db 0

read_os_data_string:
   db 'Read sector count:',0

read_os_data:
   mov ax,read_os_data_string
   call write_string

   mov ax,last_label
   add ax,511
   shr ax,9
   dec al
   and al,0x7f
   push ax
   inc al
   mov [loader_size],al
   pop ax
   push ax
   
   call write_byte
   call newline

   pop ax
   mov ah,0x02
   mov cx,0x02
   mov bx,0x0200
   mov dx,0x0000

   call write_registers

   int 0x13

   pushf 
   call write_registers
   popf

   cmp ah,0
   je read_ok
   jmp read_error

read_ok:
   ret

   times 510-($-$$) db 0
   db 0x55
   db 0xAA
   
;
; End of Boot Sector / Start of Main Loader
;

loader1:
   mov ax,0x5555
   mov [gs:2],ax
   mov ax,loader_1_string
   call write_string
   call write_registers
   call write_index_registers
   jmp enter_protected_mode

loader_1_string:
   db "Obtained rest of boot loader from disk",10,13,0

   times 1024-($-$$) db 0

string_enter_prot_mode:
   db 'Entering Protected Mode',0

string_gdt_base:
   db 'GDT Linear base address=0x',0
   
string_gdt_length:
   db 'GDT size=0x',0
   
segment_offset:
   db 'Displaying GDT Entry at 0x',0
segment_base:
   db 'Segment Base  =0x',0
segment_limit:
   db 'Segment Limit =0x',0 
segment_flags:
   db 'Segment Flags (0x80 Granularity, 0x40 Size) =0x',0
segment_access:
   db 'Segment Access =0x',0
     
[bits 16]
display_gdt_entry:
   push bx
   mov ax,segment_offset
   call write_string
   pop ax
   push ax
   call write_word
   call newline
   mov ax,segment_base
   call write_string
   pop bx
   push bx
   mov al,[bx+7]
   call write_byte
   pop bx
   push bx
   mov al,[bx+4]
   call write_byte
   pop bx
   push bx
   mov ax,[bx+2]
   call write_word
   call newline

   mov ax,segment_limit
   call write_string
   pop bx
   push bx
   mov al,[bx+6]
   and al,0x0f
   call write_byte
   pop bx
   push bx
   mov ax,[bx]
   call write_word
   call newline
   
   mov ax,segment_flags
   call write_string
   pop bx
   push bx
   mov al,[bx+6]
   and al,0xf0
   call write_byte
   call newline
   
   mov ax,segment_access
   call write_string
   pop bx
   push bx
   mov al,[bx+5]
   call write_byte
   
   call newline
   
   pop bx 
   ret
   
enter_protected_mode:
   mov ax,string_enter_prot_mode
   call write_string
   call newline
   
   mov ax,10
   shl ax,3
   dec ax
   mov [protected_gdt_data],ax

; Display GDT length
   mov ax,string_gdt_length
   call write_string
   mov ax,[protected_gdt_data]
   call write_word
   call newline

; Calculate Linear address of GDT table
   mov ax,ds
   shl ax,4
   add ax,gdt_base
   mov [protected_gdt_data+2],ax
   mov ax,0
   mov [protected_gdt_data+4],ax
   
; Display GDT data
   mov ax,string_gdt_base
   call write_string
   mov ax,[protected_gdt_data+2]
   call write_word
   mov ax,[protected_gdt_data+4]
   call write_word
   call newline
   
   mov bx,gdt_cs_entry
   call display_gdt_entry
   
   mov bx,gdt_ds_entry
   call display_gdt_entry
   mov bx,gdt_video_entry
   call display_gdt_entry

   mov bx,gdt_cs_16_entry
   call display_gdt_entry

   mov bx,gdt_ds_16_entry
   call display_gdt_entry

   mov bx,gdt_video_16_entry
   call display_gdt_entry

;   
; Enter Protected Mode
;

   sgdt [real_gdt_data]
   cli
   lgdt [protected_gdt_data]
   
   mov eax,cr0
   or al,1
   mov cr0,eax
   
   jmp dword 0x08:next_prot

[bits 32]   
next_prot:

;
; Set-up segment registers
;

   mov ax,0x10
   mov ds,ax
   mov es,ax
   mov ss,ax
   mov gs,ax
   mov fs,ax
   mov gs,ax
 
;  
; now in protected mode
;

   mov eax,string_prot_mode
   call write_string_32
   call newline_32
   
   mov eax,string_loading_program
   call write_string_32
   call newline_32
   
;
;  Now get 'loader 2' from disk ... read the first C program
;

   xor eax,eax
   mov ax,0x0209
   mov [interrupt_eax_value],eax

   xor eax,eax
   mov ax,last_label
   inc eax
   mov [interrupt_ebx_value],eax

   xor eax,eax
   mov al,[loader_size]
   inc al
   mov [interrupt_ecx_value],eax

   xor eax,eax
   mov [interrupt_edx_value],eax
   
   mov ax,0x07C0
   mov [interrupt_es_value],ax
   
   mov ax,0x13
   mov [interrupt_number],ax

   mov eax,[interrupt_eax_value]
   mov ebx,[interrupt_ebx_value]
   mov ecx,[interrupt_ecx_value]
   mov edx,[interrupt_edx_value]
   
   call invoke_real_mode_interrupt
   
   mov eax,[interrupt_eax_value]
   mov ebx,[interrupt_ebx_value]
   mov ecx,[interrupt_ecx_value]
   mov edx,[interrupt_edx_value]
   
   call newline_32
   mov eax,string_starting_stage_2
   call write_string_32
   call newline_32

   call invoke_c_program   
   
hang_final:
   push eax
   mov eax,string_program_returned
   call write_string_32
   pop eax
   call write_dword_32
   
   call newline_32
   mov eax,string_process_halt
   call write_string_32
   call newline
      
   hlt
   
string_starting_stage_2:
   db 'Calling protected mode C program',0
   
string_program_returned:
   db 'Protected mode C program returned with EAX = 0x',0
   
string_process_halt:
   db 'Halting processor',0

string_loading_program:
   db 'Loading C code',0

write_string_32:
   push eax
write_string_32_loop:

   mov eax,0x10
   mov [interrupt_number],ax

   xor eax,eax
   pop ebx
   mov al,[ebx]
   cmp al,0
   je write_string_32_exit

   mov ah,0x0e
   mov [interrupt_eax_value],eax
   push ebx
   call invoke_real_mode_interrupt
   pop ebx
   inc ebx
   push ebx
   jmp write_string_32_loop
write_string_32_exit:
   ret
   
newline_32:
   push eax
   mov eax,string_newline_32
   call write_string_32
   pop eax
   ret
   
write_dword_32:
   push eax
   ror eax,16
   and eax,0xffff
   call write_word_32
   pop eax
   and eax,0xffff
   call write_word_32
   ret
   
write_word_32:
   push eax
   ror eax,8
   and eax,0xff
   call write_byte_32
   pop eax
   and eax,0xff
   call write_byte_32
   ret

write_byte_32:
   push eax
   ror eax,4
   and eax,0x0f
   call write_digit_32
   pop eax
   and eax,0x0f
   call write_digit_32
   ret   
   
write_digit_32:
   and al,0xf
   cmp al,0x09
   jle write_digit_numeric_32
   add al,0x37
   call write_char_32
   ret

write_digit_numeric_32:
   add al,0x30
   call write_char_32
   ret

write_char_32:
   and eax,0xff
   mov ah,0x0e
   
   mov ebx,0x10
   mov [interrupt_number],ebx

   xor ebx,ebx
   mov bl,0x07
   xor ecx,ecx
   xor edx,edx
   
   call invoke_real_mode_interrupt
   ret
      
string_prot_mode:
   db 'Now in 32-bit protected mode',0
   
string_newline_32:
   db 10,13,0
   
string_back_in_real_mode:
   db 'Back in real mode',0
    
string_call_interrupt:
   db 'Executing interrupt 0x',0

string_address_1:
   db 'invoke_real_mode_interrupt_using_window_far is at 0x',0

long_jump_info:
   dd 0
   
invoke_real_mode_interrupt_using_window_far:

   mov ax,0x10
   mov ds,ax
   
   mov ebx,esp
   mov [user_esp],ebx
   
   mov ebx,[kernel_esp]
   mov esp,ebx
   
   mov ss,ax
   mov es,ax
   mov fs,ax
   mov gs,ax
   
   call invoke_real_mode_interrupt_using_window
   
   mov ax,0x10
   mov ds,ax
   
   mov ebx,[user_esp]
   mov esp,ebx
   
   mov ax,0x40
   mov ds,ax
   mov es,ax
   mov gs,ax
   mov fs,ax
   mov ss,ax
   
   retf

invoke_real_mode_interrupt_using_window:
   mov eax,invoke_real_mode_interrupt_using_window_ret
   mov [interrupt_return_address],eax
   jmp jump_to_16bit_prot_mode
invoke_real_mode_interrupt_using_window_ret:
   ret

invoke_real_mode_interrupt_far:
   call invoke_real_mode_interrupt
   retf
      
invoke_real_mode_interrupt:
   mov [interrupt_eax_value],eax
   pop eax
   mov [interrupt_return_address],eax
   mov [interrupt_ebx_value],ebx
   mov [interrupt_ecx_value],ecx
   mov [interrupt_edx_value],edx

;
;  First, switch through 16-bit protected mode
;

jump_to_16bit_prot_mode:
   jmp dword 0x20:prot_16_int+0x7c00
   
prot_16_int:
[bits 16]
   mov ax,0x28
   mov ds,ax
   mov es,ax
   mov ss,ax
   mov fs,ax
   mov gs,ax

   mov eax,cr0
   and al,0xfe
   mov cr0,eax
   
   jmp 0x07c0:real_mode_int
   
real_mode_int:
   mov ax,cs
   mov ds,ax
   mov es,ax
   mov ss,ax
   mov fs,ax
   mov gs,ax
      
   mov ax,[interrupt_number]
   shl ax,8
   mov al,0xcd
   mov [interrupt_self_modify],ax
   
   sti

   mov ax,[quiet_interrupt_flag]
   cmp ax,0
   je quiet_interrupts
      
   mov ax,string_call_interrupt
   call write_string
   mov ax,[interrupt_number]
   call write_word
   call newline
   
   mov eax,[interrupt_eax_value]
   mov ebx,[interrupt_ebx_value]
   mov ecx,[interrupt_ecx_value]
   mov edx,[interrupt_edx_value]
   
   mov esi,[interrupt_esi_value]
   mov ebp,[interrupt_ebp_value]
   
   mov ax,[interrupt_es_value]
   mov es,ax
   
   call write_registers

quiet_interrupts:

   mov eax,[interrupt_eax_value]
   mov ebx,[interrupt_ebx_value]
   mov ecx,[interrupt_ecx_value]
   mov edx,[interrupt_edx_value]
   
interrupt_self_modify:
   int 0x80
   
   pushf
   pop ax
   mov [interrupt_flags_value],ax
   
   mov [interrupt_eax_value],eax   
   mov [interrupt_ebx_value],ebx
   mov [interrupt_ecx_value],ecx
   mov [interrupt_edx_value],edx
   mov [interrupt_esi_value],esi
   mov [interrupt_ebp_value],ebp
   mov ax,es
   mov [interrupt_es_value],ax
   
   
;
;  Back to protected mode
;
   cli
   lgdt [protected_gdt_data]
   
   mov eax,cr0
   or al,1
   mov cr0,eax
   
   jmp dword 0x08:return_to_prot_mode

[bits 32]   
return_to_prot_mode:

   mov ax,0x10
   mov ds,ax
   mov es,ax
   mov ss,ax
   mov gs,ax
   mov fs,ax
   mov gs,ax
   
   mov eax,[interrupt_return_address]
   push eax
   mov eax,[interrupt_eax_value]
   ret

invoke_c_program:
   
   
;
;  Set up segment registers
;

   mov eax,esp
   mov [kernel_esp],eax
   
   mov eax,0x96300
   mov [user_esp],eax
   mov esp,eax
   
   mov ax,0x40
   mov ds,ax
   mov es,ax
   mov gs,ax
   mov ss,ax
   
   mov eax,0x08
   push eax
   
   mov eax,c_program_return
   push eax
   
;
;  Address of C code
;

   mov eax,0x38
   push eax
   xor eax,eax
   push eax
   
   xor eax,eax
   
   mov ebx,invoke_real_mode_interrupt_using_window_far
   xor ecx,ecx
   mov edx,interrupt_number
   
   xchg bx,bx
   retf
   
c_program_return:
   mov edx,eax
   
   mov ax,0x10
   
   mov ds,ax
   mov es,ax
   mov gs,ax
   mov ss,ax
   
   mov eax,[kernel_esp]
   mov esp,eax
   
   mov eax,edx
   
   ret
   
times 3072-($-$$) db 0

protected_gdt_data:
   dw 0
   dd 0

protected_idt_data:
   dw 0
   dd 0

protected_ldt_data:
   dw 0
   dd 0

real_gdt_data:
   dw 0
   dd 0

real_idt_data:
   dw 0x3ff
   dd 0

real_ldt_data:
   dw 0
   dd 0

times 4096-($-$$) db 0

gdt_base:           ;0x00
gdt_null_entry:
   dw 0
   dw 0
   dw 0
   dw 0
gdt_cs_entry:       ;0x08
   dw 0xffff
   dw 0x7c00
   db 0
   db 0x9a
   db 0xcf
   db 0
gdt_ds_entry:       ;0x10
   dw 0xffff
   dw 0x7c00
   db 0
   db 0x92
   db 0xcf
   db 0
gdt_video_entry:    ;0x18
   dw 0xffff
   dw 0x8000
   db 0x0b
   db 0x92
   db 0xcf
   db 0
gdt_cs_16_entry:    ;0x20
   dw 0xffff
   dw 0x0000
   db 0x00
   db 0x9a
   db 0x0f
   db 0
gdt_ds_16_entry:    ;0x28
   dw 0xffff
   dw 0x0000
   db 0x00
   db 0x92
   db 0x0f
   db 0
gdt_video_16_entry: ;0x30
   dw 0xffff
   dw 0x8000
   db 0x0b
   db 0x92
   db 0x0f
   db 0
gdt_gcc_cs_entry:       ;0x38
   dw 0xffff
   dw 0x9c00
   db 0
   db 0x9a
   db 0xcf
   db 0
gdt_gcc_ds_entry:       ;0x40
   dw 0xffff
   dw 0x9c00
   db 0
   db 0x92
   db 0xcf
   db 0
gdt_end:

times 4096+512-($-$$) db 0

interrupt_number:
   dd 0
   
interrupt_eax_value:
   dd 0
interrupt_ebx_value:
   dd 0
interrupt_ecx_value:
   dd 0
interrupt_edx_value:
   dd 0
interrupt_esi_value:
   dd 0
interrupt_ebp_value:
   dd 0
interrupt_flags_value:
   dd 0
interrupt_es_value:
   dd 0
interrupt_return_address:
   dd 0
quiet_interrupt_flag:
   dd 0

invoke_real_mode_interrupt_address:
  dd 0

kernel_esp:
   dd 0
   
user_esp:
   dd 0
   
times 8191-($-$$) db 0

last_label:
   nop
   


