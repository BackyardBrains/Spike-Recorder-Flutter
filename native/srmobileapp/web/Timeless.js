// var functions;
// console.log(self.origin+"/require.js");
// importScripts(self.origin+"/require.js");
// requirejs.config({
//     baseUrl: self.origin,
//     // baseUrl: '/',
//     // baseUrl: '.',
//     paths: {
//         functions:"multiply"
//         // functions:"a"
//     },
//     waitSeconds: 20
// });
// // requirejs(["maindart"], (maindart) => {
// //     console.log(maindart)
// // });
// requirejs(["functions"], (_functions) => {
//     functions = _functions;
//     // console.log("multiply")
//     // console.log(_functions);
//     console.log("Add (300,2) : ", _functions.myHyperSuperMegaFunction(300,2));
//     console.log("Multiplications (0.5 * 212) : ",functions.multiplicationz(0.5,212));
// });


onmessage = function(e) {
    console.log('Message: ', e);
    postMessage('Hello');
    let i = 0;
    // console.log(functions);
    while (true){
        // i++;
        // if (i = 100000){
            console.log("Timeless 1");
            console.log("functions.multiply(0.5, i )");
            console.log(functions.multiply(0.5, i));
        // }
    }
};