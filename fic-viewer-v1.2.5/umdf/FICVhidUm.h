/*
 * FICVhidUm.h
 * Based on Microsoft Windows-driver-samples vhidmini2 (MS-PL).
 */
#pragma once

#ifdef _KERNEL_MODE
#include <ntddk.h>
#else
#include <windows.h>
#endif

#include <wdf.h>
#include <hidport.h>
#include "FICVhidCommon.h"

typedef UCHAR HID_REPORT_DESCRIPTOR, *PHID_REPORT_DESCRIPTOR;

#define FIC_PENDING_DEPTH 128
#define FIC_MAX_INPUT_REPORT 16

typedef struct _FIC_PENDING_REPORT {
    ULONG Length;
    UCHAR Data[FIC_MAX_INPUT_REPORT];
} FIC_PENDING_REPORT, *PFIC_PENDING_REPORT;

typedef struct _DEVICE_CONTEXT {
    WDFDEVICE Device;
    WDFQUEUE DefaultQueue;
    WDFQUEUE ManualQueue;
    WDFWAITLOCK ReportLock;
    HID_DEVICE_ATTRIBUTES HidDeviceAttributes;
    HID_DESCRIPTOR HidDescriptor;
    PHID_REPORT_DESCRIPTOR ReportDescriptor;
    FIC_PENDING_REPORT Pending[FIC_PENDING_DEPTH];
    ULONG Head;
    ULONG Tail;
    ULONG Count;
} DEVICE_CONTEXT, *PDEVICE_CONTEXT;

WDF_DECLARE_CONTEXT_TYPE_WITH_NAME(DEVICE_CONTEXT, GetDeviceContext);

typedef struct _QUEUE_CONTEXT {
    WDFQUEUE Queue;
    PDEVICE_CONTEXT DeviceContext;
} QUEUE_CONTEXT, *PQUEUE_CONTEXT;

WDF_DECLARE_CONTEXT_TYPE_WITH_NAME(QUEUE_CONTEXT, GetQueueContext);

DRIVER_INITIALIZE DriverEntry;
EVT_WDF_DRIVER_DEVICE_ADD EvtDeviceAdd;

NTSTATUS QueueCreate(_In_ WDFDEVICE Device, _Out_ WDFQUEUE *Queue);
NTSTATUS ManualQueueCreate(_In_ WDFDEVICE Device, _Out_ WDFQUEUE *Queue);

NTSTATUS ReadReport(_In_ PQUEUE_CONTEXT QueueContext, _In_ WDFREQUEST Request, _Always_(_Out_) BOOLEAN *CompleteRequest);
NTSTATUS SetFeature(_In_ PQUEUE_CONTEXT QueueContext, _In_ WDFREQUEST Request);

NTSTATUS RequestCopyFromBuffer(_In_ WDFREQUEST Request, _In_ PVOID SourceBuffer, _In_ size_t NumBytesToCopyFrom);
NTSTATUS RequestGetHidXferPacket_ToWriteToDevice(_In_ WDFREQUEST Request, _Out_ HID_XFER_PACKET *Packet);

NTSTATUS FicQueueInputReport(_In_ PDEVICE_CONTEXT DeviceContext, _In_reads_bytes_(Length) const UCHAR *Data, _In_ ULONG Length);
VOID FicDrainPendingReads(_In_ PDEVICE_CONTEXT DeviceContext);
