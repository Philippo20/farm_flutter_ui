#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {
// Per-user registration supports installed and portable builds without elevation.
void RegisterAppProtocol() {
  wchar_t executable[32768];
  const DWORD length = GetModuleFileNameW(nullptr, executable, 32768);
  if (length == 0 || length >= 32768) return;
  HKEY key;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, L"Software\\Classes\\farmestates",
                     0, nullptr, 0, KEY_WRITE, nullptr, &key, nullptr) != ERROR_SUCCESS) return;
  const wchar_t description[] = L"URL:Farm Estates";
  RegSetValueExW(key, nullptr, 0, REG_SZ,
                reinterpret_cast<const BYTE*>(description), sizeof(description));
  const wchar_t empty[] = L"";
  RegSetValueExW(key, L"URL Protocol", 0, REG_SZ,
                reinterpret_cast<const BYTE*>(empty), sizeof(empty));
  HKEY commandKey;
  if (RegCreateKeyExW(key, L"shell\\open\\command", 0, nullptr, 0,
                     KEY_WRITE, nullptr, &commandKey, nullptr) == ERROR_SUCCESS) {
    const std::wstring command = L"\"" + std::wstring(executable, length) + L"\" \"%1\"";
    RegSetValueExW(commandKey, nullptr, 0, REG_SZ,
                  reinterpret_cast<const BYTE*>(command.c_str()),
                  static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t)));
    RegCloseKey(commandKey);
  }
  RegCloseKey(key);
}
}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  RegisterAppProtocol();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Farm Estates - ADOM", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
