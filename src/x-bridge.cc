// x-bridge.cc
#ifdef WIN32
#include <windows.h>
#else // unix
#include <dlfcn.h>
#include <unistd.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <node.h>

namespace demo {

using v8::FunctionCallbackInfo;
using v8::Isolate;
using v8::Local;
using v8::Object;
using v8::String;
using v8::Number;
using v8::Value;
using v8::Boolean;
using v8::Array;

typedef char *(*parse_proc)(char *s, size_t row, size_t column, char *name, char *prefix, char *tagName, char *attrName, char *scopeName, int *needClose, void *v8, void (*fn_classesCallback)(void *v8, char *name, char *active_document));

#ifdef WIN32
HMODULE g_lib = NULL;
#else
void *g_lib = NULL;
#endif

parse_proc g_fn_parse__Autocomplete = NULL;


// parse function
// parse(text, row, column)
static char name[256];
static char prefix[256];
static char tagName[256];
static char attrName[256];
static char scopeName[256];
static Local<Array> s_classes;

void callback(void *v8, char *name, char *active_document) {
  Isolate *isolate = reinterpret_cast<Isolate *>(v8);
  Local<Object> obj = Object::New(isolate);
  obj->Set(String::NewFromUtf8(isolate, "name"), String::NewFromUtf8(isolate, name ? name : ""));
  if (active_document) {
    obj->Set(String::NewFromUtf8(isolate, "active_document"), String::NewFromUtf8(isolate, active_document));
  }
  s_classes->Set(s_classes->Length(), obj);
}

void parse(const FunctionCallbackInfo<Value>& args) {
  Isolate *isolate = args.GetIsolate();

  if (3 != args.Length()) {
    return;
  }

  if (args[0]->IsString() && args[1]->IsNumber() && args[2]->IsNumber()) {
    Local<v8::String> localStr = args[0]->ToString();
    String::Utf8Value utf8Value(localStr);

    size_t row = (size_t)args[1]->NumberValue(); // NOTE js 中 Number 对象值 就只有一个 double, 因此需要转换...
    size_t column = (size_t)args[2]->NumberValue();

    if (g_fn_parse__Autocomplete) {
      // utf-8 -> 王道也!
      int need_close = 0;
      name[0] = 0;
      prefix[0] = 0;
      tagName[0] = 0;
      attrName[0] = 0;
      scopeName[0] = 0;
      s_classes = Array::New(isolate);
      char *ret = g_fn_parse__Autocomplete(&(*utf8Value)[0], row, column, name, prefix, tagName, attrName, scopeName, &need_close, isolate, callback);
      if (!ret) {
        return;
      }
      Local<Object> objReturn = Object::New(isolate);
      objReturn->Set(String::NewFromUtf8(isolate, "autocomplete"), String::NewFromUtf8(isolate, ret));
      objReturn->Set(String::NewFromUtf8(isolate, "row"),          args[1]); // Number::New(isolate, row));
      objReturn->Set(String::NewFromUtf8(isolate, "column"),       args[2]); // Number::New(isolate, column));
      objReturn->Set(String::NewFromUtf8(isolate, "symbol_type"),  String::NewFromUtf8(isolate, name));
      objReturn->Set(String::NewFromUtf8(isolate, "prefix"),  String::NewFromUtf8(isolate, prefix));
      objReturn->Set(String::NewFromUtf8(isolate, "tag_name"),  String::NewFromUtf8(isolate, tagName));
      objReturn->Set(String::NewFromUtf8(isolate, "attr_name"),  String::NewFromUtf8(isolate, attrName));
      objReturn->Set(String::NewFromUtf8(isolate, "scope_name"),  String::NewFromUtf8(isolate, scopeName));
      objReturn->Set(String::NewFromUtf8(isolate, "need_close"),  Boolean::New(isolate, need_close));
      objReturn->Set(String::NewFromUtf8(isolate, "css_classes"),  s_classes);
      objReturn->Set(String::NewFromUtf8(isolate, "debug"),  Number::New(isolate, s_classes->Length()));
      args.GetReturnValue().Set(objReturn);
    }
  }
}

// load function
// load(libname, functionname)
void load(const FunctionCallbackInfo<Value>& args) {
  Isolate* isolate = args.GetIsolate();

  if (2 > args.Length()) {
    return;
  }

  if (args[0]->IsString() && args[1]->IsString()) {
    Local<v8::String> localArgs0 = args[0]->ToString();
    Local<v8::String> localArgs1 = args[1]->ToString();
    String::Utf8Value utf8Value(localArgs0);
    String::Utf8Value utf8ValueFunc(localArgs1);
    char *libname = &(*utf8Value)[0];
    char *functionName = &(*utf8ValueFunc)[0];
    if (!g_lib) {
#ifdef WIN32
      g_lib = LoadLibraryA(libname);
#else
      g_lib = dlopen(libname, RTLD_LAZY);
#endif
      if (!g_lib) {
        args.GetReturnValue().Set(Boolean::New(isolate, false));
        return;
      }

#ifdef WIN32
      g_fn_parse__Autocomplete = (parse_proc)GetProcAddressA(g_lib, functionName);
#else
      g_fn_parse__Autocomplete = (parse_proc)dlsym(g_lib, functionName);
#endif
      if (!g_fn_parse__Autocomplete) {
#ifdef WIN32
        FreeLibrary(g_lib);
#else
        dlclose(g_lib);
#endif
        g_lib = NULL;
        args.GetReturnValue().Set(Boolean::New(isolate, false));
        return;
      }
    }
  }

  args.GetReturnValue().Set(Boolean::New(isolate, true));
}


void clear(const FunctionCallbackInfo<Value>& args) {
  if (g_lib) {
#ifdef WIN32
    FreeLibrary(g_lib);
#else
    dlclose(g_lib);
#endif
    g_lib = NULL;
  }
}


void init(Local<Object> exports) {
  NODE_SET_METHOD(exports, "parse", parse);
  NODE_SET_METHOD(exports, "load", load);
  NODE_SET_METHOD(exports, "clear", clear);
}

NODE_MODULE(xbridge, init)

}  // namespace demo
