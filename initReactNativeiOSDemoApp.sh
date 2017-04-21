#!/bin/bash

# position to a relative path
HERE="$(dirname "$(test -L "$0" && readlink "$0" || echo "$0")")"
pushd $HERE >> /dev/null

# remove any existing code
rm -rf BlinkIDReactNative

# create a sample application
react-native init BlinkIDReactNative

# enter into demo project folder
cd BlinkIDReactNative

# download npm package
echo "Downloading blinkid-react-native-ios module"
npm i --save blinkid-react-native-ios

# link package with project
echo "Linking blinkid-react-native-ios module with project"
react-native link blinkid-react-native-ios

# enter into ios project folder
cd ios

# initialize Podfile
echo "Initializing and installing Podfile"
pod init

# remove Podfile
rm -f Podfile

# replace Podfile with new Podfile
cat > Podfile << EOF
platform :ios, '8.0'

target 'BlinkIDReactNative' do
  pod 'PPBlinkID', '~> 2.7.1'
end
EOF

# install pod
pod install

# go to react native root project
cd ..

# remove index.ios.js
rm -f index.ios.js

# create index.ios.js with content
cat > index.ios.js << EOF
/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
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

console.disableYellowBox = true;

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
      setBlinkIDLicenseKey('MIJ6AWF7-5OJERWUC-KMV2EDMT-R6SFVN3Y-NBXVO4XS-X7RONXS5-IPL6ERXP-4REXFFII')
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
EOF

# upgrade 
react-native upgrade

react-native run-ios