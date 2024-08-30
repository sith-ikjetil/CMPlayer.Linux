#ifdef CMP_TARGET_UBUNTU_V22_04
    #ifdef CMP_PLATFORM_AMD64
        #include </usr/include/x86_64-linux-gnu/libavformat/avformat.h>
        #include </usr/include/x86_64-linux-gnu/libavcodec/avcodec.h>
        #include </usr/include/x86_64-linux-gnu/libswresample/swresample.h>
        #include </usr/include/x86_64-linux-gnu/libavutil/opt.h>
        #include </usr/include/x86_64-linux-gnu/libavutil/dict.h>
    #elif #ifdef CMP_PLATFORM_ARM64
        #include </usr/include/aarch64-linux-gnu/libavformat/avformat.h>
        #include </usr/include/aarch64-linux-gnu/libavcodec/avcodec.h>
        #include </usr/include/aarch64-linux-gnu/libswresample/swresample.h>
        #include </usr/include/aarch64-linux-gnu/libavutil/opt.h>
        #include </usr/include/aarch64-linux-gnu/libavutil/dict.h>
    #endif
#elif CMP_TARGET_UBUNTU_V24_04
    #ifdef CMP_PLATFORM_AMD64
        #include </usr/include/x86_64-linux-gnu/libavformat/avformat.h>
        #include </usr/include/x86_64-linux-gnu/libavcodec/avcodec.h>
        #include </usr/include/x86_64-linux-gnu/libswresample/swresample.h>
        #include </usr/include/x86_64-linux-gnu/libavutil/opt.h>
        #include </usr/include/x86_64-linux-gnu/libavutil/dict.h>
    #elif #ifdef CMP_PLATFORM_ARM64
        #include </usr/include/aarch64-linux-gnu/libavformat/avformat.h>
        #include </usr/include/aarch64-linux-gnu/libavcodec/avcodec.h>
        #include </usr/include/aarch64-linux-gnu/libswresample/swresample.h>
        #include </usr/include/aarch64-linux-gnu/libavutil/opt.h>
        #include </usr/include/aarch64-linux-gnu/libavutil/dict.h>
    #endif
#elif CMP_TARGET_FEDORA_V40
#include </usr/include/ffmpeg/libavformat/avformat.h>
#include </usr/include/ffmpeg/libavcodec/avcodec.h>
#include </usr/include/ffmpeg/libswresample/swresample.h>
#include </usr/include/ffmpeg/libavutil/opt.h>
#include </usr/include/ffmpeg/libavutil/dict.h>
#elif CMP_TARGET_MANJARO_V24
#include </usr/include/libavformat/avformat.h>
#include </usr/include/libavcodec/avcodec.h>
#include </usr/include/libswresample/swresample.h>
#include </usr/include/libavutil/opt.h>
#include </usr/include/libavutil/dict.h>
#endif
