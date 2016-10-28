%module retroarch
%{
#include "retroarch.h"
#include "runloop.h"
#include "tasks/tasks_internal.h"
%}

%inline %{
// RetroArch original entory point
void start_rarch(char* core, char* rom) {
  char* source = "retroarch";
  char* opt = "-L";
  char* argv[] = {source, rom, opt, core};
  rarch_main(4, argv, NULL);
}

/*
// Extracted main loop
void run_rarch(void) {
  int ret;
  do {
    unsigned sleep_ms = 0;
    ret = runloop_iterate(&sleep_ms);
    if (ret == 1 && sleep_ms > 0)
      retro_sleep(sleep_ms);
    task_queue_ctl(TASK_QUEUE_CTL_CHECK, NULL);
  } while (ret != -1);
  main_exit(NULL);
};

// Extracted initialization
void init_rarch () {//(int argc, char *argv[]) {
  int argc = 4;
  char *argv[] = {"RetroArch", "super_mario_world.zip", "-L", "snes9x2010_libretro.dylib"};

  void *args = NULL;

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
}
*/
%}

int main(int argc, char *argv[]);

//int rarch_main(int argc, char *argv[], void *data);
