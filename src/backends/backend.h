/**
* @file backend.h
*
* @brief utility functions for all backends
*
*/
#ifndef BACKEND_H
#define BACKEND_H

#define BACKEND_STATUS_RUNNING 0
#define BACKEND_STATUS_UNCONFIGURED 1
#define BACKEND_STATUS_UNLOADED 2

#define BACKEND_FEATURE_PERSISTANT 0x1
#define BACKEND_FEATURE_ACID 0x2
#define BACKEND_FEATURE_SYNC 0x4

typedef struct gravity_backend {
  long txid;
  void *backend;
} gravity_backend_t;

#endif /* BACKEND_H */
