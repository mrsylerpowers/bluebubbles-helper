//
//  MSMessageLayout.h
//  BlueBubblesHelper
//
//  Created by justk on 1/4/23.
//  Copyright © 2023 BlueBubbleMessaging. All rights reserved.
//

#ifndef MSMessageTemplateLayout_h
#define MSMessageTemplateLayout_h

@class MSMessageTemplateLayout;

@interface MSMessageLiveLayout : MSMessageLayout <NSSecureCoding> {

    MSMessageTemplateLayout* _alternateLayout;
}
@property (nonatomic,readonly) MSMessageTemplateLayout * alternateLayout;              //@synthesize alternateLayout=_alternateLayout - In the implementation block
+(BOOL)supportsSecureCoding;
-(id)init;
-(id)initWithCoder:(id)arg1 ;
-(void)encodeWithCoder:(id)arg1 ;
-(id)copyWithZone:(NSZone*)arg1 ;
-(id)initWithAlternateLayout:(id)arg1 ;
-(MSMessageTemplateLayout *)alternateLayout;
@end
#endif /* MSMessageTemplateLayout_h */
