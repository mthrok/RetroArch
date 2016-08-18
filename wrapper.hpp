#ifndef __REFTOARCH_INTERFACE_HPP_
#define __RETROARCH_INTERFACE_HPP_

extern "C" {
  #include <cstdio>
  #include "frontend/frontend.h"
  #include "command.h"

  //
  #include "content.h"
  #include "retroarch.h"
  #include "runloop.h"
  #include "ui/ui_companion_driver.h"
  #include "tasks/tasks_internal.h"

  class RAInterface {
  public:
    RAInterface() {};
    ~RAInterface() {};

    void start_(void) {
        rarch_main(0, {}, NULL);
    };

    void start(int argc, char *argv[]) {
      void *args = NULL;
      int ret;

      rarch_ctl(RARCH_CTL_PREINIT, NULL);
      frontend_driver_init_first(args);
      rarch_ctl(RARCH_CTL_INIT, NULL);

      if (frontend_driver_is_inited()) {
        content_ctx_info_t info;
        info.argc            = argc;
        info.argv            = argv;
        info.args            = args;
        info.environ_get     = frontend_driver_environment_get_ptr();

        if (!task_push_content_load_default(
               NULL,
               NULL,
               &info,
               CORE_TYPE_PLAIN,
               CONTENT_MODE_LOAD_FROM_CLI,
               NULL,
               NULL))
         return;
      }
      ui_companion_driver_init_first();

      do {
        unsigned sleep_ms = 0;
        ret = runloop_iterate(&sleep_ms);
        if (ret == 1 && sleep_ms > 0)
          retro_sleep(sleep_ms);
        task_queue_ctl(TASK_QUEUE_CTL_CHECK, NULL);
      } while (ret != -1);
      main_exit(args);
    };
  };

  RAInterface *RA_new() { return new RAInterface(); }

  void RA_del(RAInterface *ra) { delete ra; };

  void start_(RAInterface *ra) { ra->start_(); };

  void start(RAInterface *ra, int argc, char *argv[]) {
    ra->start(argc, argv);
  };
}

#endif
