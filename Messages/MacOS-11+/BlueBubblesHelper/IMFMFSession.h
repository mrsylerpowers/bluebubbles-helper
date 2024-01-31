// Headers generated with ktool v1.4.0
// https://github.com/cxnder/ktool | pip3 install k2l
// Platform: IOS | Minimum OS: 16.0.0 | SDK: 16.0.0


#ifndef IMFMFSESSION_H
#define IMFMFSESSION_H

@class FMFDevice, NSString, FMFSession;

#import <Foundation/Foundation.h>

#import "FMFSessionDelegate-Protocol.h"

@interface IMFMFSession : NSObject <FMFSessionDelegate>



@property (retain, nonatomic) FMFDevice *activeDevice; // ivar: _activeDevice
@property (readonly, copy) NSString *debugDescription;
@property (readonly, copy) NSString *description;
@property (nonatomic, readonly) bool disableLocationSharing;
@property (nonatomic, retain) NSString *establishingAccountID;
@property (nonatomic) unsigned long long fmfProvisionedState;
@property (nonatomic, retain) id fmlSession;
@property (readonly) unsigned long long hash;
@property (nonatomic, readonly) bool restrictLocationSharing;
@property (nonatomic, retain) FMFSession *session;
@property (readonly) Class superclass;

+ (id)sharedInstance;

- (Class)__FMFSessionClass;
- (Class)__FMLSessionClass;
- (id)_accountStore;
- (void)_accountStoreDidChangeNotification:(id)arg1;
- (id)_bestAccountForAddresses:(id)arg1;
- (id)_callerIDForChat:(id)arg1;
- (bool)_canShareLocationWithFMLHandle:(id)arg1 isFromGroup:(bool)arg2;
- (void)_configureFindMyLocateSession;
- (id)_dateFromShareDuration:(long long)arg1;
- (void)_initializeFindMySessionIfInAllowedProcess;
- (void)_postNotification:(id)arg1 object:(id)arg2 userInfo:(id)arg3;
- (void)_postRelationshipStatusDidChangeNotificationWithIMFindMyHandle:(id)arg1;
- (void)_setUpFindMyLocateSessionCallbacks;
- (void)_startFMLSessionMonitoring;
- (void)_startRefreshingLocationForFMLHandles:(id)arg1 priority:(long long)arg2 isFromGroup:(bool)arg3;
- (void)_startSharingWithFMFHandles:(id)arg1 inChat:(id)arg2 untilDate:(id)arg3;
- (void)_startSharingWithFMLHandles:(id)arg1 inChat:(id)arg2 withDuration:(long long)arg3;
- (void)_stopSharingWithFMFHandles:(id)arg1 inChat:(id)arg2;
- (void)_stopSharingWithFMLHandles:(id)arg1 inChat:(id)arg2;
- (void)_stopTrackingLocationForFMLHandles:(id)arg1 priority:(long long)arg2 isFromGroup:(bool)arg3;
- (void)_updateActiveDevice;
- (id)activeDevice;
- (bool)allChatParticipantsFollowingMyLocation:(id)arg1;
- (bool)allChatParticipantsSharingLocationWithMe:(id)arg1;
- (id)allSiblingFindMyHandlesForChat:(id)arg1;
- (bool)chatHasParticipantsFollowingMyLocation:(id)arg1;
- (bool)chatHasParticipantsSharingLocationWithMe:(id)arg1;
- (bool)chatHasSiblingParticipantsSharingLocationWithMe:(id)arg1;
- (void)dealloc;
- (void)didChangeActiveLocationSharingDevice:(id)arg1;
- (void)didReceiveLocation:(id)arg1;
- (void)didReceiveLocationForHandle:(id)arg1;
- (void)didStartAbilityToGetLocationForHandle:(id)arg1;
- (void)didStartSharingMyLocationWithHandle:(id)arg1;
- (void)didStopAbilityToGetLocationForHandle:(id)arg1;
- (void)didStopSharingMyLocationWithHandle:(id)arg1;
- (void)didUpdateHidingStatus:(bool)arg1;
- (bool)disableLocationSharing;
- (id)establishingAccountID;
- (bool)findMyHandleIsFollowingMyLocation:(id)arg1;
- (bool)findMyHandleIsSharingLocationWithMe:(id)arg1;
- (id)findMyHandlesForChat:(id)arg1;
- (id)findMyHandlesSharingLocationWithMe;
- (id)findMyLocationForFindMyHandle:(id)arg1;
- (id)findMyLocationForHandle:(id)arg1;
- (id)findMyLocationForHandleOrSibling:(id)arg1;
- (id)findMyURLForChat:(id)arg1;
- (id)fmfGroupIdGroup;
- (id)fmfGroupIdOneToOne;
- (unsigned long long)fmfProvisionedState;
- (id)fmlSession;
- (void)friendshipRequestReceived:(id)arg1;
- (void)friendshipWasRemoved:(id)arg1;
- (bool)handleIsFollowingMyLocation:(id)arg1;
- (bool)handleIsSharingLocationWithMe:(id)arg1;
- (bool)imIsProvisionedForLocationSharing;
- (id)init;
-(id)locationForFMFHandle:(id)arg0 ;
-(id)locationForHandle:(id)arg0 ;
-(id)locationForHandleOrSibling:(id)arg0 ;
- (void)makeThisDeviceActiveDevice;
- (void)refreshLocationForChat:(id)arg1;
- (void)refreshLocationForHandle:(id)arg1 inChat:(id)arg2;
- (bool)restrictLocationSharing;
- (void)sendMappingPacket:(id)arg1 toHandle:(id)arg2;
- (id)session;
- (void)setActiveDevice:(id)arg1;
- (void)setEstablishingAccountID:(id)arg1;
- (void)setFmfProvisionedState:(unsigned long long)arg1;
- (void)setFmlSession:(id)arg1;
- (void)setSession:(id)arg1;
- (void)startSharingWithChat:(id)arg1 withDuration:(long long)arg2;
- (void)startSharingWithHandle:(id)arg1 inChat:(id)arg2 withDuration:(long long)arg3;
- (void)startTrackingLocationForChat:(id)arg1;
- (void)startTrackingLocationForHandle:(id)arg1;
- (void)stopSharingWithChat:(id)arg1;
- (void)stopSharingWithHandle:(id)arg1 inChat:(id)arg2;
- (void)stopTrackingLocationForChat:(id)arg1;
- (void)stopTrackingLocationForHandle:(id)arg1;
- (id)timedOfferExpirationForChat:(id)arg1;

@end


#endif
