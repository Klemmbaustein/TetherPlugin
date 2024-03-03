#include "tether.h"
#include <Windows.h>
#include <interfaces/sys.h>

typedef void(*LogFn)(const char* msg, int sev);
typedef void(*TetherInitFn)(LogFn log, bool* reloadPtr);

static bool isRunning = false;
bool tether_shouldReload = false;

void tether_log(const char* msg, int sev)
{
	ns_log(sev, msg);
}

void tether_open()
{
	if (isRunning)
	{
		return;
	}
	ns_log(LOG_INFO, "Opening Tether...");

	wchar_t path[MAX_PATH + 40];
	HMODULE hm = NULL;

	if (GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
		GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
		L"GetField", &hm) == 0)
	{
		int ret = GetLastError();
		ns_logf(LOG_ERR, "GetModuleHandle failed, error = %d", ret);
		exit(1);
		return;
	}
	if (GetModuleFileName(hm, path, sizeof(path) / sizeof(wchar_t)) == 0)
	{
		int ret = GetLastError();
		ns_logf(LOG_ERR, "GetModuleFileName failed, error = %d", ret);
		exit(1);
		return;
	}

	wchar_t* lastPath = NULL;
	for (int i = 0; i < sizeof(path) / sizeof(wchar_t); i++)
	{
		wchar_t* c = &path[i];

		if (*c == 0)
		{
			break;
		}

		if (*c == L'\\')
		{
			lastPath = c;
		}
	}

	if (lastPath)
	{
		*lastPath = 0;
	}
	ns_log(LOG_INFO, "Loading Tether dynamic library...");

	wcscat(path, L"/bin");
	DLL_DIRECTORY_COOKIE cookie = AddDllDirectory(path);
	wcscat(path, L"/TetherInstaller.dll");

	HINSTANCE tetherDll = LoadLibraryEx(path, NULL, LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);

	RemoveDllDirectory(cookie);

	if (tetherDll == NULL)
	{
		int ret = GetLastError();
		ns_logf(LOG_ERR, "LoadLibrary failed, error = %d", ret);
		exit(1);
		return;
	}
	ns_log(LOG_INFO, "Starting Tether...");

	TetherInitFn initFunc = GetProcAddress(tetherDll, "LoadInstaller");
	initFunc(tether_log, &tether_shouldReload);
	isRunning = true;
}