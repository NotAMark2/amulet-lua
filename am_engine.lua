-- static void init_metatable_registry(lua_State *L) {
	-- lua_newtable(L);
	-- lua_pushvalue(L, -1);
	-- lua_rawseti(L, LUA_REGISTRYINDEX, AM_METATABLE_REGISTRY);
	-- lua_setglobal(L, "_metatable_registry");
-- }

rawset(_G, "_metatable_registry", {})