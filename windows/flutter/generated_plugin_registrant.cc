//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_window/desktop_window_plugin.h>
#include <firebase_core/firebase_core_plugin_c_api.h>
#include <flutter_libserialport/flutter_libserialport_plugin.h>
#include <nativec/nativec_plugin_c_api.h>
#include <permission_handler_windows/permission_handler_windows_plugin.h>
#include <winaudio/winaudio_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  DesktopWindowPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DesktopWindowPlugin"));
  FirebaseCorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseCorePluginCApi"));
  FlutterLibserialportPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterLibserialportPlugin"));
  NativecPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("NativecPluginCApi"));
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
  WinaudioPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WinaudioPluginCApi"));
}
