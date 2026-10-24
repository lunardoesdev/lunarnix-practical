#include <stdio.h>
#include <zlib.h>

int main(void)
{
    printf("hello from emscripten, zlib=%s\n", zlibVersion());
    return 0;
}
