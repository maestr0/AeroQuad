/*
  AeroQuad v2.3 - March 2011
  www.AeroQuad.com
  Copyright (c) 2011 Ted Carancho.  All rights reserved.
  An Open Source Arduino based multicopter.
 
  This program is free software: you can redistribute it and/or modify 
  it under the terms of the GNU General Public License as published by 
  the Free Software Foundation, either version 3 of the License, or 
  (at your option) any later version. 
 
  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
  GNU General Public License for more details. 
 
  You should have received a copy of the GNU General Public License 
  along with this program. If not, see <http://www.gnu.org/licenses/>. 
*/

// FlightControl.pde is responsible for combining sensor measurements and
// transmitter commands into motor commands for the defined flight configuration (X, +, etc.)
// Special thanks to Keny9999 for suggesting a more readable format for FlightControl.pde and for
// porting over the ArduPirates Stable Mode (please note this is still experimental, use at your own risk)

#ifdef UseArduPirateSuperStable
#define MAX_CONTROL_OUTPUT 500

//////////////////////////////////////////////////////////////////////////////
/////////////////////////// ArduPirateSuperStableProcessor ///////////////////
//////////////////////////////////////////////////////////////////////////////
void processArdupirateSuperStableMode(void)
{
  // ArduPirate adaptation
  // default value are P = 4, I = 0.15
  // ROLL
  float errorRoll = receiver.getAngle(ROLL) - degrees(flightAngle->getData(ROLL));  // calculate the  accel error   
  errorRoll = constrain(errorRoll, -50, 50);  // constrain the error
  if (abs(receiver.getAngle(ROLL)) < 30) {
    PID[LEVELROLL].integratedError += errorRoll * G_Dt; // calculate the integrated error
    PID[LEVELROLL].integratedError = constrain(PID[LEVELROLL].integratedError, -20, 20); // constrain it to a windup values
  }
  else
    PID[LEVELROLL].integratedError = 0; // zero integral error
  const float stableRoll = PID[LEVELROLL].P * errorRoll + PID[LEVELROLL].I * PID[LEVELROLL].integratedError; // calculate the leveing PI
  errorRoll = stableRoll - gyro.getFlightData(ROLL); // calculate the rate error
  //motors.setMotorAxisCommand(ROLL,constrain(PID[LEVELGYROROLL].P*errorRoll,-MAX_CONTROL_OUTPUT,MAX_CONTROL_OUTPUT));
  // NEW SI Version
  //motors.setMotorAxisCommand(ROLL, updatePID(radians(stableRoll), gyro.getData(ROLL), &PID[LEVELGYROROLL]));
  // OLD NON SI
  //motors.setMotorAxisCommand(ROLL, updatePID(stableRoll, gyro.getFlightData(ROLL), &PID[LEVELGYROROLL]));
  // ORIGINAL
  motors.setMotorAxisCommand(ROLL, constrain(PID[LEVELGYROROLL].P * errorRoll, -MAX_CONTROL_OUTPUT, MAX_CONTROL_OUTPUT)); // use P only PID calculate the rate PID

  // PITCH
  float errorPitch = receiver.getAngle(PITCH) + degrees(flightAngle->getData(PITCH));     
  errorPitch = constrain(errorPitch, -50, 50);                    
  if (abs(receiver.getAngle(PITCH)) < 30) {
    PID[LEVELPITCH].integratedError += errorPitch * G_Dt;                            
    PID[LEVELPITCH].integratedError = constrain(PID[LEVELPITCH].integratedError, -20, 20);
  }
  else
    PID[LEVELPITCH].integratedError = 0;
  const float stablePitch = PID[LEVELPITCH].P * errorPitch + PID[LEVELPITCH].I * PID[LEVELPITCH].integratedError;
  errorPitch = stablePitch - gyro.getFlightData(PITCH);
  //motors.setMotorAxisCommand(PITCH,constrain(PID[LEVELGYROPITCH].P*errorPitch,-MAX_CONTROL_OUTPUT,MAX_CONTROL_OUTPUT));
  // NEW SI Version
  //motors.setMotorAxisCommand(PITCH, updatePID(radians(stablePitch), -gyro.getData(PITCH), &PID[LEVELGYROPITCH]));
  // OLD NON SI
  //motors.setMotorAxisCommand(PITCH, updatePID(stablePitch, gyro.getFlightData(PITCH), &PID[LEVELGYROPITCH]));  
  // ORIGINAL
  motors.setMotorAxisCommand(PITCH, constrain(PID[LEVELGYROPITCH].P * errorPitch, -MAX_CONTROL_OUTPUT, MAX_CONTROL_OUTPUT));
}

#endif
#ifdef UseAQStable
//////////////////////////////////////////////////////////////////////////////
/////////////////////////// AQ Original Stable Mode //////////////////////////
//////////////////////////////////////////////////////////////////////////////
void processAeroQuadStableMode(void)
{
  // an attempt to make AQ Stable work with the new SI Scaling...
  // AKA 2011-03-17
  //float attitudeScaling = (1.5 * PWM2RPS); // +/-1.5 radian attitude
  //float rollStickScaled = ((receiver.getData(ROLL) - receiver.getZero(ROLL)) * attitudeScaling) - flightAngle->getData(ROLL);
  //float pitchStickScaled = ((receiver.getData(PITCH) - receiver.getZero(PITCH)) * attitudeScaling) + flightAngle->getData(PITCH);
  
  //levelAdjust[ROLL] = rollStickScaled * PID[LEVELROLL].P;
  //levelAdjust[PITCH] = pitchStickScaled * PID[LEVELPITCH].P;
  levelAdjust[ROLL] = (receiver.getAngle(ROLL) - degrees(flightAngle->getData(ROLL))) * PID[LEVELROLL].P;
  levelAdjust[PITCH] = (receiver.getAngle(PITCH) + degrees(flightAngle->getData(PITCH))) * PID[LEVELPITCH].P;
  // Check if pilot commands are not in hover, don't auto trim
  if ((abs(receiver.getTrimData(ROLL)) > levelOff) || (abs(receiver.getTrimData(PITCH)) > levelOff)) {
    zeroIntegralError();
    #if defined(AeroQuad_v18) || defined(AeroQuadMega_v2)
      digitalWrite(LED2PIN, LOW);
    #endif
    #ifdef APM_OP_CHR
      digitalWrite(LED_Green, LOW);
    #endif
  }
  else {
    //PID[LEVELROLL].integratedError = constrain(PID[LEVELROLL].integratedError + ((rollStickScaled * G_Dt) * PID[LEVELROLL].I), -levelLimit, levelLimit);
    //PID[LEVELPITCH].integratedError = constrain(PID[LEVELPITCH].integratedError + ((pitchStickScaled * G_Dt) * PID[LEVELROLL].I), -levelLimit, levelLimit);
    PID[LEVELROLL].integratedError = constrain(PID[LEVELROLL].integratedError + (((receiver.getAngle(ROLL) - degrees(flightAngle->getData(ROLL))) * G_Dt) * PID[LEVELROLL].I), -levelLimit, levelLimit);
    PID[LEVELPITCH].integratedError = constrain(PID[LEVELPITCH].integratedError + (((receiver.getAngle(PITCH) + degrees(flightAngle->getData(PITCH))) * G_Dt) * PID[LEVELPITCH].I), -levelLimit, levelLimit);
    #if defined(AeroQuad_v18) || defined(AeroQuadMega_v2)
      digitalWrite(LED2PIN, HIGH);
    #endif
    #ifdef APM_OP_CHR
      digitalWrite(LED_Green, HIGH);
    #endif
  }
  // NEW SI Version
  //motors.setMotorAxisCommand(ROLL, updatePID(receiver.getSIData(ROLL) + levelAdjust[ROLL], gyro.getData(ROLL), &PID[LEVELGYROROLL]) + PID[LEVELROLL].integratedError);
  //motors.setMotorAxisCommand(PITCH, updatePID(receiver.getSIData(PITCH) + levelAdjust[PITCH], -gyro.getData(PITCH), &PID[LEVELGYROPITCH]) + PID[LEVELPITCH].integratedError);
  //motors.setMotorAxisCommand(ROLL, updatePID(receiver.getSIData(ROLL) + radians(levelAdjust[ROLL]), gyro.getData(ROLL), &PID[LEVELGYROROLL]) + PID[LEVELROLL].integratedError);
  //motors.setMotorAxisCommand(PITCH, updatePID(receiver.getSIData(PITCH) + radians(levelAdjust[PITCH]), -gyro.getData(PITCH), &PID[LEVELGYROPITCH]) + PID[LEVELPITCH].integratedError);
  // OLD NON SI
  motors.setMotorAxisCommand(ROLL, updatePID(receiver.getData(ROLL) + levelAdjust[ROLL], gyro.getFlightData(ROLL) + 1500, &PID[LEVELGYROROLL]) + PID[LEVELROLL].integratedError);
  motors.setMotorAxisCommand(PITCH, updatePID(receiver.getData(PITCH) + levelAdjust[PITCH], gyro.getFlightData(PITCH) + 1500, &PID[LEVELGYROPITCH]) + PID[LEVELPITCH].integratedError);
}
#endif

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Attitude Mode ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////
void processAttitudeMode(void)
{
  // To Do
  // Figure out how to zero integrator when entering attitude mode from rate mode 
  // 2.3 Original
  float attitudeScaling = (0.75 * PWM2RPS); // +/-0.75 radian attitude
  // 2.3 Stable
  //float attitudeScaling = (1.5 * PWM2RPS); // +/-1.5 radian attitude factored further by transmitter factor

  // Assume receiver.getRaw(axis) returns +/-500 by using constrain() function 
  //float rollAttitudeCmd = updatePID(constrain(receiver.getRaw(ROLL) - 1500, -500, 500) * attitudeScaling, flightAngle->getData(ROLL), &PID[LEVELROLL]);
  //float pitchAttitudeCmd = updatePID(constrain(receiver.getRaw(PITCH) - 1500, -500, 500) * attitudeScaling, -flightAngle->getData(PITCH), &PID[LEVELPITCH]);
  //motors.setMotorAxisCommand(ROLL, updatePID(rollAttitudeCmd, gyro.getData(ROLL), &PID[LEVELGYROROLL]));
  //motors.setMotorAxisCommand(PITCH, updatePID(pitchAttitudeCmd, -gyro.getData(PITCH), &PID[LEVELGYROPITCH]));

  // these should be the same as the above with one exception.
  // these use the getData method which uses the smoothed and scaled RX values 
  // if you want to try them
  // AKA change this back once data collection is complete
  float recRollScaled = (receiver.getData(ROLL) - receiver.getZero(ROLL)) * attitudeScaling;
  float recPitchScaled = (receiver.getData(PITCH) - receiver.getZero(PITCH)) * attitudeScaling;
  float rollAttitudeCmd = updatePID(recRollScaled, flightAngle->getData(ROLL), &PID[LEVELROLL]);
  float pitchAttitudeCmd = updatePID(recPitchScaled, -flightAngle->getData(PITCH), &PID[LEVELPITCH]);
  // 2.3 Original
  motors.setMotorAxisCommand(ROLL, updatePID(rollAttitudeCmd, gyro.getData(ROLL), &PID[LEVELGYROROLL]));
  motors.setMotorAxisCommand(PITCH, updatePID(pitchAttitudeCmd, -gyro.getData(PITCH), &PID[LEVELGYROPITCH]));
  // 2.3 Stable
  //motors.setMotorAxisCommand(ROLL, updatePID(rollAttitudeCmd, gyro.getData(ROLL), &PID[ROLL]));
  //motors.setMotorAxisCommand(PITCH, updatePID(pitchAttitudeCmd, -gyro.getData(PITCH), &PID[PITCH]));
  #ifdef BinaryWritePID
    // **************************************************************
    // ***************** Fast Transfer Of Sensor Data ***************
    // **************************************************************
    // AeroQuad.h defines the output rate to be 10ms
    // Since writing to UART is done by hardware, unable to measure data rate directly
    // Through analysis:  115200 baud = 115200 bits/second = 14400 bytes/second
    // If float = 4 bytes, then 3600 floats/second
    // If 10 ms output rate, then 36 floats/10ms
    // Number of floats written using sendBinaryFloat is 15
    #ifdef OpenlogBinaryWrite
        printInt(21845); // Start word of 0x5555
        sendBinaryuslong(currentTime);
        sendBinaryFloat(recRollScaled);
        sendBinaryFloat(recPitchScaled);
        sendBinaryFloat(flightAngle->getData(ROLL));
        sendBinaryFloat(-flightAngle->getData(PITCH));
        sendBinaryFloat(rollAttitudeCmd);
        sendBinaryFloat(pitchAttitudeCmd);
        sendBinaryFloat(receiver.getSIData(YAW));
        sendBinaryFloat(gyro.getData(ROLL));
        sendBinaryFloat(-gyro.getData(PITCH));
        sendBinaryFloat(gyro.getData(YAW));
        printInt(32767); // Stop word of 0x7FFF
    #endif
  #endif
}

//////////////////////////////////////////////////////////////////////////////
/////////////////////////// calculateFlightError /////////////////////////////
//////////////////////////////////////////////////////////////////////////////
void calculateFlightError(void)
{
  if (flightMode == ACRO) {
    // Acrobatic Mode
    // updatePID(target, measured, PIDsettings);
    // updatePID() is defined in PID.h
    // NEW SI Version
    // measured = rate data from gyros scaled to Radians (-1.5*PI/+1.5*PI), since PID settings are found experimentally
    motors.setMotorAxisCommand(ROLL, updatePID(receiver.getSIData(ROLL), gyro.getData(ROLL), &PID[ROLL]));
    motors.setMotorAxisCommand(PITCH, updatePID(receiver.getSIData(PITCH), -gyro.getData(PITCH), &PID[PITCH]));
    // OLD NON SI
    // measured = rate data from gyros scaled to PWM (1000-2000), since PID settings are found experimentally
    //motors.setMotorAxisCommand(ROLL, updatePID(receiver.getData(ROLL), gyro.getFlightData(ROLL) + 1500, &PID[ROLL]));
    //motors.setMotorAxisCommand(PITCH, updatePID(receiver.getData(PITCH), gyro.getFlightData(PITCH) + 1500, &PID[PITCH]));
    zeroIntegralError();
  }
  else {
    processStableMode();
  }
}

//////////////////////////////////////////////////////////////////////////////
/////////////////////////// processCalibrateESC //////////////////////////////
//////////////////////////////////////////////////////////////////////////////
void processCalibrateESC(void)
{
  switch (calibrateESC) { // used for calibrating ESC's
  case 1:
    for (byte motor = FRONT; motor < LASTMOTOR; motor++)
      motors.setMotorCommand(motor, MAXCOMMAND);
    break;
  case 3:
    for (byte motor = FRONT; motor < LASTMOTOR; motor++)
      motors.setMotorCommand(motor, constrain(testCommand, 1000, 1200));
    break;
  case 5:
    for (byte motor = FRONT; motor < LASTMOTOR; motor++)
      motors.setMotorCommand(motor, constrain(motors.getRemoteCommand(motor), 1000, 1200));
    safetyCheck = ON;
    break;
  default:
    for (byte motor = FRONT; motor < LASTMOTOR; motor++)
      motors.setMotorCommand(motor, MINCOMMAND);
  }
  // Send calibration commands to motors
  motors.write(); // Defined in Motors.h
}

//////////////////////////////////////////////////////////////////////////////
/////////////////////////// processHeadingHold ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////
void processHeading(void)
{
  if (headingHoldConfig == ON) {
    //gyro.calculateHeading();

#if defined(HeadingMagHold) || defined(AeroQuadMega_CHR6DM) || defined(APM_OP_CHR6DM)
    heading = degrees(flightAngle->getHeading(YAW));
#else
    heading = degrees(gyro.getHeading());
#endif

    // Always center relative heading around absolute heading chosen during yaw command
    // This assumes that an incorrect yaw can't be forced on the AeroQuad >180 or <-180 degrees
    // This is done so that AeroQuad does not accidentally hit transition between 0 and 360 or -180 and 180
    // AKA - THERE IS A BUG HERE - if relative heading is greater than 180 degrees, the PID will swing from negative to positive
    // Doubt that will happen as it would have to be uncommanded.
    relativeHeading = heading - setHeading;
    if (heading <= (setHeading - 180)) relativeHeading += 360;
    if (heading >= (setHeading + 180)) relativeHeading -= 360;

    // Apply heading hold only when throttle high enough to start flight
    if (receiver.getData(THROTTLE) > MINCHECK ) { 
      if ((receiver.getData(YAW) > (MIDCOMMAND + 25)) || (receiver.getData(YAW) < (MIDCOMMAND - 25))) {
        // If commanding yaw, turn off heading hold and store latest heading
        setHeading = heading;
        headingHold = 0;
        PID[HEADING].integratedError = 0;
      }
      else {
        if (relativeHeading < .25 && relativeHeading > -.25) {
          //setHeading = heading;
          headingHold = 0;
          PID[HEADING].integratedError = 0;
        }
        else {
        // No new yaw input, calculate current heading vs. desired heading heading hold
        // Relative heading is always centered around zero
          headingHold = updatePID(0, relativeHeading, &PID[HEADING]);
        }
      }
    }
    else {
      // minimum throttle not reached, use off settings
      setHeading = heading;
      headingHold = 0;
      PID[HEADING].integratedError = 0;
    }
  }
  // NEW SI Version
  commandedYaw = constrain(receiver.getSIData(YAW) + radians(headingHold), -PI, PI);
  motors.setMotorAxisCommand(YAW, updatePID(commandedYaw, gyro.getData(YAW), &PID[YAW]));
  // OLD NON SI
  //commandedYaw = constrain(receiver.getData(YAW) + headingHold, 1000, 2000);
  //motors.setMotorAxisCommand(YAW, updatePID(commandedYaw, gyro.getFlightData(YAW) + 1500, &PID[YAW]));
}

//////////////////////////////////////////////////////////////////////////////
/////////////////////////// processAltitudeHold //////////////////////////////
//////////////////////////////////////////////////////////////////////////////
void processAltitudeHold(void)
{
  // ****************************** Altitude Adjust *************************
  // Thanks to Honk for his work with altitude hold
  // http://aeroquad.com/showthread.php?792-Problems-with-BMP085-I2C-barometer
  // Thanks to Sherbakov for his work in Z Axis dampening
  // http://aeroquad.com/showthread.php?359-Stable-flight-logic...&p=10325&viewfull=1#post10325
#ifdef AltitudeHold
  if (altitudeHold == ON) {
    throttleAdjust = updatePID(holdAltitude, altitude.getData(), &PID[ALTITUDE]);
    //zDampening = updatePID(0, accel.getZaxis(), &PID[ZDAMPENING]); // This is stil under development - do not use (set PID=0)
    //if((abs(flightAngle->getData(ROLL)) > radians(5)) || (abs(flightAngle->getData(PITCH)) > radians(5))) { 
    //  PID[ZDAMPENING].integratedError = 0;
    //}
    //throttleAdjust = constrain((holdAltitude - altitude.getData()) * PID[ALTITUDE].P, minThrottleAdjust, maxThrottleAdjust);
    throttleAdjust = constrain(throttleAdjust, minThrottleAdjust, maxThrottleAdjust);
    if (abs(holdThrottle - receiver.getData(THROTTLE)) > PANICSTICK_MOVEMENT) {
      altitudeHold = ALTPANIC; // too rapid of stick movement so PANIC out of ALTHOLD
    } else {
    #ifdef BinaryWrite
    #ifdef OpenlogBinaryWrite
      // change this to the new BinaryWrite
      //SerialLog.dumpRecord(LOG_REC_FLIGHT);
      //SerialLog.dumpRecord(LOG_REC_ALTHOLD);
      //SerialLog.dumpRecord(LOG_REC_ALTPID);
    #endif      
    #endif
      if (receiver.getData(THROTTLE) > (holdThrottle + ALTBUMP)) { // AKA changed to use holdThrottle + ALTBUMP - (was MAXCHECK) above 1900
        holdAltitude += 0.01;
      }
      if (receiver.getData(THROTTLE) < (holdThrottle - ALTBUMP)) { // AKA change to use holdThorrle - ALTBUMP - (was MINCHECK) below 1100
        holdAltitude -= 0.01;
      }
    }
  }
  else {
    // Altitude hold is off, get throttle from receiver
    holdThrottle = receiver.getData(THROTTLE);
    throttleAdjust = autoDescent; // autoDescent is lowered from BatteryMonitor.h during battery alarm
  }
  // holdThrottle set in FlightCommand.pde if altitude hold is on
  throttle = holdThrottle + throttleAdjust; // holdThrottle is also adjust by BatteryMonitor.h during battery alarm
#else
  //zDampening = updatePID(0, accel.getZaxis(), &PID[ZDAMPENING]); // This is stil under development - do not use (set PID=0)
  //throttle = receiver.getData(THROTTLE) - zDampening + autoDescent; 
  // If altitude hold not enabled in AeroQuad.pde, get throttle from receiver
  throttle = receiver.getData(THROTTLE) + autoDescent; //autoDescent is lowered from BatteryMonitor.h while battery critical, otherwise kept 0
#endif
}

//////////////////////////////////////////////////////////////////////////////
/////////////////////////// processMinMaxMotorCommand ////////////////////////
//////////////////////////////////////////////////////////////////////////////
void processMinMaxMotorCommand(void)
{
  // Prevents too little power applied to motors during hard manuevers
  // Also provides even motor power on both sides if limit encountered
  if ((motors.getMotorCommand(FRONT) <= MINTHROTTLE) || (motors.getMotorCommand(REAR) <= MINTHROTTLE)){
    delta = receiver.getData(THROTTLE) - MINTHROTTLE;
    motors.setMaxCommand(RIGHT, constrain(receiver.getData(THROTTLE) + delta, MINTHROTTLE, MAXCHECK));
    motors.setMaxCommand(LEFT, constrain(receiver.getData(THROTTLE) + delta, MINTHROTTLE, MAXCHECK));
  }
  else if ((motors.getMotorCommand(FRONT) >= MAXCOMMAND) || (motors.getMotorCommand(REAR) >= MAXCOMMAND)) {
    delta = MAXCOMMAND - receiver.getData(THROTTLE);
    motors.setMinCommand(RIGHT, constrain(receiver.getData(THROTTLE) - delta, MINTHROTTLE, MAXCOMMAND));
    motors.setMinCommand(LEFT, constrain(receiver.getData(THROTTLE) - delta, MINTHROTTLE, MAXCOMMAND));
  }     
  else {
    motors.setMaxCommand(RIGHT, MAXCOMMAND);
    motors.setMaxCommand(LEFT, MAXCOMMAND);
    motors.setMinCommand(RIGHT, MINTHROTTLE);
    motors.setMinCommand(LEFT, MINTHROTTLE);
  }

  if ((motors.getMotorCommand(LEFT) <= MINTHROTTLE) || (motors.getMotorCommand(RIGHT) <= MINTHROTTLE)){
    delta = receiver.getData(THROTTLE) - MINTHROTTLE;
    motors.setMaxCommand(FRONT, constrain(receiver.getData(THROTTLE) + delta, MINTHROTTLE, MAXCHECK));
    motors.setMaxCommand(REAR, constrain(receiver.getData(THROTTLE) + delta, MINTHROTTLE, MAXCHECK));
  }
  else if ((motors.getMotorCommand(LEFT) >= MAXCOMMAND) || (motors.getMotorCommand(RIGHT) >= MAXCOMMAND)) {
    delta = MAXCOMMAND - receiver.getData(THROTTLE);
    motors.setMinCommand(FRONT, constrain(receiver.getData(THROTTLE) - delta, MINTHROTTLE, MAXCOMMAND));
    motors.setMinCommand(REAR, constrain(receiver.getData(THROTTLE) - delta, MINTHROTTLE, MAXCOMMAND));
  }     
  else {
    motors.setMaxCommand(FRONT, MAXCOMMAND);
    motors.setMaxCommand(REAR, MAXCOMMAND);
    motors.setMinCommand(FRONT, MINTHROTTLE);
    motors.setMinCommand(REAR, MINTHROTTLE);
  }
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////// processHardManuevers ////////////////////////
//////////////////////////////////////////////////////////////////////////////
void processHardManuevers()
{
#ifdef XConfig    // Fix for + mode hardmanuevers
  if (receiver.getRaw(ROLL) < MINCHECK) {
    motors.setMaxCommand(FRONT, minAcro);
    motors.setMaxCommand(REAR, MAXCOMMAND);
    motors.setMaxCommand(LEFT, minAcro);
    motors.setMaxCommand(RIGHT, MAXCOMMAND);
  }
  else if (receiver.getRaw(ROLL) > MAXCHECK) {
    motors.setMaxCommand(FRONT, MAXCOMMAND);
    motors.setMaxCommand(REAR, minAcro);
    motors.setMaxCommand(LEFT, MAXCOMMAND);
    motors.setMaxCommand(RIGHT, minAcro);
  }
  else if (receiver.getRaw(PITCH) < MINCHECK) {
    motors.setMaxCommand(FRONT, MAXCOMMAND);
    motors.setMaxCommand(REAR, minAcro);
    motors.setMaxCommand(LEFT, minAcro);
    motors.setMaxCommand(RIGHT, MAXCOMMAND);
  }
  else if (receiver.getRaw(PITCH) > MAXCHECK) {
    motors.setMaxCommand(FRONT, minAcro);
    motors.setMaxCommand(REAR, MAXCOMMAND);
    motors.setMaxCommand(LEFT, MAXCOMMAND);
    motors.setMaxCommand(RIGHT, minAcro);
  }
#endif
#ifdef plusConfig
  if (receiver.getRaw(ROLL) < MINCHECK) {
    motors.setMinCommand(LEFT, minAcro);
    motors.setMaxCommand(RIGHT, MAXCOMMAND);
  }
  else if (receiver.getRaw(ROLL) > MAXCHECK) {
    motors.setMaxCommand(LEFT, MAXCOMMAND);
    motors.setMinCommand(RIGHT, minAcro);
  }
  else if (receiver.getRaw(PITCH) < MINCHECK) {
    motors.setMaxCommand(FRONT, MAXCOMMAND);
    motors.setMinCommand(REAR, minAcro);
  }
  else if (receiver.getRaw(PITCH) > MAXCHECK) {
    motors.setMinCommand(FRONT, minAcro);
    motors.setMaxCommand(REAR, MAXCOMMAND);
  }
#endif  
}

#ifdef XConfig
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// X MODE //////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
void processFlightControlXMode(void) {
  // ********************** Calculate Flight Error ***************************
  calculateFlightError();
  
  // ********************** Update Yaw ***************************************
  processHeading();

  // ********************** Altitude Adjust **********************************
  processAltitudeHold();

  // ********************** Calculate Motor Commands *************************
  if (armed && safetyCheck) {
    // Front = Front/Right, Back = Left/Rear, Left = Front/Left, Right = Right/Rear 
    motors.setMotorCommand(FRONT, throttle - motors.getMotorAxisCommand(PITCH) + motors.getMotorAxisCommand(ROLL) - motors.getMotorAxisCommand(YAW));
    motors.setMotorCommand(RIGHT, throttle - motors.getMotorAxisCommand(PITCH) - motors.getMotorAxisCommand(ROLL) + motors.getMotorAxisCommand(YAW));
    motors.setMotorCommand(LEFT, throttle + motors.getMotorAxisCommand(PITCH) + motors.getMotorAxisCommand(ROLL) + motors.getMotorAxisCommand(YAW));
    motors.setMotorCommand(REAR, throttle + motors.getMotorAxisCommand(PITCH) - motors.getMotorAxisCommand(ROLL) - motors.getMotorAxisCommand(YAW));
  } 

  // *********************** process min max motor command *******************
  processMinMaxMotorCommand();

  // Allows quad to do acrobatics by lowering power to opposite motors during hard manuevers
  if (flightMode == ACRO) {
    processHardManuevers();
  }

  // Apply limits to motor commands
  for (byte motor = FRONT; motor < LASTMOTOR; motor++) {
    motors.setMotorCommand(motor, constrain(motors.getMotorCommand(motor), motors.getMinCommand(motor), motors.getMaxCommand(motor)));
  }

  // If throttle in minimum position, don't apply yaw
  if (receiver.getData(THROTTLE) < MINCHECK) {
    for (byte motor = FRONT; motor < LASTMOTOR; motor++) {
      motors.setMotorCommand(motor, MINTHROTTLE);
    }
  }

  // ESC Calibration
  if (armed == OFF) {
    processCalibrateESC();
  }

  // *********************** Command Motors **********************
  if (armed == ON && safetyCheck == ON) {
    motors.write(); // Defined in Motors.h
  }
}
#endif
#ifdef plusConfig
//////////////////////////////////////////////////////////////////////////////
///////////////////////////////// PLUS MODE //////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
void processFlightControlPlusMode(void) {
  // ********************** Calculate Flight Error ***************************
  calculateFlightError();
  
  // ********************** Update Yaw ***************************************
  processHeading();

  // ********************** Altitude Adjust **********************************
  processAltitudeHold();

  // ********************** Calculate Motor Commands *************************
  if (armed && safetyCheck) {
    motors.setMotorCommand(FRONT, throttle - motors.getMotorAxisCommand(PITCH) - motors.getMotorAxisCommand(YAW));
    motors.setMotorCommand(REAR, throttle + motors.getMotorAxisCommand(PITCH) - motors.getMotorAxisCommand(YAW));
    motors.setMotorCommand(RIGHT, throttle - motors.getMotorAxisCommand(ROLL) + motors.getMotorAxisCommand(YAW));
    motors.setMotorCommand(LEFT, throttle + motors.getMotorAxisCommand(ROLL) + motors.getMotorAxisCommand(YAW));
  } 

  // *********************** process min max motor command *******************
  processMinMaxMotorCommand();

  // Allows quad to do acrobatics by lowering power to opposite motors during hard manuevers
  if (flightMode == ACRO) {
    processHardManuevers();
  }

  // Apply limits to motor commands
  for (byte motor = FRONT; motor < LASTMOTOR; motor++) {
    motors.setMotorCommand(motor, constrain(motors.getMotorCommand(motor), motors.getMinCommand(motor), motors.getMaxCommand(motor)));
  }

  // If throttle in minimum position, don't apply yaw
  if (receiver.getData(THROTTLE) < MINCHECK) {
    for (byte motor = FRONT; motor < LASTMOTOR; motor++) {
      motors.setMotorCommand(motor, MINTHROTTLE);
    }
  }

  // ESC Calibration
  if (armed == OFF) {
    processCalibrateESC();
  }

  // *********************** Command Motors **********************
  if (armed == ON && safetyCheck == ON) {
    motors.write(); // Defined in Motors.h
  }
}
#endif

