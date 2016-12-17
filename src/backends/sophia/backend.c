
#include "backend.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "sophia.h"

typedef struct {
  int  status;
  void *env;
} sophia_backend_t;

static int get_status (lua_State *L) {
  sophia_backend_t *b = (sophia_backend_t *)lua_touserdata(L,
      lua_upvalueindex(1));
  lua_pushnumber(L, b->status);
  return 1;
}

static int get_features (lua_State *L) {
  lua_pushnumber(L, BACKEND_FEATURE_PERSISTANT | BACKEND_FEATURE_ACID);
  return 1;
}

// get or set configuration parameters {{{
static int param (lua_State *L) {
  int str_size;
  const char *key = luaL_checkstring(L,1);
  sophia_backend_t *b = (sophia_backend_t *)lua_touserdata(L,
      lua_upvalueindex(1));
  // Only key -> get value
  if (lua_isnoneornil(L,2)) {
    char *value = sp_getstring(b->env, key, &str_size);
    if (value) {
      lua_pushstring(L, value);
      free(value);
      return 1;
    }
    lua_pushnil(L);
  }
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

static int cleanup (lua_State *L) {
  sophia_backend_t *b = (sophia_backend_t *)lua_touserdata(L,
      lua_upvalueindex(1));
  if (b->env != NULL)
    sp_destroy(b->env);
  return 0;
}

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
  {"_gc",        &cleanup},
  {NULL, NULL}
};

static int sophia_init (lua_State *L) {
  luaL_newlibtable(L, sophia_b_meths);
  sophia_backend_t *b = (sophia_backend_t *)lua_newuserdata(L, sizeof(sophia_backend_t));
  b->status = BACKEND_STATUS_UNCONFIGURED;
  b->env = sp_env();
  luaL_setfuncs(L, sophia_b_meths, 1);
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
