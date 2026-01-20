#include "Memory.h"

// Static registration for QML
static bool memoryRegistered = []() {
    qRegisterMetaType<Memory>("Memory");
    return true;
}();
