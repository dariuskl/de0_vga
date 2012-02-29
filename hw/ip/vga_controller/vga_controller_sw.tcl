#
# vga_controller_driver.tcl
#

# Create a new driver
create_driver vga_controller_driver

# Associate it with some hardware known as "vga_controller"
set_sw_property hw_class_name vga_controller

# The version of this driver
set_sw_property version 1.0

# This driver may be incompatible with versions of hardware less
# than specified below. Updates to hardware and device drivers
# rendering the driver incompatible with older versions of
# hardware are noted with this property assignment.
set_sw_property min_compatible_hw_version 1.0

# Do not initialize the driver in alt_sys_init()
set_sw_property auto_initialize false

# Location in generated BSP that above sources will be copied into
set_sw_property bsp_subdirectory drivers

#
# Source file listings...
#

# Source files
add_sw_property c_source HAL/src/vga_driver.c

# Include files
add_sw_property include_source inc/vga_controller_regs.h
add_sw_property include_source HAL/inc/vga_driver.h
add_sw_property include_source HAL/inc/fh_logo.h
add_sw_property include_source HAL/inc/charset_default.h

# This driver supports HAL & UCOSII BSP (OS) types
add_sw_property supported_bsp_type HAL

# End of file
