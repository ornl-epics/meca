program mecaprg


option +r;
option +d;

%{#include <string.h>}%
%{#include <stdlib.h>}%
%{#include <unistd.h>}%
%{#include <math.h>}%


#define Axis_DeadBand_ 0.005     /*Constant defines allowable window at_position*/

char buffer[50];   		//buffer to hold message


string message_pv;
assign message_pv to "{S}:Message";

unsigned short Status_pv;
assign Status_pv to "{S}:Status";
monitor Status_pv;


unsigned short PausedState_pv;
assign PausedState_pv to "{S}:PausedState";
monitor PausedState_pv;


#define idle_ 1 
#define moving_ 2
#define opengrip_ 4
#define closegrip_ 8
#define error_ 16

unsigned short HasRun; 

float SampleNum_pv;
assign SampleNum_pv to "{S}:SampleNum";
monitor SampleNum_pv;

unsigned short SampleNumA_pv [30000];
assign SampleNumA_pv to "{S}:SampleNumA";
monitor SampleNumA_pv;

unsigned short InTol_pv;
assign InTol_pv to "{S}:InTol";
monitor InTol_pv;

float GripperOpen_pv;
assign GripperOpen_pv to "{S}:GripperOpen";
monitor GripperOpen_pv;

float GripperClose_pv;
assign GripperClose_pv to "{S}:GripperClose";
monitor GripperClose_pv;

float HoldingPart_pv;
assign HoldingPart_pv to "{S}:GHP";
monitor HoldingPart_pv;

unsigned short Execute_pv;
assign Execute_pv to "{S}:Execute";
monitor Execute_pv;


unsigned short SetMoveLin_pv;
assign SetMoveLin_pv to "{S}:SetMoveLin";


float StartIndx_pv;
assign StartIndx_pv to "{S}:StartIndx";
monitor StartIndx_pv;

float StopIndx_pv;
assign StopIndx_pv to "{S}:StopIndx";
monitor StopIndx_pv;


float Selector_pv;
assign Selector_pv to "{S}:Selector";
monitor Selector_pv;


float Wait_pv;
assign Wait_pv to "{S}:Wait";
monitor Wait_pv;

float Instruction_pv;
assign Instruction_pv to "{S}:Instruction";
monitor Instruction_pv;


float Commands_pv [30000];
assign Commands_pv to "{S}:Commands";
monitor Commands_pv;

unsigned short ResumeFlag_pv;
assign ResumeFlag_pv to "{S}:ResumeFlag";
monitor ResumeFlag_pv;


unsigned short UnsetCB_pv;
assign UnsetCB_pv to "{S}:UnsetCB";
monitor UnsetCB_pv;

unsigned short RtrUnsetCB_pv;
assign RtrUnsetCB_pv to "{S}:RtrUnsetCB";
monitor RtrUnsetCB_pv;



unsigned short SLP; 
unsigned short i;
unsigned short ii;
double v;



ss meca1 {
state init {
	when () 	
{

}	      
	state idle	
}	

state idle {
    	when (Execute_pv !=1) 
{
        if (Status_pv !=error_)
{
        Status_pv=idle_;
        pvPut(Status_pv, SYNC);

        strcpy(message_pv, "Idle State");
        pvPut(message_pv);
        epicsThreadSleep(0.2);
}
} 
	state move 
}




state move {
/*State does the parsing of arrays and moves the robot if pause is not set*/
        when (Execute_pv==1 && SampleNum_pv>0 && PausedState_pv!=1)         {
        Status_pv=moving_;
        pvPut(Status_pv, SYNC);
	epicsThreadSleep(0.2);
	pvGet(SampleNum_pv, SYNC);
        pvGet(SampleNumA_pv, SYNC);
        ii=0;
	for (ii = 0; ii <= SampleNum_pv*2; ii++) {
       // if (i % 2 == 0 || SampleNum_pv ==0){
	StartIndx_pv =	SampleNumA_pv[ii-2];
        StopIndx_pv = SampleNumA_pv[ii-1];
        snprintf(buffer,40, "Pickout:Range indexes, %f, %f", StartIndx_pv, StopIndx_pv);
        strncpy(message_pv, buffer, 40);
        pvPut(message_pv);        
	epicsThreadSleep(0.01);
//}	
}
        pvPut(StartIndx_pv, SYNC);
        pvPut(StopIndx_pv, SYNC);

{
        strcpy(message_pv, "Moving");
        pvPut(message_pv);
	pvGet(StartIndx_pv, SYNC);
        pvGet(StopIndx_pv, SYNC);
        i=0;
        for (i = StartIndx_pv*3; i <= StopIndx_pv*3; i++) {
        if ((i % 3 == 0)&&(Status_pv!=error_)){
	        Status_pv=moving_;
        	pvPut(Status_pv, SYNC);
                epicsThreadSleep(0.2);
                strcpy(message_pv, "Moving:Going to next Coordinate");
                pvPut(message_pv);
                pvGet(Commands_pv, SYNC);
                printf("Order = %f Wait = %f instruction = %f \n", Commands_pv[i], Commands_pv[i+1], Commands_pv[i+2]);
                Selector_pv = Commands_pv[i];
                pvPut(Selector_pv, SYNC);
                Wait_pv = Commands_pv[i+1];
                pvPut(Wait_pv, SYNC);
                Instruction_pv = Commands_pv[i+2];
                pvPut(Instruction_pv, SYNC);
                epicsThreadSleep(0.2);
                SetMoveLin_pv = 1;
                pvPut(SetMoveLin_pv, SYNC);
                epicsThreadSleep(0.2);
                while(InTol_pv!=1){
                        epicsThreadSleep(0.1);
                        strcpy(message_pv, "Moving:Wait for within tolerance");
                        pvPut(message_pv);
                }
                //Sleep Function with message
                SLP==0;
                for(SLP=0;SLP<=Commands_pv[i+1]*10;SLP++){
                        epicsThreadSleep(0.100);
                        snprintf(buffer,40, "Moving:Wait after within tol %i mS", SLP*100);
                        strncpy(message_pv, buffer, 40);
                        pvPut(message_pv);
                                                         }
//Open Gripper
                 if (Instruction_pv==1)
{
                Status_pv=opengrip_;
                pvPut(Status_pv, SYNC);

                GripperOpen_pv = 1;
                pvPut(GripperOpen_pv, SYNC);
                SLP==0;
                for(SLP=0;SLP<=5;SLP++){
                        epicsThreadSleep(0.100);
                        snprintf(buffer,40, "Moving:Wait gripper Open %i mS", SLP*100);
                        strncpy(message_pv, buffer, 40);
                        pvPut(message_pv);

                }

}

//close gripper without checking for sample
                 if (Instruction_pv==2)
{
        	Status_pv=closegrip_;
	        pvPut(Status_pv, SYNC);

                GripperClose_pv = 1;
                pvPut(GripperClose_pv, SYNC);
 		SLP==0;
                for(SLP=0;SLP<=5;SLP++){
                        epicsThreadSleep(0.100);
                        snprintf(buffer,40, "Moving:Wait gripper Close %i mS", SLP*100);
                        strncpy(message_pv, buffer, 40);
                        pvPut(message_pv);

                }

}

//close the gripper and check for status of gripper to have sample

                if (Instruction_pv==3)
{
                SLP=0;
                pvGet(HoldingPart_pv);
                Status_pv=closegrip_;
                pvPut(Status_pv, SYNC);
                GripperClose_pv = 1;
                pvPut(GripperClose_pv, SYNC);
                epicsThreadSleep(0.5);

                for(SLP=0;HoldingPart_pv==0;SLP++){
                        pvGet(HoldingPart_pv);
                        epicsThreadSleep(0.200);
                        snprintf(buffer,40, "Gripper:Close, Check for Sample %i mS", SLP*100);
                        strncpy(message_pv, buffer, 40);
                        pvPut(message_pv);
                        if (HoldingPart_pv==1)
				{
					
					snprintf(buffer,40, "Gripper:Part Found");
		                        strncpy(message_pv, buffer, 40);
                		        pvPut(message_pv);
					SLP = 200;	
				}


            		if (HoldingPart_pv==0 && SLP>200)
			{
                                Status_pv=error_;
                                pvPut(Status_pv);
                                strcpy(message_pv, "Gripper:Error No Part");
                                pvPut(message_pv);
				
			}

		}
}

//wait in for loop until flag to resume

                if (Instruction_pv==4)
{
                for(SLP=0;ResumeFlag_pv==0;SLP++){
                        epicsThreadSleep(0.500);
                        snprintf(buffer,40, "Moving:waiting for resume %iS", SLP/2);
                        strncpy(message_pv, buffer, 40);
                        pvPut(message_pv);

                }


}
  
//Clear Call back for SampleNumbCB
                if (Instruction_pv==5)
{
                UnsetCB_pv = 1;
                pvPut(UnsetCB_pv, SYNC);

                for(SLP=0;SLP<=5;SLP++){
                        epicsThreadSleep(0.100);
                        snprintf(buffer,40, "Moving:Clear Callback %i mS", SLP*100);
                        strncpy(message_pv, buffer, 40);
                        pvPut(message_pv);

                }
}



//Clear Call back for return RtrFlagCB set
               if (Instruction_pv==6)
{
                epicsThreadSleep(2);
                for(SLP=0;InTol_pv==0;SLP++){

                        epicsThreadSleep(0.500);
                        snprintf(buffer,40, "Moving:waiting clear ResumeCB %iS", SLP/2);
                        strncpy(message_pv, buffer, 40);
                        pvPut(message_pv);

                }
                RtrUnsetCB_pv = 1;
                pvPut(RtrUnsetCB_pv, SYNC);


}



//wait in for loop until flag to resume is received and clear call back for sample

                if (Instruction_pv==7)
{
                epicsThreadSleep(1);
		HasRun = 0;
                for(SLP=0;ResumeFlag_pv==0;SLP++){
			if (InTol_pv==1 && HasRun==0){
			                UnsetCB_pv = 1;
			                pvPut(UnsetCB_pv, SYNC);
					HasRun = 1;
			}


                        epicsThreadSleep(0.500);
                        snprintf(buffer,40, "Moving:waiting for resume %iS CB cleared", SLP/2);
                        strncpy(message_pv, buffer, 40);
                        pvPut(message_pv);

                }


}



//Undifiened Instructions for the future
                if (Instruction_pv>7)
{
                for(SLP=0;SLP<=5;SLP++){
                        epicsThreadSleep(0.100);
                        snprintf(buffer,40, "Moving:command not defined %i mS", SLP*100);
                        strncpy(message_pv, buffer, 40);
                        pvPut(message_pv);

                }
}
                        epicsThreadSleep(0.2);

		if (PausedState_pv==1){
                for(SLP=0;PausedState_pv==1;SLP++){
                       	epicsThreadSleep(0.100);
                        snprintf(buffer,40, "Moving:Robot Paused %i mS", SLP*100);
                        strncpy(message_pv, buffer, 40);
                        pvPut(message_pv);

                }
}
                if (Status_pv != error_){
 
                        strcpy(message_pv, "Moving:Finished");
                        pvPut(message_pv);
}
		}
        }

}

}
        state idle   
}

}
