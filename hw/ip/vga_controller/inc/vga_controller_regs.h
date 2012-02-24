#ifndef __VGA_CONTROLLER_REGS_H__
#define __VGA_CONTROLLER_REGS_H__

#include <io.h>

#define IOADDR_VGA_CONTROLLER_FB_BASE_ADDR(base)           __IO_CALC_ADDRESS_NATIVE(base, 0)
#define IOWR_VGA_CONTROLLER_FB_BASE_ADDR(base, data)       IOWR(base, 0, data)

#define IOADDR_VGA_CONTROLLER_CTRL(base)      __IO_CALC_ADDRESS_NATIVE(base, 1) 
#define IOWR_VGA_CONTROLLER_CTRL(base, data)  IOWR(base, 1, data)

#endif /* __VGA_CONTROLLER_REGS_H__ */
