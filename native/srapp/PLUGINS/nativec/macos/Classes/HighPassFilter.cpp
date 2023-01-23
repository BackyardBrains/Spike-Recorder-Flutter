//
// Created by Stanislav Mircic  <stanislav at backyardbrains.com>
//
#ifndef SPIKE_RECORDER_ANDROID_HIGHPASSFILTER
#define SPIKE_RECORDER_ANDROID_HIGHPASSFILTER

#include "FilterBase.cpp"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include<stdint.h>

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif


class HighPassFilter : public FilterBase {
public:
    // LowPassFilter(){};
    HighPassFilter() = default;
    void calculateCoefficients() {
        if ((cornerFrequency != 0.0f) && (Q != 0.0f)) {
            intermediateVariables(cornerFrequency, Q);


            a0 = 1 + alpha;
            b0 = ((1 + omegaC) / 2) / a0;
            b1 = (-1 * (1 + omegaC)) / a0;
            b2 = ((1 + omegaC) / 2) / a0;
            a1 = (-2 * omegaC) / a0;
            a2 = (1 - alpha) / a0;

            setCoefficients();
        }
    }

    void setCornerFrequency(float newCornerFrequency) {
        cornerFrequency = newCornerFrequency;
        calculateCoefficients();
    }

    void setQ(float newQ) {
        Q = newQ;
        calculateCoefficients();
    }
protected:
    float cornerFrequency;
    float Q;
private:
};

HighPassFilter* highPassFilters;
EXTERNC double createHighPassFilter(short channelCount, double sampleRate, double highCutOff, double q){
    highPassFilters = new HighPassFilter[channelCount];
    for( uint32_t i = 0; i < channelCount; i++ )
    {
        HighPassFilter highPassFilter = highPassFilters[i];
        highPassFilter.initWithSamplingRate(sampleRate);
        if (highCutOff > sampleRate / 2.0f) highCutOff = sampleRate / 2.0f;
        highPassFilter.setCornerFrequency(highCutOff);
        highPassFilter.setQ(q);
    }
    return 1;
}

EXTERNC double initHighPassFilter(short channelCount, double sampleRate, double highCutOff, double q){
    for( uint32_t i = 0; i < channelCount; i++ )
    {
        HighPassFilter highPassFilter = highPassFilters[i];
        highPassFilter.initWithSamplingRate(sampleRate);
        if (highCutOff > sampleRate / 2.0f) highCutOff = sampleRate / 2.0f;
        highPassFilter.setCornerFrequency(highCutOff);
        highPassFilter.setQ(q);
    }
    return 1;
}

EXTERNC double applyHighPassFilter(short channelIdx, short *data, uint32_t sampleCount){
    highPassFilters[channelIdx].filter(data, sampleCount, false);
    return 1;
}

// EXTERNC double createFilters(){
//     return 30;
// }
#endif