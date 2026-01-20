#include "DIContainer.h"
#include "../services/MQTTService.h"

void DIContainer::initialize() {
    auto& container = DIContainer::instance();

    // Register services
    container.registerSingleton(new MQTTService());

    // Add more services as needed
}
