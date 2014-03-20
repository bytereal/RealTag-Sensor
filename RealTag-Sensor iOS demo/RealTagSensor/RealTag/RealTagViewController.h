//
//  RealTagViewController.h
//  RealTag
//
//  Created by Ray Wenderlich on 9/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface RealTagViewController : GLKViewController<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (weak, nonatomic) IBOutlet UILabel *dx;
@property (weak, nonatomic) IBOutlet UILabel *dy;
@property (weak, nonatomic) IBOutlet UILabel *dz;

@property (strong) CBPeripheral     *connectingPeripheral;
@property (strong) CBCharacteristic *wantChar,*tpChar;

@property (weak, nonatomic) IBOutlet UILabel *tempture;
@property (weak, nonatomic) IBOutlet UILabel *pressure;
@property (weak, nonatomic) IBOutlet UILabel *realtagname;
@property (weak, nonatomic) IBOutlet UILabel *realtagstatus;
@end
