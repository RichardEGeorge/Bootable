#include <stdarg.h>

char *message="Printed from C code loaded from disc.";
	
void get_interrupt_address();
int work();

int invoke_real_mode_interrupt=0;
int real_mode_interrupt_number=0;

int cursor_x=0,cursor_y=0;
int screen_x=80,screen_y=25;
short int colour = 0x2a;

short int *video = (short int *)(0xb8000 - 0x9c00);

void advance_cursor();
void scroll_one_line();

int main(void)
{   
   get_interrupt_address();
   
   work();

   // Force a return to the operating system
   
   __asm__("xchg %bx,%bx");
   __asm__("movl $615168,%ebx");
   __asm__("movl %ebx,%esp");
   __asm__("subl $8,%esp");
   __asm__(".byte 203");
   
   return 0;
}

void get_interrupt_address()
{
   int b;
   int c;
   
   __asm__("  mov %%ebx,%0" : "=r" (b) ); 
   __asm__("  mov %%edx,%0" : "=r" (c) ); 
   
   invoke_real_mode_interrupt=b;
   real_mode_interrupt_number=c;
}

void write_character(char c)
{
   if (c==13)
   {
      cursor_x = 0;
      return;
   }
   
   if (c==10)
   {
      cursor_x = screen_x-1;
      advance_cursor();
      return;
   }
   
   short int *p = video + (cursor_x + (screen_x * cursor_y ));
   short int u;
   *p = ((short int)c & 0xff) | ( ((short int)colour) << 8) & 0xff00;
   advance_cursor();
}

void advance_cursor()
{
   cursor_x++;
   if (cursor_x==screen_x)
   {
      cursor_x = 0;
      cursor_y++;
   }
   if (cursor_y==screen_y)
   {
      scroll_one_line();
      cursor_y--;
      cursor_x = 0;
   }
}

void scroll_one_line()
{
   short int *p1=video,*p2=video + screen_x;
   int i;
   for (i=0;i<screen_x*(screen_y-1);i++)
   {
      *p1 = *p2;
      p1++;
      p2++;
   }
}

void clear_display()
{
   short int *p = video,blank = ((colour << 8) & 0xFF00) | ((short int)0x20);
   int i;
   
   for (i=0;i<(screen_x*screen_y);i++)
   {  
      *p = blank;
      p++;
   }
   cursor_x = 0;
   cursor_y = 0;
}

void write_string(const char *c)
{
   int i;
   for (i=0;c[i]!=0;i++) write_character(c[i]);
}

void write_hex_digit_u(int x)
{
   char c;
   if (x<10) c='0'+x; else c='A'+x-10;
   write_character(c);
}

void write_hex_digit_l(int x)
{
   char c;
   if (x<10) c='0'+x; else c='a'+x-10;
   write_character(c);
}

void write_hex_byte(int x)
{
   write_hex_digit_u( (x & 0xF0) >> 4);
   write_hex_digit_u(x & 0x0F);
}

void write_hex_word(int x)
{
   write_hex_byte((x & 0xFF00) >> 8);
   write_hex_byte(x & 0x00FF);
}

void write_hex_dword(int x)
{
   write_hex_word((x & 0xFFFF0000) >> 16);
   write_hex_word(x & 0x0000FFFF);
}

void write_decimal_number2(int x,int first);

void write_decimal_number(int x)
{
   write_decimal_number2(x,1);
}

void write_decimal_number2(int x,int first)
{
   if (first==1)
   {
      if (x==0)
      {
         write_character('0');
         return;
      }
      
      if (x<0)
      {
         write_character('-');
         write_decimal_number2(-x,0);
         return;
      }
   }
   
   int y = x % 10;
   int z = (x - y) / 10;
   if (z != 0) write_decimal_number2(z,0);
   write_character('0'+y);
}

void write_hex_number2(unsigned int x,int first,int c);

void write_hex_number_l(unsigned int x)
{
   write_hex_number2(x,1,0);
}

void write_hex_number_u(unsigned int x)
{
   write_hex_number2(x,1,1);
}

void write_hex_number2(unsigned int x,int first,int c)
{
   if (first==1)
   {
      if (x==0)
      {
         write_character('0');
         return;
      }
   }
   
   int y = x % 16;
   int z = (x - y) / 16;
   if (z != 0) write_hex_number2(z,0,c);
   if (c==1) write_hex_digit_u(y); else write_hex_digit_l(y);
}


void printf(const char *format, ...)
{
   char *s;
   va_list vl;
   int i=0;
   char ch;
   int j;
   va_start(vl,format);
   
   while (format[i]!=0)
   {
      if (format[i]=='%')
      {
          switch (format[i+1])
          {
             case 0:
                va_end(vl);
                return;
                
             case 'd':
                j=va_arg(vl,int);
                write_decimal_number(j);
                i+=2;
                break;
            
             case 'x':
                j=va_arg(vl,int);
                write_hex_number_l(j);
                i+=2;
                break;
                
             case 'X':
                j=va_arg(vl,int);
                write_hex_number_u(j);
                i+=2;
                break;
                
            case 'c':
                ch=va_arg(vl,char);
                write_character(ch);
                i+=2;
                break;
                
            case '%':
                write_character('%');
                i+=2;
                break;
                
            case 's':
                s = va_arg(vl,char *);
                write_string(s);
                i+=2;
                break;
           }
      }
      else
      {
         write_character(format[i++]);
      }
   }   
   va_end(vl);
}

int call_real_mode_interrupt()
{
   int a = invoke_real_mode_interrupt;
   __asm__("\tpush %%cs\n\tpush $label%=\n\tpush $8\n\tpush %0\n\t.byte 203\nlabel%=:\n" : : "r" (a));   
}

void poke_interrupt_region(int offset,int value)
{
   __asm__("\tpush %gs\n\tpush $16\n\tpop %%gs\n\tmov %1,%%gs:(%0)\n\tpop %gs\n" : : "r" (offset), "r" (value)); 
}

int peek_interrupt_region(int offset)
{
   int result;
   __asm__("\tpush %gs\n\tpush $16\n\tpop %%gs\n\tmov %%gs:(%1),%0\n\tpop %gs\n" : "=r" (result) : "r" (offset));    
   return result;
}

void set_interrupt_EAX(int v)
{
   poke_interrupt_region(real_mode_interrupt_number+12,v);
}

void set_interrupt_EBX(int v)
{
   poke_interrupt_region(real_mode_interrupt_number+16,v);
}

void set_interrupt_ECX(int v)
{
   poke_interrupt_region(real_mode_interrupt_number+20,v);
}

void set_interrupt_EDX(int v)
{
   poke_interrupt_region(real_mode_interrupt_number+24,v);
}

void set_interrupt_number(int n)
{
   poke_interrupt_region(real_mode_interrupt_number,n);
}

/*
interrupt_number: 0
   dd 0
quiet_interrupt_flag: 4
   dd 0
interrupt_return_address: 8
   dd 0
interrupt_eax_value: 12
   dd 0
interrupt_ebx_value: 16
   dd 0
interrupt_ecx_value: 20
   dd 0
interrupt_edx_value: 24
   dd 0
interrupt_esi_value: 28
   dd 0
interrupt_ebp_value: 32
   dd 0
interrupt_flags_value: 36
   dd 0
interrupt_es_value: 40
   dd 0
   */

int utoi(const char *c)
{
   switch(c[0])
   {
      case 0:
         return 0;
         
      case '0':
         return utoi(c+1);
         
      case 'd':
      case 'D':
         return ratoi(c+1,10);
      
      case 'x':
      case 'X':
         return ratoi(c+1,16);
         
      case 'b':
      case 'B':
         return ratoi(c+1,2);
         
      case 'o':
      case 'O':
         return ratoi(c+1,8);
         
      case '-':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
         return ratoi(c,10);
         
      default:
         return 0;
   }
}

int ctoi(char);
int ratoi(const char *,int);

int atoi(const char *c)
{
   return ratoi(c,10);
}

int htoi(const char *c)
{
   return ratoi(c,16);
}

int btoi(const char *c)
{
   return ratoi(c,2);
}
   
int ratoi(const char *c,int base)
{
   int result=0,i;
   if (c[0]==0) return 0;
   if (c[0]=='-') return -ratoi(c+1,base);
   
   for (i=0;c[i]!=0;i++)
   {
      result*=base;
      result+=ctoi(c[i]);
   }
   
   return result;
}

int ctoi(char c)
{
   if ((c>='0') && (c<='9')) return c-'0';
   if ((c>='A') && (c<='F')) return c-'A'+10;
   if ((c>='a') && (c<='f')) return c-'a'+10;
}

int work()
{
   clear_display();
   write_string("Hello from 32-bit protected mode\n");
   write_string("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n\n");
   
   poke_interrupt_region(real_mode_interrupt_number,0x10);
   poke_interrupt_region(real_mode_interrupt_number+4,0x0e41);
   poke_interrupt_region(real_mode_interrupt_number+8,0x0007);
   poke_interrupt_region(real_mode_interrupt_number+12,0x0000);
   call_real_mode_interrupt();
   
   printf("Real mode interrupt vector = 0008:%X, interrupt register table = 0010:%X\n",invoke_real_mode_interrupt,real_mode_interrupt_number);
   printf("Next tasks:\n");
   printf("1. Set up IDTR and GDTR from inside C program\n");
   printf("2. Enable input via interrupts\n");
   
   char *str = "-123";
   
   printf("utoi(%s)=%X\n",str,utoi(str));
   
   return 0;
}

typedef struct tagDiskGeometry {
   int disk_number;
   int present;
   int cylinder_count;
   int head_count;
   int sectors_per_track;
} DiskGeometry;

typedef struct tagLongPointer {
   unsigned int segment;
   void *offset;
} LongPointer;

typedef struct tagRealModePointer {
   unsigned short int segment;
   unsigned short int offset;
} RealModePointer;

typedef struct tagCHSDiskAccess {
   int disk_number;
   int start_track;
   int start_head;
   int start_sector;
   int read_length;
   int direction;
} CHSDiskRead;

typedef struct tagLBADiskAccess {
   int disk_number;
   int lba_start;
   int count;
   int direction;
} LBADiskRead;


int disk_read()
{  
   DiskGeometry a;

   a.disk_number = 0;
   a.present = 1;
   a.cylinder_count = 18;
   a.head_count = 2;
   a.sectors_per_track = 80;
}

typedef struct tagGDTEntry {
   unsigned short int size;
   unsigned int position;
} GDTEntry;

typedef struct tagLDTEntry {
   unsigned short int size;
   unsigned int position;
} LDTEntry;

typedef struct tagIDTEntry {
   unsigned short int size;
   unsigned int position;
} IDTEntry;

typedef struct tagProcessState {

   unsigned int EAX;
   unsigned int EBX;
   unsigned int ECX;
   unsigned int EDX;

   unsigned int ESI;
   unsigned int EBP;
   unsigned int ESP;
   unsigned int EDI;
   
   unsigned int EIP;
   unsigned ing EFLAGS;
   
   unsigned short int CS;
   unsigned short int DS;
   unsigned short int SS;
   unsigned short int ES;
   unsigned short int FS;
   unsigned short int GS;
   
} ProcessState;



int TranslateLBAtoCHS(LBADiskAccess *lba,CHSDiskAcess *chs,LBADiskAccess *remainder)
{
   
}

void RealMemoryCopy(RealModePointer *rp,LongPointer *lp,int size,int direction)
{
   lp->segment = 0x40;
   lp->offset = rp->segment * 16 + rp->offset - 0x9C00;
}

void PerformCHSAccess(CHSDiskAddress *,RealModePointer *,int direction)
{
}

int getSizeOfTransfer(CHSDiskAccess *d)
{
   return d->read_length*512;
}

void PerformLBAAccess(LBADiskAccess *request,LongPointer *pos,int direction)
{
   CHSDiskAcess chs;
   LBADiskAccess access,remainder;
   RealModePointer buffer;
   LongPointer pos;
   
   memcopy(&request,&access,sizeof(LBADiskAddress));
   memcopy(&pos,&position,sizeof(LongPointer));
   
   while (access->count>0)
   {
      TranslateLBAtoCHS(&access,&chs,&remainder);
      int sz = getSizeOfTransfer(&chs);
      if (direction==1)
      {
         PerformCHSAccess(&chs,&buffer,direction);
         RealMemoryCopy(&buffer,&position,sz,direction);
      }
      else
      {
         RealMemoryCopy(&buffer,&position,sz,direction);
         PerformCHSAccess(&chs,&buffer,direction);
      }
      memcopy(&remainder,&access,sizeof(LBADiskAddress));
      position->offset += sz;
   }
}





