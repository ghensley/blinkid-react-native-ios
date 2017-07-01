//
//  BlinkIDReactNative.m
//  BlinkIDReactNative
//
//  Created by Jura Skrlec on 12/04/2017.
//  Copyright © 2017 Microblink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlinkIDReactNative.h"
#import "RCTConvert.h"
#import <MicroBlink/MicroBlink.h>

@interface BlinkIDReactNative () <PPScanningDelegate>

@property (nonatomic) PPCameraType cameraType;

@property (nonatomic, strong) NSDictionary* options;

@property (nonatomic, strong) RCTResponseSenderBlock callback;

@property (nonatomic, strong) NSString* licenseKey;

@property (nonatomic) PPImageMetadata *lastImageMetadata;

@property (nonatomic) BOOL shouldReturnCroppedDocument;

@property (nonatomic) BOOL shouldReturnSuccessfulFrame;

@end


@implementation BlinkIDReactNative

RCT_EXPORT_MODULE();

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}


- (NSDictionary *)constantsToExport {
    NSMutableDictionary* constants = [NSMutableDictionary dictionary];
    return [NSDictionary dictionaryWithDictionary:constants];
}


RCT_EXPORT_METHOD(setBlinkIDLicenseKey:(NSString*)key callback:(RCTResponseSenderBlock)callback) {
    if (key.length == 0 && callback) {
        callback(@[@"License key needed"]);
    }
    else {
        self.licenseKey = key;
    }

}


RCT_EXPORT_METHOD(scan:(NSDictionary*)scanOptions callback:(RCTResponseSenderBlock)callback) {
    
    BOOL isFrontCamera = [[scanOptions valueForKey:@"isFrontCamera"] boolValue];
    if (!isFrontCamera) {
        self.cameraType = PPCameraTypeBack;
    } else {
        self.cameraType = PPCameraTypeFront;
    }
    
    self.callback = callback;
    self.options = scanOptions;
    
    /** Instantiate the scanning coordinator */
    NSError *error;
    PPCameraCoordinator *coordinator = [self coordinatorWithError:&error];
    
    /** If scanning isn't supported, present an error */
    if (coordinator == nil) {
        callback(@[[error localizedDescription]]);

        return;
    }
    
    /** Allocate and present the scanning view controller */
    UIViewController<PPScanningViewController>* scanningViewController = [PPViewControllerFactory cameraViewControllerWithDelegate:self coordinator:coordinator error:nil];
    
    // allow rotation if VC is displayed as a modal view controller
    scanningViewController.autorotate = YES;
    scanningViewController.supportedOrientations = UIInterfaceOrientationMaskAll;
    
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [rootViewController presentViewController:scanningViewController animated:YES completion:nil];
    });
    
}

RCT_EXPORT_METHOD(dismiss) {
    [self dismissScanningView];
}


#pragma mark - BlinkID specifics

/**
 * Method allocates and initializes the Scanning coordinator object.
 * Coordinator is initialized with settings for scanning
 *
 *  @param error Error object, if scanning isn't supported
 *
 *  @return initialized coordinator
 */
- (PPCameraCoordinator *)coordinatorWithError:(NSError**)error {
    /** 0. Check if scanning is supported */
    
    if ([PPCameraCoordinator isScanningUnsupportedForCameraType:self.cameraType error:error]) {
        return nil;
    }
    
    /** 1. Initialize the Scanning settings */
    
    // Initialize the scanner settings object. This initialize settings with all default values.
    PPSettings *settings = [[PPSettings alloc] init];
    
    self.shouldReturnCroppedDocument = NO;
    self.shouldReturnSuccessfulFrame = NO;
    
    if ([[self.options valueForKey:@"shouldReturnSuccessfulFrame"] boolValue]) {
        settings.metadataSettings.successfulFrame = YES;
        self.shouldReturnSuccessfulFrame = YES;
    }
    
    if ([[self.options valueForKey:@"shouldReturnCroppedDocument"] boolValue]) {
        settings.metadataSettings.dewarpedImage = YES;
        self.shouldReturnCroppedDocument = YES;
    }
    
    settings.cameraSettings.cameraType = self.cameraType;
    
    self.lastImageMetadata = nil;

    
    // Do not timeout
    settings.scanSettings.partialRecognitionTimeout = 0.0f;
    
    
    /** 2. Setup the license key */
    
    // Visit www.microblink.com to get the license key for your app
    settings.licenseSettings.licenseKey = self.licenseKey;
    
    
    /** 3. Set up what is being scanned. See detailed guides for specific use cases. */
    
    /**
     * Add all needed recognizers
     */
    
    if ([self shouldUseUsdlRecognizer]) {
        [settings.scanSettings addRecognizerSettings:[self usdlRecognizerSettings]];
    }
    
    if ([self shouldUseMrtdRecognizer]) {
        [settings.scanSettings addRecognizerSettings:[self mrtdRecognizerSettings]];
    }
    
    if ([self shouldUseEudlRecognizer]) {
        [settings.scanSettings addRecognizerSettings:[self eudlRecognizerSettingsWithCountry:PPEudlCountryAny]];
    }
    
    if ([self shouldUseDocumentFaceRecognizer]) {
        [settings.scanSettings addRecognizerSettings:[self documentFaceRecognizerSettings]];
    }
    
    /** 4. Initialize the Scanning Coordinator object */
    
    PPCameraCoordinator *coordinator = [[PPCameraCoordinator alloc] initWithSettings:settings];
    
    return coordinator;
}

#pragma mark - PPScanDelegate

- (void)scanningViewControllerUnauthorizedCamera:(UIViewController<PPScanningViewController> *)scanningViewController {
    // Add any logic which handles UI when app user doesn't allow usage of the phone's camera
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController
                  didFindError:(NSError *)error {
    // Can be ignored. See description of the method
}

- (void)scanningViewControllerDidClose:(UIViewController<PPScanningViewController> *)scanningViewController {
        // As scanning view controller is presented full screen and modally, dismiss it
    [scanningViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController didOutputMetadata:(PPMetadata *)metadata {
    // Check if metadata obtained is image. You can set what type of image is outputed by setting different properties of PPMetadataSettings (currently, dewarpedImage is set at line 207)
    if ([metadata isKindOfClass:[PPImageMetadata class]]) {
        self.lastImageMetadata = (PPImageMetadata *)metadata;
    }
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController
              didOutputResults:(NSArray<PPRecognizerResult*> *)results {
    
    // Here you process scanning results. Scanning results are given in the array of PPRecognizerResult objects.
    // first, pause scanning until we process all the results
    [scanningViewController pauseScanning];
    
    [self returnResults:results cancelled:(results == nil)];
}

- (void)scanningViewController:(UIViewController<PPScanningViewController> *)scanningViewController didFinishDetectionWithResult:(PPDetectorResult *)result {
    if (result) {
        NSLog(@"finished with result: %@", result);
    }
}

#pragma mark - Used Recognizers


- (BOOL)shouldUseUsdlRecognizer {
    return [[self.options valueForKey:@"addUsdlRecognizer"] boolValue];
}

- (BOOL)shouldUseMrtdRecognizer {
    return [[self.options valueForKey:@"addMrtdRecognizer"] boolValue];
}

- (BOOL)shouldUseEudlRecognizer {
    return [[self.options valueForKey:@"addEudlRecognizer"] boolValue];
}

- (BOOL)shouldUseDocumentFaceRecognizer {
    return [[self.options valueForKey:@"addDocumentFaceRecognizer"] boolValue];
}

#pragma mark - Utils

- (void)setDictionary:(NSMutableDictionary *)dict withUsdlResult:(PPUsdlRecognizerResult *)usdlResult {
    [dict setObject:[usdlResult getAllStringElements] forKey:@"fields"];
    [dict setObject:@"USDL result" forKey:@"resultType"];
}

- (void)setDictionary:(NSMutableDictionary *)dict withMrtdRecognizerResult:(PPMrtdRecognizerResult *)mrtdResult {
    NSMutableDictionary *stringElements = [NSMutableDictionary dictionaryWithDictionary:[mrtdResult getAllStringElements]];
    [stringElements setObject:[mrtdResult rawDateOfBirth] forKey:@"DateOfBirth"];
    [stringElements setObject:[mrtdResult rawDateOfExpiry] forKey:@"DateOfExpiry"];
    [dict setObject:stringElements forKey:@"fields"];
    [dict setObject:[mrtdResult mrzText] forKey:@"raw"];
    [dict setObject:@"MRTD result" forKey:@"resultType"];
}

- (void)setDictionary:(NSMutableDictionary *)dict withEudlRecognizerResult:(PPEudlRecognizerResult *)eudlResult {
    [dict setObject:[eudlResult getAllStringElements] forKey:@"fields"];
    [dict setObject:@"EUDL result" forKey:@"resultType"];
}

- (void)setDictionary:(NSMutableDictionary *)dict withDocumentFaceResult:(PPDocumentFaceRecognizerResult *)documentFaceResult {
    [dict setObject:[documentFaceResult getAllStringElements] forKey:@"fields"];
    [dict setObject:@"DocumentFace result" forKey:@"resultType"];
}

- (void)returnResults:(NSArray *)results cancelled:(BOOL)cancelled {
    NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
    [resultDict setObject:[NSNumber numberWithInt:(cancelled ? 1 : 0)] forKey:@"cancelled"];
    
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    
    for (PPRecognizerResult *result in results) {
        
        if ([result isKindOfClass:[PPUsdlRecognizerResult class]]) {
            PPUsdlRecognizerResult *usdlResult = (PPUsdlRecognizerResult *)result;
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [self setDictionary:dict withUsdlResult:usdlResult];
            
            [resultArray addObject:dict];
        }
        
        
        if ([result isKindOfClass:[PPMrtdRecognizerResult class]]) {
            PPMrtdRecognizerResult *mrtdDecoderResult = (PPMrtdRecognizerResult *)result;
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [self setDictionary:dict withMrtdRecognizerResult:mrtdDecoderResult];
            
            [resultArray addObject:dict];
        }
        
        if ([result isKindOfClass:[PPEudlRecognizerResult class]]) {
            PPEudlRecognizerResult *eudlDecoderResult = (PPEudlRecognizerResult *)result;
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [self setDictionary:dict withEudlRecognizerResult:eudlDecoderResult];
            
            [resultArray addObject:dict];
        }
        
        if ([result isKindOfClass:[PPDocumentFaceRecognizerResult class]]) {
            PPDocumentFaceRecognizerResult *documentFaceResult = (PPDocumentFaceRecognizerResult *)result;
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [self setDictionary:dict withDocumentFaceResult:documentFaceResult];
            
            [resultArray addObject:dict];
        }
    }
    
    if ([resultArray count] > 0) {
        [resultDict setObject:resultArray forKey:@"resultList"];
    }
    
    if (!cancelled) {
        UIImage *image = self.lastImageMetadata.image;
        if (image) {
            NSData *imageData = UIImageJPEGRepresentation(self.lastImageMetadata.image, 0.9f);
            NSString *encodedImage = [NSString stringWithFormat:@"%@%@", @"data:image/jpg;base64,", [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
            [resultDict setObject:encodedImage
                           forKey:@"resultImage"];
        }
    }
    
    [self finishWithScanningResults:@[[NSNull null], resultDict]];

}

- (void) reset {
    self.callback = nil;
    self.options = nil;
}


- (void) dismissScanningView {
    [self reset];
    [[self getRootViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void) finishWithScanningResults:(NSArray*) results {
    if (self.callback && results) {
        self.callback(results);
    }
        
    [self dismissScanningView];
}

- (UIViewController*) getRootViewController {
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    return rootViewController;
}

- (PPMrtdRecognizerSettings *)mrtdRecognizerSettings {
    
    PPMrtdRecognizerSettings *mrtdRecognizerSettings = [[PPMrtdRecognizerSettings alloc] init];
    
    /********* All recognizer settings are set to their default values. Change accordingly. *********/
    
    
    // Setting this will give you the chance to parse MRZ result, if Mrtd recognizer wasn't
    // successful in parsing (this can happen since MRZ isn't always formatted accoring to ICAO Document 9303 standard.
    // @see http://www.icao.int/Security/mrtd/pages/Document9303.aspx
    mrtdRecognizerSettings.allowUnparsedResults = NO;
    
    // This property is useful if you're at the same time obtaining Dewarped image metadata, since it allows you to obtain dewarped and
    // cropped
    // images of MRTD documents. Dewarped images are returned to scanningViewController:didOutputMetadata: callback,
    // as PPImageMetadata objects with name @"MRTD"
    
    if (self.shouldReturnCroppedDocument) {
        mrtdRecognizerSettings.dewarpFullDocument = YES;
    } else {
        mrtdRecognizerSettings.dewarpFullDocument = NO;
    }
    
    return mrtdRecognizerSettings;
}


- (PPEudlRecognizerSettings *)eudlRecognizerSettingsWithCountry:(PPEudlCountry)country {
    
    PPEudlRecognizerSettings *eudlRecognizerSettings = [[PPEudlRecognizerSettings alloc] initWithEudlCountry:country];
    
    /********* All recognizer settings are set to their default values. Change accordingly. *********/
    
    /**
     * If YES, document issue date will be extracted
     * Set this to NO if youre not interested in this data to speed up the scanning process!
     */
    eudlRecognizerSettings.extractIssueDate = YES;
    
    /**
     * If YES, document expiry date will be extracted
     * Set this to NO if youre not interested in this data to speed up the scanning process!
     */
    eudlRecognizerSettings.extractExpiryDate = YES;
    
    /**
     * If YES, owner's address will be extracted
     * Set this to NO if youre not interested in this data to speed up the scanning process!
     */
    eudlRecognizerSettings.extractAddress = YES;
    
    // This property is useful if you're at the same time obtaining Dewarped image metadata, since it allows you to obtain dewarped and
    // cropped
    // images of MRTD documents. Dewarped images are returned to scanningViewController:didOutputMetadata: callback,
    // as PPImageMetadata objects with name @"MRTD"
    
    if (self.shouldReturnCroppedDocument) {
        eudlRecognizerSettings.showFullDocument = YES;
    } else {
        eudlRecognizerSettings.showFullDocument = NO;
    }
    
    return eudlRecognizerSettings;
}

- (PPUsdlRecognizerSettings *)usdlRecognizerSettings {
    
    PPUsdlRecognizerSettings *usdlRecognizerSettings = [[PPUsdlRecognizerSettings alloc] init];
    
    /********* All recognizer settings are set to their default values. Change accordingly. *********/
    
    /**
     * Set this to YES to scan even barcode not compliant with standards
     * For example, malformed PDF417 barcodes which were incorrectly encoded
     * Use only if necessary because it slows down the recognition process
     */
    usdlRecognizerSettings.scanUncertain = NO;
    
    /**
     * Set this to YES to scan barcodes which don't have quiet zone (white area) around it
     * Disable if you need a slight speed boost
     */
    usdlRecognizerSettings.allowNullQuietZone = YES;
    
    /**
     * Set this to YES if you want to scan 1D barcodes if they are present on the DL.
     * If NO, just PDF417 barcode will be scanned.
     */
    usdlRecognizerSettings.scan1DCodes = NO;
    
    return usdlRecognizerSettings;
}

- (PPDocumentFaceRecognizerSettings *)documentFaceRecognizerSettings {
    
    PPDocumentFaceRecognizerSettings *documentFaceReconizerSettings = [[PPDocumentFaceRecognizerSettings alloc] init];
    
    // This property is useful if you're at the same time obtaining Dewarped image metadata, since it allows you to obtain dewarped and
    // cropped
    // images of MRTD documents. Dewarped images are returned to scanningViewController:didOutputMetadata: callback,
    // as PPImageMetadata objects with name @"MRTD"
    
    if (self.shouldReturnCroppedDocument) {
        documentFaceReconizerSettings.returnFullDocument = YES;
    } else {
        documentFaceReconizerSettings.returnFullDocument = NO;
    }
    
    return documentFaceReconizerSettings;
}

@end
