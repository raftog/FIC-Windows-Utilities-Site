#define UNICODE
#define _UNICODE

#include <windows.h>
#include <setupapi.h>
#include <newdev.h>
#include <stdio.h>
#include <wchar.h>

#pragma comment(lib, "setupapi.lib")
#pragma comment(lib, "newdev.lib")

static void PrintWin32Error(const wchar_t* where)
{
    DWORD error = GetLastError();
    wchar_t* message = NULL;

    FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        error,
        0,
        (LPWSTR)&message,
        0,
        NULL);

    fwprintf(stderr, L"%ls failed: %lu", where, error);
    if (message) {
        fwprintf(stderr, L" - %ls", message);
        LocalFree(message);
    } else {
        fwprintf(stderr, L"\n");
    }
}

static BOOL HasHardwareId(const wchar_t* wanted)
{
    HDEVINFO devs = SetupDiGetClassDevsW(NULL, NULL, NULL, DIGCF_ALLCLASSES);
    if (devs == INVALID_HANDLE_VALUE) {
        return FALSE;
    }

    BOOL found = FALSE;
    for (DWORD index = 0;; ++index) {
        SP_DEVINFO_DATA data = {};
        data.cbSize = sizeof(data);

        if (!SetupDiEnumDeviceInfo(devs, index, &data)) {
            if (GetLastError() == ERROR_NO_MORE_ITEMS) {
                break;
            }
            continue;
        }

        wchar_t ids[4096] = {};
        DWORD type = 0;
        DWORD bytes = 0;

        if (!SetupDiGetDeviceRegistryPropertyW(
                devs,
                &data,
                SPDRP_HARDWAREID,
                &type,
                reinterpret_cast<PBYTE>(ids),
                sizeof(ids),
                &bytes)) {
            continue;
        }

        if (type != REG_MULTI_SZ && type != REG_SZ) {
            continue;
        }

        for (const wchar_t* p = ids; *p; p += wcslen(p) + 1) {
            if (_wcsicmp(p, wanted) == 0) {
                found = TRUE;
                break;
            }
        }

        if (found) {
            break;
        }
    }

    SetupDiDestroyDeviceInfoList(devs);
    return found;
}

static BOOL CreateRootDevice(const wchar_t* infPath, const wchar_t* hardwareId)
{
    GUID classGuid = {};
    wchar_t className[MAX_CLASS_NAME_LEN] = {};

    if (!SetupDiGetINFClassW(
            infPath,
            &classGuid,
            className,
            ARRAYSIZE(className),
            NULL)) {
        PrintWin32Error(L"SetupDiGetINFClassW");
        return FALSE;
    }

    HDEVINFO devs = SetupDiCreateDeviceInfoList(&classGuid, NULL);
    if (devs == INVALID_HANDLE_VALUE) {
        PrintWin32Error(L"SetupDiCreateDeviceInfoList");
        return FALSE;
    }

    SP_DEVINFO_DATA data = {};
    data.cbSize = sizeof(data);

    BOOL ok = SetupDiCreateDeviceInfoW(
        devs,
        className,
        &classGuid,
        L"FIC Viewer Virtual HID Input",
        NULL,
        DICD_GENERATE_ID,
        &data);

    if (!ok) {
        PrintWin32Error(L"SetupDiCreateDeviceInfoW");
        SetupDiDestroyDeviceInfoList(devs);
        return FALSE;
    }

    wchar_t hardwareIds[512] = {};
    if (wcslen(hardwareId) + 2 >= ARRAYSIZE(hardwareIds)) {
        SetLastError(ERROR_INSUFFICIENT_BUFFER);
        PrintWin32Error(L"Hardware ID");
        SetupDiDestroyDeviceInfoList(devs);
        return FALSE;
    }

    wcscpy_s(hardwareIds, hardwareId);

    ok = SetupDiSetDeviceRegistryPropertyW(
        devs,
        &data,
        SPDRP_HARDWAREID,
        reinterpret_cast<const BYTE*>(hardwareIds),
        static_cast<DWORD>((wcslen(hardwareId) + 2) * sizeof(wchar_t)));

    if (!ok) {
        PrintWin32Error(L"SetupDiSetDeviceRegistryPropertyW");
        SetupDiDestroyDeviceInfoList(devs);
        return FALSE;
    }

    ok = SetupDiCallClassInstaller(
        DIF_REGISTERDEVICE,
        devs,
        &data);

    if (!ok) {
        PrintWin32Error(L"DIF_REGISTERDEVICE");
        SetupDiDestroyDeviceInfoList(devs);
        return FALSE;
    }

    SetupDiDestroyDeviceInfoList(devs);
    return TRUE;
}

int wmain(int argc, wchar_t** argv)
{
    const wchar_t* hardwareId = L"Root\\FICVhid";

    if (argc < 2 || !argv[1] || !argv[1][0]) {
        fwprintf(stderr, L"Usage: FICVhidInstall.exe <full-or-relative-path-to-FICVhid.inf> [hardware-id]\n");
        return 2;
    }

    if (argc >= 3 && argv[2] && argv[2][0]) {
        hardwareId = argv[2];
    }

    wchar_t infPath[MAX_PATH] = {};
    DWORD length = GetFullPathNameW(argv[1], ARRAYSIZE(infPath), infPath, NULL);
    if (length == 0 || length >= ARRAYSIZE(infPath)) {
        PrintWin32Error(L"GetFullPathNameW");
        return 2;
    }

    if (GetFileAttributesW(infPath) == INVALID_FILE_ATTRIBUTES) {
        PrintWin32Error(L"INF path");
        return 2;
    }

    if (!HasHardwareId(hardwareId)) {
        wprintf(L"Creating root device node for %ls...\n", hardwareId);
        if (!CreateRootDevice(infPath, hardwareId)) {
            return 2;
        }
    } else {
        wprintf(L"Existing %ls device node found; updating driver...\n", hardwareId);
    }

    BOOL rebootRequired = FALSE;
    if (!UpdateDriverForPlugAndPlayDevicesW(
            NULL,
            hardwareId,
            infPath,
            INSTALLFLAG_FORCE,
            &rebootRequired)) {
        PrintWin32Error(L"UpdateDriverForPlugAndPlayDevicesW");
        return 2;
    }

    wprintf(L"FIC Viewer Virtual HID driver installed successfully.\n");
    if (rebootRequired) {
        wprintf(L"Windows reports that a reboot is required.\n");
        return 1;
    }

    return 0;
}
