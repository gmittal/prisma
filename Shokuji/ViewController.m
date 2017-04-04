//
//  ViewController.m

#import "ViewController.h"
#import "DetailView.h"
#import "ZXingObjC.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/CGImageProperties.h>
#import <HealthKit/HealthKit.h>

@interface ViewController ()

@end

@implementation ViewController
{
    AVCaptureStillImageOutput* stillImageOutput;
    UIImageView* capturedView;
    UIButton* capture;
    UILabel* label;
}

#define dWidth self.view.frame.size.width
#define dHeight self.view.frame.size.height

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    

//    UIImageView* cameraview
    // Do any additional setup after loading the view, typically from a nib.
}

-(void) viewDidAppear:(BOOL)animated
{
    
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetHigh;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    [session addInput:input];
    AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    newCaptureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    newCaptureVideoPreviewLayer.frame = CGRectMake(0, 0, dWidth, dHeight);
    //    newCaptureVideoPreviewLayer.la
    [self.view.layer addSublayer:newCaptureVideoPreviewLayer];
    [session startRunning];
    
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    [session addOutput:stillImageOutput];
    
    
    UIButton* chevron = [[UIButton alloc] initWithFrame:CGRectMake(10, 20, 40, 40)];
//    chevron.backgroundColor = [UIColor blueColor];
    [chevron setImage:[UIImage imageNamed:@"chevron-left.png"] forState:UIControlStateNormal];
//    chevron.imageView.image = [UIImage imageNamed:@"chevron-left.png"];
    [self.view addSubview:chevron];
    [chevron addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    
    
    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(0, -10, self.view.frame.size.width, 100)];
    title.font = [UIFont fontWithName:@"Hybrea" size:40];
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = [UIColor whiteColor];
    title.text = @"Prism";
//    [self.view addSubview:title];
    
    
    float width = 75;
    float height = 75;
    capture = [[UIButton alloc] initWithFrame:CGRectMake(dWidth/2 - (width/2), dHeight - height*1.3, width, height)];

    [capture setImage:[UIImage imageNamed:@"camera-button.png"] forState:UIControlStateNormal];
    
    capture.backgroundColor = [UIColor clearColor];
    
    label = [[UILabel alloc] initWithFrame:capture.frame];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
    [self.view addSubview:label];
    
    [self.view addSubview:capture];
    
    [capture addTarget:self action:@selector(capture) forControlEvents:UIControlEventTouchUpInside];
    
}



-(void)close
{
    [self dismissViewControllerAnimated:NO completion:^{}];
    
}

-(void) capture
{
    [[NSUserDefaults standardUserDefaults] setInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"snap"]+1 forKey:@"snap"];
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection)
        {
            break;
        }
    }
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
         if (exifAttachments)
         {
         } else {
             NSLog(@"no attachments");
         }
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *image = [[UIImage alloc] initWithData:imageData];
         
       
         NSData *imageData2 = UIImageJPEGRepresentation(image, 0.0);
         NSString *encodedString = [imageData2 base64Encoding];
             
             NSLog(@"%d",encodedString.length);
         
         
         encodedString = [encodedString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
         
         NSString *post = [NSString stringWithFormat:@"image=%@",encodedString];
         NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
         
         NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
         
         NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
         [request setURL:[NSURL URLWithString:@"http://usekenko.co/food-analysis"]];
         [request setHTTPMethod:@"POST"];
         [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
         [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
         [request setHTTPBody:postData];
         
         

         DetailView* dv = [[DetailView alloc] init];
         [dv setParent:self];
         dv.modalPresentationStyle = UIModalPresentationOverCurrentContext;
         self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
         
         [dv sendRequest:request];
         [dv setImage:image];
         
         
         UIView* v = [[UIView alloc] initWithFrame: CGRectMake(0, 0, dWidth, dHeight)];
         [self.view addSubview: v];
         v.backgroundColor = [UIColor whiteColor];
         [UIView animateWithDuration:0.2 delay:0.0 options:
          UIViewAnimationOptionCurveEaseIn animations:^{
              v.backgroundColor = [UIColor clearColor];
          } completion:^ (BOOL completed) {
              [v removeFromSuperview];
              [self presentViewController:dv animated:NO completion:^{}];
          }];
             
     }];
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


-(void) reload
{
    label.layer.opacity = 1;
    capture.layer.opacity = 1;
}


-(void) flashScreen {
    
}

-(void) detailScreen
{
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
