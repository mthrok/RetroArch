%module retroarch
%{
#include "libretro.h"
#include "core.h"
#include "retroarch.h"
#include "configuration.h"
#include "runloop.h"
#include "tasks/tasks_internal.h"
#define SWIG_FILE_WITH_INIT
%}

%include "typemaps.i"
%include "numpy.i"

%init %{
  import_array();
%}

////////////////////////////////////////////////////////////////////////////////
// INITIALIZATION
// Custom input mapping to make rarch_init callable with list arguments
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

%inline %{
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

  // Run one frame
  unsigned sleep_ms = 0;
  int ret = runloop_iterate(&sleep_ms);
}
%}

////////////////////////////////////////////////////////////////////////////////
// SCREEN FRAME RETRIEVAL
// Retrieve screen size
%apply unsigned *OUTPUT {unsigned *frame_width, unsigned *frame_height};

%inline %{
unsigned _get_bpp() {
  // Check video format
  switch(video_driver_get_pixel_format()) {
  case RETRO_PIXEL_FORMAT_0RGB1555:
  case RETRO_PIXEL_FORMAT_RGB565:
    return 2;
  case RETRO_PIXEL_FORMAT_XRGB8888:
    return 4;
  default:
    // TODO: Throw error
    printf("Unexpected format type\n");
    return 1;
  }
}

void rarch_get_frame_size(unsigned *frame_width, unsigned *frame_height) {
  void *pBuffer; size_t pitch;
  video_driver_cached_frame_get(&pBuffer, frame_width, frame_height, &pitch);
}
%}

%clear unsigned *frame_width, unsigned *frame_height;

// Retrieve screen
%apply (unsigned short** ARGOUTVIEW_ARRAY2, int* DIM1, int* DIM2) {(unsigned short**frame_buffer, int *frame_height, int *frame_width)};

%inline %{
void rarch_get_frame(unsigned short**frame_buffer,
		     int *frame_height, int *frame_width) {
  size_t pitch; unsigned h, w, bpp = _get_bpp();
  video_driver_cached_frame_get((void**)frame_buffer, &w, &h, &pitch);

  *frame_height = (int)h;
  *frame_width = (int)pitch / bpp;
  // printf("H:%u, W:%u, P:%u, Data:%p\n",
  // 	   *frame_height, *frame_width, pitch, *frame_buffer);
}
%}

%clear (unsigned short**frame_buffer, int *frame_height, int *frame_width);

////////////////////////////////////////////////////////////////////////////////
// Memory retrieval. FIXME
%inline %{

void rarch_get_memory_size() {
  retro_ctx_memory_info_t info;
  bool ret;

  info.id = RETRO_MEMORY_SAVE_RAM;
  ret = core_get_memory(&info);
  printf("RETRO_MEMORY_SAVE_RAM [%i]: %i\n", info.id, ret);
  printf("  size: %d\n", info.size);
  printf("  id:   %u\n", info.id);
  printf("  data:   %p\n", info.data);

  info.id = RETRO_MEMORY_RTC;
  ret = core_get_memory(&info);
  printf("RETRO_MEMORY_RTC [%i]: %i\n", info.id, ret);
  printf("  size: %d\n", info.size);
  printf("  id:   %u\n", info.id);
  printf("  data:   %p\n", info.data);

  info.id = RETRO_MEMORY_SYSTEM_RAM;
  ret = core_get_memory(&info);
  printf("RETRO_MEMORY_SYSTEM_RAM [%i]: %i\n", info.id, ret);
  printf("  size: %d\n", info.size);
  printf("  id:   %u\n", info.id);
  printf("  data:   %p\n", info.data);

  info.id = RETRO_MEMORY_VIDEO_RAM;
  ret = core_get_memory(&info);
  printf("RETRO_MEMORY_VIDEO_RAM [%i]: %i\n", info.id, ret);
  printf("  size: %d\n", info.size);
  printf("  id:   %u\n", info.id);
  printf("  data:   %p\n", info.data);

}

%}

////////////////////////////////////////////////////////////////////////////////
// Input retrieval
%inline %{
void rarch_check_input(void) {
  settings_t *settings = config_get_ptr();
  // printf("max user: %zu\n", settings->input.max_users);
  for (size_t i = 0; i < settings->input.max_users; ++i) {
    struct retro_keybind *bind = settings->input.binds[i];
    for (size_t j = 0; j < RARCH_BIND_LIST_END; ++j) {
      struct retro_keybind bind_ = bind[j];
      /*
      if (!bind_.valid || bind_.id > 23) {
	continue;
      }
      if (bind_.joykey == 0xFFFF &&
	  bind_.joyaxis == 0xFFFFFFFF) {
	continue;
      }
      */
      if (bind_.joykey != bind_.def_joykey) {
	printf("User %zu: joykey  %zu\n", i, bind_.joykey);
      }
      if (bind_.joyaxis != bind_.def_joyaxis) {
	printf("User %u: joyaxis %u\n", i, bind_.joyaxis);
      }
    }
  }
}

%}

////////////////////////////////////////////////////////////////////////////////
%inline %{
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
