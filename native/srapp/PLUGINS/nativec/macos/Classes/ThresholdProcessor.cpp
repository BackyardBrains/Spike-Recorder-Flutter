#ifndef SPIKE_RECORDER_ANDROID_THRESHOLDPROCESSOR_H
#define SPIKE_RECORDER_ANDROID_THRESHOLDPROCESSOR_H

#include <algorithm>
#include <climits>
#include "Processor.cpp"
#include "HeartbeatHelper.cpp"


// #include "include/dart_api.h"
// #include "include/dart_native_api.h"
#include "include/dart_api_dl.h"
#include <mutex>    
#include <condition_variable>

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

#if defined(__GNUC__)
    #define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
#elif defined(_MSC_VER)
    #define FUNCTION_ATTRIBUTE __declspec(dllexport)
#endif


class HeartbeatListener : public OnHeartbeatListener {
public:
    HeartbeatListener() = default;

    ~HeartbeatListener() = default;

    void onHeartbeat(int bmp) override {
        // backyardbrains::utils::JniHelper::invokeStaticVoid(vm, "onHeartbeat", "(I)V", bmp);
    }
};


class ThresholdProcessor : public Processor {
public:
    // const char *TAG = "ThresholdProcessor";
    static constexpr int DEFAULT_SAMPLE_COUNT = static_cast<const int>(2.4f * 44100.0f);
    ThresholdProcessor(){}
    // ThresholdProcessor(OnHeartbeatListener *listener){
    //     heartbeatHelper = new HeartbeatHelper(getSampleRate(), listener);

    //     // we need to initialize initial trigger values and local buffer because they depend on channel count
    //     triggerValue = new float[getChannelCount()];
    //     for (int i = 0; i < getChannelCount(); i++) {
    //         triggerValue[i] = INT_MAX;
    //     }
    //     lastTriggeredValue = new float[getChannelCount()]{0};

    //     init(true);
    // }

    ~ThresholdProcessor() = default;

    // Returns the number of sample sequences that should be summed to get the average spike value.
    int getAveragedSampleCount() {
        return averagedSampleCount;
    }

    // Sets the number of sample sequences that should be summed to get the average spike value.
    void setAveragedSampleCount(int _averagedSampleCount) {
        // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "setAveragedSampleCount(%d)", averagedSampleCount);

        if (_averagedSampleCount <= 0 || averagedSampleCount == _averagedSampleCount) return;
        averagedSampleCount = _averagedSampleCount;
    }

    // Sets the sample frequency threshold.
    void setThreshold(float threshold) {
        triggerValue[getSelectedChannel()] = threshold;
    }
    // Resets all the fields used for calculations when next batch comes
    void resetThreshold() {
        resetOnNextBatch = true;
    }

    void setPaused(bool _paused) {
        if (paused == _paused) return;

        paused = _paused;
    }

    // Returns current averaging trigger type
    int getTriggerType() {
        return triggerType;
    }

    // Sets current averaging trigger type
    void setTriggerType(int _triggerType) {
        if (triggerType == _triggerType) return;
        triggerType = _triggerType;
    }

    // Starts/stops processing heartbeat
    void setBpmProcessing(bool _processBpm) {
        if (processBpm == _processBpm) return;

        // reset BPM if we stopped processing heartbeat
        if (!_processBpm) resetBpm();

        processBpm = _processBpm;
    }

    void process(short **outSamples, int *outSamplesCounts, short **inSamples,
                                    const int *inSampleCounts,
                                    const int *inEventIndices, const int *inEvents, const int inEventCount) {
        if (paused) return;

        bool shouldReset = false;
        bool shouldResetLocalBuffer = false;
        int selectedChannel = getSelectedChannel();
        // reset buffers if selected channel has changed
        if (lastSelectedChannel != selectedChannel) {
            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because channel has changed");
            lastSelectedChannel = selectedChannel;
            shouldReset = true;
        }
        // reset buffers if threshold changed
        if (lastTriggeredValue[selectedChannel] != triggerValue[selectedChannel]) {
            //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because trigger value has changed");
            lastTriggeredValue[selectedChannel] = triggerValue[selectedChannel];
            shouldReset = true;
        }
        // reset buffers if averages sample count changed
        if (lastAveragedSampleCount != averagedSampleCount) {
            //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because last averaged sample count has changed");
            lastAveragedSampleCount = averagedSampleCount;
            shouldReset = true;
        }
        // reset buffers if sample rate changed
        if (lastSampleRate != getSampleRate()) {
            //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because sample rate has changed");
            lastSampleRate = getSampleRate();
            shouldReset = true;
            shouldResetLocalBuffer = true;
        }
        // let's save last channel count so we can use it to delete all the arrays
        int channelCount = getChannelCount();
        int tmpLastChannelCount = lastChannelCount;
        if (lastChannelCount != channelCount) {
            //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because channel count has changed");
            lastChannelCount = channelCount;
            shouldReset = true;
            shouldResetLocalBuffer = true;
        }
        if (shouldReset || resetOnNextBatch) {
            // reset rest of the data
            clean(tmpLastChannelCount, shouldResetLocalBuffer);
            init(shouldResetLocalBuffer);
            resetOnNextBatch = false;
        }

        int tmpInSampleCount;
        short *tmpInSamples;
        int copyFromIncoming, copyFromBuffer;
        int i;
        short **tmpSamples;
        int *tmpSamplesCounts;
        short *tmpSamplesRow;
        int *tmpSummedSampleCounts;
        int *tmpSummedSamples;
        short *tmpAveragedSamples;
        int samplesToCopy;
        int j, k;
        int kStart, kEnd;

        for (i = 0; i < channelCount; i++) {
            tmpInSampleCount = inSampleCounts[i];
            tmpInSamples = inSamples[i];
            tmpSamples = samplesForCalculation[i];
            tmpSamplesCounts = samplesForCalculationCounts[i];
            tmpSummedSampleCounts = summedSamplesCounts[i];
            tmpSummedSamples = summedSamples[i];

            // append unfinished sample buffers with incoming samples
            for (j = 0; j < samplesForCalculationCount[i]; j++) {
                tmpSamplesRow = tmpSamples[j];
                kStart = tmpSamplesCounts[j];

                // we just need to append enough to fill the unfinished rows till end (sampleCount)
                samplesToCopy = std::min(sampleCount - kStart, tmpInSampleCount);
                std::copy(tmpInSamples, tmpInSamples + samplesToCopy, tmpSamplesRow + kStart);

                kEnd = kStart + samplesToCopy;
                for (k = kStart; k < kEnd; k++) {
                    // add new value and increase summed samples count for current position
                    tmpSummedSamples[k] += tmpSamplesRow[k];
                    tmpSummedSampleCounts[k]++;
                }
                tmpSamplesCounts[j] = kEnd;
            }
        }


        short currentSample;
        // loop through incoming samples and listen for the threshold hit
        for (i = 0; i < inSampleCounts[selectedChannel]; i++) {
            currentSample = inSamples[selectedChannel][i];

            // heartbeat processing Can't add incoming to buffer, it's larger then buffer
            if (processBpm && triggerType == TRIGGER_ON_THRESHOLD) {
                sampleCounter++;
                lastTriggerSampleCounter++;

                // check if minimum BPM reset period passed after last threshold hit and reset if necessary
                if (lastTriggerSampleCounter > minBpmResetPeriodCount) resetBpm();
            }
            // end of heartbeat processing

            if (triggerType == TRIGGER_ON_THRESHOLD) { // triggering by a threshold value
                if (!inDeadPeriod) {
                    // check if we hit the threshold
                    if ((triggerValue[selectedChannel] >= 0 && currentSample > triggerValue[selectedChannel] &&
                            prevSample <= triggerValue[selectedChannel]) ||
                        (triggerValue[selectedChannel] < 0 && currentSample < triggerValue[selectedChannel] &&
                            prevSample >= triggerValue[selectedChannel])) {
                        // we hit the threshold, turn on dead period of 5ms
                        inDeadPeriod = true;

                        // create new samples for current threshold
                        for (j = 0; j < channelCount; j++) {
                            prepareNewSamples(inSamples[j], inSampleCounts[j], j, i);
                        }

                        // heartbeat processingA
                        if (processBpm) {
                            // pass data to heartbeat helper
                            heartbeatHelper->beat(sampleCounter);
                            // reset the last triggered sample counter
                            // and start counting for next heartbeat reset period
                            lastTriggerSampleCounter = 0;
                        }
                        // end of heartbeat processing
                    }
                } else {
                    if (++deadPeriodSampleCounter > deadPeriodCount) {
                        deadPeriodSampleCounter = 0;
                        inDeadPeriod = false;
                    }
                }
            } else if (inEventCount > 0) { // triggering on events
                for (j = 0; j < inEventCount; j++) {
                    if (triggerType == TRIGGER_ON_EVENTS) {
                        if (i == inEventIndices[j]) {
                            // create new samples for current threshold
                            for (k = 0; k < channelCount; k++) {
                                prepareNewSamples(inSamples[k], inSampleCounts[k], k, i);
                            }
                        }
                    } else {
                        if (i == inEventIndices[j] && triggerType == inEvents[j]) {
                            // create new samples for current threshold
                            for (k = 0; k < channelCount; k++) {
                                prepareNewSamples(inSamples[k], inSampleCounts[k], k, i);
                            }
                        }
                    }
                }
            }

            prevSample = currentSample;
        }

        for (i = 0; i < channelCount; i++) {
            tmpInSampleCount = inSampleCounts[i];
            tmpInSamples = inSamples[i];

            // add samples to local buffer
            copyFromBuffer = std::max(bufferSampleCount - tmpInSampleCount, 0);
            copyFromIncoming = std::min(bufferSampleCount - copyFromBuffer, tmpInSampleCount);
            if (copyFromBuffer > 0)
                std::copy(buffer[i] + tmpInSampleCount, buffer[i] + bufferSampleCount, buffer[i]);
            std::copy(tmpInSamples, tmpInSamples + copyFromIncoming,
                        buffer[i] + bufferSampleCount - copyFromIncoming);
        }

        int *counts = new int[averagedSampleCount]{0};
        for (i = 0; i < channelCount; i++) {
            tmpSummedSampleCounts = summedSamplesCounts[i];
            tmpSummedSamples = summedSamples[i];
            tmpAveragedSamples = averagedSamples[i];

            // calculate the averages for all channels
            for (j = 0; j < sampleCount; j++)
                if (tmpSummedSampleCounts[j] != 0)
                    tmpAveragedSamples[j] = (short) (tmpSummedSamples[j] / tmpSummedSampleCounts[j]);
                else
                    tmpAveragedSamples[j] = 0;
            std::copy(tmpAveragedSamples, tmpAveragedSamples + sampleCount, outSamples[i]);
            outSamplesCounts[i] = sampleCount;
        }
        delete[] counts;
    }
    void appendIncomingSamples(short **inSamples, int *inSampleCounts) {
        bool shouldReset = false;
        bool shouldResetLocalBuffer = false;
        int selectedChannel = getSelectedChannel();
        // reset buffers if selected channel has changed
        if (lastSelectedChannel != selectedChannel) {
            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because channel has changed");
            lastSelectedChannel = selectedChannel;
            shouldReset = true;
        }
        // reset buffers if threshold changed
        if (lastTriggeredValue[selectedChannel] != triggerValue[selectedChannel]) {
            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because trigger value has changed");
            lastTriggeredValue[selectedChannel] = triggerValue[selectedChannel];
            shouldReset = true;
        }
        // reset buffers if averages sample count changed
        if (lastAveragedSampleCount != averagedSampleCount) {
            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because last averaged sample count has changed");
            lastAveragedSampleCount = averagedSampleCount;
            shouldReset = true;
        }
        // reset buffers if sample rate changed
        if (lastSampleRate != getSampleRate()) {
            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because sample rate has changed");
            lastSampleRate = getSampleRate();
            shouldReset = true;
            shouldResetLocalBuffer = true;
        }
        // let's save last channel count so we can use it to delete all the arrays
        int channelCount = getChannelCount();
        int tmpLastChannelCount = lastChannelCount;
        if (lastChannelCount != channelCount) {
            // //__android_log_print(ANDROID_LOG_DEBUG, TAG, "Resetting because channel count has changed");
            lastChannelCount = channelCount;
            shouldReset = true;
            shouldResetLocalBuffer = true;
        }
        if (shouldReset || resetOnNextBatch) {
            // reset rest of the data
            clean(tmpLastChannelCount, shouldResetLocalBuffer);
            init(shouldResetLocalBuffer);
            resetOnNextBatch = false;
        }

        int tmpInSampleCount;
        short *tmpInSamples;
        int copyFromIncoming, copyFromBuffer;
        int i;

        // in case we don't need to average let's just add incoming samples to local buffer
        for (i = 0; i < channelCount; i++) {
            tmpInSampleCount = inSampleCounts[i];
            tmpInSamples = inSamples[i];

            // add samples to local buffer
            copyFromBuffer = std::max(bufferSampleCount - tmpInSampleCount, 0);
            copyFromIncoming = std::min(bufferSampleCount - copyFromBuffer, tmpInSampleCount);
            if (copyFromBuffer > 0)
                std::copy(buffer[i] + tmpInSampleCount, buffer[i] + bufferSampleCount, buffer[i]);
            std::copy(tmpInSamples, tmpInSamples + copyFromIncoming,
                        buffer[i] + bufferSampleCount - copyFromIncoming);
        }
    }

private:
    static const char *TAG;

    // We shouldn't process more than 2.4 seconds of samples in any given moment
    static constexpr float MAX_PROCESSED_SECONDS = 2.4f;
    // When threshold is hit we should have a dead period of 5ms before checking for next threshold hit
    static constexpr float DEAD_PERIOD_SECONDS = 0.005f;
    // Default number of samples that needs to be summed to get the averaged sample
    static constexpr int DEFAULT_AVERAGED_SAMPLE_COUNT = 1;
    // Minimum number of seconds without a heartbeat before resetting the heartbeat helper
    static constexpr double DEFAULT_MIN_BPM_RESET_PERIOD_SECONDS = 3;

    // Constants that define we are currently averaging when threshold is hit
    static constexpr int TRIGGER_ON_THRESHOLD = -1;
    // Constants that define we are currently averaging on all events
    static constexpr int TRIGGER_ON_EVENTS = 0;

    // Prepares new sample collection for averaging
    void prepareNewSamples(const short *inSamples, int length, int channelIndex, int sampleIndex);

    // Creates and initializes all the fields used for calculations
    void init(bool resetLocalBuffer);

    // Deletes all array fields used for calculations
    void clean(int channelCount, bool resetLocalBuffer);

    // Resets all local variables used for the heartbeat processing
    void resetBpm();

    // Number of samples that we collect for one sample stream
    int sampleCount = 0;
    // Used to check whether channel has changed since the last incoming sample batch
    int lastSelectedChannel = 0;
    // Threshold value that triggers the averaging
    float *triggerValue;
    // Used to check whether threshold trigger value has changed since the last incoming sample batch
    float *lastTriggeredValue;
    // Number of samples that needs to be summed to get the averaged sample
    int averagedSampleCount = DEFAULT_AVERAGED_SAMPLE_COUNT;
    // Used to check whether number of averages samples has changed since the last incoming sample batch
    int lastAveragedSampleCount = 0;
    // Used to check whether sample rate has changed since the last incoming sample batch
    float lastSampleRate = 0;
    // Used to check whether chanel count has changed since the last incoming sample batch
    int lastChannelCount = 0;
    // Whether buffers need to be reset before processing next batch
    bool resetOnNextBatch = false;

    // We need to buffer half of samples total count up to the sample that hit's threshold
    int bufferSampleCount = sampleCount / 2;
    // Buffer that holds most recent 1.2 ms of audio so we can prepend new sample buffers when threshold is hit
    short **buffer;
    // Holds number of sample rows that have been averaged
    int *samplesForCalculationCount;
    // Holds number of samples in each sample row
    int **samplesForCalculationCounts;
    // Holds sample rows
    short ***samplesForCalculation;
    // Holds number of samples that have been summed at specified position
    int **summedSamplesCounts;
    // Holds sums of all the samples at specified position
    int **summedSamples;
    // Holds averages of all the samples at specified position
    short **averagedSamples;

    // Dead period when we don't check for threshold after hitting one
    int deadPeriodCount = 0;
    // Counts samples between two dead periods
    int deadPeriodSampleCounter;
    // Whether we are currently in dead period (not listening for threshold hit)
    bool inDeadPeriod;

    // Holds previously processed sample so we can compare whether we have a threshold hit
    short prevSample;

    // Whether threshold is currently paused or not. If paused, processing returns values as if the threshold is always reset.
    bool paused = false;

    // Current type of trigger we're averaging on
    int triggerType = TRIGGER_ON_THRESHOLD;

    // Holds reference to HeartbeatHelper that processes threshold hits as heart beats
    HeartbeatHelper *heartbeatHelper;
    // Period without heartbeat that we wait for before resetting the heartbeat helper
    int minBpmResetPeriodCount = 0;
    // Index of the sample that triggered the threshold hit
    int lastTriggerSampleCounter;
    // Counts samples between two resets that need to be passed to heartbeat helper
    int sampleCounter;
    // Whether BPM should be processed or not
    bool processBpm;
};




// C++ TO FLUTTER
static Dart_Port_DL dart_port = 0;

// Ensure that the function is not-mangled; exported as a pure C function
EXTERNC FUNCTION_ATTRIBUTE void set_dart_port(Dart_Port_DL port)
{
    dart_port = port;
}

// Sample usage of Dart_PostCObject_DL to post message to Flutter side
char* debug_print(const char *message)
{
    if (!dart_port)
        return (char*) "wrong port"; 
    // as_array.values = new _Dart_CObject[2];
    Dart_CObject c_request_arr[2];
    c_request_arr[0] = Dart_CObject();
    c_request_arr[0].type = Dart_CObject_kInt32;
    c_request_arr[0].value.as_int32 = 12;

    c_request_arr[1] = Dart_CObject();
    c_request_arr[1].type = Dart_CObject_kInt32;
    c_request_arr[1].value.as_int32 = 1;

    Dart_CObject* requestArr[]={&c_request_arr[0],&c_request_arr[1],&c_request_arr[2],&c_request_arr[3]};

    Dart_CObject msg ;
    msg.type = Dart_CObject_kArray;
    msg.value.as_array.values = requestArr;
    msg.value.as_array.length = sizeof(c_request_arr) / sizeof(c_request_arr[0]);

    // msg.type = Dart_CObject_kString;
    // msg.value.as_string = (char *) "tessstt print debug";
    // printf(msg.value.as_string);
    // The function is thread-safe; you can call it anywhere on your C++ code
    try{
        Dart_PostCObject_DL(dart_port, &msg);
        return (char *) "success";
    }catch(...){
        return (char *) "failed";
    }   
    
}





// HighPassFilter* highPassFilters;
ThresholdProcessor thresholdProcessor[6];
EXTERNC FUNCTION_ATTRIBUTE double createThresholdProcess(short channelCount, double sampleRate, double highCutOff, double q){
    // highPassFilters = new HighPassFilter[channelCount];
    for( int32_t i = 0; i < channelCount; i++ )
    {
        // thresholdProcessor[i] = new ThresholdProcessor(new HeartbeatListener());
        // HighPassFilter highPassFilter = HighPassFilter();
        // highPassFilters[i].initWithSamplingRate(sampleRate);
        // if (highCutOff > sampleRate / 2.0f) highCutOff = sampleRate / 2.0f;
        // highPassFilters[i].setCornerFrequency(highCutOff);
        // highPassFilters[i].setQ(q);
        // highPassFilters[i] = highPassFilter;
    }
    return 1;
}

EXTERNC FUNCTION_ATTRIBUTE double initThresholdProcess(short channelCount, double sampleRate, double highCutOff, double q){
    for( int32_t i = 0; i < channelCount; i++ )
    {
        // HighPassFilter highPassFilter = highPassFilters[i];
        // highPassFilters[i].initWithSamplingRate(sampleRate);
        // if (highCutOff > sampleRate / 2.0f) highCutOff = sampleRate / 2.0f;
        // highPassFilters[i].setCornerFrequency(highCutOff);
        // highPassFilters[i].setQ(q);
    }
    return 1;
}

EXTERNC FUNCTION_ATTRIBUTE double applyThresholdProcess(short channelIdx, short *data, int32_t sampleCount){
    // highPassFilters[channelIdx].filter(data, sampleCount, false);
    debug_print("APPLYING THRESHOLD ");
    return 1;
}


//Namespac
// namespace dart {

////////////////////////////////////////////////////////////////////////////////
// Initialize `dart_api_dl.h`
// intptr_t (*my_callback_blocking_fp_)(intptr_t);
// Dart_Port my_callback_blocking_send_port_;

// // static void FreeFinalizer(void*, void* value) {
// //   free(value);
// // }

// EXTERNC FUNCTION_ATTRIBUTE intptr_t InitDartApiDL(void* data) {
DART_EXPORT intptr_t InitDartApiDL(void* data) {
  return Dart_InitializeApiDL(data);
// return 1;
}

// // void NotifyDart(Dart_Port send_port) {
// // //   printf("C   :  Posting message (port: %" Px64 ", work: %" Px ").\n",
// // //          send_port, work_addr);

// //   Dart_CObject dart_object;
// //   dart_object.type = Dart_CObject_kInt64;
// // //   dart_object.value.as_int64 = work_addr;

// //   const bool result = Dart_PostCObject_DL(send_port, &dart_object);
// //   if (!result) {
// //     // FATAL("C   :  Posting message to port failed.");
// //   }
// // }

// intptr_t MyCallbackBlocking(intptr_t a) {
//   std::mutex mutex;
//   std::unique_lock<std::mutex> lock(mutex);
//   intptr_t result = 2;
// //   auto callback = my_callback_blocking_fp_;  // Define storage duration.
//   std::condition_variable cv;
// //   bool notified = false;
// //   const Work work = [a, &result, callback, &cv, &notified]() {
// //     result = callback(a);
// //     printf("C Da:     Notify result ready.\n");
// //     notified = true;
// //     cv.notify_one();
// //   };
// //   const Work* work_ptr = new Work(work);  // Copy to heap.
// //   NotifyDart(my_callback_blocking_send_port_);
//   printf("C   :  Waiting for result.\n");
// //   while (!notified) {
// //     cv.wait(lock);
// //   }
//   printf("C   :  Received result.\n");
//   return result;
// }

// DART_EXPORT void RegisterMyCallbackBlocking(Dart_Port send_port,
//                                             intptr_t (*callback1)(intptr_t)) {
//   my_callback_blocking_fp_ = callback1;
//   my_callback_blocking_send_port_ = send_port;
//   my_callback_blocking_fp_(123);
//   Dart_CObject dart_object;
//   dart_object.type = Dart_CObject_kInt64;
//   dart_object.value.as_int64 = work_addr;

//   const bool result = Dart_PostCObject_DL(send_port, &dart_object);
//   if (!result) {
//     FATAL("C   :  Posting message to port failed.");
//   }  
// }

// }
//Namespac


#endif



