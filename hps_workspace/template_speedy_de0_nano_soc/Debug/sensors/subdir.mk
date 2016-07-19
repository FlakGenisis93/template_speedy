################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../sensors/ADXL345.c \
../sensors/gesonsor_nano.c \
../sensors/hmc6343.c \
../sensors/itg3200.c \
../sensors/laser.c \
../sensors/max11613.c \
../sensors/srf08.c \
../sensors/tpa81.c 

OBJS += \
./sensors/ADXL345.o \
./sensors/gesonsor_nano.o \
./sensors/hmc6343.o \
./sensors/itg3200.o \
./sensors/laser.o \
./sensors/max11613.o \
./sensors/srf08.o \
./sensors/tpa81.o 

C_DEPS += \
./sensors/ADXL345.d \
./sensors/gesonsor_nano.d \
./sensors/hmc6343.d \
./sensors/itg3200.d \
./sensors/laser.d \
./sensors/max11613.d \
./sensors/srf08.d \
./sensors/tpa81.d 


# Each subdirectory must supply rules for building sources it contributes
sensors/%.o: ../sensors/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler 4 [arm-linux-gnueabihf]'
	arm-linux-gnueabihf-gcc -Dsoc_cv_av -I"H:\Git\template_speedy\hps_workspace\template_speedy_de0_nano_soc\actuators" -I"H:\Git\template_speedy\hps_workspace\template_speedy_de0_nano_soc\src" -I"H:\Git\template_speedy\hps_workspace\template_speedy_de0_nano_soc\sensors" -I"C:\altera\16.0\embedded\ip\altera\hps\altera_hps\hwlib\include" -O0 -g -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


