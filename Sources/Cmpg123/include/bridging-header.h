#ifdef CMP_TARGET_UBUNTU_V22_04
    #include </usr/include/mpg123.h>
    #include </usr/include/fmt123.h>
#elif CMP_TARGET_UBUNTU_V24_04
    #ifdef CMP_PLATFORM_AMD64
        #include </usr/include/x86_64-linux-gnu/mpg123.h>
        #include </usr/include/x86_64-linux-gnu/fmt123.h>
    #elif CMP_PLATFORM_ARM64
        #include </usr/include/aarch64-linux-gnu/mpg123.h>
        #include </usr/include/aarch64-linux-gnu/fmt123.h>
    #endif
#elif CMP_TARGET_FEDORA_V40
    #include </usr/include/mpg123.h>
    #include </usr/include/fmt123.h>
#elif CMP_TARGET_MANJARO_V24
    #include </usr/include/mpg123.h>
    #include </usr/include/fmt123.h>
#endif