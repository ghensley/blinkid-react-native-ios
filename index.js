'use strict'

var reactNative = require('react-native');
var { NativeModules, Platform } = reactNative;

let { BlinkIDReactNative } = NativeModules
if (Platform.OS === 'ios') {
  BlinkIDReactNative = addPromisesForAll(BlinkIDReactNative)
}
const { scan, setBlinkIDLicenseKey } = BlinkIDReactNative

let licenseKey
module.exports = {
  setBlinkIDLicenseKey: key => {
    licenseKey = key
    return BlinkIDReactNative.setBlinkIDLicenseKey(key)
  },
  scan: async (settings={}) => {
    if (!licenseKey) {
      throw new Error('Set Your Microblink License key')
    }
    const result = await scan(settings)
    return result
  }
}


function addPromisesForAll (partOfModule) {
  const promisesAdded = {}
  for (var promise in partOfModule) {
    let promiseValue = partOfModule[promise]
    if (typeof promiseValue === 'function') {
      promisesAdded[promise] = addPromiseForOne(promiseValue)
    } else {
      promisesAdded[promise] = promiseValue
    }
  }
  return promisesAdded
}

function addPromiseForOne (fn) {
  return function (...args) {
    return new Promise((resolve, reject) => {
      args.push((error, response) => {
        if (error) {
          reject(error)
        } else {
          resolve(response)
        }
      })
      fn.apply(this, args)
    })
  }
}
