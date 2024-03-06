#include "native_closures.h"
#include "bindings/module.h"
#include "bindings/relay.h"
#include "interfaces/sys.h"
#include "tether/tether.h"

SQRESULT Script_LaunchTether(HSquirrelVM* sqvm)
{
	SQRelay* api = sqapi(SC_UI);

	tether_open();

	return SQRESULT_NULL;
}

SQRESULT Script_TetherCheckReloadMods(HSquirrelVM* sqvm)
{
	SQRelay* api = sqapi(SC_UI);

	api->sq_pushbool(sqvm, tether_shouldReload);
	tether_shouldReload = false;

	return SQRESULT_NOTNULL;
}

SQRESULT Script_TetherCheckConnectServer(HSquirrelVM* sqvm)
{
	SQRelay* api = sqapi(SC_UI);
	
	api->sq_pushstring(sqvm, tether_newMapBuffer, strlen(tether_newMapBuffer));
	memset(tether_newMapBuffer, 0, sizeof(tether_newMapBuffer));

	return SQRESULT_NOTNULL;
}

SQRESULT Script_TetherReceiveGameInfo(HSquirrelVM* sqvm)
{
	SQRelay* api = sqapi(SC_UI);

	tether_setGameInfo(api->sq_getstring(sqvm, 1), api->sq_getstring(sqvm, 2), api->sq_getstring(sqvm, 3));

	return SQRESULT_NULL;
}

// internally used linked list to keep track of registered squirrel native
// closures
struct SQFunctionRegistrationList;

// Add your server native closures here
void sv_register_native_closures(CSquirrelVM* sqvm) 
{
}

// Add your client native closures here
void cl_register_native_closures(CSquirrelVM* sqvm) {
  // cl_bind_native_closure(sqvm, "return_type", "name", "params", "helptext", callback);
}

// Add your ui native closures here
void ui_register_native_closures(CSquirrelVM* sqvm)
{
	sv_bind_native_closure(
		sqvm, "void", "LaunchTether", "", "Launches Tether",
		Script_LaunchTether
	);

	sv_bind_native_closure(
		sqvm, "bool", "TetherCheckReloadMods", "", "Checks if Tether sent a message to reload all mods",
		Script_TetherCheckReloadMods
	);

	sv_bind_native_closure(
		sqvm, "string", "TetherCheckConnectServer", "", "Checks if Tether sent a message to connect to a server by it's ID",
		Script_TetherCheckConnectServer
	);

	sv_bind_native_closure(
		sqvm, "void", "TetherReceiveGameInfo", "string CurrentMap, string CurrentServer, string CurrentMode", "",
		Script_TetherReceiveGameInfo
	);
}

struct SQFunctionRegistrationList {
  SQFunctionRegistration reg;
  struct SQFunctionRegistrationList* next;
};

struct SQFunctionRegistrationList* _sv_regs = 0;
struct SQFunctionRegistrationList* _cl_regs = 0;
struct SQFunctionRegistrationList* _ui_regs = 0;

SQNativeClosureReturnType get_ret_ty(const char* ret_ty) {
  if (strcmp(ret_ty, "bool"))
	return SQ_RET_BOOL;
  if (strcmp(ret_ty, "vector"))
	return SQ_RET_VEC;
  if (strcmp(ret_ty, "int"))
	return SQ_RET_INT;
  if (strcmp(ret_ty, "entity"))
	return SQ_RET_ENT;
  if (strcmp(ret_ty, "string"))
	return SQ_RET_STR;
  if (strcmp(ret_ty, "array"))
	return SQ_RET_ARR;
  if (strcmp(ret_ty, "asset"))
	return SQ_RET_ASSET;
  if (strcmp(ret_ty, "table"))
	return SQ_RET_TABLE;

  return SQ_RET_DEFAULT;
}

void bind_native_closure(
	struct SQFunctionRegistrationList* prev, CSquirrelVM* sqvm, const char* return_type, const char* name,
	const char* args_signature, const char* help_text, SQNativeClosureImplementation implementation
) {
  struct SQFunctionRegistrationList* fn_entry = malloc(sizeof(struct SQFunctionRegistrationList));
  fn_entry->next = prev;

  SQFunctionRegistration* fn = &fn_entry->reg;
  fn->sq_name = name;
  fn->native_name = name;
  fn->help_text = help_text;
  fn->raw_ret_ty = return_type;
  fn->args_signature = args_signature;
  fn->unknown1 = 0;
  fn->dev_level = 0;
  fn->short_name = name;
  fn->unknown2 = 0;
  fn->return_type = get_ret_ty(return_type);
  fn->external_buffer = 0;
  fn->external_buffer_size = 0;
  fn->unknown3 = 0;
  fn->unknown4 = 0;
  fn->implementation = implementation;

  sqapi(sqvm->context)
	  ->c_sq_register_function(sqvm, fn, 0); // TODO northstar always sets 1, seems to be only for class members.
											 // Both work in the root table though for some reason.
}

void sv_bind_native_closure(
	CSquirrelVM* sqvm, const char* return_type, const char* name, const char* args_signature, const char* help_text,
	SQNativeClosureImplementation implementation
) {
  bind_native_closure(_sv_regs, sqvm, return_type, name, args_signature, help_text, implementation);
}

void ui_bind_native_closure(
	CSquirrelVM* sqvm, const char* return_type, const char* name, const char* args_signature, const char* help_text,
	SQNativeClosureImplementation implementation
) {
  bind_native_closure(_ui_regs, sqvm, return_type, name, args_signature, help_text, implementation);
}

void cl_bind_native_closure(
	CSquirrelVM* sqvm, const char* return_type, const char* name, const char* args_signature, const char* help_text,
	SQNativeClosureImplementation implementation
) {
  bind_native_closure(_cl_regs, sqvm, return_type, name, args_signature, help_text, implementation);
}

void _deregister_native_closures(struct SQFunctionRegistrationList* list) {
  struct SQFunctionRegistrationList* c = list;
  while (c) {
	struct SQFunctionRegistrationList* l = c;
	c = c->next;
	free(l);
  }
  list = 0;
}

void cl_deregister_native_closures() { _deregister_native_closures(_cl_regs); }
void ui_deregister_native_closures() { _deregister_native_closures(_ui_regs); }
void sv_deregister_native_closures() { _deregister_native_closures(_sv_regs); }

void register_native_closures(CSquirrelVM* sqvm) {
  switch (sqvm->context) {
  case SC_SERVER:
	sv_register_native_closures(sqvm);
	break;
  case SC_CLIENT:
	cl_register_native_closures(sqvm);
	break;
  case SC_UI:
	ui_register_native_closures(sqvm);
	break;
  }
}

void deregister_native_closures(ScriptContext context) {
  switch (context) {
  case SC_SERVER:
	sv_deregister_native_closures();
	break;
  case SC_CLIENT:
	cl_deregister_native_closures();
	break;
  case SC_UI:
	ui_deregister_native_closures();
	break;
  }
}
