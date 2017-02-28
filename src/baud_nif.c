#include "erl_nif.h"
#include "baud_nif.h"

#include <string.h>

//http://erlang.org/doc/man/erl_nif.html
//http://erlang.org/doc/tutorial/nif.html
//https://github.com/davisp/nif-examples
//https://github.com/msantos/srly
//https://spin.atomicobject.com/2015/03/16/elixir-native-interoperability-ports-vs-nifs/
//http://andrealeopardi.com/posts/using-c-from-elixir-with-nifs/
//http://stackoverflow.com/questions/18266626/what-is-the-range-of-a-windows-handle-on-a-64-bits-application
//http://stackoverflow.com/questions/8059616/whats-the-range-of-file-descriptors-on-64-bit-linux

ErlNifResourceType* RES_TYPE;
ERL_NIF_TERM atom_ok;
ERL_NIF_TERM atom_er;

void release_resource(ErlNifEnv *env, void *obj)
{
        UNUSED(env);

        BAUD_RESOURCE *res = obj;

        serial_close(res);
}

static int open_resource(ErlNifEnv* env)
{
        RES_TYPE = enif_open_resource_type(env,
                                           "Elixir.Baud.Nif",
                                           "Elixir.Baud.Nif",
                                           release_resource,
                                           ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER,
                                           NULL);
        if (RES_TYPE == NULL) return -1;
        return 0;
}

static int load(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info)
{
        UNUSED(priv);
        UNUSED(load_info);

        if (open_resource(env) == -1) return -1;

        atom_ok = enif_make_atom(env, "ok");
        atom_er = enif_make_atom(env, "er");

        return 0;
}

static int reload(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info)
{
        UNUSED(priv);
        UNUSED(load_info);

        if (open_resource(env) == -1) return -1;

        return 0;
}

static int upgrade(ErlNifEnv* env, void** priv, void** old_priv, ERL_NIF_TERM load_info)
{
        UNUSED(priv);
        UNUSED(old_priv);
        UNUSED(load_info);

        if (open_resource(env) == -1) return -1;

        return 0;
}

static ERL_NIF_TERM nif_open(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
        if (argc != 3) {
                return enif_make_badarg(env);
        }
        ErlNifBinary device;
        if (!enif_inspect_binary(env, argv[0], &device)) {
                return enif_make_badarg(env);
        }
        int speed;
        if (!enif_get_int(env, argv[1], &speed)) {
                return enif_make_badarg(env);
        }
        ErlNifBinary config;
        if (!enif_inspect_binary(env, argv[2], &config) || config.size!=3) {
                return enif_make_badarg(env);
        }
        char path[device.size + 1];
        char conf[config.size + 1];
        memcpy(path, device.data, device.size);
        memcpy(conf, config.data, config.size);
        path[device.size] = 0;
        conf[config.size] = 0;
        BAUD_RESOURCE* res = (BAUD_RESOURCE*)enif_alloc_resource(
                RES_TYPE,
                sizeof(BAUD_RESOURCE));
        if (res == NULL) return enif_make_badarg(env);
        if (serial_open(res, path, speed, conf) < 0) {
                serial_close(res); //may have failed after creation
                enif_release_resource(res);
                return enif_make_tuple2(env,
                                        atom_er,
                                        enif_make_int(env, -1)
                                        );
        }
        else return enif_make_tuple2(env,
                                     atom_ok,
                                     enif_make_resource(env, res)
                                     );
}

static ERL_NIF_TERM nif_read(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
        if (argc != 1) {
                return enif_make_badarg(env);
        }
        BAUD_RESOURCE* res = NULL;
        if (!enif_get_resource(env, argv[0], RES_TYPE, (void**) &res)) {
                return enif_make_badarg(env);
        }
        int size = serial_available(res);
        if (size < 0)
                return enif_make_tuple2(env,
                                        atom_er,
                                        enif_make_int(env, size)
                                        );
        ErlNifBinary bin;
        if (!enif_alloc_binary(size, &bin)) {
                enif_release_binary(&bin);
                return enif_raise_exception(env,
                                            enif_make_string(env,
                                                             "enif_alloc_binary failed",
                                                             ERL_NIF_LATIN1));
        }
        if (serial_read(res, bin.data, bin.size) != bin.size) {
                return enif_raise_exception(env,
                                            enif_make_string(env,
                                                             "serial_read failed",
                                                             ERL_NIF_LATIN1));
        }
        return enif_make_tuple2(env,
                                atom_ok,
                                enif_make_binary(env, &bin)
                                );
}

static ERL_NIF_TERM nif_write(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
        if (argc != 2) {
                return enif_make_badarg(env);
        }
        BAUD_RESOURCE* res = NULL;
        if (!enif_get_resource(env, argv[0], RES_TYPE, (void**) &res)) {
                return enif_make_badarg(env);
        }
        ErlNifBinary bin;
        if (!enif_inspect_binary(env, argv[1], &bin)) {
                return enif_make_badarg(env);
        }
        if (serial_write(res, bin.data, bin.size) != bin.size) {
                return enif_raise_exception(env,
                                            enif_make_string(env,
                                                             "serial_write failed",
                                                             ERL_NIF_LATIN1));
        }
        return atom_ok;
}

static ERL_NIF_TERM nif_close(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
        if (argc != 1) {
                return enif_make_badarg(env);
        }
        BAUD_RESOURCE* res = NULL;
        if (!enif_get_resource(env, argv[0], RES_TYPE, (void**) &res)) {
                return enif_make_badarg(env);
        }
        if (serial_close(res) < 0) {
                return enif_raise_exception(env,
                                            enif_make_string(env,
                                                             "serial_close failed",
                                                             ERL_NIF_LATIN1));
        }
        return atom_ok;
}

static ErlNifFunc nif_funcs[] =
{
        {"open", 3, nif_open, 0},
        {"read", 1, nif_read, 0},
        {"write", 2, nif_write, 0},
        {"close", 1, nif_close, 0}
};

ERL_NIF_INIT(Elixir.Baud.Nif, nif_funcs, &load, &reload, &upgrade, NULL)
