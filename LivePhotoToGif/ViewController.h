//
//  ViewController.h
//  LivePhotoToGif
//
//  Created by Piyush Kachariya on 4/10/16.
//  Copyright © 2016 KachariyaCo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MessageUI/MessageUI.h>

@interface ViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,MFMailComposeViewControllerDelegate>

@property(nonatomic,retain) IBOutlet UIButton *btnVideoToImage;
@property(nonatomic,retain) IBOutlet UIButton *btnVideoToVideo;
@property(nonatomic,retain) IBOutlet UIButton *btnVideoToGIF;
@property(nonatomic,retain) IBOutlet UIButton *btnSelectLivePhoto;
@property(nonatomic,retain) IBOutlet UIImageView *FrameImage;

@end

