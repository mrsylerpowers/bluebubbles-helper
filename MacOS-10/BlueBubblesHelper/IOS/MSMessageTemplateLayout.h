//
//  MSMessageTemplateLayout.h
//  BlueBubblesHelper
//
//  Created by justk on 1/4/23.
//  Copyright © 2023 BlueBubbleMessaging. All rights reserved.
//

#ifndef MSMessageTemplateLayout_h
#define MSMessageTemplateLayout_h
#import <objc/NSObject.h>
#import "MSMessageLayout.h"
@class NSString, NSURL, UIImage, NSData;

@interface MSMessageTemplateLayout : MSMessageLayout <NSSecureCoding> {

    NSString* _caption;
    NSString* _subcaption;
    NSString* _trailingCaption;
    NSString* _trailingSubcaption;
    NSURL* _mediaFileURL;
    UIImage* _image;
    NSData* _mediaData;
    NSString* _mediaType;
    NSString* _imageTitle;
    NSString* _imageSubtitle;
}
@property (nonatomic,retain) NSData * mediaData;                       //@synthesize mediaData=_mediaData - In the implementation block
@property (nonatomic,retain) NSString * mediaType;                     //@synthesize mediaType=_mediaType - In the implementation block
@property (nonatomic,copy) NSString * caption;                         //@synthesize caption=_caption - In the implementation block
@property (nonatomic,copy) NSString * subcaption;                      //@synthesize subcaption=_subcaption - In the implementation block
@property (nonatomic,copy) NSString * trailingCaption;                 //@synthesize trailingCaption=_trailingCaption - In the implementation block
@property (nonatomic,copy) NSString * trailingSubcaption;              //@synthesize trailingSubcaption=_trailingSubcaption - In the implementation block
@property (nonatomic,retain) UIImage * image;                          //@synthesize image=_image - In the implementation block
@property (nonatomic,copy) NSURL * mediaFileURL;                       //@synthesize mediaFileURL=_mediaFileURL - In the implementation block
@property (nonatomic,copy) NSString * imageTitle;                      //@synthesize imageTitle=_imageTitle - In the implementation block
@property (nonatomic,copy) NSString * imageSubtitle;                   //@synthesize imageSubtitle=_imageSubtitle - In the implementation block
+(BOOL)supportsSecureCoding;
-(NSString *)caption;
-(void)setCaption:(NSString *)arg1 ;
-(id)init;
-(void)setImage:(UIImage *)arg1 ;
-(id)initWithCoder:(id)arg1 ;
-(void)encodeWithCoder:(id)arg1 ;
-(BOOL)isEqual:(id)arg1 ;
-(unsigned long long)hash;
-(UIImage *)image;
-(id)copyWithZone:(NSZone*)arg1 ;
-(NSString *)mediaType;
-(void)setMediaType:(NSString *)arg1 ;
-(void)setTrailingCaption:(NSString *)arg1 ;
-(void)setTrailingSubcaption:(NSString *)arg1 ;
-(void)setImageTitle:(NSString *)arg1 ;
-(void)setImageSubtitle:(NSString *)arg1 ;
-(NSString *)subcaption;
-(NSString *)trailingCaption;
-(NSString *)trailingSubcaption;
-(NSString *)imageTitle;
-(NSString *)imageSubtitle;
-(NSURL *)mediaFileURL;
-(void)setMediaFileURL:(NSURL *)arg1 ;
-(void)setSubcaption:(NSString *)arg1 ;
-(NSData *)mediaData;
-(void)setMediaData:(NSData *)arg1 ;
@end

#endif /* MSMessageTemplateLayout_h */
@implementation MSMessageTemplateLayout

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    <#code#>
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    <#code#>
}

@end
