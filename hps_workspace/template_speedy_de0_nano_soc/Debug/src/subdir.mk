################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/main.c 

OBJS += \
./src/main.o 

C_DEPS += \
./src/main.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler 4 [arm-linux-gnueabihf]'
	arm-linux-gnueabihf-gcc -Dsoc_cv_av -I"H:\Masterarbeit\work\quartus\hps_workspace\template_speedy_de0_nano_soc\actuators" -I"H:\Masterarbeit\work\quartus\hps_workspace\template_speedy_de0_nano_soc\src" -I"H:\Masterarbeit\work\quartus\hps_workspace\template_speedy_de0_nano_soc\sensors" -I"C:\altera\16.0\embedded\ip\altera\hps\altera_hps\hwlib\include" -O0 -g -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


