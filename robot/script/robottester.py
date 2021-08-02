#!/usr/bin/env python
import re
import string
import epics
import time
import ast

CBStatusPV="CG3:SE:Robot:Busy.RVAL"
CBSampleNumberPV="CG3:SE:Robot:SampleNumCB"
SampleNumberPV = "CG3:SE:Robot:SampleNum"
ResumeFlagPV = "CG3:SE:Robot:ResumeFlag"
RobotStatusPV = "CG3:SE:Robot:Status"


CBStatus_pv  = epics.PV(CBStatusPV)
CBSampleNumber_pv= epics.PV(CBSampleNumberPV)
SampleNumber_pv = epics.PV(SampleNumberPV)
ResumeFlag_pv = epics.PV(ResumeFlagPV)
RobotStatus_pv = epics.PV(RobotStatusPV) 

for i in range (5):
	print("group test %d" %(i))
	CBint = 0
	print("Starting test")
	for x in range(0, 49):
	    PrintOnce = 1
	    print("We're on sample %d" % (x))
	    CBSampleNumber_pv.put(x)
	    time.sleep(2)
	    RobotStatusint =RobotStatus_pv.get() 
	    time.sleep(2)
	    while RobotStatusint>1: 
		print("robot status, %d" % (RobotStatusint))
	   	RobotStatusint =RobotStatus_pv.get()
		time.sleep(20)
        	if PrintOnce:
        		print("We're waiting for robot-- we are on sample %d" % (x))
			PrintOnce = 0
        	ResumeFlag_pv.put(1)

	print("Test Finished ran all samples %d times", (i))


