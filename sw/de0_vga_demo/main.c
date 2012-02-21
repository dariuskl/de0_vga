/*!
 *	\file main.c
 *
 *	\date		File created: Feb 21, 2012
 *	\author		Darius Kellermann
 *
 *	\version	WS 11/12
 */

#include <stdio.h>

#include "vga_driver.h"
#include "system.h"
#include "io.h"


int main ()
{
	uint16 x, y, color;
	uint64 *frame_buffer;
	char buffer[200] = {0};

	// Try to allocate as many segments as required for the frame buffer.
	if ((frame_buffer = (uint64 *) malloc (((DISPLAY_NUM_COLUMNS * DISPLAY_NUM_ROWS) / 5) * sizeof (uint64))) == NULL)
	{																			// if allocating the frame buffer failed
		printf ("FATAL: Could not allocate memory for the frame buffer\n");		// print error
		return -1;																// and return
	}
	printf ("Frame buffer allocated at base address %#x\n", (uint32) frame_buffer);

	IOWR (VGA_0_BASE, VGA_CSR_FB_BASE_ADDR, (uint32) frame_buffer);		// write frame buffer base address into control register
	printf ("Base address written into control register\n");

	color = 0xFFF;
	for (y = 0; y < DISPLAY_NUM_ROWS; y++)
		for (x = 0; x < DISPLAY_NUM_COLUMNS; x++)
			frame_px_w (frame_buffer, x, y, color);

	printf ("Frame buffer whitened\n");

	IOWR (VGA_0_BASE, VGA_CSR_CTRL, VGA_CSR_CTRL_GO);							// write GO-Bit into control register
	printf ("VGA startet %d\n", VGA_PRINTLN_TEXT_OFFSET_X);
	sprintf (buffer, "VGA started.");
	vprintln (frame_buffer, buffer);

	sprintf (buffer, "Hello World!");
	vprintln (frame_buffer, buffer);

	while (1)
	{
		printf ("Tell me what to say: ");
		scanf ("%s", buffer);
		printf ("Writing \"%s\" into the buffer\n", buffer);
		vprintln (frame_buffer, buffer);
	}

	return 0;
}