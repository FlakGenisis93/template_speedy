################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/lcd.c \
../src/main.c 

OBJS += \
./src/lcd.o \
./src/main.o 

C_DEPS += \
./src/lcd.d \
./src/main.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler 4 [arm-linux-gnueabihf]'
	arm-linux-gnueabihf-gcc -I"C:\altera\16.0\embedded\ip\altera\hps\altera_hps\hwlib\include" -I"H:\Git\template_speedy\hps_workspace\lcd\actuators" -O0 -g -Wall -c -fmessage-length=0 -Dsoc_cv_av -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


