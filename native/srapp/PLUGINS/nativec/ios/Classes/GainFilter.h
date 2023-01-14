#ifndef GainFilter_h
#define GainFilter_h

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

EXTERNC double GainFilter(double sample, double multiplier);
