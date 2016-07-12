#include "laser_include.h"

/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    task1_stk[TASK_STACKSIZE];
OS_STK    task2_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */

#define TASK1_PRIORITY		6
#define TASK2_PRIORITY		5

void task1(void* pdata)
{
	uint16_t distance[ARRAY_LENGHT];
	uint8_t debug =0;
	while (1)// fuer immer...
	{
		printf("TASK 1\n");
/************************************************/
/****			H	I	E	R				*****/
/****	Q	U	E	L	L	C	O	D	E	*****/
/****	E	I	N	F	U	E	G	E	N	*****/
/************************************************/
		debug = doMeasurement(&distance);
		OSTimeDlyHMSM(0, 0, 1, 0);
	}

}


void task2(void* pdata)
{
	while(1)//fuer immer...
	{
		printf("Task 2 begin\n");
////
/////************************************************/
/////****			H	I	E	R				*****/
/////****	Q	U	E	L	L	C	O	D	E	*****/
/////****	E	I	N	F	U	E	G	E	N	*****/
/////************************************************/
		OSTimeDlyHMSM(0, 1, 0, 0);
		printf("\nTask 2 end\n");
	}// fuer immer...
}
/* The main function creates two task and starts multi-tasking */
int main(void)
{
  
  OSTaskCreateExt(task1,
                  NULL,
                  (void *)&task1_stk[TASK_STACKSIZE-1],
                  TASK1_PRIORITY,
                  TASK1_PRIORITY,
                  task1_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);


  OSTaskCreateExt(task2,
                  NULL,
                  (void *)&task2_stk[TASK_STACKSIZE-1],
                  TASK2_PRIORITY,
                  TASK2_PRIORITY,
                  task2_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);
  OSStart();


  return 0;
}
