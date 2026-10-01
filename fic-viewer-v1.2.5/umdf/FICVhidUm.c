/*
 * FIC Viewer Virtual HID UMDF2 driver, V1.2.5.
 *
 * This file is derived in part from Microsoft's vhidmini2 sample in
 * Windows-driver-samples and is distributed under the Microsoft Public License.
 */

#include "FICVhidUm.h"

HID_REPORT_DESCRIPTOR G_ReportDescriptor[] = {
    /* Vendor control feature collection, Report ID 1 */
    0x06,0x00,0xFF,
    0x09,0x01,
    0xA1,0x01,
    0x85,FIC_CONTROL_REPORT_ID,
    0x09,0x01,
    0x15,0x00,
    0x26,0xFF,0x00,
    0x75,0x08,
    0x95,FIC_FEATURE_REPORT_SIZE_CB,
    0xB1,0x02,
    0xC0,

    /* Standard keyboard collection, Report ID 2 */
    0x05,0x01,
    0x09,0x06,
    0xA1,0x01,
    0x85,FIC_KEYBOARD_REPORT_ID,
    0x05,0x07,
    0x19,0xE0,
    0x29,0xE7,
    0x15,0x00,
    0x25,0x01,
    0x75,0x01,
    0x95,0x08,
    0x81,0x02,
    0x95,0x01,
    0x75,0x08,
    0x81,0x01,
    0x95,0x06,
    0x75,0x08,
    0x15,0x00,
    0x25,0x65,
    0x05,0x07,
    0x19,0x00,
    0x29,0x65,
    0x81,0x00,
    0xC0,

    /* Absolute mouse collection, Report ID 3 */
    0x05,0x01,
    0x09,0x02,
    0xA1,0x01,
    0x85,FIC_MOUSE_REPORT_ID,
    0x09,0x01,
    0xA1,0x00,
    0x05,0x09,
    0x19,0x01,
    0x29,0x05,
    0x15,0x00,
    0x25,0x01,
    0x95,0x05,
    0x75,0x01,
    0x81,0x02,
    0x95,0x01,
    0x75,0x03,
    0x81,0x03,
    0x05,0x01,
    0x09,0x30,
    0x09,0x31,
    0x15,0x00,
    0x27,0xFF,0xFF,0x00,0x00,
    0x75,0x10,
    0x95,0x02,
    0x81,0x02,
    0x09,0x38,
    0x15,0x81,
    0x25,0x7F,
    0x75,0x08,
    0x95,0x01,
    0x81,0x06,
    0xC0,
    0xC0
};

HID_DESCRIPTOR G_HidDescriptor = {
    0x09,
    0x21,
    0x0111,
    0x00,
    0x01,
    {
        {
            0x22,
            sizeof(G_ReportDescriptor)
        }
    }
};

static VOID FicCopyBytes(UCHAR *d, const UCHAR *s, ULONG n)
{
    ULONG i;
    for (i = 0; i < n; ++i) d[i] = s[i];
}

NTSTATUS
DriverEntry(
    _In_ PDRIVER_OBJECT DriverObject,
    _In_ PUNICODE_STRING RegistryPath
    )
{
    WDF_DRIVER_CONFIG config;
    WDF_DRIVER_CONFIG_INIT(&config, EvtDeviceAdd);
    return WdfDriverCreate(
        DriverObject,
        RegistryPath,
        WDF_NO_OBJECT_ATTRIBUTES,
        &config,
        WDF_NO_HANDLE);
}

NTSTATUS
EvtDeviceAdd(
    _In_ WDFDRIVER Driver,
    _Inout_ PWDFDEVICE_INIT DeviceInit
    )
{
    NTSTATUS status;
    WDF_OBJECT_ATTRIBUTES attributes;
    WDFDEVICE device;
    PDEVICE_CONTEXT ctx;

    UNREFERENCED_PARAMETER(Driver);

    WdfFdoInitSetFilter(DeviceInit);

    WDF_OBJECT_ATTRIBUTES_INIT_CONTEXT_TYPE(&attributes, DEVICE_CONTEXT);
    status = WdfDeviceCreate(&DeviceInit, &attributes, &device);
    if (!NT_SUCCESS(status)) return status;

    ctx = GetDeviceContext(device);
    RtlZeroMemory(ctx, sizeof(*ctx));
    ctx->Device = device;

    ctx->HidDescriptor = G_HidDescriptor;
    ctx->ReportDescriptor = G_ReportDescriptor;

    RtlZeroMemory(&ctx->HidDeviceAttributes, sizeof(ctx->HidDeviceAttributes));
    ctx->HidDeviceAttributes.Size = sizeof(HID_DEVICE_ATTRIBUTES);
    ctx->HidDeviceAttributes.VendorID = FIC_VHID_VID;
    ctx->HidDeviceAttributes.ProductID = FIC_VHID_PID;
    ctx->HidDeviceAttributes.VersionNumber = FIC_VHID_VERSION;

    status = WdfWaitLockCreate(WDF_NO_OBJECT_ATTRIBUTES, &ctx->ReportLock);
    if (!NT_SUCCESS(status)) return status;

    status = QueueCreate(device, &ctx->DefaultQueue);
    if (!NT_SUCCESS(status)) return status;

    status = ManualQueueCreate(device, &ctx->ManualQueue);
    if (!NT_SUCCESS(status)) return status;

    return STATUS_SUCCESS;
}

#ifdef _KERNEL_MODE
EVT_WDF_IO_QUEUE_IO_INTERNAL_DEVICE_CONTROL EvtIoDeviceControl;
#else
EVT_WDF_IO_QUEUE_IO_DEVICE_CONTROL EvtIoDeviceControl;
#endif

NTSTATUS
QueueCreate(
    _In_ WDFDEVICE Device,
    _Out_ WDFQUEUE *Queue
    )
{
    NTSTATUS status;
    WDF_IO_QUEUE_CONFIG config;
    WDF_OBJECT_ATTRIBUTES attributes;
    WDFQUEUE queue;
    PQUEUE_CONTEXT qctx;

    WDF_IO_QUEUE_CONFIG_INIT_DEFAULT_QUEUE(&config, WdfIoQueueDispatchParallel);
#ifdef _KERNEL_MODE
    config.EvtIoInternalDeviceControl = EvtIoDeviceControl;
#else
    config.EvtIoDeviceControl = EvtIoDeviceControl;
#endif

    WDF_OBJECT_ATTRIBUTES_INIT_CONTEXT_TYPE(&attributes, QUEUE_CONTEXT);
    status = WdfIoQueueCreate(Device, &config, &attributes, &queue);
    if (!NT_SUCCESS(status)) return status;

    qctx = GetQueueContext(queue);
    qctx->Queue = queue;
    qctx->DeviceContext = GetDeviceContext(Device);
    *Queue = queue;
    return STATUS_SUCCESS;
}

NTSTATUS
ManualQueueCreate(
    _In_ WDFDEVICE Device,
    _Out_ WDFQUEUE *Queue
    )
{
    WDF_IO_QUEUE_CONFIG config;
    WDF_IO_QUEUE_CONFIG_INIT(&config, WdfIoQueueDispatchManual);
    return WdfIoQueueCreate(Device, &config, WDF_NO_OBJECT_ATTRIBUTES, Queue);
}

NTSTATUS
RequestCopyFromBuffer(
    _In_ WDFREQUEST Request,
    _In_ PVOID SourceBuffer,
    _In_ size_t NumBytesToCopyFrom
    )
{
    NTSTATUS status;
    WDFMEMORY memory;
    size_t outputBufferLength;

    status = WdfRequestRetrieveOutputMemory(Request, &memory);
    if (!NT_SUCCESS(status)) return status;

    WdfMemoryGetBuffer(memory, &outputBufferLength);
    if (outputBufferLength < NumBytesToCopyFrom) return STATUS_INVALID_BUFFER_SIZE;

    status = WdfMemoryCopyFromBuffer(memory, 0, SourceBuffer, NumBytesToCopyFrom);
    if (NT_SUCCESS(status)) WdfRequestSetInformation(Request, NumBytesToCopyFrom);
    return status;
}

static NTSTATUS FicPopReport(_In_ PDEVICE_CONTEXT ctx, _Out_ PFIC_PENDING_REPORT out)
{
    NTSTATUS status = STATUS_NO_MORE_ENTRIES;

    WdfWaitLockAcquire(ctx->ReportLock, NULL);
    if (ctx->Count) {
        *out = ctx->Pending[ctx->Head];
        ctx->Head = (ctx->Head + 1) % FIC_PENDING_DEPTH;
        ctx->Count--;
        status = STATUS_SUCCESS;
    }
    WdfWaitLockRelease(ctx->ReportLock);
    return status;
}

NTSTATUS
FicQueueInputReport(
    _In_ PDEVICE_CONTEXT ctx,
    _In_reads_bytes_(Length) const UCHAR *Data,
    _In_ ULONG Length
    )
{
    PFIC_PENDING_REPORT slot;

    if (!ctx || !Data || !Length || Length > FIC_MAX_INPUT_REPORT) {
        return STATUS_INVALID_PARAMETER;
    }

    WdfWaitLockAcquire(ctx->ReportLock, NULL);

    if (ctx->Count == FIC_PENDING_DEPTH) {
        ctx->Head = (ctx->Head + 1) % FIC_PENDING_DEPTH;
        ctx->Count--;
    }

    slot = &ctx->Pending[ctx->Tail];
    RtlZeroMemory(slot, sizeof(*slot));
    slot->Length = Length;
    FicCopyBytes(slot->Data, Data, Length);
    ctx->Tail = (ctx->Tail + 1) % FIC_PENDING_DEPTH;
    ctx->Count++;

    WdfWaitLockRelease(ctx->ReportLock);

    FicDrainPendingReads(ctx);
    return STATUS_SUCCESS;
}

VOID
FicDrainPendingReads(
    _In_ PDEVICE_CONTEXT ctx
    )
{
    NTSTATUS status;
    WDFREQUEST request;
    FIC_PENDING_REPORT report;

    for (;;) {
        status = WdfIoQueueRetrieveNextRequest(ctx->ManualQueue, &request);
        if (!NT_SUCCESS(status)) break;

        status = FicPopReport(ctx, &report);
        if (!NT_SUCCESS(status)) {
            WdfRequestForwardToIoQueue(request, ctx->ManualQueue);
            break;
        }

        status = RequestCopyFromBuffer(request, report.Data, report.Length);
        WdfRequestComplete(request, status);
    }
}

NTSTATUS
ReadReport(
    _In_ PQUEUE_CONTEXT QueueContext,
    _In_ WDFREQUEST Request,
    _Always_(_Out_) BOOLEAN *CompleteRequest
    )
{
    FIC_PENDING_REPORT report;
    NTSTATUS status;

    status = FicPopReport(QueueContext->DeviceContext, &report);
    if (NT_SUCCESS(status)) {
        *CompleteRequest = TRUE;
        return RequestCopyFromBuffer(Request, report.Data, report.Length);
    }

    status = WdfRequestForwardToIoQueue(Request, QueueContext->DeviceContext->ManualQueue);
    if (NT_SUCCESS(status)) {
        *CompleteRequest = FALSE;
    } else {
        *CompleteRequest = TRUE;
    }
    return status;
}

NTSTATUS
SetFeature(
    _In_ PQUEUE_CONTEXT QueueContext,
    _In_ WDFREQUEST Request
    )
{
    NTSTATUS status;
    HID_XFER_PACKET packet;
    PFIC_CONTROL_REPORT control;
    FIC_KEYBOARD_INPUT_REPORT key;
    FIC_MOUSE_INPUT_REPORT mouse;
    FIC_KEYBOARD_INPUT_REPORT keyZero;
    FIC_MOUSE_INPUT_REPORT mouseZero;

    status = RequestGetHidXferPacket_ToWriteToDevice(Request, &packet);
    if (!NT_SUCCESS(status)) return status;

    if (packet.reportId != FIC_CONTROL_REPORT_ID ||
        packet.reportBufferLen < sizeof(FIC_CONTROL_REPORT)) {
        return STATUS_INVALID_PARAMETER;
    }

    control = (PFIC_CONTROL_REPORT)packet.reportBuffer;
    if (control->ReportId != FIC_CONTROL_REPORT_ID) return STATUS_INVALID_PARAMETER;

    switch (control->Command) {
    case FIC_CMD_KEYBOARD:
        RtlZeroMemory(&key, sizeof(key));
        key.ReportId = FIC_KEYBOARD_REPORT_ID;
        FicCopyBytes((UCHAR*)&key.Modifier, control->Payload, 8);
        status = FicQueueInputReport(
            QueueContext->DeviceContext,
            (const UCHAR*)&key,
            sizeof(key));
        break;

    case FIC_CMD_MOUSE:
        RtlZeroMemory(&mouse, sizeof(mouse));
        mouse.ReportId = FIC_MOUSE_REPORT_ID;
        FicCopyBytes((UCHAR*)&mouse.Buttons, control->Payload, 6);
        status = FicQueueInputReport(
            QueueContext->DeviceContext,
            (const UCHAR*)&mouse,
            sizeof(mouse));
        break;

    case FIC_CMD_RESET:
        RtlZeroMemory(&keyZero, sizeof(keyZero));
        keyZero.ReportId = FIC_KEYBOARD_REPORT_ID;
        RtlZeroMemory(&mouseZero, sizeof(mouseZero));
        mouseZero.ReportId = FIC_MOUSE_REPORT_ID;
        status = FicQueueInputReport(
            QueueContext->DeviceContext,
            (const UCHAR*)&keyZero,
            sizeof(keyZero));
        if (NT_SUCCESS(status)) {
            status = FicQueueInputReport(
                QueueContext->DeviceContext,
                (const UCHAR*)&mouseZero,
                sizeof(mouseZero));
        }
        break;

    default:
        status = STATUS_INVALID_PARAMETER;
        break;
    }

    if (NT_SUCCESS(status)) {
        WdfRequestSetInformation(Request, sizeof(FIC_CONTROL_REPORT));
    }

    return status;
}

VOID
EvtIoDeviceControl(
    _In_ WDFQUEUE Queue,
    _In_ WDFREQUEST Request,
    _In_ size_t OutputBufferLength,
    _In_ size_t InputBufferLength,
    _In_ ULONG IoControlCode
    )
{
    NTSTATUS status = STATUS_NOT_IMPLEMENTED;
    BOOLEAN completeRequest = TRUE;
    WDFDEVICE device = WdfIoQueueGetDevice(Queue);
    PDEVICE_CONTEXT ctx = GetDeviceContext(device);
    PQUEUE_CONTEXT qctx = GetQueueContext(Queue);

    UNREFERENCED_PARAMETER(OutputBufferLength);
    UNREFERENCED_PARAMETER(InputBufferLength);

    switch (IoControlCode) {
    case IOCTL_HID_GET_DEVICE_DESCRIPTOR:
        status = RequestCopyFromBuffer(
            Request,
            &ctx->HidDescriptor,
            ctx->HidDescriptor.bLength);
        break;

    case IOCTL_HID_GET_DEVICE_ATTRIBUTES:
        status = RequestCopyFromBuffer(
            Request,
            &ctx->HidDeviceAttributes,
            sizeof(ctx->HidDeviceAttributes));
        break;

    case IOCTL_HID_GET_REPORT_DESCRIPTOR:
        status = RequestCopyFromBuffer(
            Request,
            ctx->ReportDescriptor,
            ctx->HidDescriptor.DescriptorList[0].wReportLength);
        break;

    case IOCTL_HID_READ_REPORT:
        status = ReadReport(qctx, Request, &completeRequest);
        break;

#ifndef _KERNEL_MODE
    case IOCTL_UMDF_HID_SET_FEATURE:
        status = SetFeature(qctx, Request);
        break;
#else
    case IOCTL_HID_SET_FEATURE:
        status = SetFeature(qctx, Request);
        break;
#endif

    case IOCTL_HID_ACTIVATE_DEVICE:
    case IOCTL_HID_DEACTIVATE_DEVICE:
        status = STATUS_SUCCESS;
        break;

    default:
        status = STATUS_NOT_IMPLEMENTED;
        break;
    }

    if (completeRequest) {
        WdfRequestComplete(Request, status);
    }
}
