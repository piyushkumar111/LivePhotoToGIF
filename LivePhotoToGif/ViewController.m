//
//  ViewController.m
//  LivePhotoToGif
//
//  Created by Piyush Kachariya on 4/10/16.
//  Copyright © 2016 KachariyaCo. All rights reserved.
//

#import "ViewController.h"
#import "SVProgressHUD/SVProgressHUD.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import "NSGIF.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController ()
{
    NSArray *aryGifframes;
    float floatGifTime;
    NSURL *videoURL;
    NSURL *photoURL;

}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    aryGifframes = [[NSMutableArray alloc]init];

    _btnVideoToGIF.layer.cornerRadius = 12;
    _btnVideoToGIF.clipsToBounds=YES;
    _btnVideoToGIF.layer.borderWidth = 1.0f;
    _btnVideoToGIF.layer.borderColor = [[UIColor whiteColor] CGColor];
    [_btnVideoToGIF setBackgroundColor:[UIColor orangeColor]];
    
    _btnVideoToImage.layer.cornerRadius = 12;
    _btnVideoToImage.clipsToBounds=YES;
    _btnVideoToImage.layer.borderWidth = 1.0f;
    _btnVideoToImage.layer.borderColor = [[UIColor whiteColor] CGColor];
    [_btnVideoToImage setBackgroundColor:[UIColor orangeColor]];
    
    _btnVideoToVideo.layer.cornerRadius = 12;
    _btnVideoToVideo.clipsToBounds=YES;
    _btnVideoToVideo.layer.borderWidth = 1.0f;
    _btnVideoToVideo.layer.borderColor = [[UIColor whiteColor] CGColor];
    [_btnVideoToVideo setBackgroundColor:[UIColor orangeColor]];

    _btnSelectLivePhoto.layer.cornerRadius = 12;
    _btnSelectLivePhoto.clipsToBounds=YES;
    _btnSelectLivePhoto.layer.borderWidth = 1.0f;
    _btnSelectLivePhoto.layer.borderColor = [[UIColor whiteColor] CGColor];
    [_btnSelectLivePhoto setBackgroundColor:[UIColor orangeColor]];

    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Helper methods for Extracting images from GIF

static void createImagesAndDelays(CGImageSourceRef source, size_t count, CGImageRef imagesOut[count], int delayCentisecondsOut[count]) {
    for (size_t i = 0; i < count; ++i) {
        imagesOut[i] = CGImageSourceCreateImageAtIndex(source, i, NULL);
        delayCentisecondsOut[i] = delayCentisecondsForImageAtIndex(source, i);
    }
}

static int sum(size_t const count, int const *const values) {
    int theSum = 0;
    for (size_t i = 0; i < count; ++i) {
        theSum += values[i];
    }
    return theSum;
}

static NSArray *frameArray(size_t const count, CGImageRef const images[count], int const delayCentiseconds[count], int const totalDurationCentiseconds) {
    int const gcd = vectorGCD(count, delayCentiseconds);
    size_t const frameCount = totalDurationCentiseconds / gcd;
    UIImage *frames[frameCount];
    for (size_t i = 0, f = 0; i < count; ++i) {
        UIImage *const frame = [UIImage imageWithCGImage:images[i]];
        for (size_t j = delayCentiseconds[i] / gcd; j > 0; --j) {
            frames[f++] = frame;
        }
    }
    return [NSArray arrayWithObjects:frames count:frameCount];
}

static int vectorGCD(size_t const count, int const *const values) {
    int gcd = values[0];
    for (size_t i = 1; i < count; ++i) {
        // Note that after I process the first few elements of the vector, `gcd` will probably be smaller than any remaining element.  By passing the smaller value as the second argument to `pairGCD`, I avoid making it swap the arguments.
        gcd = pairGCD(values[i], gcd);
    }
    return gcd;
}

static int pairGCD(int a, int b) {
    if (a < b)
        return pairGCD(b, a);
    while (true) {
        int const r = a % b;
        if (r == 0)
            return b;
        a = b;
        b = r;
    }
}

#if __has_feature(objc_arc)
#define toCF (__bridge CFTypeRef)
#define fromCF (__bridge id)
#else
#define toCF (CFTypeRef)
#define fromCF (id)
#endif

static int delayCentisecondsForImageAtIndex(CGImageSourceRef const source, size_t const i) {
    int delayCentiseconds = 1;
    CFDictionaryRef const properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
    if (properties) {
        CFDictionaryRef const gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
        if (gifProperties) {
            NSNumber *number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (number == NULL || [number doubleValue] == 0) {
                number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
            }
            if ([number doubleValue] > 0) {
                // Even though the GIF stores the delay as an integer number of centiseconds, ImageIO “helpfully” converts that to seconds for us.
                delayCentiseconds = (int)lrint([number doubleValue] * 100);
            }
        }
        CFRelease(properties);
    }
    return delayCentiseconds;
}

#pragma mark - Helper methods

-(void)setDownloadedImages
{
    UIImage *newImage1   = [aryGifframes objectAtIndex:0];
    _FrameImage.frame = CGRectMake((self.view.frame.size.width-newImage1.size.width)/2,(self.view.frame.size.height-newImage1.size.height)/2,newImage1.size.width, newImage1.size.height);
    
    if (newImage1.size.width >= self.view.frame.size.width)
    {
        float oldWidth = newImage1.size.width;
        float scaleFactor = (self.view.frame.size.width) / oldWidth;
        
        float newHeight = newImage1.size.height * scaleFactor;
        float newWidth = oldWidth * scaleFactor;
        
        _FrameImage.frame = CGRectMake((self.view.frame.size.width-newWidth)/2,(self.view.frame.size.height-newHeight)/2,newWidth,newHeight);
    }
    
    NSMutableArray *images = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= [aryGifframes count]; i++)
    {
        UIImage *image = [aryGifframes objectAtIndex:i-1];
        [images addObject:image];
    }
    
    _FrameImage.image = nil;
    _FrameImage.animationImages = [NSArray arrayWithArray:images];
    _FrameImage.animationDuration = floatGifTime * [aryGifframes count];
    _FrameImage.animationRepeatCount = 0;
    [_FrameImage startAnimating];
    [SVProgressHUD dismiss];
}

-(void)convertVideoToGif :(NSURL*)fileURL
{
    [NSGIF optimalGIFfromURL:fileURL loopCount:0 completion:^(NSURL *GifURL) {
        
        NSLog(@"Finished generating GIF: %@", GifURL);
        NSData *imageData=[NSData dataWithContentsOfURL:GifURL];
        
        CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
        size_t const count = CGImageSourceGetCount(source);
        CGImageRef images[count];
        int delayCentiseconds[count]; // in centiseconds
        
        createImagesAndDelays(source, count, images, delayCentiseconds);
        float const totalDurationCentiseconds = sum(count, delayCentiseconds);
        
        floatGifTime = (float)(totalDurationCentiseconds/(count*100));
        aryGifframes = frameArray(count, images, delayCentiseconds, totalDurationCentiseconds);
        [SVProgressHUD dismiss];
        [self setDownloadedImages];
    }];
}



- (void)exportAnimatedGif
{
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"animated.gif"];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path],
                                                                        kUTTypeGIF,
                                                                        [aryGifframes count],
                                                                        NULL);
    
    NSDictionary *frameProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:floatGifTime] forKey:(NSString *)kCGImagePropertyGIFDelayTime] forKey:(NSString *)kCGImagePropertyGIFDictionary];
    
    NSDictionary *gifProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount] forKey:(NSString *)kCGImagePropertyGIFDictionary];
    
    for (int i = 0; i<[aryGifframes count];i++)
    {
        UIImage *bgImage  = [aryGifframes objectAtIndex:i];

        UIGraphicsBeginImageContextWithOptions(bgImage.size, FALSE, 0.0);
        [bgImage drawInRect:CGRectMake( 0, 0, bgImage.size.width, bgImage.size.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        CGImageDestinationAddImage(destination,newImage.CGImage, (CFDictionaryRef)frameProperties);
        
    }
    
    CGImageDestinationSetProperties(destination, (CFDictionaryRef)gifProperties);
    CGImageDestinationFinalize(destination);
    CFRelease(destination);
    
    
    NSLog(@"animated GIF file created at %@", path);
    
    [self emailGIFFromLivePhoto:path];

}

#pragma mark - UIImagePickerController Delegate method

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ( [mediaType isEqualToString:@"public.movie" ])
    {
        [SVProgressHUD showWithStatus:@"Loading..." maskType:SVProgressHUDMaskTypeGradient];
        
        NSLog(@"Picked a movie at URL %@",  [info objectForKey:UIImagePickerControllerMediaURL]);
        NSURL *fileURL =  [info objectForKey:UIImagePickerControllerMediaURL];
        NSLog(@"> %@", [fileURL absoluteString]);
        [self convertVideoToGif:fileURL];
    }
    else
    {
        PHLivePhoto *livePhoto = [info objectForKey:UIImagePickerControllerLivePhoto];
        
        [SVProgressHUD showWithStatus:@"Loading..." maskType:SVProgressHUDMaskTypeGradient];
        
        if(livePhoto)
        {
            NSArray *resourceArray = [PHAssetResource assetResourcesForLivePhoto:livePhoto];
            PHAssetResourceManager *arm = [PHAssetResourceManager defaultManager];
            
            
            PHAssetResource *assetResource = resourceArray[0];
            
            // Create path.
            NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString* filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.jpg"];
            photoURL = [[NSURL alloc] initFileURLWithPath:filePath];
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            
            [arm writeDataForAssetResource:assetResource toFile:photoURL options:nil completionHandler:^(NSError * _Nullable error) {
                NSLog(@"error: %@",error);
            }];
            
            
            assetResource = resourceArray[1];
            
            // Create path.
            filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.mov"];
            videoURL = [[NSURL alloc] initFileURLWithPath:filePath];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            
            [arm writeDataForAssetResource:assetResource toFile:videoURL options:nil completionHandler:^(NSError * _Nullable error)
             {
                 NSLog(@"videoURL: %@",videoURL);
                 NSLog(@"error: %@",error);
                 [self convertVideoToGif:videoURL];
             }];
        }
        else
        {
            // create an alert view
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Not a Live Photo" message:@"Sadly this is a standard UIImage so we can't show it in our Live Photo View. Try another one." preferredStyle:UIAlertControllerStyleAlert];
            
            // add a single action
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"Thanks, Phone!" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:action];
            
            // and display it
            [self presentViewController:alert animated:YES completion:nil];
            
            
            [SVProgressHUD dismiss];
        }
    }
}

#pragma mark MFMailComposeViewController Delegate Methods

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    NSString *message;
    switch (result)
    {
        case MFMailComposeResultCancelled:
            message = @"Result: canceled";
            break;
        case MFMailComposeResultSaved:
            message = @"Result: saved";
            break;
        case MFMailComposeResultSent:
            message = @"Result: sent";
            break;
        case MFMailComposeResultFailed:
            message = @"Result: failed";
            break;
        default:
            message = @"Result: not sent";
            break;
    }
    
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"E-Mail" message:message delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - UIButton clicked

-(IBAction)btnShareGIFCLicked:(id)sender
{
    if ([sender tag] == 1)
    {
        [self emailPhotoFromGif:photoURL];
    }
    
    if ([sender tag] == 2)
    {
        [self emailPhotoFromVideo:videoURL];
    }
    
    if ([sender tag] == 3)
    {
        [self exportAnimatedGif];
    }
}

-(IBAction)btnLivePhotoGIFClicked:(id)sender;
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = NO;
    
    NSArray *mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeLivePhoto,(NSString *)kUTTypeGIF];
    imagePicker.mediaTypes = mediaTypes;
    
    [self presentViewController:imagePicker animated:YES completion:nil];}

#pragma mark - Shar GIF option

- (BOOL) connectedToNetwork
{
    NSURLRequest *imageReq = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]];
    NSData *returnData = [NSURLConnection sendSynchronousRequest:imageReq returningResponse:nil error:nil];
    if ([returnData length] > 0)
    {
       return YES;
    }
    return NO;
}

-(IBAction)emailPhotoFromGif :(NSURL *)path
{
    
    if([self connectedToNetwork])
    {
        // We must always check whether the current device is configured for sending emails
        Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
        if (mailClass != nil)
        {
            // We must always check whether the current device is configured for sending emails
            if ([mailClass canSendMail])
            {
                
                NSData *data = [NSData dataWithContentsOfURL:path];
                UIImage *image = [[UIImage alloc] initWithData:data];
                
                
                MFMailComposeViewController *composeVC = [[MFMailComposeViewController alloc] init];
                composeVC.mailComposeDelegate = self;
                [composeVC setSubject:@"Check out this cool GIF"];
                
                
                UIImage *artworkImage = image;
                
                NSData *artworkJPEGRepresentation = nil;
                if (artworkImage)
                {
                    artworkJPEGRepresentation = UIImageJPEGRepresentation(artworkImage, 1);
                }
                
                if (artworkJPEGRepresentation)
                {
                    [composeVC addAttachmentData:artworkJPEGRepresentation mimeType:@"image/jpeg" fileName:@" image.jpg"];
                }
                NSString *emailBody = [NSString stringWithFormat:@"GIF from Live Photo"];
                
                [composeVC setMessageBody:emailBody isHTML:YES];
                [self presentViewController:composeVC animated:YES completion:nil];
            }
            else
            {
                [SVProgressHUD showWithStatus:@"Your mail is not configure."];

            }
        }
        else
        {
            [SVProgressHUD showWithStatus:@"Your mail is not configure."];
        }
    }
    else
    {
        [SVProgressHUD showWithStatus:@"The Internet connection appears to be offline."];
    }
}

-(IBAction)emailPhotoFromVideo :(NSURL *)path
{
    
    if([self connectedToNetwork])
    {
        // We must always check whether the current device is configured for sending emails
        Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
        if (mailClass != nil)
        {
            // We must always check whether the current device is configured for sending emails
            if ([mailClass canSendMail])
            {
                
                MFMailComposeViewController *composeVC = [[MFMailComposeViewController alloc] init];
                composeVC.mailComposeDelegate = self;
                [composeVC setSubject:@"Check out this cool GIF"];
                [composeVC addAttachmentData:[NSData dataWithContentsOfURL:videoURL] mimeType:@"video/quicktime" fileName:@"Image.mov"];
                
                
                NSString *emailBody = [NSString stringWithFormat:@"GIF from Live Photo"];
                
                [composeVC setMessageBody:emailBody isHTML:YES];
                [self presentViewController:composeVC animated:YES completion:nil];
            }
            else
            {
                [SVProgressHUD showWithStatus:@"Your mail is not configure."];
            }
        }
        else
        {
            [SVProgressHUD showWithStatus:@"Your mail is not configure."];
        }
    }
    else
    {
        [SVProgressHUD showWithStatus:@"The Internet connection appears to be offline."];
    }
}

-(IBAction)emailGIFFromLivePhoto :(NSString *)path
{
    
    if([self connectedToNetwork])
    {
        // We must always check whether the current device is configured for sending emails
        Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
        if (mailClass != nil)
        {
            // We must always check whether the current device is configured for sending emails
            if ([mailClass canSendMail])
            {
                
                UIImage *image = [UIImage imageWithContentsOfFile:path];
                
                MFMailComposeViewController *composeVC = [[MFMailComposeViewController alloc] init];
                composeVC.mailComposeDelegate = self;
                [composeVC setSubject:@"Check out this cool GIF"];
                
                //NSString *emailBody = LINK_AppLinkAppleEmail;//add code
                
                
                UIImage *artworkImage = image;
                
                NSData *artworkJPEGRepresentation = nil;
                if (artworkImage)
                {
                    artworkJPEGRepresentation = UIImageJPEGRepresentation(artworkImage, 1);
                }
                
                NSString *filePath1;
                
                if (artworkJPEGRepresentation)
                {
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *documentsPath = [paths objectAtIndex:0];
                    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"animated.gif"];
                    filePath1 = filePath;
                    
                    NSData *imageData = [[NSData alloc] initWithContentsOfFile:filePath];
                    [composeVC addAttachmentData:imageData mimeType:@"image/gif" fileName:@"pic.gif"];
                }
                NSString *emailBody = [NSString stringWithFormat:@"GIF from Live Photo"];
                
                [composeVC setMessageBody:emailBody isHTML:YES];
                [self presentViewController:composeVC animated:YES completion:nil];
            }
            else
            {
                [SVProgressHUD showWithStatus:@"Your mail is not configure."];
            }
        }
        else
        {
            [SVProgressHUD showWithStatus:@"Your mail is not configure."];
        }
    }
    else
    {
        [SVProgressHUD showWithStatus:@"The Internet connection appears to be offline."];
    }
}


@end
