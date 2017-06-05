#include <dlfcn.h>
#include <stdio.h>

int main(int argc, char **argv) {
	void *lib = dlopen("./libmmy.dylib", RTLD_LAZY);

  if (!lib) {
		perror("dlopen");
		return 1;
	}

	char *(*f)(void) = dlsym(lib, "foo");
	char *uuy = f();
	printf("%s\n", sss);
	dlclose(lib);
	return 0;
}
