extern "C"
{
    #include "lua.h"
    #include "lualib.h"
    #include "lauxlib.h"

    #include "uv.h"

    #include "luvit/luvit_init.h"
}

int main(int argc, char *argv[])
{
    lua_State *L;
    uv_loop_t *loop;

    argv = uv_setup_args(argc, argv);

    L = luaL_newstate();
    if (L == NULL)
    {
        fprintf(stderr, "luaL_newstate has failed\n");
        return 1;
    }

    luaL_openlibs(L);

    loop = uv_default_loop();

    #ifdef USE_OPENSSL
    luvit_init_ssl();
    #endif

    /* Get argv */
    lua_createtable (L, argc, 0);
    for (int index = 0; index < argc; index++) {
        lua_pushstring (L, argv[index]);
        lua_rawseti(L, -2, index);
    }
    lua_setglobal(L, "argv");


    if (luvit_init(L, loop))
    {
        fprintf(stderr, "luvit_init has failed\n");
        return 1;
    }


    lua_pushboolean(L, true);
    lua_setglobal(L, "LUAPP");

    lua_pushboolean(L, false);
    lua_setglobal(L, "SERVER");

    lua_pushboolean(L, false);
    lua_setglobal(L, "CLIENT");

    luaL_dostring(L, "package.path = package.path .. \";resources/lua/?.lua;resources/lua/?/init.lua\"");

    if(luaL_dostring(L, "require \"luapp\""))
    {
        printf("%s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
        lua_close(L);
        return -1;
    }

    lua_close(L);
    return 0;
}