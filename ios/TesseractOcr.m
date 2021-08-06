#import "TesseractOcr.h"
#import <TesseractOCR/TesseractOCR.h>

@implementation TesseractOcr {
  bool hasListeners;
}

- (void)startObserving {
  hasListeners = YES;
}

- (void)stopObserving {
  hasListeners = NO;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[ @"onProgressChange" ];
}

- (void)sendEvent:(NSNumber *)progress {
  if (hasListeners) {
    [self sendEventWithName:@"onProgressChange" body:@{@"percent" : progress}];
  }
}

RCT_EXPORT_MODULE();

// test
RCT_EXPORT_METHOD(recognize
                  : (NSString *)imagePath
                  : (NSString *)lang
                  : (NSDictionary *)options
                  : (RCTPromiseResolveBlock)resolve
                  : (RCTPromiseRejectBlock)reject) {

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // Load the image
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imagePath]];
    UIImage *image = [UIImage imageWithData:imageData];

    // get the iterator level
    G8PageIteratorLevel level = [self getIteratorLevel:options[@"level"]];

    // Create your G8Tesseract object using the initWithLanguage method:
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:lang];
    [tesseract setImage:image];

    tesseract.delegate = self;

    // allow list and deny list
    if ([options[@"allowList"] length]) {
      tesseract.charWhitelist = options[@"allowList"];
    }

    if ([options[@"denyList"] length]) {
      tesseract.charBlacklist = options[@"denyList"];
    }

    [tesseract recognize];

    NSLog(@"%@", [tesseract recognizedText]);

    dispatch_async(dispatch_get_main_queue(), ^{
      // Resolve the method with the scan result
      // (Returns a Javascript Promise object)
      resolve([tesseract recognizedText]);
    });
  });
}

- (G8PageIteratorLevel)getIteratorLevel:(NSString *)level {
  // Why the hell does Obj-C not allow switching on a string?
  if ([level isEqual:@"block"]) {
    return G8PageIteratorLevelBlock;
  } else if ([level isEqual:@"paragraph"]) {
    return G8PageIteratorLevelParagraph;
  } else if ([level isEqual:@"line"]) {
    return G8PageIteratorLevelTextline;
  } else if ([level isEqual:@"symbol"]) {
    return G8PageIteratorLevelSymbol;
  } else {
    // word (default)
    return G8PageIteratorLevelWord;
  }
}

- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
  NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
  [self sendEvent:@(tesseract.progress)];
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
  return NO; // return YES, if you need to interrupt tesseract before it finishes
}

@end
