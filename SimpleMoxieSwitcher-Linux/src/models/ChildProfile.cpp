// ChildProfile is a Q_GADGET struct defined entirely in the header
// No additional implementation needed - using default constructors
#include "ChildProfile.h"

// Static registration for QML
static bool childProfileRegistered = []() {
    qRegisterMetaType<ChildProfile>("ChildProfile");
    return true;
}();
