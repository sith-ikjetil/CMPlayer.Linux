#include </usr/include/x86_64-linux-gnu/libavformat/avformat.h>
#include </usr/include/x86_64-linux-gnu/libavcodec/avcodec.h>
#include </usr/include/x86_64-linux-gnu/libswresample/swresample.h>
#include </usr/include/x86_64-linux-gnu/libavutil/opt.h>
#include </usr/include/x86_64-linux-gnu/libavutil/dict.h>

#if LIBAVCODEC_VERSION_MAJOR >= 59
#define FFMPEG_VERSION_MAJOR 6
#elif LIBAVCODEC_VERSION_MAJOR >= 58
#define FFMPEG_VERSION_MAJOR 4
#else
#define FFMPEG_VERSION_MAJOR 3 // or older versions
#endif

int getFFmpegMajorVersion();