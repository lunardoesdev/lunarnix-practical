#include <stdio.h>
#include <zlib.h>

int main(void)
{
    const char text[] = "lunarnix cross stdenv";
    printf("zlib=%s crc32=%lu\n", zlibVersion(),
           (unsigned long)crc32(0L, (const Bytef *)text, sizeof(text) - 1));
    return 0;
}
