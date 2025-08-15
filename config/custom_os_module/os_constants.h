#ifndef OS_CONSTANTS_H
#define OS_CONSTANTS_H

#define OS_LINUX 0
#define OS_MAC   1

enum os_type {
    OS_TYPE_LINUX = OS_LINUX,
    OS_TYPE_MAC = OS_MAC
};

extern enum os_type current_os;

#endif
