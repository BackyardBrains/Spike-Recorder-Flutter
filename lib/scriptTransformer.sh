#!/bin/bash  
#/Users/macbook/Documents/BYB/github/srmobileapp/lib/library.dart
functions=("multiply" "floor" "generateArray" "envelopingSamples" "calculateLevel" "executeOneMessage" "executeContentOfMessageBuffer" "testEscapeSequence" "frameHasAllBytes" "checkIfHaveWholeFrame" "areWeAtTheEndOfFrame" "serialParsing")
file=/Users/macbook/Documents/BYB/github/srmobileapp/lib/library.dart
output_file=/Users/macbook/Documents/BYB/github/srmobileapp/build/web/libraries/library1.js
while read line; do  
  
#Readind each line in sequence  
if [ "$line" == "import 'dart:convert';" ]; then
    echo "define(function(require, exports, module) {" > $output_file
elif [[ "$line" == *"utf8.decode"* ]]; then
    printf "${line/utf8\.decode(/String.fromCharCode(...}" >> $output_file 
elif [[ "$line" == *"codeUnitAt"* ]]; then
    printf "${line/codeUnitAt(/charCodeAt(...}" >> $output_file 
elif [[ "$line" == *"return val.floor()"* ]]; then
    printf "${line/return val.floor()/return Math.floor(val)}" >> $output_file 
else
    flag="1"
    for item in ${functions[@]}; do
        fn="${item}("
        # echo "aslkdjasljdaklsjdklasjlkasjdlkasjsdklajskldjalksdjkalsjdklasjdklj$fn"
        # echo "$fn"
        # echo "$line"
        # echo "$line" =~ .*"$fn".*
        if [[ "$line" =~ ^"$fn".*"{" ]]; then
            function="function ${item}("
            printf "${line/$fn/$function}" >> $output_file 
            flag="0"
        fi
    done    
    if [ "$flag" == "1" ]; then
        echo "$line" >> $output_file
    fi
fi
done <$file

printf "return {
    'multiply': multiply,
    'envelopingSamples' : envelopingSamples,
    'calculateLevel' : calculateLevel,
    'executeOneMessage' : executeOneMessage,
    'executeContentOfMessageBuffer' : executeContentOfMessageBuffer,
    'testEscapeSequence' : testEscapeSequence,
    'frameHasAllBytes' : frameHasAllBytes,
    'checkIfHaveWholeFrame' : checkIfHaveWholeFrame,
    'areWeAtTheEndOfFrame' : areWeAtTheEndOfFrame,
};});" >> $output_file

# exec $output_file