//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_window/desktop_window_plugin.h>
#include <flutter_libserialport/flutter_libserialport_plugin.h>
#include <nativec/nativec_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) desktop_window_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DesktopWindowPlugin");
  desktop_window_plugin_register_with_registrar(desktop_window_registrar);
  g_autoptr(FlPluginRegistrar) flutter_libserialport_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterLibserialportPlugin");
  flutter_libserialport_plugin_register_with_registrar(flutter_libserialport_registrar);
  g_autoptr(FlPluginRegistrar) nativec_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "NativecPlugin");
  nativec_plugin_register_with_registrar(nativec_registrar);
}
