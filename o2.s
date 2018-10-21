.thumb
.syntax unified

.include "gpio_constants.s"
.include "sys-tick_constants.s"

.text
	.global Start
	
Start:
	//enabling systick and gpio_interrupts
	bl		set_up_systick
	bl 		set_up_gpio_interrupt
	bl	 	null_lcd

	//setting up counting registers
	mov 	r10, #0		//for flags
	mov 	r9, #0		//for tenths
	mov 	r8, #0		//for seconds
	mov 	r7, #0		//for minutes
	ldr 	r6, =tenths
	ldr 	r5, =seconds
	ldr 	r4, =minutes
	b 		loop

loop:
	cmp 	r10, #0b1			//0 bit is increase flag
	beq		increase_tenths
	b 		loop

increase_tenths:
	mov 	r10, #0
	add		r9, r9, #1
	cmp		r9, #10
	bpl		increase_seconds
	str 	r9, [r6]
	b 		loop

increase_seconds:
	bl 		toggle_led
	sub 	r9, r9, #10
	str 	r9, [r6]
	add		r8, r8, #1
	cmp		r8, #60
	bpl		increase_minutes
	str 	r8, [r5]
	b 		loop

increase_minutes:
	sub 	r8, r8, #60
	add 	r7, r7, #1
	str 	r8, [r5]
	str 	r7, [r4]
	b 		loop

toggle_led:
	push 	{r0, r1, lr}

	ldr 	r0, =PORT_E * PORT_SIZE + GPIO_BASE + GPIO_PORT_DOUTTGL
    mov 	r1, (1 << LED_PIN)
    str 	r1, [r0]

	pop		{r0, r1, lr}
  	mov 	pc, lr


set_up_systick:
	push 	{r0, r1, lr}

	ldr		r0, =SYSTICK_BASE + SYSTICK_LOAD
	ldr 	r1, =FREQUENCY / 10
	str 	r1, [r0]

	ldr 	r0, =SYSTICK_BASE
	ldr	 	r1, [r0]
	orr 	r1, r1, 0b110
	str 	r1, [r0]

	pop 	{r0, r1, lr}
	mov 	pc, lr

set_up_gpio_interrupt:
	push 	{r0, r1, lr}

	//enable interrupts for port b
	ldr 	r0, =GPIO_EXTIPSELH + GPIO_BASE
	ldr 	r1, [r0]

	and 	r1, ~(0b1111 << 4)
	orr 	r1, (PORT_B << 4)
	str 	r1, [r0]

	//set interrupts to happen on falling edges.
	ldr 	r0, =GPIO_EXTIFALL + GPIO_BASE
	ldr 	r1, [r0]

	orr 	r1, (1 << BUTTON_PIN)
	str 	r1, [r0]

	ldr 	r0, =GPIO_IEN + GPIO_BASE
	ldr 	r1, [r0]
	orr 	r1, (1 << BUTTON_PIN)
	str 	r1, [r0]

	pop 	{r0, r1, lr}
	mov 	pc, lr

.global SysTick_Handler
.thumb_func
SysTick_Handler:
	orr		r10, r10, #1
	bx		lr

.global GPIO_ODD_IRQHandler
.thumb_func
GPIO_ODD_IRQHandler:
	push 	{r0, r1, lr}
	//toggle SysTick
	ldr 	r0, =SYSTICK_BASE
	ldr 	r1, [r0]
	eor 	r1, r1, #0b1
	str 	r1, [r0]

	//clear if
	ldr 	r0, =GPIO_BASE + GPIO_IFC
	ldr 	r1, [r0]

	orr 	r1, r1, (1 << BUTTON_PIN)
	str 	r1, [r0]
	pop		{r0, r1, lr}
	bx		lr

null_lcd:
	push 	{r0, r1, lr}

	ldr 	r0, =tenths
	mov 	r1, #0
	str 	r1, [r0]
	ldr 	r0, =seconds
	str 	r1, [r0]
	ldr 	r0, =minutes
	str 	r1, [r0]

	pop 	{r0, r1, lr}
	mov 	pc, lr

NOP //no touchey

