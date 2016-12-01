
#include "backend.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "sophia.h"

static int get_status (lua_State *L) {
  lua_pushnumber(L, BACKEND_STATUS_RUNNING);
  return 1;
}

static int get_features (lua_State *L) {
  lua_pushnumber(L, BACKEND_FEATURE_PERSISTANT | BACKEND_FEATURE_ACID);
  return 1;
}

// get or set configuration parameters {{{
static int param (lua_State *L) {
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
static const luaL_Reg sophia_b_meths[] = {
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

static int sophia_init (lua_State *L) {
  luaL_newlib(L, sophia_b_meths);
  return 1;
}

static const luaL_Reg sophia_b_funcs[] = {
  {"init",  &sophia_init},
  {NULL, NULL}
};

int luaopen_gravity_backend_sophia (lua_State *L) {
  luaL_newlib(L, sophia_b_funcs);
  return 1;
}
// }}}

// vim: fdm=marker
