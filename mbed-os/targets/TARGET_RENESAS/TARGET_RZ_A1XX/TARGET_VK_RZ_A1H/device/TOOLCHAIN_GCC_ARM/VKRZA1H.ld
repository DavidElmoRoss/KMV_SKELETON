/* Linker script for mbed VK_RZ_A1H */

/* Linker script to configure memory regions. */

#ifdef RUN_FROM_SDRAM
MEMORY
{
  L_TTB (rw)  : ORIGIN = 0x20000000, LENGTH = 0x00004000
  RAM (rwx) : ORIGIN = 0x08000000, LENGTH = 0x01E00000
  RAM_NC (rwx) : ORIGIN = 0x49E00000, LENGTH = 0x00200000
  SRAM (rwx) : ORIGIN = 0x200A0000, LENGTH = 0x00960000
}
REGION_ALIAS("SFLASH", RAM);
/*TTBOFFSET = 1M;*/

#elif defined (RUN_FROM_SRAM)
MEMORY
{
  L_TTB (rw)  : ORIGIN = 0x20000000, LENGTH = 0x00004000 
  RAM (rwx) : ORIGIN = 0x200A0000, LENGTH = 0x00860000
  RAM_NC (rwx) : ORIGIN = 0x60900000, LENGTH = 0x00100000
  SDRAM  (rwx) : ORIGIN = 0x08000000, LENGTH = 0x02000000
}
REGION_ALIAS("SFLASH", RAM);
/*TTBOFFSET = 1M;*/
#else

#if !defined(MBED_APP_START)
  #define MBED_APP_START 0x18020000
#endif

#if !defined(MBED_APP_SIZE)
  #define MBED_APP_SIZE 0x1FE0000
#endif

  #define SFLASH_ADDR         MBED_APP_START
  #define SFLASH_SIZE         MBED_APP_SIZE

MEMORY
{
  ROM   (rx)  : ORIGIN = 0x00000000, LENGTH = 0x02000000
  SFLASH (rx) : ORIGIN = SFLASH_ADDR, LENGTH = SFLASH_SIZE 
  L_TTB (rw)  : ORIGIN = 0x20000000, LENGTH = 0x00004000 
  RAM (rwx) : ORIGIN = 0x20020000, LENGTH = 0x008E0000
  RAM_NC (rwx) : ORIGIN = 0x20900000, LENGTH = 0x00100000
  SDRAM  (rwx) : ORIGIN = 0x08000000, LENGTH = 0x02000000
}
#endif

/* Linker script to place sections and symbol values. Should be used together
 * with other linker script that defines memory regions FLASH and RAM.
 * It references following symbols, which must be defined in code:
 *   Reset_Handler : Entry of reset handler
 * 
 * It defines following symbols, which code can use without definition:
 *   __exidx_start
 *   __exidx_end
 *   __etext
 *   __data_start__
 *   __preinit_array_start
 *   __preinit_array_end
 *   __init_array_start
 *   __init_array_end
 *   __fini_array_start
 *   __fini_array_end
 *   __data_end__
 *   __bss_start__
 *   __bss_end__
 *   __end__
 *   end
 *   __HeapLimit
 *   __StackLimit
 *   __StackTop
 *   __stack
 */
ENTRY(Reset_Handler)

SECTIONS
{
    .text :
    {

        Image$$VECTORS$$Base = .;
        KEEP(*(.isr_vector))
        *(SVC_TABLE)
        *(.text*)

        KEEP(*(.init))
        KEEP(*(.fini))

        /* .ctors */
        *crtbegin.o(.ctors)
        *crtbegin?.o(.ctors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
        *(SORT(.ctors.*))
        *(.ctors)

        /* .dtors */
        *crtbegin.o(.dtors)
        *crtbegin?.o(.dtors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
        *(SORT(.dtors.*))
        *(.dtors)
        Image$$VECTORS$$Limit = .;

        Image$$RO_DATA$$Base = .;
        *(.rodata*)
        Image$$RO_DATA$$Limit = .;

        KEEP(*(.eh_frame*))
    } > SFLASH

    .ARM.extab : 
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > SFLASH

    __exidx_start = .;
    .ARM.exidx :
    {
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    } > SFLASH
    __exidx_end = .;


    .copy.table :
    {
        . = ALIGN(8);
        __copy_table_start__ = .;
        LONG (__etext)
        LONG (__data_start__)
        LONG (__data_end__ - __data_start__)
        LONG (__etext2)
        LONG (__nc_data_start)
        LONG (__nc_data_end - __nc_data_start)
        LONG (LOADADDR(.ram_code))
        LONG (ADDR(.ram_code))
        LONG (SIZEOF(.ram_code))
        __copy_table_end__ = .;
    } > SFLASH

    .zero.table :
    {
        . = ALIGN(8);
        __zero_table_start__ = .;
        LONG (__bss_start__)
        LONG (__bss_end__ - __bss_start__)
        LONG (__nc_bss_start)
        LONG (__nc_bss_end - __nc_bss_start)
        __zero_table_end__ = .;
    } > SFLASH

    .ram_code : ALIGN( 0x8 ) {
        __ram_code_load  = .;
        __ram_code_start = LOADADDR(.ram_code) + ( __ram_code_load - ADDR(.ram_code) );

        *(RAM_CODE)

        *(RAM_CONST)

        . = ALIGN( 0x8 );
        __ram_code_end = LOADADDR(.ram_code) + ( . - ADDR(.ram_code) );
    } > RAM AT > SFLASH

    Load$$SEC_RAM_CODE$$Base    = LOADADDR(.ram_code);
    Image$$SEC_RAM_CODE$$Base   = ADDR(.ram_code);
    Load$$SEC_RAM_CODE$$Length  = SIZEOF(.ram_code);
        
    .ttb :
    {
        Image$$TTB$$ZI$$Base = .;
        . += 0x00004000;
        Image$$TTB$$ZI$$Limit = .;
    } > L_TTB

    __etext = Load$$SEC_RAM_CODE$$Base + SIZEOF(.ram_code);

    .data : AT (__etext)
    {
        Image$$RW_DATA$$Base = .;
        __data_start__ = .;
        *(vtable)
        *(.data*)
        Image$$RW_DATA$$Limit = .;

        . = ALIGN(8);
        /* preinit data */
        PROVIDE (__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE (__preinit_array_end = .);

        . = ALIGN(8);
        /* init data */
        PROVIDE (__init_array_start = .);
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
        PROVIDE (__init_array_end = .);


        . = ALIGN(8);
        /* finit data */
        PROVIDE (__fini_array_start = .);
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array))
        PROVIDE (__fini_array_end = .);

        . = ALIGN(8);
        /* All data end */
        __data_end__ = .;

    } > RAM

    .bss ALIGN(0x10):
    {
        Image$$RW_IRAM1$$Base = .;
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        __bss_end__ = .;
        Image$$RW_IRAM1$$Limit = .;
    } > RAM

    .heap :
    {
        __end__ = .;
        end = __end__;
        *(.heap*)
    } > RAM

    /* .stack_dummy section doesn't contains any symbols. It is only
     * used for linker to calculate size of stack sections, and assign
     * values to stack symbols later */
    .stack_dummy (COPY):
    {
        *(.stack*)
    } > RAM

    /* Set stack top to end of RAM, and stack limit move down by
     * size of stack_dummy section */
    __StackTop = ORIGIN(RAM) + LENGTH(RAM);
    _estack = __StackTop;
    __StackLimit = __StackTop - SIZEOF(.stack_dummy);
    __HeapLimit = __StackLimit;
    PROVIDE(__stack = __StackTop);

    /* Check if data + heap + stack exceeds RAM limit */
    ASSERT(__StackLimit >= __HeapLimit, "region RAM overflowed with stack")

    __etext2 = __etext + SIZEOF(.data);
    .nc_data : AT (__etext2)
    {
        Image$$RW_DATA_NC$$Base = .;
        __nc_data_start = .;
        *(NC_DATA)

        . = ALIGN(8);
        __nc_data_end = .;
        Image$$RW_DATA_NC$$Limit = .;
    } > RAM_NC

    .nc_bss (NOLOAD) :
    {
        Image$$ZI_DATA_NC$$Base = .;
        __nc_bss_start = .;
        *(NC_BSS)

        . = ALIGN(8);
        __nc_bss_end = .;
        Image$$ZI_DATA_NC$$Limit = .;
    } > RAM_NC
}
