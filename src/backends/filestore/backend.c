/**
 * @brief generic file storage backend
 */
#include "backend.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "mpack.h"

typedef struct {
  int  status;
} fs_backend_t;

static int get_status (lua_State *L) {
  fs_backend_t *b = (fs_backend_t *)lua_touserdata(L,
      lua_upvalueindex(1));
  lua_pushnumber(L, b->status);
  return 1;
}

static int get_features (lua_State *L) {
  lua_pushnumber(L, BACKEND_FEATURE_PERSISTANT);
  return 1;
}

// get or set configuration parameters {{{
static int param (lua_State *L) {
  fs_backend_t *b = (fs_backend_t *)lua_touserdata(L,
      lua_upvalueindex(1));
  return 1;
}
// }}}

// CRUD operations {{{
static int create_node (lua_State *L) {
  return 1;
}

static int create_link (lua_State *L) {
  return 1;
}

static int delete_node (lua_State *L) {
  return 0;
}

static int delete_link (lua_State *L) {
  return 0;
}

static int read_node (lua_State *L) {
  return 1;
}

static int read_link (lua_State *L) {
  return 1;
}

static int write_node (lua_State *L) {
  return 1;
}

static int write_link (lua_State *L) {
  return 1;
}

static int get_nodes (lua_State *L) {
  return 1;
}

static int get_links (lua_State *L) {
  return 1;
}
// }}}

// transaction functions {{{
static int start_tx (lua_State *L) {
  return 1;
}

static int commit_tx (lua_State *L) {
  return 1;
}

static int rollback_tx (lua_State *L) {
  return 1;
}
// }}}

// lua api definition {{{
static const luaL_Reg filestore_b_meths[] = {
  {"status",     &get_status},
  {"features",   &get_features},
  {"param",      &param},
  {"createNode", &create_node},
  {"createLink", &create_link},
  {"deleteNode", &delete_node},
  {"deleteLink", &delete_link},
  {"writeNode",  &write_node},
  {"writeLink",  &write_link},
  {"readNode",   &read_node},
  {"readLink",   &read_link},
  {"get_nodes",  &get_nodes},
  {"get_links",  &get_links},
  {"tx",         &start_tx},
  {"commit",     &commit_tx},
  {"rollback",   &rollback_tx},
  {NULL, NULL}
};

static int filestore_init (lua_State *L) {
  luaL_newlibtable(L, filestore_b_meths);
  fs_backend_t *b = (fs_backend_t *)lua_newuserdata(L, sizeof(fs_backend_t));
  b->status = BACKEND_STATUS_UNCONFIGURED;
  luaL_setfuncs(L, filestore_b_meths, 1);
  return 1;
}

static const luaL_Reg filestore_b_funcs[] = {
  {"init",  &filestore_init},
  {NULL, NULL}
};

int luaopen_gravity_backend_filestore (lua_State *L) {
  luaL_newlib(L, filestore_b_funcs);
  return 1;
}
// }}}

// vim: fdm=marker
