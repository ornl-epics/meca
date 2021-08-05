# MECA
EPICS Driver developed by Mariano Ruiz, zma@ornl.gov

 Meca500 Six-Axis Industrial Robot Arm Automation at Oak Ridge National Laboratory (ORNL) High Flux Isotope Reactor (HFIR) Biological Small-Angle Neutron Scattering Instrument (BIO-SANS) using the Experimental Physics and Industrial Control System (EPICS) toolkit.

A versatile sample changer that enables simultaneous spectroscopic measurements enhancing the throughput of the BIO-SANS beam line. The current sample holders handle 48 or 96 samples, but the software can be easily configured for other setups from a configuration file. To control the robot, there are two screens, the user screen and the advanced screen. The robot can be scripted using the beam line experiment variables.

The Meca500 is a Six-Axis Industrial Robot Arm with 5 micrometer precision. The robot can be interfaced using TCP/IP, EtherCAT or Ethernet/IP. The TCP/IP interface was selected. It is possible to move the motor in two different spaces, Joint Space and Cartesian Space. This software uses the three-dimensional cartesian coordinate system.

The software to control the sample changer uses the EPICS toolkit and Python. More Specifically, the EPICS Asyn driver establish the TCP/IP connection, the EPICS database handles the initialization parameters, Alarms, a section of the logic, and shares the process variables via CA (Channel Access) to the CSS GUI. Scripting of the robot according to beam line acquisition is accessed using CA. The EPICS State Notation Language handles most of the logic and sequencing of the steps. The software is written in a way that the sequencing of steps and positions can be configured from a file making the software highly flexible. The configuration file parsing and coordinate loading is accomplished with Python.

Software Flow

Communicating using the TCP/IP method and Network Topology

There are two ports used for communication, the control port and the monitor port. Since monitoring can be accomplished using the control port, the BIO-SANS Sample Changer software sends motion and requests commands solely over the control port 10000. The communication was originally tested with LabVIEW® and then migrated to EPICS. The communication uses the Asyn drvAsynIPPort driver to communicate over TCP/IP.

drvAsynIPPortConfigure ("Robot1","10.112.63.200:10000",0,0,0)

The network that communicates to the robot is secluded from the servers to prevent unwanted network traffic pollution and access. The robot resides on 10.112.X.X class B network and uses a router to communicate to the control server on network 10.111.X.X. Additionally, outside monitoring can be accomplished over outside access networks.

The Robot receives plain text ASCII commands over the TCP/IP line from a Linux server Point to Point and the control and status view of the Robot can be accessed using the EPICS CA protocol from any 10.111 network or view access on other networks using CSS GUI or CATOOLS. The CA EPICS protocol is based on UDP and TCP/IP.

Initialization Commands

The initialization commands are used to set clear errors, enable movement, and set forces and velocities.

MECA Robot Main DB Mariano Ruiz Dec 8th, 2020
#initialize Robot
record(seq, "SE:SE:Robot:InitSeq") {
  field(DESC, "Initialize Robot")
  field(PINI, "YES") #Process on initialization of software
  field(DOL1, "1")
  field(DLY1, "1")
  field(LNK1, "SE:SE:Robot:ResetError.PROC")
  field(DOL2, "1")
  field(DLY2, "1")
  field(LNK2, "SE:SE:Robot:ResumeMotion.PROC")
  field(DOL3, "1")
  field(DLY3, "1")
  field(LNK3, "SE:SE:Robot:SetGripperVel.PROC") #%40
  field(DOL4, "1")
  field(DLY4, "1")
  field(LNK4, "SE:SE:Robot:SetGripperForce.PROC") #%30
  field(DOL5, "1")
  field(DLY5, "1")
  field(LNK5, "SE:SE:Robot:SetJointVel.PROC") #%40
  field(DOL6, "1")
  field(DLY6, "1")
  field(LNK6, "SE:SE:Robot:SetCartLinVel.PROC") #80 mm/s
}


First, the Boolean record ResetError? resets the robot error status. Secondly, the Boolean record ResumeMontion? resumes the robot motion. Thirdly, the Gripper Velocity is configured using a percentage (∼100mm/s) ranging from 10%to100%. The software uses 40 mm/s gripper velocity. The gripper Force is configured (∼40 N) 10% to 100%. The software uses %30 or 12 N of gripper force. The velocities of all joints are limited proportionally. The top velo city of joints 1 and 2 is 150 ∘/s, of joint 3 is 180 ∘/s, of joints 4 and 5 is 300 ∘/s, and of joint 6 is 500 ∘/s. Our software uses %40 Joint Velocity. The software joints 1 and 2 are set to 60 ∘/s. Joint 3 is set to 72 ∘/s. Joint 4 and 5 are set to 120 ∘/s, and Joint 6 is set to 200 ∘/s. Lastly, the software sets the Cartesian Linear Velocity ranging from 0.001 mm/s to 1000 mm/s. the robot software is set to 80 mm/s.

Python Data File Parsing

The file has a semi-XML format. The <dedicated> tag, the <indx> tag, and the <cmd> tag, axises are saved to the file following the meca robot move commands, MoveLin?(%(A).3f,%(B).3f,%(C).3f,%(D).3f,%(E).3f,%(F).3f)";

A Python script parses the dedicated coordinates, the start and stop index of commands, the command groups, and the six axis coordinates. All of these variables are loaded into memory as waveform records and parsed and sequenced by the State Notation Language. The waveform records can be interpreted as single dimensional arrays. The dedicated array handles 300 points or 50 axis groups. The start and stop index can have up to 10000 values or 5000 start/stop indexes. The commands can handle up to 10000 steps. Lastly, the software can have 1666 axis groups.

The <dedicated> tag coordinates are used for manual movements. On the screen the advanced user can trigger up to 13 dedicated position from a momentary push button, but the software can handle up to 50 dedicated positions if the user inputs the index of the dedicated coordinate group and triggers the Move Linear push button.

The <indx> tags contains the limits of the start of commands and the stop of commands. It indicates to the software where the start of a full sample move and recover ends.

The <cmd> tags are what dictates the logic of steps of the code. The command has the axis group location to move, how long to wait after moving in seconds, and gripper and/or CallBack? commands. The CallBack? is used to inform the scripting or other software that the Place Sample or Return Sample has finished.

<cmd>	Select Coordinate location Step X	Wait Step X	Gripper and CallBack Actions Number Step X	Select Coordinate location Step X+1	Wait Step X+1	Command Number Step X+1

Actions for gripper and CallBacks on <cmd> tag 
Command 1	Open Gripper
Command 2	Close Gripper
Command 3	Close Gripper and check for part on Gripper
Command 4	Wait for Resume command and clear CallBack
Command 5	Clear Sample Placed at landing pad CallBack
Command 6	Clear CallBack Sample return to cartridges 


SNL (State Notation Language)

The SNL handles most of the software logic. Its job is to deconstruct the waveforms containing the dedicated coordinates, indexes, commands, and coordinates. Receive the sample number to place on the neutron beam and to return the sample while checking the status of the robot and reporting error and position status to CSS. Additionally, sets the Place and Return CallBacks?.

Simplified Pseudocode
If ExecuteButton=True and SampleNumber>0 and Paused=False
	Set Status to Moving
	Get the Start Index of Sample Number and Stop Index of Sample Number
		Get the corresponding Sample coordinates, waits, and commands in StartIndx and StopIndx
		While the Counter is not equal to StopIndx of Sample Number
			Counter = Counter +1
			Get Corresponding Coordinate groups
			Move to Next Position
				If not within tolerance and not time out
					Wait
				Endif
			Wait Time before moving to next position
			Get Next Command 
				If Command = Open Gripper
					Open the Gripper
				If Command = Close Gripper
					Close the Gripper
				If Command = Close Gripper and check for part on Gripper
					Close the Gripper
					if part on gripper
						Set Status to Part Found
					Else
						Set Status to Error Part not Found and Stop
					Endif						

				If Command = Wait for Resume command and clear CallBack
					Clear CallBack
					While resume command not received
						Set Status to waiting for return sample command
					Endwhile

				If Command = Clear Sample Placed at landing pad CallBack
					Clear sample placed CallBack
Set Status to Clear sample placed CallBack
				
				If Command = Clear CallBack Sample return to cartridges 
					Clear sample return to cartridge CallBack
					Set Status to clear sample return to cartridge CallBack
				Else
					Set Status to command not defined
				Endif	
		

		Endwhile 
	Set Status to not Moving
Endif
		

Alarm

The robot software can alert if an error has occurred over the network using CA to an alarm handler monitoring hundreds of other CA alarms around the beam lines. To alert if an alarm has occurred, the software uses the CA protocol. This PV checks if the Status, GES, GOH, PartError?, PauseState?, and Activation State. GetStatusRobot? checks if the robot is activated, homed, not in simulation, not on error, and not paused. GES checks for the gripper status error. GOH checks if the gripper is not overheated. PartError? checks if there is no part on the gripper when a part should be present. PuasedState? checks if the robot is not paused. Lastly, ActivationState? checks if the robot is active. If any of these conditions are true and the alarm is enabled, the GlobalAlarm? PV is activated.

record(calc, "SE:SE:Robot:GlobalAlarm"){
  field(INPA, "SE:SE:Robot:AlarmDisable CPP")
  field(INPB, "SE:SE:Robot:ErrorState CPP")
  field(INPC, "SE:SE:Robot:GES CPP")
  field(INPD, "SE:SE:Robot:GOH CPP")
  field(INPE, "SE:SE:Robot:PartError CPP")
  field(INPF, "SE:SE:Robot:PausedState CPP")
  field(INPG, "SE:SE:Robot:ActivationState CPP")
  field(CALC, "A&((B>0)|C>0|D>0|E>0|F>0|G=0)")
  field(HIHI, "1")
  field(HHSV, "MAJOR")
  info(archive, "Monitor, 00:01:00")

}		

Event Driven Confirmation and Scripting.

The software is capable of alerting the operator that the sample has been placed or returned correctly as an event. The event driven actions are also referred as CallBacks?. As soon as the robot starts to move, the software automatically set the Place Sample CallBack? equal to True. The Place Sample CallBack? is cleared by commands 4 or 5 in the SNL. The commands 5 is normally positioned after the Sample has been placed on the beam and the arm is cleared from Radiation Exposure. The Return Sample CallBack? is set automatically by the software as soon as the user or script sends the return sample Command. After the sample can is returned to the cartridge holder, the command 6 is sent to Clear Return Sample CallBack?. At this point, the script or the user can continue by placing another sample or changing other PVs around the beam line.

Command 4	Wait for Resume command and clear CallBack
Command 5	Clear Sample Placed at landing pad CallBack
Command 6	Clear CallBack Sample return to cartridges 

References for Software Section of the Paper later to be added at the end of the main paper.

​https://cdn.mecademic.com/uploads/docs/meca500-r3-programming-manual-8-3.pdf

​https://epics.anl.gov/EpicsDocumentation/AppDevManuals/Sequencer/snl_1.9_man.html

​https://epics.anl.gov/base/R3-14/12-docs/CAref.html

Meca Recovery in case of Error



Ensure samples, hat, are back to position and gripper is free.
 
On CSS go to IOC Status and stop the meca robot IOC.
 
Go to http://10.112.63.200 on the local OPI.
 
Connect to the robot by clicking the AC connector icon on the right top.
 
Now activate by clicking the lightning icon.
 
Home the robot by clicking on the little single story tiny black house with a chimney.
 
Disconnect by unchecking the AC connector icon.
 
On CSS Start meca IOC on IOC Status screen.
 
On CSS meca robot advanced screen click neutral and then move linear. The password is meca. This will move the robot to the neutral position. If you were unable to remove a sample from the gripper, you can execute the open gripper on the advanced screen. It will drop the sample.
 
As the last step select a sample to continue with the experiment or run the script from the start of placing a sample.





EPICS Module ASYN drvAsynIPPortConfigure
