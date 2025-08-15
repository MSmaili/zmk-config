#include <zephyr/device.h>
#include <zephyr/logging/log.h>
#include <zmk/behavior.h>
#include <zmk/hid.h>
#include <zmk/endpoints.h>
#include <zmk/event_manager.h>
#include "os_constants.h"

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

struct os_kp_config {
    bool mac_first;
};

static int os_kp_init(const struct device *dev) {
    return 0;
}

static int os_kp_binding_pressed(struct zmk_behavior_binding *binding,
                                struct zmk_behavior_binding_event event) {
    const struct device *dev = zmk_behavior_get_binding(binding->behavior_dev);
    const struct os_kp_config *config = dev->config;

    uint32_t code;
    if (config->mac_first) {
        code = (current_os == OS_TYPE_MAC) ? binding->param1 : binding->param2;
    } else {
        code = (current_os == OS_TYPE_LINUX) ? binding->param1 : binding->param2;
    }

    LOG_DBG("OS-dependent press: OS=%s, code=0x%08X",
            (current_os == OS_TYPE_MAC) ? "mac" : "linux", code);
    return zmk_hid_keyboard_press(code);
}

static int os_kp_binding_released(struct zmk_behavior_binding *binding,
                                 struct zmk_behavior_binding_event event) {
    const struct device *dev = zmk_behavior_get_binding(binding->behavior_dev);
    const struct os_kp_config *config = dev->config;

    uint32_t code;
    if (config->mac_first) {
        code = (current_os == OS_TYPE_MAC) ? binding->param1 : binding->param2;
    } else {
        code = (current_os == OS_TYPE_LINUX) ? binding->param1 : binding->param2;
    }

    return zmk_hid_keyboard_release(code);
}

static const struct zmk_behavior_driver_api os_kp_driver_api = {
    .binding_pressed = os_kp_binding_pressed,
    .binding_released = os_kp_binding_released,
};

#define OS_KP_INST(n)                                                         \
    static const struct os_kp_config os_kp_config_##n = {                   \
        .mac_first = DT_INST_STRING_TOKEN(n, default) == DT_STRING_TOKEN(mac), \
    };                                                                        \
    BEHAVIOR_DT_INST_DEFINE(n, os_kp_init, NULL, NULL,                      \
                           &os_kp_config_##n, POST_KERNEL,                   \
                           CONFIG_KERNEL_INIT_PRIORITY_DEFAULT,              \
                           &os_kp_driver_api);

DT_INST_FOREACH_STATUS_OKAY(OS_KP_INST)
