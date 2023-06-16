//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <git2dart_binaries/git2dart_binaries_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) git2dart_binaries_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "Git2dartBinariesPlugin");
  git2dart_binaries_plugin_register_with_registrar(git2dart_binaries_registrar);
}
