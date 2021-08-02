#!/usr/bin/env python
#Mariano Ruiz Dec 11, 2020 could be a function
import os
import re
import string
import epics
import time
import ast
from string import join

beamline = os.getenv('BEAMLINE')
beamline = beamline.upper()
#print beamline

TriggerLogicPV=beamline+":SE:Robot:RunScript"
PathPV=beamline+":SE:Robot:ScriptFile"
CoordinatesPV=beamline+":SE:Robot:Coordinates"
IndexPV=beamline+":SE:Robot:SampleNumA"
CommandsPV=beamline+":SE:Robot:Commands"
DCoordPV=beamline+":SE:Robot:DCoord"

data = ""


Tlo  = epics.PV(TriggerLogicPV)
path = epics.PV(PathPV)
Cpv  = epics.PV(CoordinatesPV)
Ipv  = epics.PV(IndexPV)
CopV = epics.PV(CommandsPV)
Dcpv = epics.PV(DCoordPV)

trigger=Tlo.get()
#####css when loads triggers the script
#####the TriggerLogicPV prevents triggering when css loads
if trigger ==1:
	print ("starting script to get coordinates")
#####get path and conver from char to string
	ar_val=path.get(as_string=True)
	location= ar_val


	file = open(location)
	#file = open("/home/controls/share/opi/meca/robot/script/Robot_Positions.txt")
	data = file.read()
	file.close()


#####################################MoveLin()
	Extract = re.findall(r'MoveLin\((.+?)\)',data)
	Extracted=join(Extract, ",")
	Extracted = re.sub('[^0-9\.\,\-]', '', Extracted)
	#print Extracted
	info=(ast.literal_eval(Extracted))
	Cpv.put(info)
	time.sleep(0.1)
####################################[]
	Extract = re.findall(r'<indx>(.+?)</indx>',data)
	Extracted=join(Extract, ",")
	Extracted = re.sub('[^0-9\.\,\-]', '', Extracted)
	#print Extracted
	info=(ast.literal_eval(Extracted))
	Ipv.put(info)
	time.sleep(0.1)
###################################<cmd></cmd>
	Extract = re.findall(r'<cmd>(.+?)</cmd>',data)
	Extracted=join(Extract, ",")
	Extracted = re.sub('[^0-9\.\,\-]', '', Extracted)
	print Extracted
	info=(ast.literal_eval(Extracted))
	CopV.put(info)
	time.sleep(0.1)
###################################<dedicated></dedicated>
	Extract = re.findall(r'<dedicated>(.+?)</dedicated>',data)
	Extracted=join(Extract, ",")
	Extracted = re.sub('[^0-9\.\,\-]', '', Extracted)
	#print Extracted
	info=(ast.literal_eval(Extracted))
	Dcpv.put(info)
	time.sleep(0.1)

	print ("Script to import meca coordinates finished")

