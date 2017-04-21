# BlinkID iOS SDK wrapper for React Native

This repository contains example wrapper for BlinkID native SDK [iOS](https://github.com/BlinkID/blinkid-ios). For 100% of features and maximum control, consider using native SDK.


### Licensing

- [Generate](https://microblink.com/login?url=/customer/generatedemolicence) a **free demo license key** to start using the SDK in your app (registration required)

- Get information about pricing and licensing of [BlinkID](https://microblink.com/blinkid)

## Installation

First generate an empty project if needed:

```shell
react-native init NameOfYourProject
```

Add the **blinkid-react-native-ios** module to your project:

```shell
cd <path_to_your_project>
npm i --save blinkid-react-native-ios
```

Link module with your project: 

```shell
react-native link blinkid-react-native-ios
```

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like BlinkID in your projects.

- If you wish to use version v1.4.0 or above, you need to install [Git Large File Storage](https://git-lfs.github.com) by running these comamnds:
```shell
brew install git-lfs
git lfs install
```

- **Be sure to restart your console after installing Git LFS**

#### Podfile

In your project, you will need to add MicroBlink.framework/MicroBlink framework. Go to your **./NameOfYourProject/ios** folder and create Podfile at the root of your iOS project: 

```ruby
platform :ios, '8.0'

target 'TargetName' do
  pod 'PPBlinkID', '~> 2.7.1'
end
```

After you have added Podfile, install it by running this command:
```shell
pod install
```

## Demo
This repository contains **initReactNativeiOSDemoApp.sh** script which you can download that will create React Native project and download all of its dependencies. Put that script in your wanted folder and run this command: 
```shell
./initReactNativeiOSDemoApp.sh
```

After some time, XCode will open your project. Go to **Targets -> General** and for each **Target** set your team.


You **need** to say **y** and press enter to finish the installation of demo app.
It will lunch iOS simulator with Demo application.

## Usage

To use the module you call it in your index.ios.js file like the example below:

```javascript

/**
* Use these scanner types
* Available: "USDL", "MRTD", "EKDL"
* USDL - scans barcodes located on the back of US driver's license
* MRTD - scans Machine Readable Travel Document, contained in various IDs and passports
* EUDL - scans the front of European driver's license
*/

/**
 * There are several options you need to pass to scan function to add recognizers and to obtain the image and results
 * available:
 *  "isFrontCamera" : if it's set to false, back camera is used, else front
 *  "addEudlRecognizer" : set to true if you want to add EUDL recognizer
 *  "addMrtdRecognizer" : set to true if you want to add MRTD recognizer
 *  "addUsdlRecognizer" : set to true if you want to add USDL recognizer
 *  "shouldReturnCroppedDocument": if true, dewarped images in the recognition process will be saved
 *  "shouldReturnSuccessfulFrame": if true, image on which scan gave valid scaning result will be saved
 */

/**
 * Scan method returns scan fields in JSON format and image (image is returned as Base64 encoded JPEG)
 *  "scanningResult.resultImage" : image is returned as Base64 encoded JPEG
 *  "scanningResult.resultList[0].fields" : all the fields in JSON format
 */
import React, { Component } from 'react';
import { scan, setBlinkIDLicenseKey } from 'blinkid-react-native-ios';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  TouchableHighlight,
  Alert,
  Image,
  ScrollView
} from 'react-native';

export default class BlinkIDReactNative extends Component {
    constructor(props) {
    super(props);
    this.state = {showResults: false, 
                  resultImage: '',
                  resultsList: '',
                  licenseKeyErrorMessage: ''};
  }
  async scan() {
    try {
      setBlinkIDLicenseKey('3SU5N6JB-ZDIE3O7P-7PCWDKWW-GYVO766Y-XLENEMDV-BFTOESUJ-AFG3WD7K-5YYAF7UO')
    }
    catch (e) {
      this.setState({licenseKeyErrorMessage: 'Please set Your Microblink license key'})
  }
    const scanningResult = await scan({
      isFrontCamera: false,
      addEudlRecognizer: true,
      addMrtdRecognizer: false,
      addUsdlRecognizer: true,
      shouldReturnCroppedDocument: true,
      shouldReturnSuccessfulFrame: true
    })
    if (scanningResult) {
       this.setState({ showResults: true, resultImage: scanningResult.resultImage, resultsList: JSON.stringify(scanningResult.resultList[0].fields)});
    }
  }
  render() {
    let displayImage = this.state.resultImage;
    let displayFields = this.state.resultsList;
    let licenseKeyErrorMessage = this.state.licenseKeyErrorMessage;
    return (
      <View style={styles.container}>
        <TouchableHighlight onPress={this.scan.bind(this)} style={styles.button}>
          <Text style={styles.results}>Scan</Text>
        </TouchableHighlight>
        <Text style={styles.results}>{licenseKeyErrorMessage}</Text>
        <Text style={styles.results}>MicroBlink Ltd</Text>
        <ScrollView
          automaticallyAdjustContentInsets={false}
          scrollEventThrottle={200}y> 
          <Image source={{uri: displayImage, scale: 3}} style={styles.imageResult}/>
          <Text style={styles.results}>{displayFields}</Text>
        </ScrollView>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  button:{
        paddingTop:70,
        paddingBottom:10
    },
  results: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  imageLogo: {
    width: 100,
    height: 100,
    alignItems: 'center',
    justifyContent: 'center'
  },
  imageResult: {
    width: 300,
    height: 200,
    alignItems: 'center',
    justifyContent: 'center'
  },
});

AppRegistry.registerComponent('BlinkIDReactNative', () => BlinkIDReactNative);
```
+ Available scanners are:
    + **USDL**  - scans barcodes located on the back of US driver's license
    + **MRTD** - scans Machine Readable Travel Document, contained in various IDs and passports
    + **EUDL** - scans the front of European driver's license
	
+ Scan method returns scan fields in JSON format and image (image is returned as Base64 encoded JPEG)
	+ **scanningResult.resultImage** : image is returned as Base64 encoded JPEG
	+ **scanningResult.resultList[0].fields** : all the fields in JSON format

+ License parameter must be provided for **iOS**.

