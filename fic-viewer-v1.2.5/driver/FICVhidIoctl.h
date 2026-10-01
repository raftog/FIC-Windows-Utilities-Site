#pragma once
#include <winioctl.h>

#define FIC_VHID_DOS_DEVICE L"\\\\.\\FICVirtualInput"

#define IOCTL_FIC_VHID_KEY   CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_WRITE_DATA)
#define IOCTL_FIC_VHID_MOUSE CTL_CODE(FILE_DEVICE_UNKNOWN, 0x801, METHOD_BUFFERED, FILE_WRITE_DATA)
#define IOCTL_FIC_VHID_RESET CTL_CODE(FILE_DEVICE_UNKNOWN, 0x802, METHOD_BUFFERED, FILE_WRITE_DATA)

#pragma pack(push,1)
typedef struct _FIC_VHID_KEY_REPORT {
    unsigned char Modifier;
    unsigned char Reserved;
    unsigned char Keys[6];
} FIC_VHID_KEY_REPORT;

typedef struct _FIC_VHID_MOUSE_REPORT {
    unsigned char Buttons;
    unsigned short X;
    unsigned short Y;
    signed char Wheel;
} FIC_VHID_MOUSE_REPORT;
#pragma pack(pop)
