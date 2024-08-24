#ifdef CMP_TARGET_UBUNTU
#include </usr/include/mpg123.h>
#include </usr/include/fmt123.h>
#elif CMP_TARGET_UBUNTU_V24_04
#include </usr/include/x86_64-linux-gnu/mpg123.h>
#include </usr/include/x86_64-linux-gnu/fmt123.h>
#elif CMP_TARGET_FEDORA
#include </usr/include/mpg123.h>
#include </usr/include/fmt123.h>
#endif