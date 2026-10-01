/*
 * FIC Viewer Virtual HID UMDF control definitions.
 * Derived in part from Microsoft Windows-driver-samples vhidmini2 (MS-PL).
 */
#pragma once
#include <windows.h>

#define FIC_VHID_VID 0xF1C0
#define FIC_VHID_PID 0x0125
#define FIC_VHID_VERSION 0x0125

#define FIC_CONTROL_REPORT_ID 1
#define FIC_KEYBOARD_REPORT_ID 2
#define FIC_MOUSE_REPORT_ID 3

#define FIC_CMD_KEYBOARD 1
#define FIC_CMD_MOUSE 2
#define FIC_CMD_RESET 3

#pragma pack(push,1)
typedef struct _FIC_CONTROL_REPORT {
    UCHAR ReportId;
    UCHAR Command;
    UCHAR Payload[8];
    UCHAR Reserved[6];
} FIC_CONTROL_REPORT, *PFIC_CONTROL_REPORT;

typedef struct _FIC_KEYBOARD_INPUT_REPORT {
    UCHAR ReportId;
    UCHAR Modifier;
    UCHAR Reserved;
    UCHAR Keys[6];
} FIC_KEYBOARD_INPUT_REPORT, *PFIC_KEYBOARD_INPUT_REPORT;

typedef struct _FIC_MOUSE_INPUT_REPORT {
    UCHAR ReportId;
    UCHAR Buttons;
    USHORT X;
    USHORT Y;
    CHAR Wheel;
} FIC_MOUSE_INPUT_REPORT, *PFIC_MOUSE_INPUT_REPORT;
#pragma pack(pop)

#define FIC_FEATURE_REPORT_SIZE_CB ((USHORT)(sizeof(FIC_CONTROL_REPORT)-1))
#define FIC_KEYBOARD_REPORT_SIZE_CB ((USHORT)(sizeof(FIC_KEYBOARD_INPUT_REPORT)-1))
#define FIC_MOUSE_REPORT_SIZE_CB ((USHORT)(sizeof(FIC_MOUSE_INPUT_REPORT)-1))

#define FIC_MANUFACTURER_STRING L"FIC Viewer"
#define FIC_PRODUCT_STRING L"FIC Viewer Virtual Input"
#define FIC_SERIAL_STRING L"FICV125"
