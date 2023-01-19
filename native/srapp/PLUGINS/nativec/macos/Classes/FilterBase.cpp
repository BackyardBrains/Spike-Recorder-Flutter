//
// Created by Stanislav Mircic  <stanislav at backyardbrains.com>
//

// #include <FilterBase.h>
#ifndef SPIKE_RECORDER_ANDROID_FILTERBASE
#define SPIKE_RECORDER_ANDROID_FILTERBASE

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


class FilterBase {
public:
  int val;

    // FilterBase(){
    // }
    FilterBase() = default;

    float getSamplingRate(){
        return samplingRate;
    }

    void initWithSamplingRate(float sr) {
        samplingRate = sr;

        for (float &coefficient : coefficients) {
            coefficient = 0.0f;
        }

        gInputKeepBuffer[0] = 0.0f;
        gInputKeepBuffer[1] = 0.0f;
        gOutputKeepBuffer[0] = 0.0f;
        gOutputKeepBuffer[1] = 0.0f;

        one = 1.0f;
    }

    void setCoefficients() {
        coefficients[0] = b0;
        coefficients[1] = b1;
        coefficients[2] = b2;
        coefficients[3] = a1;
        coefficients[4] = a2;
    }
    void filter(int16_t *data, int32_t numFrames, bool flush) {
        auto *tempFloatBuffer = (float *) std::malloc(numFrames * sizeof(float));
        for (int32_t i = numFrames - 1; i >= 0; i--) {
            tempFloatBuffer[i] = (float) data[i];
        }
        filterContiguousData(tempFloatBuffer, numFrames);
        if (flush) {
            for (int32_t i = numFrames - 1; i >= 0; i--) {
                data[i] = 0;
            }
        } else {
            for (int32_t i = numFrames - 1; i >= 0; i--) {
                data[i] = (int16_t) tempFloatBuffer[i];
            }
        }
        free(tempFloatBuffer);
    }

    void filterContiguousData(float *data, int32_t numFrames) {
        // Provide buffer for processing
        auto *tInputBuffer = (float *) std::malloc((numFrames + 2) * sizeof(float));
        auto *tOutputBuffer = (float *) std::malloc((numFrames + 2) * sizeof(float));

        // Copy the data
        memcpy(tInputBuffer, gInputKeepBuffer, 2 * sizeof(float));
        memcpy(tOutputBuffer, gOutputKeepBuffer, 2 * sizeof(float));
        memcpy(&(tInputBuffer[2]), data, numFrames * sizeof(float));

        // Do the processing
        // vDSP_deq22(tInputBuffer, 1, coefficients, tOutputBuffer, 1, numFrames);
        //https://developer.apple.com/library/ios/documentation/Accelerate/Reference/vDSPRef/index.html#//apple_ref/c/func/vDSP_deq22
        int n;
        for (n = 2; n < numFrames + 2; n++) {
            tOutputBuffer[n] = tInputBuffer[n] * coefficients[0] + tInputBuffer[n - 1] * coefficients[1] +
                                tInputBuffer[n - 2] * coefficients[2] - tOutputBuffer[n - 1] * coefficients[3] -
                                tOutputBuffer[n - 2] * coefficients[4];
        }

        // Copy the data
        memcpy(data, tOutputBuffer, numFrames * sizeof(float));
        memcpy(gInputKeepBuffer, &(tInputBuffer[numFrames]), 2 * sizeof(float));
        memcpy(gOutputKeepBuffer, &(tOutputBuffer[numFrames]), 2 * sizeof(float));

        free(tInputBuffer);
        free(tOutputBuffer);
    }

protected:

    void intermediateVariables(float Fc, float Q) {
        omega = static_cast<float>(2 * M_PI * Fc / samplingRate);
        omegaS = sin(omega);
        omegaC = cos(omega);
        alpha = omegaS / (2 * Q);
    }

    float one;
    float samplingRate;
    float gInputKeepBuffer[2];
    float gOutputKeepBuffer[2];
    float omega, omegaS, omegaC, alpha;
    float coefficients[5];
    float a0, a1, a2, b0, b1, b2;
private:  
};






// EXTERNC double createFilters(){
//     return 30;
// }
#endif