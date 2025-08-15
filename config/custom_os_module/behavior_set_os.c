#include <zephyr/device.h>
#include <zephyr/logging/log.h>
#include <zmk/behavior.h>
#include <zmk/event_manager.h>
#include "os_constants.h"

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

enum os_type current_os = OS_TYPE_LINUX;

static int set_os_binding_pressed(struct zmk_behavior_binding *binding,
                                 struct zmk_behavior_binding_event event) {
    switch (binding->param1) {
        case OS_LINUX:
            current_os = OS_TYPE_LINUX;
            LOG_DBG("Set OS to Linux");
            break;
        case OS_MAC:
            current_os = OS_TYPE_MAC;
            LOG_DBG("Set OS to macOS");
            break;
        default:
            LOG_WRN("Unknown OS code: %d", binding->param1);
            return -EINVAL;
    }
    return ZMK_BEHAVIOR_OPAQUE;
}

static const struct zmk_behavior_driver_api set_os_driver_api = {
    .binding_pressed = set_os_binding_pressed,
};

BEHAVIOR_DT_INST_DEFINE(0, NULL, NULL, NULL, NULL, POST_KERNEL,
                       CONFIG_KERNEL_INIT_PRIORITY_DEFAULT,
                       &set_os_driver_api);
