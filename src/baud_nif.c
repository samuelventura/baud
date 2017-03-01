#include "baud_nif.h"
#include "erl_nif.h"

#include <stdio.h>

ErlNifResourceType *RES_TYPE;
ERL_NIF_TERM atom_ok;
ERL_NIF_TERM atom_er;

void release_resource(ErlNifEnv *env, void *obj) {
  UNUSED(env);

  BAUD_RESOURCE *res = obj;

  serial_close(res);
}

static int open_resource(ErlNifEnv *env) {
  RES_TYPE = enif_open_resource_type(
      env, "Elixir.Baud.Nif", "Elixir.Baud.Nif", release_resource,
      ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER, NULL);

  if (RES_TYPE == NULL)
    return -1;

  return 0;
}

static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info) {
  UNUSED(priv);
  UNUSED(load_info);

  if (open_resource(env) == -1)
    return -1;

  atom_ok = enif_make_atom(env, "ok");
  atom_er = enif_make_atom(env, "er");

  return 0;
}

static int reload(ErlNifEnv *env, void **priv, ERL_NIF_TERM load_info) {
  UNUSED(priv);
  UNUSED(load_info);

  if (open_resource(env) == -1)
    return -1;

  return 0;
}

static int upgrade(ErlNifEnv *env, void **priv, void **old_priv,
                   ERL_NIF_TERM load_info) {
  UNUSED(priv);
  UNUSED(old_priv);
  UNUSED(load_info);

  if (open_resource(env) == -1)
    return -1;

  return 0;
}

static ERL_NIF_TERM nif_open(ErlNifEnv *env, int argc,
                             const ERL_NIF_TERM argv[]) {
  if (argc != 3) {
    return enif_make_tuple2(
        env, atom_er,
        enif_make_string(env, "Invalid argument count", ERL_NIF_LATIN1));
  }
  ErlNifBinary device;
  if (!enif_inspect_binary(env, argv[0], &device)) {
    return enif_make_tuple2(
        env, atom_er,
        enif_make_string(env, "Argument 0 is not a binary", ERL_NIF_LATIN1));
  }
  if (device.size > MAXPATH - PADSIZE) {
    return enif_make_tuple2(
        env, atom_er, enif_make_string(env, "Invalid device", ERL_NIF_LATIN1));
  }
  int speed;
  if (!enif_get_int(env, argv[1], &speed)) {
    return enif_make_tuple2(
        env, atom_er,
        enif_make_string(env, "Argument 1 is not an integer", ERL_NIF_LATIN1));
  }
  if (speed <= 0 || speed >= 0x7FFFFFFF) {
    return enif_make_tuple2(
        env, atom_er, enif_make_string(env, "Invalid speed", ERL_NIF_LATIN1));
  }
  ErlNifBinary config;
  if (!enif_inspect_binary(env, argv[2], &config)) {
    return enif_make_tuple2(
        env, atom_er,
        enif_make_string(env, "Argument 2 is not a binary", ERL_NIF_LATIN1));
  }
  if (config.size != 3) {
    return enif_make_tuple2(
        env, atom_er, enif_make_string(env, "Invalid config", ERL_NIF_LATIN1));
  }
  BAUD_RESOURCE *res =
      (BAUD_RESOURCE *)enif_alloc_resource(RES_TYPE, sizeof(BAUD_RESOURCE));
  if (res == NULL) {
    return enif_raise_exception(
        env,
        enif_make_string(env, "enif_alloc_resource failed", ERL_NIF_LATIN1));
  }
  snprintf(res->device, device.size + 1, (const char *const)device.data);
  snprintf(res->config, config.size + 1, (const char *const)config.data);
  serial_open(res, speed);
  if (res->error != NULL) {
    // prevent error override by close method
    const char *error = res->error;
    serial_close(res);
    enif_release_resource(res);
    return enif_make_tuple2(env, atom_er,
                            enif_make_string(env, error, ERL_NIF_LATIN1));
  }
  return enif_make_tuple2(env, atom_ok, enif_make_resource(env, res));
}

static ERL_NIF_TERM nif_read(ErlNifEnv *env, int argc,
                             const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_tuple2(
        env, atom_er,
        enif_make_string(env, "Invalid argument count", ERL_NIF_LATIN1));
  }
  BAUD_RESOURCE *res = NULL;
  if (!enif_get_resource(env, argv[0], RES_TYPE, (void **)&res)) {
    return enif_make_tuple2(
        env, atom_er,
        enif_make_string(env, "Argument 0 is not a resource", ERL_NIF_LATIN1));
  }
  serial_available(res);
  if (res->error != NULL) {
    return enif_make_tuple2(env, atom_er,
                            enif_make_string(env, res->error, ERL_NIF_LATIN1));
  }
  if (res->count < 0)
    return enif_make_tuple2(env, atom_er, enif_make_int(env, res->count));
  ErlNifBinary bin;
  if (!enif_alloc_binary(res->count, &bin)) {
    enif_release_binary(&bin);
    return enif_raise_exception(
        env, enif_make_string(env, "enif_alloc_binary failed", ERL_NIF_LATIN1));
  }
  serial_read(res, bin.data, (COUNT)bin.size);
  if (res->error != NULL) {
    return enif_make_tuple2(env, atom_er,
                            enif_make_string(env, res->error, ERL_NIF_LATIN1));
  }
  return enif_make_tuple2(env, atom_ok, enif_make_binary(env, &bin));
}

static ERL_NIF_TERM nif_write(ErlNifEnv *env, int argc,
                              const ERL_NIF_TERM argv[]) {
  if (argc != 2) {
    return enif_make_tuple2(
        env, atom_er,
        enif_make_string(env, "Invalid argument count", ERL_NIF_LATIN1));
  }
  BAUD_RESOURCE *res = NULL;
  if (!enif_get_resource(env, argv[0], RES_TYPE, (void **)&res)) {
    return enif_make_tuple2(
        env, atom_er,
        enif_make_string(env, "Argument 0 is not a resource", ERL_NIF_LATIN1));
  }
  ErlNifBinary bin;
  if (!enif_inspect_binary(env, argv[1], &bin)) {
    return enif_make_tuple2(
        env, atom_er,
        enif_make_string(env, "Argument 1 is not a binary", ERL_NIF_LATIN1));
  }
  serial_write(res, bin.data, (COUNT)bin.size);
  if (res->error != NULL) {
    return enif_make_tuple2(env, atom_er,
                            enif_make_string(env, res->error, ERL_NIF_LATIN1));
  }
  return atom_ok;
}

static ERL_NIF_TERM nif_close(ErlNifEnv *env, int argc,
                              const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_tuple2(
        env, atom_er,
        enif_make_string(env, "Invalid argument count", ERL_NIF_LATIN1));
  }
  BAUD_RESOURCE *res = NULL;
  if (!enif_get_resource(env, argv[0], RES_TYPE, (void **)&res)) {
    return enif_make_tuple2(
        env, atom_er,
        enif_make_string(env, "Argument 0 is not a resource", ERL_NIF_LATIN1));
  }
  serial_close(res);
  if (res->error != NULL) {
    return enif_make_tuple2(env, atom_er,
                            enif_make_string(env, res->error, ERL_NIF_LATIN1));
  }
  return atom_ok;
}

static ErlNifFunc nif_funcs[] = {{"open", 3, nif_open, 0},
                                 {"read", 1, nif_read, 0},
                                 {"write", 2, nif_write, 0},
                                 {"close", 1, nif_close, 0}};

ERL_NIF_INIT(Elixir.Baud.Nif, nif_funcs, &load, &reload, &upgrade, NULL)
