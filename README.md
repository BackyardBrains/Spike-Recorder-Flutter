Spike Recorder Flutter
========================

A neural recording app that runs on Windows, Android, iOS and OSX.


Building instructions
------------------------

To build Spike Recorder Flutter follow these steps.

### Installing dependencies

***on OS X***

- Please follow the Flutter installation [here](https://docs.flutter.dev/get-started/install/macos)
- Clone this repository by following this command
    ```sh
     git clone https://github.com/BackyardBrains/Spike-Recorder-Flutter.git ./srapp     
     cd srapp
    ```
- Install packages
    ```sh
     flutter pub get
    ```
- Run project
    ```sh
     flutter run 
    ```

***on Windows***

- Please follow the Flutter installation [here](https://docs.flutter.dev/get-started/install/windows)
- Clone this repository by following this command
    ```sh
     git clone https://github.com/BackyardBrains/Spike-Recorder-Flutter.git ./srapp  
     cd srapp
    ```
- Install packages
    ```sh
     flutter pub get
    ```
- Run project
    ```sh
     flutter run 
    ```


> **Warning**
> Please follow these additional instructions to run the Web App

- Install Visual Studio Code
- Install [Live Server extension](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer)
- Find the file
  ```sh
    .vscode\extensions\ritwickdey.liveserver-5.6.1\node_modules\live-server\index.js
  ```
- Find line 
  ```
	if (cors) {
		app.use(require("cors")({
			origin: true, // reflecting request origin
			credentials: true // allowing requests with credentials
		}));
	}
  ```
- Copy this lines and put above the previous line
  ```
	app.use((req, res, next) => {
		res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
		res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
		next();
	});
  ```
- Rename the main.dart into main_temp.dart, skip changes when asked.
- Rename the main_thresholdweb.dart into main.dart, skip changes when asked.
- Build project
  ```sh
     flutter build web
  ```
- Run the live server extension by clicking the Go Live button at the bottom right of the Visual Studio Code window
- To deploy the app please user ```index.js``` in folder server.


Requirements
------------------------

- Flutter version 3.13.0
- XCode version 14.2 or newer
