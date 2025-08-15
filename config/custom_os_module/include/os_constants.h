#pragma once

#include <zephyr/kernel.h>

// OS type enumeration
enum os_type {
    OS_TYPE_LINUX = 0,
    OS_TYPE_MAC = 1
};

// Parameter constants for devicetree bindings
#define OS_LINUX 0
#define OS_MAC 1

// Global OS state (extern declaration)
extern enum os_type current_os;
