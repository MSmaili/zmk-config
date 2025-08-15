#define DT_DRV_COMPAT zmk_behavior_set_os

#include <zephyr/device.h>
#include <zephyr/logging/log.h>

#include <drivers/behavior.h>
#include <zmk/behavior.h>

#include <zmk-os/os_constants.h>

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

// Global OS state - defaults based on Kconfig
#ifdef CONFIG_ZMK_OS_DEFAULT_LINUX
enum os_type current_os = OS_TYPE_LINUX;
#else
enum os_type current_os = OS_TYPE_MAC;
#endif

static int set_os_binding_pressed(struct zmk_behavior_binding *binding,
                                  struct zmk_behavior_binding_event event) {
    switch (binding->param1) {
        case OS_LINUX:
            current_os = OS_TYPE_LINUX;
#ifdef CONFIG_ZMK_OS_DEBUG
            LOG_DBG("Set OS to Linux");
#endif
            break;
        case OS_MAC:
            current_os = OS_TYPE_MAC;
#ifdef CONFIG_ZMK_OS_DEBUG
            LOG_DBG("Set OS to macOS");
#endif
            break;
        default:
            LOG_WRN("Invalid OS parameter: %d", binding->param1);
            return -EINVAL;
    }

    return ZMK_BEHAVIOR_OPAQUE;
}

static int set_os_binding_released(struct zmk_behavior_binding *binding,
                                   struct zmk_behavior_binding_event event) {
    // No action on release
    return ZMK_BEHAVIOR_OPAQUE;
}

static const struct behavior_driver_api set_os_driver_api = {
    .binding_pressed = set_os_binding_pressed,
    .binding_released = set_os_binding_released,
};

static int set_os_init(const struct device *dev) { return 0; }

#define SET_OS_INST(n)                                                         \
    BEHAVIOR_DT_INST_DEFINE(n, set_os_init, NULL, NULL, NULL, POST_KERNEL,    \
                            CONFIG_KERNEL_INIT_PRIORITY_DEFAULT,               \
                            &set_os_driver_api);

DT_INST_FOREACH_STATUS_OKAY(SET_OS_INST)
