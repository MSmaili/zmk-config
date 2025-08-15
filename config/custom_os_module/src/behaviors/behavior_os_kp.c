#define DT_DRV_COMPAT zmk_behavior_os_kp

#include <zephyr/device.h>
#include <zephyr/logging/log.h>

#include <drivers/behavior.h>
#include <zmk/behavior.h>
#include <zmk/hid.h>
#include <zmk/endpoints.h>

#include <zmk-os/os_constants.h>

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

struct os_kp_config {
    bool mac_first; // true if "mac", false if "linux"
};

static int os_kp_binding_pressed(struct zmk_behavior_binding *binding,
                                struct zmk_behavior_binding_event event) {
    const struct device *dev = zmk_behavior_get_binding(binding->behavior_dev);
    const struct os_kp_config *config = dev->config;

    uint32_t keycode;

    // Determine keycode based on parameter ordering and current OS
    if (config->mac_first) {
        // param1=Mac, param2=Linux
        keycode = (current_os == OS_TYPE_MAC) ? binding->param1 : binding->param2;
    } else {
        // param1=Linux, param2=Mac (default)
        keycode = (current_os == OS_TYPE_LINUX) ? binding->param1 : binding->param2;
    }

#ifdef CONFIG_ZMK_OS_DEBUG
    LOG_DBG("OS-dependent press: OS=%s, keycode=0x%08X",
            (current_os == OS_TYPE_LINUX) ? "linux" : "mac", keycode);
#endif

    return zmk_hid_press(keycode);
}

static int os_kp_binding_released(struct zmk_behavior_binding *binding,
                                 struct zmk_behavior_binding_event event) {
    const struct device *dev = zmk_behavior_get_binding(binding->behavior_dev);
    const struct os_kp_config *config = dev->config;

    uint32_t keycode;

    if (config->mac_first) {
        keycode = (current_os == OS_TYPE_MAC) ? binding->param1 : binding->param2;
    } else {
        keycode = (current_os == OS_TYPE_LINUX) ? binding->param1 : binding->param2;
    }

#ifdef CONFIG_ZMK_OS_DEBUG
    LOG_DBG("OS-dependent release: OS=%s, keycode=0x%08X",
            (current_os == OS_TYPE_LINUX) ? "linux" : "mac", keycode);
#endif

    return zmk_hid_release(keycode);
}

static const struct behavior_driver_api os_kp_driver_api = {
    .binding_pressed = os_kp_binding_pressed,
    .binding_released = os_kp_binding_released,
};

static int os_kp_init(const struct device *dev) { return 0; }

#define OS_KP_INST(n)                                                          \
    static struct os_kp_config os_kp_config_##n = {                           \
        .mac_first = !DT_INST_ENUM_IDX_OR(n, default, 0),                     \
    };                                                                         \
    BEHAVIOR_DT_INST_DEFINE(n, os_kp_init, NULL, NULL, &os_kp_config_##n,     \
                            POST_KERNEL, CONFIG_KERNEL_INIT_PRIORITY_DEFAULT,  \
                            &os_kp_driver_api);

DT_INST_FOREACH_STATUS_OKAY(OS_KP_INST)
