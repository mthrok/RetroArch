%module retroarch

%{
#include "retroarch.h"
#include "runloop.h"
#include "tasks/tasks_internal.h"
%}

////////////////////////////////////////////////////////////////////////////////
// Custom mapping to make rarch_init callable with list arguments
%typemap(in) (int main_argc, char *main_argv[]) {
  int i;
  if (!PyList_Check($input)) {
    PyErr_SetString(PyExc_ValueError, "Expecting a list");
    return NULL;
  }
  $1 = PyList_Size($input);
  $2 = (char **) malloc(($1+1)*sizeof(char *));
  for (i = 0; i < $1; i++) {
    PyObject *s = PyList_GetItem($input,i);
    if (!PyString_Check(s)) {
      free($2);
      PyErr_SetString(PyExc_ValueError, "List items must be strings");
      return NULL;
    }
    $2[i] = PyString_AsString(s);
  }
  $2[i] = 0;
}

%typemap(freearg) (int main_argc, char *main_argv[]) {
  if ($2) free($2);
}
////////////////////////////////////////////////////////////////////////////////

%inline %{
// UI Initialization
void rarch_init(int main_argc, char *main_argv[]) {
  void *args = NULL;

  rarch_ctl(RARCH_CTL_PREINIT, NULL);
  frontend_driver_init_first(args);
  rarch_ctl(RARCH_CTL_INIT, NULL);

  if (frontend_driver_is_inited()) {
    content_ctx_info_t info;
    info.argc            = main_argc;
    info.argv            = main_argv;
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

// One step
int rarch_step(void) {
  unsigned sleep_ms = 0;
  int ret = runloop_iterate(&sleep_ms);
  if (ret == 1 && sleep_ms > 0)
    retro_sleep(sleep_ms);
  task_queue_ctl(TASK_QUEUE_CTL_CHECK, NULL);
  return ret;
}

// Clean up
void rarch_exit() {
  main_exit(NULL);
}

%}
