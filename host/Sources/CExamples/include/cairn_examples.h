// The apps' Lean initializers, which Cairn's CLean doesn't declare. Cairn's CLean declares the
// runtime and the v1 app ABI (`cairn_app_init`, `cairn_app_step`, `cairn_app_frame`). Each
// executable links one app's library (.cairn/lib/libcairn_examples_<app>.a), so it defines only
// its own initializer; the others here are never called.
#pragma once
#include <stdint.h>
#include "cairn_lean.h"

// Named after the package (`cairn_examples`, `_` doubled) and the module that has the exports.
cairn_obj *runtime_initialize_cairn__examples_Counter_Abi(uint8_t builtin);
cairn_obj *runtime_initialize_cairn__examples_Basics(uint8_t builtin);
cairn_obj *runtime_initialize_cairn__examples_Todo_Abi(uint8_t builtin);
cairn_obj *runtime_initialize_cairn__examples_Clock_Abi(uint8_t builtin);
cairn_obj *runtime_initialize_cairn__examples_Tray_Abi(uint8_t builtin);
cairn_obj *runtime_initialize_cairn__examples_Gallery_Abi(uint8_t builtin);
