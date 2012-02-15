/*!
 * \file vga_driver.c
 *
 * \date	File created: Jan 13, 2012
 * \author	Darius Kellermann
 *
 * \version WS 11/12
 */

#include "vga_driver.h"

void put_frame_buffer (uint64 *frame_buffer, uint16 *element, uint8 width, uint8 height, uint16 off_x, uint16 off_y)
{
	uint16 x, y;

	if (frame_buffer == 0)
		return;

	for (y = off_y; (y < (off_y + height)) && (y < DISPLAY_NUM_ROWS); y++)
		for (x = off_x; (x < (off_x + width)) && (x < DISPLAY_NUM_COLUMNS); x++)
			frame_px_w (frame_buffer, x, y, element[(x-off_x)+(width*(y-off_y))]);
}
