const bundledBoardConfig = ('''{
    "config": {
        "version":"1.0",
        "boards":[
          {
              "uniqueName": "NRNSBPRO",
              "userFriendlyFullName":"Neuron SpikerBox",
              "userFriendlyShortName":"SpikerBox",
              "hardwareComProtocolType": "iap2",
              "bybProtocolType": "BYB1",
              "bybProtocolVersion": "1.0",
              "maxSampleRate":"10000",
              "maxNumberOfChannels":"2",
              "sampleResolution":14,
              "supportedPlatforms":"ios",
              "productURL":"https://backyardbrains.com/products/spikerbox",
              "helpURL":"https://backyardbrains.com/products/spikerbox",
              "firmwareUpdateUrl":"",
              "iconURL":"",
              "defaultTimeScale":"2.0",
              "defaultAmplitudeScale":"1.0",
              "sampleRateIsFunctionOfNumberOfChannels":0,
              "miniOSAppVersion":"3.0.0",
              "minAndroidAppVersion":"1.0.0",
              "minWinAppVersion":"1.0.0",
              "minMacAppVersion":"1.0.0",
              "minLinuxAppVersion":"1.0.0",
              "p300CapabilityPresent":0,
              "filter":{
                  "signalType":"neuronSignal",
                  "lowPassON":1,
                  "lowPassCutoff":"5000.0",
                  "highPassON":1,
                  "highPassCutoff":"1.0",
                  "notchFilterState":"notch60Hz"
              },
              "channels":[
                  {
                      "userFriendlyFullName":"Neuron Channel 1",
                      "userFriendlyShortName":"Neuron Ch. 1",
                      "activeByDefault":1,
                      "filtered":1,
                      "calibrationCoef":1.0,
                      "channelIsCalibrated":1,
                      "defaultVoltageScale":3.0
                  },
                  {
                      "userFriendlyFullName":"Neuron Channel 2",
                      "userFriendlyShortName":"Neuron Ch. 2",
                      "activeByDefault":0,
                      "filtered":1,
                      "calibrationCoef":1.0,
                      "channelIsCalibrated":1,
                      "defaultVoltageScale":3.0
                  }
              ],
              "expansionBoards":[
                  {
                      "boardType":"0",
                      "userFriendlyFullName":"Default - events detection expansion board",
                      "userFriendlyShortName":"Events detection",
                      "supportedPlatforms":"android,ios,win,mac,linux",
                      "maxNumberOfChannels":"0"
                  },
                  {
                      "boardType":"1",
                      "userFriendlyFullName":"Additional analog input channels",
                      "userFriendlyShortName":"Analog x 2",
                      "maxSampleRate":"5000",
                      "supportedPlatforms":"ios",
                      "productURL":"",
                      "helpURL":"",
                      "iconURL":"",
                      "maxNumberOfChannels":"2",
                      "defaultTimeScale":"0.1",
                      "defaultAmplitudeScale":"1.0",
                      "channels":[
                          {
                              "userFriendlyFullName":"Neuron Channel 3",
                              "userFriendlyShortName":"Neuron Ch. 3",
                              "activeByDefault":0,
                              "filtered":1,
                              "calibrationCoef":1.0,
                              "channelIsCalibrated":1,
                              "defaultVoltageScale":3.0
                          },
                          {
                              "userFriendlyFullName":"Neuron Channel 4",
                              "userFriendlyShortName":"Neuron Ch. 4",
                              "activeByDefault":0,
                              "filtered":0,
                              "calibrationCoef":1.0,
                              "channelIsCalibrated":1,
                              "defaultVoltageScale":3.0
                          }
                      ]
                  },
                  {
                      "boardType":"4",
                      "userFriendlyFullName":"The Reflex Hammer",
                      "userFriendlyShortName":"Hammer",
                      "maxSampleRate":"5000",
                      "maxNumberOfChannels":"1",
                      "supportedPlatforms":"ios",
                      "productURL":"https://backyardbrains.com/products/ReflexHammer",
                      "helpURL":"https://backyardbrains.com/products/ReflexHammer",
                      "iconURL":"",
                      "defaultTimeScale":"0.1",
                      "defaultAmplitudeScale":"1.0",
                      "channels":[
                          {
                              "userFriendlyFullName":"Hammer channel",
                              "userFriendlyShortName":"Hammer ch.",
                              "activeByDefault":1,
                              "filtered":1,
                              "calibrationCoef":1.0,
                              "channelIsCalibrated":1,
                              "defaultVoltageScale":3.0
                          }
                      ]
                  },
                  {
                      "boardType":"5",
                      "userFriendlyFullName":"The Joystick control",
                      "userFriendlyShortName":"Joystick",
                      "maxSampleRate":"5000",
                      "maxNumberOfChannels":"1",
                      "supportedPlatforms":"win",
                      "productURL":"",
                      "helpURL":"",
                      "iconURL":"",
                      "defaultTimeScale":"0.1",
                      "defaultAmplitudeScale":"1.0",
                      "channels":[
                          {
                              "userFriendlyFullName":"Joystick EMG channel",
                              "userFriendlyShortName":"Joystick EMG",
                              "activeByDefault":1,
                              "filtered":0,
                              "calibrationCoef":1.0,
                              "channelIsCalibrated":1,
                              "defaultVoltageScale":3.0
                          }
                      ]
                  }
              ]
          },
            {
                "uniqueName": "SpikerBox",
                "userFriendlyFullName":"Human SpikerBox",
                "userFriendlyShortName":"SpikerBox",
                "hardwareComProtocolType": "iap2",
                "bybProtocolType": "BYB1",
                "bybProtocolVersion": "1.0",
                "maxSampleRate":"5000",
                "maxNumberOfChannels":"2",
                "sampleResolution":14,
                "supportedPlatforms":"ios",
                "productURL":"https://backyardbrains.com/products/heartAndBrainSpikerBox",
                "helpURL":"https://backyardbrains.com/products/heartAndBrainSpikerBox",
                "firmwareUpdateUrl":"",
                "iconURL":"",
                "defaultTimeScale":"2.0",
                "defaultAmplitudeScale":"1.0",
                "sampleRateIsFunctionOfNumberOfChannels":0,
                "miniOSAppVersion":"3.0.0",
                "minAndroidAppVersion":"1.0.0",
                "minWinAppVersion":"1.0.0",
                "minMacAppVersion":"1.0.0",
                "minLinuxAppVersion":"1.0.0",
                "p300CapabilityPresent":1,
                "filter":{
                    "signalType":"eegSignal,ecgSignal",
                    "lowPassON":1,
                    "lowPassCutoff":"2500.0",
                    "highPassON":1,
                    "highPassCutoff":"70.0",
                    "notchFilterState":"notch60Hz"
                },
                "channels":[
                    {
                        "userFriendlyFullName":"EEG/ECG/EMG Channel 1",
                        "userFriendlyShortName":"EEG/ECG/EMG Ch. 1",
                        "activeByDefault":1,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":3.0
                    },
                    {
                        "userFriendlyFullName":"EEG/ECG/EMG Channel 2",
                        "userFriendlyShortName":"EEG/ECG/EMG Ch. 2",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":3.0
                    }
                ],
                "expansionBoards":[
                    {
                        "boardType":"0",
                        "userFriendlyFullName":"Default - events detection expansion board",
                        "userFriendlyShortName":"Events detection",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "maxNumberOfChannels":"0"
                    },
                    {
                        "boardType":"1",
                        "userFriendlyFullName":"Additional analog input channels",
                        "userFriendlyShortName":"Analog x 2",
                        "maxSampleRate":"5000",
                        "supportedPlatforms":"ios",
                        "productURL":"",
                        "helpURL":"",
                        "iconURL":"",
                        "maxNumberOfChannels":"2",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"EEG/ECG/EMG Channel 3",
                                "userFriendlyShortName":"EEG/ECG/EMG Ch. 3",
                                "activeByDefault":0,
                                "filtered":1,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":3.0
                            },
                            {
                                "userFriendlyFullName":"EEG/ECG/EMG Channel 4",
                                "userFriendlyShortName":"EEG/ECG/EMG Ch. 4",
                                "activeByDefault":0,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":3.0
                            }
                        ]
                    },
                    {
                        "boardType":"4",
                        "userFriendlyFullName":"The Reflex Hammer",
                        "userFriendlyShortName":"Hammer",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"ios",
                        "productURL":"https://backyardbrains.com/products/ReflexHammer",
                        "helpURL":"https://backyardbrains.com/products/ReflexHammer",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Hammer channel",
                                "userFriendlyShortName":"Hammer ch.",
                                "activeByDefault":1,
                                "filtered":1,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":3.0
                            }
                        ]
                    },
                    {
                        "boardType":"5",
                        "userFriendlyFullName":"The Joystick control",
                        "userFriendlyShortName":"Joystick",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"win",
                        "productURL":"",
                        "helpURL":"",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Joystick EMG channel",
                                "userFriendlyShortName":"Joystick EMG",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":3.0
                            }
                        ]
                    }
                ]
            },
            {
                "uniqueName": "HUMANSB",
                "userFriendlyFullName":"Human SpikerBox",
                "userFriendlyShortName":"SpikerBox",
                "hardwareComProtocolType": "serial",
                "bybProtocolType": "BYB1",
                "bybProtocolVersion": "1.0",
                "maxSampleRate":"5000",
                "maxNumberOfChannels":"2",
                "sampleResolution":14,
                "supportedPlatforms":"android,win,mac,linux,ios",
                "productURL":"https://backyardbrains.com/products/heartAndBrainSpikerBox",
                "helpURL":"https://backyardbrains.com/products/heartAndBrainSpikerBox",
                "firmwareUpdateUrl":"https://backyardbrains.com/products/firmwares/sbpro/compatibility.xml",
                "iconURL":"",
                "defaultTimeScale":"2.0",
                "defaultAmplitudeScale":"1.0",
                "sampleRateIsFunctionOfNumberOfChannels":0,
                "miniOSAppVersion":"3.0.0",
                "minAndroidAppVersion":"1.0.0",
                "minWinAppVersion":"1.0.0",
                "minMacAppVersion":"1.0.0",
                "minLinuxAppVersion":"1.0.0",
                "p300CapabilityPresent":1,
                "filter":{
                    "signalType":"eegSignal,ecgSignal",
                    "lowPassON":1,
                    "lowPassCutoff":"2500.0",
                    "highPassON":1,
                    "highPassCutoff":"70.0",
                    "notchFilterState":"notch60Hz"
                },
                "channels":[
                    {
                        "userFriendlyFullName":"EEG/ECG/EMG Channel 1",
                        "userFriendlyShortName":"EEG/ECG/EMG Ch. 1",
                        "activeByDefault":1,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":3.0
                    },
                    {
                        "userFriendlyFullName":"EEG/ECG/EMG Channel 2",
                        "userFriendlyShortName":"EEG/ECG/EMG Ch. 2",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":3.0
                    }
                ],
                "expansionBoards":[
                    {
                        "boardType":"0",
                        "userFriendlyFullName":"Default - events detection expansion board",
                        "userFriendlyShortName":"Events detection",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "maxNumberOfChannels":"0"
                    },
                    {
                        "boardType":"1",
                        "userFriendlyFullName":"Additional analog input channels",
                        "userFriendlyShortName":"Analog x 2",
                        "maxSampleRate":"5000",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "productURL":"",
                        "helpURL":"",
                        "iconURL":"",
                        "maxNumberOfChannels":"2",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"EEG/ECG/EMG Channel 3",
                                "userFriendlyShortName":"EEG/ECG/EMG Ch. 3",
                                "activeByDefault":0,
                                "filtered":1,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":3.0
                            },
                            {
                                "userFriendlyFullName":"EEG/ECG/EMG Channel 4",
                                "userFriendlyShortName":"EEG/ECG/EMG Ch. 4",
                                "activeByDefault":0,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":3.0
                            }
                        ]
                    },
                    {
                        "boardType":"4",
                        "userFriendlyFullName":"The Reflex Hammer",
                        "userFriendlyShortName":"Hammer",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "productURL":"https://backyardbrains.com/products/ReflexHammer",
                        "helpURL":"https://backyardbrains.com/products/ReflexHammer",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Hammer channel",
                                "userFriendlyShortName":"Hammer ch.",
                                "activeByDefault":1,
                                "filtered":1,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":3.0
                            }
                        ]
                    },
                    {
                        "boardType":"5",
                        "userFriendlyFullName":"The Joystick control",
                        "userFriendlyShortName":"Joystick",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"win",
                        "productURL":"",
                        "helpURL":"",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Joystick EMG channel",
                                "userFriendlyShortName":"Joystick EMG",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":3.0
                            }
                        ]
                    }
                ]
            },
            {
                "uniqueName": "MUSCLESB",
                "userFriendlyFullName":"Muscle SpikerBox Pro",
                "userFriendlyShortName":"Muscle SpikerBox Pro",
                "hardwareComProtocolType": "hid",
                "bybProtocolType": "BYB1",
                "bybProtocolVersion": "1.0",
                "maxSampleRate":"10000",
                "maxNumberOfChannels":"2",
                "sampleResolution":10,
                "defaultTimeScale":"0.1",
                "supportedPlatforms":"android,ios,win,mac,linux",
                "productURL":"https://backyardbrains.com/products/musclespikerboxpro",
                "helpURL":"https://backyardbrains.com/products/musclespikerboxpro",
                "iconURL":"",
                "firmwareUpdateUrl":"https://backyardbrains.com/products/firmwares/sbpro/compatibility.xml",
                "defaultAmplitudeScale":"1.0",
                "sampleRateIsFunctionOfNumberOfChannels":0,
                "miniOSAppVersion":"3.0.0",
                "minAndroidAppVersion":"1.0.0",
                "minWinAppVersion":"1.0.0",
                "minMacAppVersion":"1.0.0",
                "minLinuxAppVersion":"1.0.0",
                "p300CapabilityPresent":0,
                "usb":{
                    "VID":"0x2E73",
                    "PID":"0x1"
                },
                "filter":{
                    "signalType":"emgSignal",
                    "lowPassON":1,
                    "lowPassCutoff":"2500.0",
                    "highPassON":1,
                    "highPassCutoff":"1.0",
                    "notchFilterState":"notch60Hz"
                },
                "channels":[
                    {
                        "userFriendlyFullName":"EMG Channel 1",
                        "userFriendlyShortName":"EMG Ch. 1",
                        "activeByDefault":1,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"EMG Channel 2",
                        "userFriendlyShortName":"EMG Ch. 2",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    }
                ],
                "expansionBoards":[
                    {
                        "boardType":"0",
                        "userFriendlyFullName":"Default - events detection expansion board",
                        "userFriendlyShortName":"Events detection",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "maxNumberOfChannels":"0"
                    },
                    {
                        "boardType":"1",
                        "userFriendlyFullName":"Additional analog input channels",
                        "userFriendlyShortName":"Analog x 2",
                        "maxSampleRate":"5000",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "productURL":"",
                        "helpURL":"",
                        "iconURL":"",
                        "maxNumberOfChannels":"2",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"EMG Channel 3",
                                "userFriendlyShortName":"EMG Ch. 3",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            },
                            {
                                "userFriendlyFullName":"EMG Channel 4",
                                "userFriendlyShortName":"EMG Ch. 4",
                                "activeByDefault":0,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    },
                    {
                        "boardType":"4",
                        "userFriendlyFullName":"The Reflex Hammer",
                        "userFriendlyShortName":"Hammer",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "productURL":"https://backyardbrains.com/products/ReflexHammer",
                        "helpURL":"https://backyardbrains.com/products/ReflexHammer",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Hammer channel",
                                "userFriendlyShortName":"Hammer ch.",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    },
                    {
                        "boardType":"5",
                        "userFriendlyFullName":"The Joystick control",
                        "userFriendlyShortName":"Joystick",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"win",
                        "productURL":"",
                        "helpURL":"",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Joystick EMG channel",
                                "userFriendlyShortName":"Joystick EMG",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    }
                ]
            },
            {
                "uniqueName": "AMMOD",
                "userFriendlyFullName":"Spiker Box via audio cable",
                "userFriendlyShortName":"Spiker Box via audio cable",
                "hardwareComProtocolType": "local",
                "bybProtocolType": "",
                "bybProtocolVersion": "",
                "maxSampleRate":"44100",
                "maxNumberOfChannels":"1",
                "sampleResolution":0,
                "defaultTimeScale":"4",
                "supportedPlatforms":"android,ios,win,mac,linux",
                "productURL":"https://backyardbrains.com/",
                "helpURL":"https://backyardbrains.com/",
                "iconURL":"",
                "firmwareUpdateUrl":"",
                "defaultAmplitudeScale":"1.0",
                "sampleRateIsFunctionOfNumberOfChannels":0,
                "miniOSAppVersion":"3.0.0",
                "minAndroidAppVersion":"1.0.0",
                "minWinAppVersion":"1.0.0",
                "minMacAppVersion":"1.0.0",
                "minLinuxAppVersion":"1.0.0",
                "p300CapabilityPresent":0,
                "filter":{
                    "signalType":"emgSignal,ekgSignal",
                    "lowPassON":1,
                    "lowPassCutoff":"500.0",
                    "highPassON":0,
                    "highPassCutoff":"0",
                    "notchFilterState":"notchOff"
                },
                "channels":[
                    {
                        "userFriendlyFullName":"SpikerBox Channel 1",
                        "userFriendlyShortName":"SpikerBox Ch. 1",
                        "activeByDefault":1,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":0,
                        "defaultVoltageScale":0.1
                    }
                ],
                "expansionBoards":[
                ]
            },
            {
                "uniqueName": "NEURONSB",
                "userFriendlyFullName":"Neuron SpikerBox Pro",
                "userFriendlyShortName":"Neuron SpikerBox Pro",
                "hardwareComProtocolType": "iap2,hid",
                "bybProtocolType": "BYB1",
                "bybProtocolVersion": "1.0",
                "maxSampleRate":"10000",
                "maxNumberOfChannels":"2",
                "sampleResolution":10,
                "supportedPlatforms":"android,ios,win,mac,linux",
                "productURL":"https://backyardbrains.com/products/neuronspikerboxpro",
                "helpURL":"https://backyardbrains.com/products/neuronspikerboxpro",
                "firmwareUpdateUrl":"https://backyardbrains.com/products/firmwares/sbpro/compatibility.xml",
                "iconURL":"",
                "defaultTimeScale":"0.1",
                "defaultAmplitudeScale":"1.0",
                "sampleRateIsFunctionOfNumberOfChannels":0,
                "miniOSAppVersion":"3.0.0",
                "minAndroidAppVersion":"1.0.0",
                "minWinAppVersion":"1.0.0",
                "minMacAppVersion":"1.0.0",
                "minLinuxAppVersion":"1.0.0",
                "p300CapabilityPresent":0,
                "usb":{
                    "VID":"0x2E73",
                    "PID":"0x2"
                },
                "filter":{
                    "signalType":"neuronSignal",
                    "lowPassON":1,
                    "lowPassCutoff":"2500.0",
                    "highPassON":1,
                    "highPassCutoff":"1.0",
                    "notchFilterState":"notch60Hz"
                },
                "channels":[
                    {
                        "userFriendlyFullName":"Neuron Channel 1",
                        "userFriendlyShortName":"Neuron Ch. 1",
                        "activeByDefault":1,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"Neuron Channel 2",
                        "userFriendlyShortName":"Neuron Ch. 2",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    }
                ],
                "expansionBoards":[
                    {
                        "boardType":"0",
                        "userFriendlyFullName":"Default - events detection expansion board",
                        "userFriendlyShortName":"Events detection",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "maxNumberOfChannels":"0"
                    },
                    {
                        "boardType":"1",
                        "userFriendlyFullName":"Additional analog input channels",
                        "userFriendlyShortName":"Analog x 2",
                        "maxSampleRate":"5000",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "maxNumberOfChannels":"2",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Neuron Channel 3",
                                "userFriendlyShortName":"Neuron Ch. 3",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            },
                            {
                                "userFriendlyFullName":"Neuron Channel 4",
                                "userFriendlyShortName":"Neuron Ch. 4",
                                "activeByDefault":0,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    },
                    {
                        "boardType":"4",
                        "userFriendlyFullName":"The Reflex Hammer",
                        "userFriendlyShortName":"Hammer",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "productURL":"https://backyardbrains.com/products/ReflexHammer",
                        "helpURL":"https://backyardbrains.com/products/ReflexHammer",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Hammer channel",
                                "userFriendlyShortName":"Hammer ch.",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    },
                    {
                        "boardType":"5",
                        "userFriendlyFullName":"The Joystick control",
                        "userFriendlyShortName":"Joystick",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"win",
                        "productURL":"",
                        "helpURL":"",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Joystick EMG channel",
                                "userFriendlyShortName":"Joystick EMG.",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    }
                ]
            },
            {
                "uniqueName": "MSBPCDC",
                "userFriendlyFullName":"Muscle SpikerBox Pro",
                "userFriendlyShortName":"Muscle SpikerBox Pro",
                "hardwareComProtocolType": "serial",
                "bybProtocolType": "BYB1",
                "bybProtocolVersion": "1.0",
                "maxSampleRate":"10000",
                "maxNumberOfChannels":"2",
                "sampleResolution":10,
                "defaultTimeScale":"0.1",
                "supportedPlatforms":"android,ios,win,mac,linux",
                "productURL":"https://backyardbrains.com/products/musclespikerboxpro",
                "helpURL":"https://backyardbrains.com/products/musclespikerboxpro",
                "iconURL":"",
                "firmwareUpdateUrl":"",
                "defaultAmplitudeScale":"1.0",
                "sampleRateIsFunctionOfNumberOfChannels":0,
                "miniOSAppVersion":"3.0.0",
                "minAndroidAppVersion":"1.0.0",
                "minWinAppVersion":"1.0.0",
                "minMacAppVersion":"1.0.0",
                "minLinuxAppVersion":"1.0.0",
                "p300CapabilityPresent":0,
                "usb":{
                    "VID":"0x2E73",
                    "PID":"0x6"
                },
                "filter":{
                    "signalType":"emgSignal",
                    "lowPassON":1,
                    "lowPassCutoff":"2500.0",
                    "highPassON":1,
                    "highPassCutoff":"1.0",
                    "notchFilterState":"notch60Hz"
                },
                "channels":[
                    {
                        "userFriendlyFullName":"EMG Channel 1",
                        "userFriendlyShortName":"EMG Ch. 1",
                        "activeByDefault":1,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"EMG Channel 2",
                        "userFriendlyShortName":"EMG Ch. 2",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    }
                ],
                "expansionBoards":[
                    {
                        "boardType":"0",
                        "userFriendlyFullName":"Default - events detection expansion board",
                        "userFriendlyShortName":"Events detection",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "maxNumberOfChannels":"0"
                    },
                    {
                        "boardType":"1",
                        "userFriendlyFullName":"Additional analog input channels",
                        "userFriendlyShortName":"Analog x 2",
                        "maxSampleRate":"5000",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "productURL":"",
                        "helpURL":"",
                        "iconURL":"",
                        "maxNumberOfChannels":"2",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"EMG Channel 3",
                                "userFriendlyShortName":"EMG Ch. 3",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            },
                            {
                                "userFriendlyFullName":"EMG Channel 4",
                                "userFriendlyShortName":"EMG Ch. 4",
                                "activeByDefault":0,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    },
                    {
                        "boardType":"4",
                        "userFriendlyFullName":"The Reflex Hammer",
                        "userFriendlyShortName":"Hammer",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "productURL":"https://backyardbrains.com/products/ReflexHammer",
                        "helpURL":"https://backyardbrains.com/products/ReflexHammer",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Hammer channel",
                                "userFriendlyShortName":"Hammer ch.",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    },
                    {
                        "boardType":"5",
                        "userFriendlyFullName":"The Joystick control",
                        "userFriendlyShortName":"Joystick",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"win",
                        "productURL":"",
                        "helpURL":"",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Joystick EMG channel",
                                "userFriendlyShortName":"Joystick EMG",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    }
                ]
            },
            {
                "uniqueName": "NSBPCDC",
                "userFriendlyFullName":"Neuron SpikerBox Pro",
                "userFriendlyShortName":"Neuron SpikerBox Pro",
                "hardwareComProtocolType": "serial",
                "bybProtocolType": "BYB1",
                "bybProtocolVersion": "1.0",
                "maxSampleRate":"10000",
                "maxNumberOfChannels":"2",
                "sampleResolution":10,
                "supportedPlatforms":"android,ios,win,mac,linux",
                "productURL":"https://backyardbrains.com/products/neuronspikerboxpro",
                "helpURL":"https://backyardbrains.com/products/neuronspikerboxpro",
                "firmwareUpdateUrl":"https://backyardbrains.com/products/firmwares/sbpro/compatibility.xml",
                "iconURL":"",
                "defaultTimeScale":"0.1",
                "defaultAmplitudeScale":"1.0",
                "sampleRateIsFunctionOfNumberOfChannels":0,
                "miniOSAppVersion":"3.0.0",
                "minAndroidAppVersion":"1.0.0",
                "minWinAppVersion":"1.0.0",
                "minMacAppVersion":"1.0.0",
                "minLinuxAppVersion":"1.0.0",
                "p300CapabilityPresent":0,
                "usb":{
                    "VID":"0x2E73",
                    "PID":"0x7"
                },
                "filter":{
                    "signalType":"neuronSignal",
                    "lowPassON":1,
                    "lowPassCutoff":"2500.0",
                    "highPassON":1,
                    "highPassCutoff":"1.0",
                    "notchFilterState":"notch60Hz"
                },
                "channels":[
                    {
                        "userFriendlyFullName":"Neuron Channel 1",
                        "userFriendlyShortName":"Neuron Ch. 1",
                        "activeByDefault":1,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"Neuron Channel 2",
                        "userFriendlyShortName":"Neuron Ch. 2",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    }
                ],
                "expansionBoards":[
                    {
                        "boardType":"0",
                        "userFriendlyFullName":"Default - events detection expansion board",
                        "userFriendlyShortName":"Events detection",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "maxNumberOfChannels":"0"
                    },
                    {
                        "boardType":"1",
                        "userFriendlyFullName":"Additional analog input channels",
                        "userFriendlyShortName":"Analog x 2",
                        "maxSampleRate":"5000",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "maxNumberOfChannels":"2",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Neuron Channel 3",
                                "userFriendlyShortName":"Neuron Ch. 3",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            },
                            {
                                "userFriendlyFullName":"Neuron Channel 4",
                                "userFriendlyShortName":"Neuron Ch. 4",
                                "activeByDefault":0,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    },
                    {
                        "boardType":"4",
                        "userFriendlyFullName":"The Reflex Hammer",
                        "userFriendlyShortName":"Hammer",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"android,ios,win,mac,linux",
                        "productURL":"https://backyardbrains.com/products/ReflexHammer",
                        "helpURL":"https://backyardbrains.com/products/ReflexHammer",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Hammer channel",
                                "userFriendlyShortName":"Hammer ch.",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    },
                    {
                        "boardType":"5",
                        "userFriendlyFullName":"The Joystick control",
                        "userFriendlyShortName":"Joystick",
                        "maxSampleRate":"5000",
                        "maxNumberOfChannels":"1",
                        "supportedPlatforms":"win",
                        "productURL":"",
                        "helpURL":"",
                        "iconURL":"",
                        "defaultTimeScale":"0.1",
                        "defaultAmplitudeScale":"1.0",
                        "channels":[
                            {
                                "userFriendlyFullName":"Joystick EMG channel",
                                "userFriendlyShortName":"Joystick EMG.",
                                "activeByDefault":1,
                                "filtered":0,
                                "calibrationCoef":1.0,
                                "channelIsCalibrated":1,
                                "defaultVoltageScale":0.1
                            }
                        ]
                    }
                ]
            },
            {
                "uniqueName": "HBLEOSB",
                "userFriendlyFullName":"Heart and Brain SpikerBox",
                "userFriendlyShortName":"H&B SpikerBox",
                "hardwareComProtocolType": "serial",
                "bybProtocolType": "BYB1",
                "bybProtocolVersion": "1.0",
                "maxSampleRate":"10000",
                "maxNumberOfChannels":"1",
                "sampleResolution":10,
                "supportedPlatforms":"android,win,mac,linux",
                "productURL":"https://backyardbrains.com/products/heartandbrainspikerbox",
                "helpURL":"https://backyardbrains.com/products/heartandbrainspikerbox",
                "firmwareUpdateUrl":"",
                "iconURL":"",
                "defaultTimeScale":"0.1",
                "defaultAmplitudeScale":"1.0",
                "sampleRateIsFunctionOfNumberOfChannels":0,
                "miniOSAppVersion":"3.0.0",
                "minAndroidAppVersion":"1.0.0",
                "minWinAppVersion":"1.0.0",
                "minMacAppVersion":"1.0.0",
                "minLinuxAppVersion":"1.0.0",
                "p300CapabilityPresent":0,
                "filter":{
                    "signalType":"eegSignal,ecgSignal",
                    "lowPassON":1,
                    "lowPassCutoff":"100.0",
                    "highPassON":1,
                    "highPassCutoff":"1.0",
                    "notchFilterState":"notch60Hz"
                },
                "channels":[
                    {
                        "userFriendlyFullName":"H&B Channel 1",
                        "userFriendlyShortName":"H&B Ch. 1",
                        "activeByDefault":1,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    }
                ],
                "expansionBoards":[
                ]
            },
            {
                "uniqueName": "HEARTSS",
                "userFriendlyFullName":"Heart and Brain SpikerShield",
                "userFriendlyShortName":"H&B SpikerShield",
                "hardwareComProtocolType": "serial",
                "bybProtocolType": "BYB1",
                "bybProtocolVersion": "1.0",
                "maxSampleRate":"10000",
                "maxNumberOfChannels":"6",
                "sampleResolution":10,
                "supportedPlatforms":"android,win,mac,linux",
                "productURL":"https://backyardbrains.com/products/heartandbrainspikershieldbundle",
                "helpURL":"https://backyardbrains.com/products/heartandbrainspikershieldbundle",
                "firmwareUpdateUrl":"",
                "iconURL":"",
                "defaultTimeScale":"0.1",
                "defaultAmplitudeScale":"1.0",
                "sampleRateIsFunctionOfNumberOfChannels":1,
                "miniOSAppVersion":"3.0.0",
                "minAndroidAppVersion":"1.0.0",
                "minWinAppVersion":"1.0.0",
                "minMacAppVersion":"1.0.0",
                "minLinuxAppVersion":"1.0.0",
                "p300CapabilityPresent":0,
                "filter":{
                    "signalType":"eegSignal,ecgSignal",
                    "lowPassON":1,
                    "lowPassCutoff":"100.0",
                    "highPassON":1,
                    "highPassCutoff":"1.0",
                    "notchFilterState":"notch60Hz"
                },
                "channels":[
                    {
                        "userFriendlyFullName":"H&B Channel 1",
                        "userFriendlyShortName":"H&B Ch. 1",
                        "activeByDefault":1,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"H&B Channel 2",
                        "userFriendlyShortName":"H&B Ch. 2",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"H&B Channel 3",
                        "userFriendlyShortName":"H&B Ch. 3",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"H&B Channel 4",
                        "userFriendlyShortName":"H&B Ch. 4",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"H&B Channel 5",
                        "userFriendlyShortName":"H&B Ch. 5",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"H&B Channel 6",
                        "userFriendlyShortName":"H&B Ch. 6",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    }

                ],
                "expansionBoards":[
                ]
            },
            {
                "uniqueName": "MUSCLESS",
                "userFriendlyFullName":"Muscle SpikerShield",
                "userFriendlyShortName":"Muscle SpikerShield",
                "hardwareComProtocolType": "serial",
                "bybProtocolType": "BYB1",
                "bybProtocolVersion": "1.0",
                "maxSampleRate":"10000",
                "maxNumberOfChannels":"6",
                "sampleResolution":10,
                "supportedPlatforms":"android,win,mac,linux",
                "productURL":"https://backyardbrains.com/products/musclespikershield",
                "helpURL":"https://backyardbrains.com/products/musclespikershield",
                "firmwareUpdateUrl":"",
                "iconURL":"",
                "defaultTimeScale":"0.1",
                "defaultAmplitudeScale":"1.0",
                "sampleRateIsFunctionOfNumberOfChannels":1,
                "miniOSAppVersion":"3.0.0",
                "minAndroidAppVersion":"1.0.0",
                "minWinAppVersion":"1.0.0",
                "minMacAppVersion":"1.0.0",
                "minLinuxAppVersion":"1.0.0",
                "p300CapabilityPresent":0,
                "filter":{
                    "signalType":"emgSignal",
                    "lowPassON":1,
                    "lowPassCutoff":"25000.0",
                    "highPassON":1,
                    "highPassCutoff":"70.0",
                    "notchFilterState":"notch60Hz"
                },
                "channels":[
                    {
                        "userFriendlyFullName":"Muscle Channel 1",
                        "userFriendlyShortName":"Muscle Ch. 1",
                        "activeByDefault":1,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"Muscle Channel 2",
                        "userFriendlyShortName":"Muscle Ch. 2",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"Muscle Channel 3",
                        "userFriendlyShortName":"Muscle Ch. 3",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"Muscle Channel 4",
                        "userFriendlyShortName":"Muscle Ch. 4",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"Muscle Channel 5",
                        "userFriendlyShortName":"Muscle Ch. 5",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    },
                    {
                        "userFriendlyFullName":"Muscle Channel 6",
                        "userFriendlyShortName":"Muscle Ch. 6",
                        "activeByDefault":0,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    }

                ],
                "expansionBoards":[
                ]
            },
            {
                "uniqueName": "PLANTSS",
                "userFriendlyFullName":"Plant SpikerBox",
                "userFriendlyShortName":"Plant SpikerBox",
                "hardwareComProtocolType": "serial",
                "bybProtocolType": "BYB1",
                "bybProtocolVersion": "1.0",
                "maxSampleRate":"10000",
                "maxNumberOfChannels":"1",
                "sampleResolution":10,
                "supportedPlatforms":"android,win,mac,linux",
                "productURL":"https://backyardbrains.com/products/plantspikerbox",
                "helpURL":"https://backyardbrains.com/products/plantspikerbox",
                "firmwareUpdateUrl":"",
                "iconURL":"",
                "defaultTimeScale":"0.1",
                "defaultAmplitudeScale":"1.0",
                "sampleRateIsFunctionOfNumberOfChannels":0,
                "miniOSAppVersion":"3.0.0",
                "minAndroidAppVersion":"1.0.0",
                "minWinAppVersion":"1.0.0",
                "minMacAppVersion":"1.0.0",
                "minLinuxAppVersion":"1.0.0",
                "p300CapabilityPresent":0,
                "filter":{
                    "signalType":"plantSignal",
                    "lowPassON":1,
                    "lowPassCutoff":"5.0",
                    "highPassON":0,
                    "highPassCutoff":"0.0",
                    "notchFilterState":"notchOff"
                },
                "channels":[
                    {
                        "userFriendlyFullName":"Plant Channel 1",
                        "userFriendlyShortName":"Plant Ch. 1",
                        "activeByDefault":1,
                        "filtered":1,
                        "calibrationCoef":1.0,
                        "channelIsCalibrated":1,
                        "defaultVoltageScale":0.1
                    }
                ],
                "expansionBoards":[
                ]
            }
        ]
    }
}''');