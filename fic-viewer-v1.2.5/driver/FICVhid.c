#include <ntddk.h>
#include <wdf.h>
#include <vhf.h>

#define IOCTL_FIC_VHID_KEY   CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_WRITE_DATA)
#define IOCTL_FIC_VHID_MOUSE CTL_CODE(FILE_DEVICE_UNKNOWN, 0x801, METHOD_BUFFERED, FILE_WRITE_DATA)
#define IOCTL_FIC_VHID_RESET CTL_CODE(FILE_DEVICE_UNKNOWN, 0x802, METHOD_BUFFERED, FILE_WRITE_DATA)

#pragma pack(push,1)
typedef struct _FIC_VHID_KEY_REPORT {
    UCHAR Modifier;
    UCHAR Reserved;
    UCHAR Keys[6];
} FIC_VHID_KEY_REPORT;

typedef struct _FIC_VHID_MOUSE_REPORT {
    UCHAR Buttons;
    USHORT X;
    USHORT Y;
    CHAR Wheel;
} FIC_VHID_MOUSE_REPORT;
#pragma pack(pop)

typedef struct _DEVICE_CONTEXT {
    VHFHANDLE Vhf;
} DEVICE_CONTEXT, *PDEVICE_CONTEXT;

WDF_DECLARE_CONTEXT_TYPE_WITH_NAME(DEVICE_CONTEXT, FicGetContext)

static const UCHAR g_ReportDescriptor[] = {
    /* Keyboard, Report ID 1 */
    0x05,0x01, 0x09,0x06, 0xA1,0x01, 0x85,0x01,
    0x05,0x07, 0x19,0xE0, 0x29,0xE7, 0x15,0x00, 0x25,0x01,
    0x75,0x01, 0x95,0x08, 0x81,0x02,
    0x75,0x08, 0x95,0x01, 0x81,0x01,
    0x05,0x07, 0x19,0x00, 0x29,0x65, 0x15,0x00, 0x25,0x65,
    0x75,0x08, 0x95,0x06, 0x81,0x00,
    0xC0,

    /* Absolute mouse, Report ID 2 */
    0x05,0x01, 0x09,0x02, 0xA1,0x01, 0x85,0x02,
    0x09,0x01, 0xA1,0x00,
    0x05,0x09, 0x19,0x01, 0x29,0x05, 0x15,0x00, 0x25,0x01,
    0x95,0x05, 0x75,0x01, 0x81,0x02,
    0x95,0x01, 0x75,0x03, 0x81,0x03,
    0x05,0x01, 0x09,0x30, 0x09,0x31,
    0x15,0x00, 0x27,0xFF,0xFF,0x00,0x00,
    0x75,0x10, 0x95,0x02, 0x81,0x02,
    0x09,0x38, 0x15,0x81, 0x25,0x7F,
    0x75,0x08, 0x95,0x01, 0x81,0x06,
    0xC0, 0xC0
};

EVT_WDF_DRIVER_DEVICE_ADD FicEvtDeviceAdd;
EVT_WDF_IO_QUEUE_IO_DEVICE_CONTROL FicEvtIoDeviceControl;
EVT_WDF_OBJECT_CONTEXT_CLEANUP FicEvtDeviceCleanup;

static NTSTATUS FicSubmit(PDEVICE_CONTEXT ctx, UCHAR reportId, PUCHAR payload, ULONG payloadBytes)
{
    HID_XFER_PACKET packet;
    UCHAR buffer[16];

    if (!ctx || !ctx->Vhf || payloadBytes + 1 > sizeof(buffer)) {
        return STATUS_DEVICE_NOT_READY;
    }

    RtlZeroMemory(buffer, sizeof(buffer));
    buffer[0] = reportId;
    if (payloadBytes) {
        RtlCopyMemory(buffer + 1, payload, payloadBytes);
    }

    packet.reportBuffer = buffer;
    packet.reportBufferLen = payloadBytes + 1;
    packet.reportId = reportId;
    return VhfReadReportSubmit(ctx->Vhf, &packet);
}

VOID FicEvtDeviceCleanup(WDFOBJECT Object)
{
    PDEVICE_CONTEXT ctx = FicGetContext((WDFDEVICE)Object);
    if (ctx && ctx->Vhf) {
        VhfDelete(ctx->Vhf, TRUE);
        ctx->Vhf = NULL;
    }
}

VOID FicEvtIoDeviceControl(
    WDFQUEUE Queue,
    WDFREQUEST Request,
    size_t OutputBufferLength,
    size_t InputBufferLength,
    ULONG IoControlCode)
{
    WDFDEVICE device = WdfIoQueueGetDevice(Queue);
    PDEVICE_CONTEXT ctx = FicGetContext(device);
    NTSTATUS status = STATUS_INVALID_DEVICE_REQUEST;
    PVOID data = NULL;
    size_t size = 0;
    UCHAR zeroKey[sizeof(FIC_VHID_KEY_REPORT)] = {0};
    UCHAR zeroMouse[sizeof(FIC_VHID_MOUSE_REPORT)] = {0};

    UNREFERENCED_PARAMETER(OutputBufferLength);
    UNREFERENCED_PARAMETER(InputBufferLength);

    switch (IoControlCode) {
    case IOCTL_FIC_VHID_KEY:
        status = WdfRequestRetrieveInputBuffer(Request, sizeof(FIC_VHID_KEY_REPORT), &data, &size);
        if (NT_SUCCESS(status)) {
            status = FicSubmit(ctx, 1, (PUCHAR)data, sizeof(FIC_VHID_KEY_REPORT));
        }
        break;

    case IOCTL_FIC_VHID_MOUSE:
        status = WdfRequestRetrieveInputBuffer(Request, sizeof(FIC_VHID_MOUSE_REPORT), &data, &size);
        if (NT_SUCCESS(status)) {
            status = FicSubmit(ctx, 2, (PUCHAR)data, sizeof(FIC_VHID_MOUSE_REPORT));
        }
        break;

    case IOCTL_FIC_VHID_RESET:
        status = FicSubmit(ctx, 1, zeroKey, sizeof(zeroKey));
        if (NT_SUCCESS(status)) {
            status = FicSubmit(ctx, 2, zeroMouse, sizeof(zeroMouse));
        }
        break;
    }

    WdfRequestComplete(Request, status);
}

NTSTATUS FicEvtDeviceAdd(WDFDRIVER Driver, PWDFDEVICE_INIT DeviceInit)
{
    NTSTATUS status;
    WDFDEVICE device;
    WDF_OBJECT_ATTRIBUTES attributes;
    WDF_IO_QUEUE_CONFIG queueConfig;
    PDEVICE_CONTEXT ctx;
    VHF_CONFIG vhfConfig;
    UNICODE_STRING deviceName;
    UNICODE_STRING symLink;

    UNREFERENCED_PARAMETER(Driver);

    RtlInitUnicodeString(&deviceName, L"\\Device\\FICVirtualInput");
    status = WdfDeviceInitAssignName(DeviceInit, &deviceName);
    if (!NT_SUCCESS(status)) return status;

    WdfDeviceInitSetDeviceType(DeviceInit, FILE_DEVICE_UNKNOWN);
    WdfDeviceInitSetExclusive(DeviceInit, FALSE);

    WDF_OBJECT_ATTRIBUTES_INIT_CONTEXT_TYPE(&attributes, DEVICE_CONTEXT);
    attributes.EvtCleanupCallback = FicEvtDeviceCleanup;

    status = WdfDeviceCreate(&DeviceInit, &attributes, &device);
    if (!NT_SUCCESS(status)) return status;

    ctx = FicGetContext(device);
    RtlZeroMemory(ctx, sizeof(*ctx));

    RtlInitUnicodeString(&symLink, L"\\DosDevices\\FICVirtualInput");
    status = WdfDeviceCreateSymbolicLink(device, &symLink);
    if (!NT_SUCCESS(status)) return status;

    WDF_IO_QUEUE_CONFIG_INIT_DEFAULT_QUEUE(&queueConfig, WdfIoQueueDispatchSequential);
    queueConfig.EvtIoDeviceControl = FicEvtIoDeviceControl;
    status = WdfIoQueueCreate(device, &queueConfig, WDF_NO_OBJECT_ATTRIBUTES, WDF_NO_HANDLE);
    if (!NT_SUCCESS(status)) return status;

    VHF_CONFIG_INIT(&vhfConfig,
        WdfDeviceWdmGetDeviceObject(device),
        sizeof(g_ReportDescriptor),
        g_ReportDescriptor);

    vhfConfig.HidDeviceAttributes.Size = sizeof(HID_DEVICE_ATTRIBUTES);
    vhfConfig.HidDeviceAttributes.VendorID = 0xF1C0;
    vhfConfig.HidDeviceAttributes.ProductID = 0x0125;
    vhfConfig.HidDeviceAttributes.VersionNumber = 0x0125;

    status = VhfCreate(&vhfConfig, &ctx->Vhf);
    if (!NT_SUCCESS(status)) return status;

    status = VhfStart(ctx->Vhf);
    if (!NT_SUCCESS(status)) {
        VhfDelete(ctx->Vhf, TRUE);
        ctx->Vhf = NULL;
        return status;
    }

    return STATUS_SUCCESS;
}

NTSTATUS DriverEntry(PDRIVER_OBJECT DriverObject, PUNICODE_STRING RegistryPath)
{
    WDF_DRIVER_CONFIG config;
    WDF_OBJECT_ATTRIBUTES attributes;

    WDF_DRIVER_CONFIG_INIT(&config, FicEvtDeviceAdd);
    WDF_OBJECT_ATTRIBUTES_INIT(&attributes);

    return WdfDriverCreate(
        DriverObject,
        RegistryPath,
        &attributes,
        &config,
        WDF_NO_HANDLE);
}
