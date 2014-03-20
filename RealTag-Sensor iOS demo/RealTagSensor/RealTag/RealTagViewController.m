//
//  RealTagViewController.m
//  RealTag
//
//  Created by Ray Wenderlich on 9/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RealTagViewController.h"

typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2];
} Vertex;

static CBCentralManager *CM;
static NSTimer *mTimer;
//static BOOL readflag = false;
static BOOL readB6flag = false;
static BOOL readB7flag = false;
static float Angel_accX,Angel_accY,Angel_accZ;
static float sTempure,sPressure;
static NSString *realname,*realstatus;

const Vertex Vertices[] = {
    // Front
    {{1, -1, 1}, {1, 0, 0, 1}, {1, 0}},
    {{1, 1, 1}, {0, 1, 0, 1}, {1, 1}},
    {{-1, 1, 1}, {0, 0, 1, 1}, {0, 1}},
    {{-1, -1, 1}, {0, 0, 0, 1}, {0, 0}},
    // Back
    {{1, 1, -1}, {1, 0, 0, 1}, {0, 1}},
    {{-1, -1, -1}, {0, 1, 0, 1}, {1, 0}},
    {{1, -1, -1}, {0, 0, 1, 1}, {0, 0}},
    {{-1, 1, -1}, {0, 0, 0, 1}, {1, 1}},
    // Left
    {{-1, -1, 1}, {1, 0, 0, 1}, {1, 0}}, 
    {{-1, 1, 1}, {0, 1, 0, 1}, {1, 1}},
    {{-1, 1, -1}, {0, 0, 1, 1}, {0, 1}},
    {{-1, -1, -1}, {0, 0, 0, 1}, {0, 0}},
    // Right
    {{1, -1, -1}, {1, 0, 0, 1}, {1, 0}},
    {{1, 1, -1}, {0, 1, 0, 1}, {1, 1}},
    {{1, 1, 1}, {0, 0, 1, 1}, {0, 1}},
    {{1, -1, 1}, {0, 0, 0, 1}, {0, 0}},
    // Top
    {{1, 1, 1}, {1, 0, 0, 1}, {1, 0}},
    {{1, 1, -1}, {0, 1, 0, 1}, {1, 1}},
    {{-1, 1, -1}, {0, 0, 1, 1}, {0, 1}},
    {{-1, 1, 1}, {0, 0, 0, 1}, {0, 0}},
    // Bottom
    {{1, -1, -1}, {1, 0, 0, 1}, {1, 0}},
    {{1, -1, 1}, {0, 1, 0, 1}, {1, 1}},
    {{-1, -1, 1}, {0, 0, 1, 1}, {0, 1}}, 
    {{-1, -1, -1}, {0, 0, 0, 1}, {0, 0}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 5, 7,
    // Left
    8, 9, 10,
    10, 11, 8,
    // Right
    12, 13, 14,
    14, 15, 12,
    // Top
    16, 17, 18,
    18, 19, 16,
    // Bottom
    20, 21, 22,
    22, 23, 20
};

@interface RealTagViewController () {
    float _curRed;
    BOOL _increasing;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;   
    GLuint _vertexArray;
    float _rotation;
    GLKMatrix4 _rotMatrix;
    GLKVector3 _anchor_position;
    GLKVector3 _current_position;
    GLKQuaternion _quatStart;
    GLKQuaternion _quat;
    
    BOOL _slerping;
    float _slerpCur;
    float _slerpMax;
    GLKQuaternion _slerpStart;
    GLKQuaternion _slerpEnd;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation RealTagViewController 
@synthesize context = _context;
@synthesize effect = _effect;
// Rest of file...

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (void)setupGL {
    
    [EAGLContext setCurrentContext:self.context];
    glEnable(GL_CULL_FACE);
    
    self.effect = [[GLKBaseEffect alloc] init];
    
    NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES],
                              GLKTextureLoaderOriginBottomLeft, 
                              nil];

    NSError * error;    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"tile_floor" ofType:@"png"];
    GLKTextureInfo * info = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if (info == nil) {
        NSLog(@"Error loading file: %@", [error localizedDescription]);
    }
    self.effect.texture2d0.name = info.name;
    self.effect.texture2d0.enabled = true;
    
    // New lines
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    // Old stuff
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    // New lines (were previously in draw)
    glEnableVertexAttribArray(GLKVertexAttribPosition);        
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord));
    
    // New line
    glBindVertexArrayOES(0);
    
    _rotMatrix = GLKMatrix4Identity;
    _quat = GLKQuaternionMake(0, 0, 0, 1);
    _quatStart = GLKQuaternionMake(0, 0, 0, 1);
    
    UITapGestureRecognizer * dtRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    dtRec.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:dtRec];
}

- (void)tearDownGL {
    
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    //glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    Angel_accX = 0.0;
    Angel_accY = 0.0;
    Angel_accZ = 0.0;
    sTempure = 0.0;
    sPressure = 0.0;
    realname = @"RealTAG Device";
    realstatus = @"None";

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }

    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    [self setupGL];
    
    dispatch_queue_t centralQueue = dispatch_queue_create("com.bytereal.BLESensortest", DISPATCH_QUEUE_SERIAL);
    CM = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue];

    [self cmStartScan];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self cmStopScan];

    [self tearDownGL];

    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    //glClearColor(_curRed, 255.0, 255.0, 1.0);
    glClearColor(200.0, 200.0, 200.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    [self.effect prepareToDraw];    
    
    glBindVertexArrayOES(_vertexArray);   
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
}

#pragma mark - GLKViewControllerDelegate

- (void)update {
    /*
    if (_increasing) {
        _curRed += 1.0 * self.timeSinceLastUpdate;
    } else {
        _curRed -= 1.0 * self.timeSinceLastUpdate;
    }
    if (_curRed >= 1.0) {
        _curRed = 1.0;
        _increasing = NO;
    }
    if (_curRed <= 0.0) {
        _curRed = 0.0;
        _increasing = YES;
    }
    */
    if(readB6flag){
        readB6flag = false;
        self.dx.text = [NSMutableString stringWithFormat:@"%f",Angel_accX];
        self.dy.text = [NSMutableString stringWithFormat:@"%f",Angel_accY];
        self.dz.text = [NSMutableString stringWithFormat:@"%f",Angel_accZ];
    }
    if(readB7flag){
        readB7flag = false;
        self.tempture.text = [NSMutableString stringWithFormat:@"%f",sTempure];
        self.pressure.text = [NSMutableString stringWithFormat:@"%f",sPressure];
    }
    
    self.realtagname.text = realname;
    self.realtagstatus.text = realstatus;
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.0f, 10.0f);    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    if (_slerping) {
        
        _slerpCur += self.timeSinceLastUpdate;
        float slerpAmt = _slerpCur / _slerpMax;
        if (slerpAmt > 1.0) {
            slerpAmt = 1.0;
            _slerping = NO;
        }
        
        _quat = GLKQuaternionSlerp(_slerpStart, _slerpEnd, slerpAmt);
    }
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);
    /*
    //modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, _rotMatrix);
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(_quat);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotation);
    */
    //_rotation += 90 * self.timeSinceLastUpdate;
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(Angel_accY), 1, 0, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(-Angel_accX), 0, 1, 0);
    //modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(Angel_accZ), 0, 0, 1);

    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
}

- (GLKVector3) projectOntoSurface:(GLKVector3) touchPoint
{
    float radius = self.view.bounds.size.width/3; 
    GLKVector3 center = GLKVector3Make(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0);
    GLKVector3 P = GLKVector3Subtract(touchPoint, center);
    
    // Flip the y-axis because pixel coords increase toward the bottom.
    P = GLKVector3Make(P.x, P.y * -1, P.z);
    
    float radius2 = radius * radius;
    float length2 = P.x*P.x + P.y*P.y;
    
    if (length2 <= radius2)
        P.z = sqrt(radius2 - length2);
    else
    {
        /*
        P.x *= radius / sqrt(length2);
        P.y *= radius / sqrt(length2);
        P.z = 0;
        */
        P.z = radius2 / (2.0 * sqrt(length2));
        float length = sqrt(length2 + P.z * P.z);
        P = GLKVector3DivideScalar(P, length);
    }
    
    return GLKVector3Normalize(P);
}

- (void)computeIncremental {
    
    GLKVector3 axis = GLKVector3CrossProduct(_anchor_position, _current_position);
    float dot = GLKVector3DotProduct(_anchor_position, _current_position);    
    float angle = acosf(dot);
    
    GLKQuaternion Q_rot = GLKQuaternionMakeWithAngleAndVector3Axis(angle * 2, axis);
    Q_rot = GLKQuaternionNormalize(Q_rot);

    // TODO: Do something with Q_rot...
    _quat = GLKQuaternionMultiply(Q_rot, _quatStart);
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];

    _anchor_position = GLKVector3Make(location.x, location.y, 0);
    _anchor_position = [self projectOntoSurface:_anchor_position];

    _current_position = _anchor_position;
    _quatStart = _quat;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];    
    CGPoint lastLoc = [touch previousLocationInView:self.view];
    CGPoint diff = CGPointMake(lastLoc.x - location.x, lastLoc.y - location.y);
    
    float rotX = -1 * GLKMathDegreesToRadians(diff.y / 2.0);
    float rotY = -1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
    bool isInvertible;
    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(1, 0, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(0, 1, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);
    
    _current_position = GLKVector3Make(location.x, location.y, 0);
    _current_position = [self projectOntoSurface:_current_position];
 
    [self computeIncremental];

}

- (void)doubleTap:(UITapGestureRecognizer *)tap {
    [self resetCube];
}

- (void)resetCube{
    _slerping = YES;
    _slerpCur = 0;
    _slerpMax = 1.0;
    _slerpStart = _quat;
    _slerpEnd = GLKQuaternionMake(0, 0, 0, 1);

}

#pragma mark - CBCentralManagerDelegate Methods

-(void)centralManagerDidUpdateState:(CBCentralManager*)cManager
{
    NSMutableString* nsmstring=[NSMutableString stringWithString:@"UpdateState:"];
    switch (cManager.state) {
        case CBCentralManagerStateUnknown:
            [nsmstring appendString:@"Unknown\n"];
            break;
        case CBCentralManagerStateUnsupported:
            [nsmstring appendString:@"Unsupported\n"];
            break;
        case CBCentralManagerStateUnauthorized:
            [nsmstring appendString:@"Unauthorized\n"];
            break;
        case CBCentralManagerStateResetting:
            [nsmstring appendString:@"Resetting\n"];
            break;
        case CBCentralManagerStatePoweredOff:
            [nsmstring appendString:@"PoweredOff\n"];
            break;
        case CBCentralManagerStatePoweredOn:
            [nsmstring appendString:@"PoweredOn\n"];
            break;
        default:
            [nsmstring appendString:@"none\n"];
            break;
    }
    NSLog(@"%@",nsmstring);
    if(cManager.state != CBCentralManagerStatePoweredOn){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"BLE Warning"
                                                        message:nsmstring
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        
        [alert show];
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    NSMutableString* nsmstring=[NSMutableString stringWithString:@"\n"];
    [nsmstring appendString:@"Peripheral Info:"];
    [nsmstring appendFormat:@"NAME: %@\n",peripheral.name];
    [nsmstring appendFormat:@"RSSI: %@\n",RSSI];
    
    if (peripheral.state == CBPeripheralStateConnected){
        [nsmstring appendString:@"isConnected: connected\n"];
    }else if(peripheral.state == CBPeripheralStateConnecting){
        [nsmstring appendString:@"isConnected: connecting\n"];
    }else if(peripheral.state == CBPeripheralStateDisconnected){
        [nsmstring appendString:@"isConnected: disconnected\n"];
    }else{
        [nsmstring appendFormat:@"isConnected: unknow %d\n",peripheral.state];
    }
    //NSLog(@"adverisement:%@",advertisementData);
    [nsmstring appendFormat:@"adverisement:%@",advertisementData];
    [nsmstring appendString:@"didDiscoverPeripheral\n"];
    //NSLog(@"%@",nsmstring);
    NSLog(@"%@,%@",peripheral.name,RSSI);
    
    realname = peripheral.name;
    
    if(peripheral.state != CBPeripheralStateConnected){
        [CM connectPeripheral:peripheral options:nil];
        self.connectingPeripheral = peripheral;
        realstatus = @"Connecting...";
    }
}
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral:%@",peripheral.name);
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
    [peripheral readRSSI];
    realstatus = @"Connected";
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"didDisconnectPeripheral:%@",peripheral.name);
    readB6flag = false;
    readB7flag = false;
    realstatus = @"Disconnected";
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    //NSLog(@"peripheralDidUpdateRSSI:%@ %@",peripheral.name, peripheral.RSSI);
    if (error) {
        NSLog(@"ERROR: readRSSI failed. %@", error.description);
        //[peripheral readRSSI];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *aService in peripheral.services) {
        NSLog(@"Service found with UUID: %@", aService.UUID);
        
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"FFA0"]]) {
            [peripheral discoverCharacteristics:nil forService:aService];
        }
        
    }
    
}
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FFA0"]]) {
        for (CBCharacteristic *aChar in service.characteristics) {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"FFB6"]]) {
                [peripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a sensor %@",aChar);
                self.wantChar = aChar;
            }else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"FFB7"]]) {
                [peripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a sensor %@",aChar);
                self.tpChar = aChar;
            }
        }
    }
}
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Characteristic value : %@ with ID %@", characteristic.value, characteristic.UUID);
    //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFB6"]]){
        unsigned int x,y,z;
        x = ((unsigned char*)(characteristic.value.bytes))[0] + (((unsigned char*)(characteristic.value.bytes))[1] << 8);
        y = ((unsigned char*)(characteristic.value.bytes))[2] + (((unsigned char*)(characteristic.value.bytes))[3] << 8);
        z = ((unsigned char*)(characteristic.value.bytes))[4] + (((unsigned char*)(characteristic.value.bytes))[5] << 8);
    
        [self calcXYZ:x ay:y az:z];

        //NSLog(@"x:%f, y:%f, z:%f",Angel_accX,Angel_accY,Angel_accZ);
        readB6flag = true;
        usleep(100);
        [self.connectingPeripheral readValueForCharacteristic:self.wantChar];
    }else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFB7"]]){
        unsigned int t,p;
        t = ((unsigned char*)(characteristic.value.bytes))[0] + (((unsigned char*)(characteristic.value.bytes))[1] << 8) + (((unsigned char*)(characteristic.value.bytes))[2] << 16) + (((unsigned char*)(characteristic.value.bytes))[3] << 24);
        p = ((unsigned char*)(characteristic.value.bytes))[4] + (((unsigned char*)(characteristic.value.bytes))[5] << 8) + (((unsigned char*)(characteristic.value.bytes))[6] << 16) + (((unsigned char*)(characteristic.value.bytes))[7] << 24);

        sTempure = t/10.0;
        sPressure = p/1.0;
        readB7flag = true;
        usleep(100);
        [self.connectingPeripheral readValueForCharacteristic:self.tpChar];
    }
}

- (void)cmStartScan
{
    NSDictionary *options = @{ CBCentralManagerScanOptionAllowDuplicatesKey: @YES };
    //NSDictionary *options = nil;
    //NSArray	*uuidArray= [NSArray arrayWithObjects:[CBUUID UUIDWithString:@"FFE0"],[CBUUID UUIDWithString:@"1802"],[CBUUID UUIDWithString:@"1803"],[CBUUID UUIDWithString:@"1804"],[CBUUID UUIDWithString:@"E20A39F4-73F5-4BC4-A12F-17D1AD07A961"], nil];
    NSArray *uuidArray = nil;
    [CM scanForPeripheralsWithServices:uuidArray options:options];
    //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    mTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(mTimerTask) userInfo:nil repeats:YES];
}
- (void)cmStopScan
{
    [mTimer invalidate];
    [CM stopScan];
}

-(void)mTimerTask
{
    //if(readflag){
    //    readflag = false;

        //[self.connectingPeripheral readValueForCharacteristic:self.wantChar];
    //}
}

-(void)calcXYZ:(int16_t)ax ay:(int16_t)ay az:(int16_t)az
{
    float Ax,Ay,Az;
    
    Ax = ax/16384.00;
    Ay = ay/16384.00;
    Az = az/16384.00;
    
    Angel_accX=atan(Ax/sqrt(Az*Az+Ay*Ay))*180/3.14;
    Angel_accY=atan(Ay/sqrt(Ax*Ax+Az*Az))*180/3.14;
    Angel_accZ=atan(Az/sqrt(Ax*Ax+Ay*Ay))*180/3.14;
	
}
@end
