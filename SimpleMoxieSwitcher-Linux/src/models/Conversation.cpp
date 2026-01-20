#include "Conversation.h"

// Static registration for QML
static bool conversationRegistered = []() {
    qRegisterMetaType<ChatMessage>("ChatMessage");
    qRegisterMetaType<Conversation>("Conversation");
    return true;
}();
