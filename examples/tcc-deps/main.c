#include <png.h>
#include <stdio.h>
#include <string.h>
#include <zlib.h>

int main(void)
{
    const char *message = "lunarnix tcc dependency probe";
    uLong crc = crc32(0L, Z_NULL, 0);

    crc = crc32(crc, (const Bytef *)message, (uInt)strlen(message));

    printf("zlib=%s crc32=%08lx libpng=%lu\n",
           zlibVersion(),
           (unsigned long)crc,
           (unsigned long)png_access_version_number());

    return 0;
}
