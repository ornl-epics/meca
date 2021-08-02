#!../../bin/linux-x86_64/Robot

## You may have to change Robot to something else
## everywhere it appears in this file

< envPaths

cd ${TOP}

## Register all support components
dbLoadDatabase "dbd/Robot.dbd"
Robot_registerRecordDeviceDriver pdbbase
drvAsynIPPortConfigure ("Robot1","10.112.63.200:10000",0,0,0)

dbLoadRecords(db/meca.db)
#################################################
# autosave

epicsEnvSet IOCNAME MecaRobot
epicsEnvSet SAVE_DIR /home/controls/var/$(IOCNAME)

save_restoreSet_Debug(0)

### status-PV prefix, so save_restore can find its status PV's.
save_restoreSet_status_prefix("CG3:SE:Robot:")

set_requestfile_path("$(SAVE_DIR)")
set_savefile_path("$(SAVE_DIR)")

save_restoreSet_NumSeqFiles(3)
save_restoreSet_SeqPeriodInSeconds(600)
set_pass0_restoreFile("$(IOCNAME).sav")
set_pass0_restoreFile("$(IOCNAME)_pass0.sav")
set_pass1_restoreFile("$(IOCNAME).sav")



cd ${TOP}/iocBoot/${IOC}
iocInit


#This prints low level commands and responses
#asynSetTraceMask("Robot1",0,0xFF)
#asynSetTraceIOMask("Robot1",0,0xFF)



# Create request file and start periodic 'save'
epicsThreadSleep(5)
makeAutosaveFileFromDbInfo("$(SAVE_DIR)/$(IOCNAME).req", "autosaveFields")
create_monitor_set("$(IOCNAME).req", 5)


## Start any sequence programs
seq(mecaprg, "S=CG3:SE:Robot")

