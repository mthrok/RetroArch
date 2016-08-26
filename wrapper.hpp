#ifndef __RETROARCH_INTERFACE_WRAPPER_HPP_
#define __RETROARCH_INTERFACE_WRAPPER_HPP_


extern "C" {
  #include "interface.hpp"

  RAInterface *RA_new() { return new RAInterface(); }

  void RA_del(RAInterface *ra) { delete ra; };

  void start(RAInterface *ra) { ra->start(); };

  void init(RAInterface *ra, int argc, char *argv[]) {
    ra->init(argc, argv);
  };

  void run(RAInterface *ra) {
    ra->run();
  };

  void step(RAInterface *ra) {
    ra->step();
  };

  void stop(RAInterface *ra) {
    ra->stop();
  }

  void get_config(RAInterface *ra) {
    ra->get_config();
  }

  void get_screen_info(RAInterface *ra) {
    ra->get_screen_info();
  }

  uint64_t get_frame_count(RAInterface *ra) {
    return ra->get_frame_count();
  }

  void get_frame(RAInterface *ra, const void **data,
                  unsigned *width, unsigned *height, size_t *pitch) {
    ra->get_frame(data, width, height, pitch);
  }

  int get_pixel_format(RAInterface *ra) {
    return ra->get_pixel_format();
  }
}

#endif
