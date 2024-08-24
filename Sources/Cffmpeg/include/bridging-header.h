#ifdef CMP_TARGET_UBUNTU_V22_04
#include </usr/include/x86_64-linux-gnu/libavformat/avformat.h>
#include </usr/include/x86_64-linux-gnu/libavcodec/avcodec.h>
#include </usr/include/x86_64-linux-gnu/libswresample/swresample.h>
#include </usr/include/x86_64-linux-gnu/libavutil/opt.h>
#include </usr/include/x86_64-linux-gnu/libavutil/dict.h>
#elif CMP_TARGET_UBUNTU_V24_04
#include </usr/include/x86_64-linux-gnu/libavformat/avformat.h>
#include </usr/include/x86_64-linux-gnu/libavcodec/avcodec.h>
#include </usr/include/x86_64-linux-gnu/libswresample/swresample.h>
#include </usr/include/x86_64-linux-gnu/libavutil/opt.h>
#include </usr/include/x86_64-linux-gnu/libavutil/dict.h>
#elif CMP_TARGET_FEDORA_V40
#include </usr/include/ffmpeg/libavformat/avformat.h>
#include </usr/include/ffmpeg/libavcodec/avcodec.h>
#include </usr/include/ffmpeg/libswresample/swresample.h>
#include </usr/include/ffmpeg/libavutil/opt.h>
#include </usr/include/ffmpeg/libavutil/dict.h>
#endif

#if LIBAVCODEC_VERSION_MAJOR >= 59
#define FFMPEG_VERSION_MAJOR 6
#elif LIBAVCODEC_VERSION_MAJOR >= 58
#define FFMPEG_VERSION_MAJOR 4
#else
#define FFMPEG_VERSION_MAJOR 3 // or older versions
#endif

int getFFmpegMajorVersion();