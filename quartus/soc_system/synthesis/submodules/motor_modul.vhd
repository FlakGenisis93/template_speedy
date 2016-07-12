--! @file 	motor_modul.vhd
--! @brief	Dieses Modul dient zur verarbeitung der eingehenden Befehle und zur Steuerung ueber
--!			die Regler.
--! @details	In diesem MOdul werden die Eingaenge in Registern abgelegt und alle gro�en
--! 		Operationen durchgefuehrt. Es wird vermieden mit real Zahlen zu rechnen und 
--!		stattdessen wird auf integer werte zurueckgegriffen.
--! 		Die Realisierung erfolgt ueber eine Statemachine die je nach Befehl die passenden
--!		Operationen ausfuehrt.
--! 		Es wird hier auf die Distanz und die Geschwindigkeit ueberpruft.
--!
--! 
--! @author 	BoE. Lt. Kluge Florian
--! @version 	V0.6.0
--! @date    	30.06.2016
--!
--! @par History:
--! @details	- 	V0.1 	start of development 
--!				01.04.2016 Kluge
--!
--! @details	-	V0.2	Drive_st mit Motor m1 und Distanz funktioniert
--!				26.04.2016 Kluge
--!
--! @details	-	V0.3	Drive_st mit m1/m2 sowie turn_st mit m1/m2 + anfaenge vom curve_st
--!				09.05.2016 Kluge
--!
--! @details	-	V0.4.0	Regler fuer drive_st implementiert
--!				30.04.2016 Kluge
--!
--! @details	-	V0.4.1	drive_st fertiggestellt
--!				10.05.2016 Kluge
--!
--! @details	-	V0.5.0	turn_st mit Regler verbunden
--!				30.05.2016 Kluge
--!
--! @details	-	V0.5.1	turn_st optimiert und fertiggestellt
--!				06.06.2016 Kluge			
--!
--! @details	-	V0.6.0	curve_st fertiggestellt
--!				30.06.2016 Kluge			
--!
--! @todo		---
--!
--! @bug			---


library IEEE;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;


-- C Befehl muss: - laut interface daten pruefen und in die richtigen register schreiben

entity motor_modul is
	Generic( 
           REG1_cntBits: INTEGER := 8;
           REG2_cntBits: INTEGER := 16;
           REG3_cntBits: INTEGER := 3
           
	);

	port
	(
		
		clk								: in std_logic;
		reset_n							: in std_logic;		

	--Gyro input 
		gyro_angle_in					: in std_logic_vector(REG2_cntBits-1 downto 0); 	--noch nicht gepr�ft

	--Encoder 1 und 2 input
		encoder1_register_in			: in std_logic_vector(1 downto 0); 
		encoder2_register_in			: in std_logic_vector(1 downto 0); 

	--Input vom interface
		sabertooth_m1_command_in	: in std_logic_vector(REG1_cntBits-1 downto 0);		--:= (others=>'0');--fragen ob man vorher belegen darf/muss...
		sabertooth_m2_command_in	: in std_logic_vector(REG1_cntBits-1 downto 0);
		sabertooth_m_angle_in		: in std_logic_vector(REG2_cntBits-1 downto 0);
		sabertooth_m_distance_in	: in std_logic_vector(REG2_cntBits-1 downto 0);
		sabertooth_m_relation_in	: in std_logic_vector(REG1_cntBits-1 downto 0);
		sabertooth_m_speed_in		: in std_logic_vector(REG2_cntBits-1 downto 0);
		sabertooth_m_cmd_in			: in std_logic_vector(REG3_cntBits-1 downto 0);
		sabertooth_m_start_in		: in std_logic;
		
		curve_m1_distance_in			: in std_logic_vector(REG2_cntBits-1 downto 0);		--sl strecke links
		curve_m2_distance_in			: in std_logic_vector(REG2_cntBits-1 downto 0);		--sr strecke rechts
		curve_resolution_in			: in std_logic_vector(REG2_cntBits-1 downto 0);

	--Output zum interface
		uart_out							: out std_logic;
		LED_DriveStatus				: out std_logic_vector(1 downto 0);
		done_reg							: out std_logic := '1';										--zur Steuerung in Nios
		E1_reg							: out std_logic_vector(REG2_cntBits-1 downto 0);	--zum Debuggen
		E2_reg							: out std_logic_vector(REG2_cntBits-1 downto 0);	--zum Debuggen
		curve_angle_reg				: out std_logic_vector(REG2_cntBits-1 downto 0);	--zum Debuggen
		curve_angle_sum_reg			: out std_logic_vector(REG2_cntBits-1 downto 0)		--zum Debuggen
 

	);

end motor_modul;

architecture arch_motor_modul of motor_modul is

--------component encoder_motor------------------------------------------------------------------------------------
	component encoder_motor is
		port(
			reset_n								: in std_logic;
			clk									: in std_logic;
						
			LED_DriveStatus					: out std_logic_vector( 1 downto 0);                      
			Encoder1_DriveSystem				: in std_logic_vector( 1 downto 0)  := (others => 'X'); 
         Encoder2_DriveSystem				: in std_logic_vector( 1 downto 0)  := (others => 'X'); 
			Encoder1_Register					: out std_logic_vector(15 downto 0);                     
			Encoder2_Register					: out std_logic_vector(15 downto 0);

			Encoder1_Full_Register			: out std_logic_vector(19 downto 0);
			Encoder2_Full_Register			: out std_logic_vector(19 downto 0);
			Encoder1_Full_Register_Enable	: in std_logic;
			Encoder2_Full_Register_Enable	: in std_logic;
			Encoder_New_Command				: in std_logic
		);
	end component encoder_motor;

--------component baud_gen---------------------------------------------------------------------------------------
	component baud_gen_k is
		port(
			reset_n	: in STD_LOGIC; 
			clk		: in STD_LOGIC; 

			baud_en	: out STD_LOGIC
		);
	end component baud_gen_k;

--------component uart_send---------------------------------------------------------------------------------------
	component uart_send_k is
		port(
			reset_n		: in STD_LOGIC; 
			clk			: in STD_LOGIC; 

			send_en		: in STD_LOGIC := '0';
			send_active	: in STD_LOGIC := '0';
			send_m1_in	: in STD_LOGIC_VECTOR(31 DOWNTO 0);
			send_m2_in	: in STD_LOGIC_VECTOR(31 DOWNTO 0);
			send_done	: out STD_LOGIC := '0';
			send_out		: out STD_LOGIC := '0'
		);
	end component uart_send_k;


--------component winkel_modul---------------------------------------------------------------------------------------
	component winkel_modul is
		Generic( 
			MAX_COUNT: integer := 5_000_000;	--neue werte des gyros alle 100ms -> 50MHz(system) -->5000000
			REG1_Angle_cntBits: INTEGER := 16
			);
		port
		(
			reset_n				: in  std_logic;
			clk					: in  std_logic;

			drive_enable_in	: in  std_logic;
			turn_enable_in		: in  std_logic;
			curve_enable_in	: in  std_logic;

			gyro_angle_in		: in std_logic_vector(REG2_cntBits-1 downto 0); --eigentlich 16bit fuer Zahle aber vllt. 15bit(32767) und 1bit fuer +/-
			aim_angle_in		: in std_logic_vector(REG2_cntBits-1 downto 0); --eigentlich 16bit fuer Zahle aber vllt. 15bit(32767) und 1bit fuer +/- // +/- wird hier aber nicht gebraucht...

			--resolution_in		: in std_logic_vector(REG2_cntBits-1 downto 0);
			
			curve_angle_out	: out std_logic_vector(REG2_cntBits-1 downto 0);
			--curve_enable_out	: out std_logic;
			turn_enable_out	: out std_logic
			--drive_enable_out	: out std_logic				
		);
	end component winkel_modul;
		
		
--------component pid_regler---------------------------------------------------------------------------------------
	component pid_regler
		generic(
			REG1_cntBits		: INTEGER := 8;
			REG2_cntBits		: INTEGER := 16;

			CNT_MAX				: INTEGER := 2_500_000 --enspricht bei 50MHZ 0,1s// 2_500_000->50ms

		);
 
		port(
			clk					: in std_logic;
			reset_n				: in std_logic;		

			active_in			: in std_logic;
			w1_soll_in			: in std_logic_vector(REG2_cntBits-1 downto 0); --in ticks/100ms von c
			x1_ist_in			: in std_logic_vector(REG2_cntBits-1 downto 0); --in ticks/100ms von encoder
			w2_soll_in			: in std_logic_vector(REG2_cntBits-1 downto 0); --in ticks/100ms von c
			x2_ist_in			: in std_logic_vector(REG2_cntBits-1 downto 0); --in ticks/100ms von encoder
			y1_out				: out std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0'); -- geschwindigkeits stufen 0-127
			y2_out				: out std_logic_vector(REG1_cntBits-1 downto 0):= (others=>'0'); -- geschwindigkeits stufen 0-127
			new_value_m1_out	: out std_logic := '0';
			new_value_m2_out	: out std_logic := '0'
		);
	end component pid_regler;


--states
type state_type is(get_cmd_st, drive_st, turn_st, curve1_st, curve2_st);
signal state_s 									: state_type := get_cmd_st;

--signals
signal sabertooth_m1_command_reg				: std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0');
signal sabertooth_m2_command_reg				: std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0');
signal sabertooth_m_angle_reg					: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');
signal sabertooth_m_distance_reg				: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');
signal sabertooth_m_relation_reg				: std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0');
signal sabertooth_m_speed_reg					: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');

signal curve_m1_speed_sig						:  std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0'); --8 bit da max. 127
signal curve_m2_speed_sig						:  std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0'); --8 bit da max. 127
signal curve_lr_sig								:	std_logic_vector(1 downto 0) 					:= (others=>'0'); --kennzeichnet seite mit laengerem weg
--signal curve_m1_distance_reg					: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');
--signal curve_m2_distance_reg					: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');
signal m1_speed_sig								:  std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); --8 bit da max. 127
signal m2_speed_sig								:  std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); --8 bit da max. 127



--signals fuer encoder
signal Encoder1_Register_sig					: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');
signal Encoder2_Register_sig					: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');

signal Encoder1_Full_Register_sig			: std_logic_vector(19 downto 0) := (others=>'0');
signal Encoder2_Full_Register_sig			: std_logic_vector(19 downto 0) := (others=>'0');
signal Encoder_New_Command_sig				: std_logic := '0';
signal Encoder1_Full_Register_Enable_sig	: std_logic := '0';
signal Encoder2_Full_Register_Enable_sig	: std_logic := '0';

--signals fuer uart
	--signals fuer baud_gen
	signal baud_en_sig 							: std_logic := '0';
	
	--signals fuer uart_send
	signal send_active_sig						: STD_LOGIC := '0';
	signal send_m1_in_sig						: STD_LOGIC_VECTOR(31 DOWNTO 0):= (others=>'0');
	signal send_m2_in_sig						: STD_LOGIC_VECTOR(31 DOWNTO 0):= (others=>'0');
	signal send_done_sig							: STD_LOGIC := '0';


--signals zum steuern
signal job_m1_working_sig						: std_logic := '0'; 		--aktive flag
signal job_m2_working_sig						: std_logic := '0'; 		--aktive flag
signal sabertooth_m_distance_in_ticks_var	: std_logic_vector(19 downto 0) := (others=>'0'); --uebergabe var fuer das links-schieben
--signal send_achtiv_m1_sig						: std_logic := '0';		--steuert das starten des Uarts
--signal send_achtiv_m2_sig						: std_logic := '0';		--steuert das starten des Uarts
signal job_m1_done_sig							: std_logic := '0'; 		--aktive flag
signal job_m2_done_sig							: std_logic := '0'; 		--aktive flag
signal curve_m1_distance_in_ticks_var		: std_logic_vector(19 downto 0) := (others=>'0'); --uebergabe var fuer das links-schieben
signal curve_m2_distance_in_ticks_var		: std_logic_vector(19 downto 0) := (others=>'0'); --uebergabe var fuer das links-schieben

signal circle_part_distance1_in_ticks_var		: std_logic_vector(19 downto 0) := (others=>'0'); --uebergabe var fuer das links-schieben
signal circle_part_distance2_in_ticks_var		: std_logic_vector(19 downto 0) := (others=>'0'); --uebergabe var fuer das links-schieben


--signals fuer winkel_modul
signal drive_enable_in_sig						: std_logic := '0';  
signal turn_enable_in_sig						: std_logic := '0'; 
signal curve_enable_in_sig						: std_logic := '0'; 

signal resolution_in_sig						: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');
signal curve_angle_out_sig						: std_logic_vector(REG2_cntBits-1 downto 0); 
signal curve_angle_sig							: std_logic_vector(REG2_cntBits-1 downto 0); 
--signal curve_angle_sum_sig						: std_logic_vector(REG2_cntBits-1 downto 0);
signal curve_enable_out_sig					: std_logic := '0';
signal turn_enable_out_sig						: std_logic := '0'; 
signal drive_enable_out_sig					: std_logic := '0';  

--signal regler
signal active_regler_sig						: std_logic := '0';
signal new_value_m1_in_sig						: std_logic := '0';
signal new_value_m2_in_sig						: std_logic := '0';
signal w1_speed_out_sig							: std_logic_vector(15 downto 0) := (others=>'0');
signal w2_speed_out_sig							: std_logic_vector(15 downto 0) := (others=>'0');
signal y1_speed_in_sig							: std_logic_vector(7 downto 0) := (others=>'0');
signal y2_speed_in_sig							: std_logic_vector(7 downto 0) := (others=>'0');

--signal done_test									: std_logic := '0';

begin

--------instanz encoder_motor---------------------------------------------------------------------------
	inst_encoder_motor : encoder_motor
	port map (
		--in der instanz => in diesem level
 		reset_n								=> reset_n,
		clk									=> clk,
	
		LED_DriveStatus					=> LED_DriveStatus,    
	
		Encoder1_DriveSystem				=> encoder1_register_in,
   	Encoder2_DriveSystem				=> encoder2_register_in, 
	
		Encoder1_Register					=> Encoder1_Register_sig,
		Encoder2_Register					=> Encoder2_Register_sig, 

		Encoder1_Full_Register			=> Encoder1_Full_Register_sig,
		Encoder2_Full_Register			=> Encoder2_Full_Register_sig,
		Encoder1_Full_Register_Enable	=> Encoder1_Full_Register_Enable_sig,
		Encoder2_Full_Register_Enable	=> Encoder2_Full_Register_Enable_sig,
 		Encoder_New_Command				=> Encoder_New_Command_sig
	);

--------instanz baud_gen---------------------------------------------------------------------------
	inst_baud_gen : baud_gen_k
	port map (
		--in der instanz => in diesem level
 		reset_n	=> reset_n,
		clk		=> clk,

		baud_en	=> baud_en_sig
	);

--------instanz uart_send---------------------------------------------------------------------------
	inst_uart_send : uart_send_k
	port map (
		--in der instanz => in diesem level
 		reset_n		=> reset_n,
		clk			=> clk,

		send_en		=> baud_en_sig, --kommt vom baud_gen
		send_active	=> send_active_sig,
		send_m1_in	=> send_m1_in_sig,
		send_m2_in	=> send_m2_in_sig,
		send_done	=> send_done_sig,
		send_out		=> uart_out
	);

--------instanz winkel_modul---------------------------------------------------------------------------
	inst_winkel_modul : winkel_modul
	port map (
		--in der instanz => in diesem level
 		reset_n				=> reset_n,
		clk					=> clk,

		drive_enable_in	=> drive_enable_in_sig, 
		turn_enable_in		=> turn_enable_in_sig,
		curve_enable_in	=> curve_enable_in_sig,

		gyro_angle_in		=> gyro_angle_in, --vom interface
		aim_angle_in		=> sabertooth_m_angle_in, --vom interface

		--resolution_in		=> resolution_in_sig,
		
		curve_angle_out	=> curve_angle_out_sig,
		--curve_enable_out	=> curve_enable_out_sig,
		turn_enable_out	=> turn_enable_out_sig
		--drive_enable_out	=> drive_enable_out_sig
	);
	
	
--------instanz pid_regler---------------------------------------------------------------------------
	regler : pid_regler
	port map (
		--in der instanz => in diesem level
 		reset_n			=> reset_n,
		clk				=> clk,

		active_in		=> active_regler_sig, 
		
		w1_soll_in		=> w1_speed_out_sig,
		x1_ist_in		=> Encoder1_Register_sig, --ersten beiden bits clearen
		
		w2_soll_in		=> w2_speed_out_sig, 
		x2_ist_in		=> Encoder2_Register_sig,
		
		y1_out			=> y1_speed_in_sig,
		y2_out			=> y2_speed_in_sig,
		
		new_value_m1_out	=> new_value_m1_in_sig,
		new_value_m2_out	=> new_value_m2_in_sig
	);


	
	E1_reg <= Encoder1_Register_sig;
	E2_reg <= Encoder2_Register_sig;
	
	

	PROCESS(clk, reset_n)-- dient zur uebergabe der register und zur einhaltung der entfernung 15 bit

	variable cmd_reg_local						: std_logic_vector(2 downto 0) := (others=>'0');
	variable sabertooth_m_speed_zero_var	: std_logic_vector(REG1_cntBits-1 downto 0):= (others=>'0');
	variable sem_uart_send_var					: std_logic := '0';
	
	

	--test fuer uart
	constant address      : std_logic_vector(7 downto 0) := "10000000"; --128 default address of the Sabertooth
	variable temp_sum_m1  : std_logic_vector(7 downto 0) := "00000000";
	variable temp_sum_m2  : std_logic_vector(7 downto 0) := "00000000";
	variable check_sum_m1 : std_logic_vector(7 downto 0) := "00000000";
	variable check_sum_m2 : std_logic_vector(7 downto 0) := "00000000";
	
	variable count_var	 : integer RANGE 1000 downto 0 := 0; 

	variable w1_temp_var	 : integer RANGE 1000 downto 0 := 0;
	variable w2_temp_var	 : integer RANGE 1000 downto 0 := 0;
	
	variable curve_angle_sum_var	 : integer RANGE 1000000 downto 0 := 0;
	
	


	BEGIN
		IF reset_n = '0' then

			sabertooth_m1_command_reg				<= (others=>'0');
			sabertooth_m2_command_reg				<= (others=>'0');
			sabertooth_m_angle_reg					<= (others=>'0');
			sabertooth_m_distance_reg				<= (others=>'0');
			sabertooth_m_relation_reg				<= (others=>'0');
			sabertooth_m_speed_reg					<= (others=>'0');
			Encoder1_Full_Register_Enable_sig	<= '0';
			Encoder2_Full_Register_Enable_sig	<= '0';
			Encoder_New_Command_sig					<= '0';
			
					
			state_s										<= get_cmd_st;

		ELSIF clk'EVENT AND clk = '1' THEN
			case state_s is

				when get_cmd_st =>
					send_active_sig		<= '0';
					job_m1_working_sig	<= '0';
					job_m2_working_sig	<= '0';
					job_m1_done_sig		<= '0';
					job_m2_done_sig		<= '0';
					
					done_reg 				<= '1';
					IF sabertooth_m_start_in = '1' THEN
						cmd_reg_local := sabertooth_m_cmd_in;

						sabertooth_m1_command_reg <= sabertooth_m1_command_in;
						sabertooth_m2_command_reg <= sabertooth_m2_command_in;
						sabertooth_m_angle_reg	  <= sabertooth_m_angle_in;
						sabertooth_m_distance_reg <= sabertooth_m_distance_in;
						sabertooth_m_relation_reg <= sabertooth_m_relation_in;
						sabertooth_m_speed_reg 	  <= sabertooth_m_speed_in;
						
						Encoder1_Full_Register_Enable_sig	<= '0';--test
						Encoder2_Full_Register_Enable_sig	<= '0';--test

						case cmd_reg_local is	
							when "001" => 
								state_s										<= drive_st;
								Encoder1_Full_Register_Enable_sig	<= '1';
								Encoder2_Full_Register_Enable_sig	<= '1';
								Encoder_New_Command_sig					<= '1';
								done_reg										<= '0';
								
								w1_speed_out_sig 	<= sabertooth_m_speed_in;
								w2_speed_out_sig 	<= sabertooth_m_speed_in;
								
								
								sabertooth_m_distance_in_ticks_var(17 downto 3) <= sabertooth_m_distance_in(14 downto 0); --ein bit weniger wegen vorzeichen
												
							when "010" =>
								state_s <= turn_st;
								turn_enable_in_sig	<= '1';
								done_reg					<= '0';
								
								
								w1_speed_out_sig 	<= sabertooth_m_speed_in;
								w2_speed_out_sig 	<= sabertooth_m_speed_in;
								

								

							when "011" =>	
								state_s <= curve1_st;

								curve_enable_in_sig	<= '1';
								Encoder1_Full_Register_Enable_sig	<= '1';
								Encoder2_Full_Register_Enable_sig	<= '1';
								Encoder_New_Command_sig					<= '1';
								done_reg										<= '0';
								
								curve_angle_sum_var := 0;
								
								
								resolution_in_sig <= curve_resolution_in;--"0000000000000101";--5->0000000000000101--10->0000000000001010
								
--								w1_speed_out_sig 	<= "0000000010101000";--0000000001000111--100->0000000011000111
--								w2_speed_out_sig 	<= "0000000010001100";--0000000000110010--100->0000000010001100
								
								circle_part_distance1_in_ticks_var(18 downto 3) <= curve_m1_distance_in; --"000001010000101";--curve_m1_distance_in(14 downto 0);--100->000001000011001/110->000001001001111/108->000001001000100
								circle_part_distance2_in_ticks_var(18 downto 3) <= curve_m2_distance_in; --"000000111000100";--curve_m2_distance_in(14 downto 0);--100->000000101111001/110->000000110011110/108->000000110010111
								
								--457->000000111001001 fuer r=120 l //+20% 	->548->001000100100 //aufloesung20->274
								--140->000000010001100 fuer r=120 r				->168->10101000							84
								
								
								IF sabertooth_m_angle_in(15) = '0' THEN -- 360 grad// rechte kurve(user)  linke seite mehr strecke
									curve_lr_sig <= "10";
									
									w1_speed_out_sig 	<= std_logic_vector(to_unsigned((to_integer(unsigned(sabertooth_m_speed_in))*to_integer(unsigned(sabertooth_m_relation_in))),16));
									w2_speed_out_sig	<= sabertooth_m_speed_in;
									
									
								ELSE												-- -360 grad// links kurve
									curve_lr_sig <= "01";
									
									w1_speed_out_sig 	<= sabertooth_m_speed_in;
									w2_speed_out_sig	<=	std_logic_vector(to_unsigned((to_integer(unsigned(sabertooth_m_speed_in))*to_integer(unsigned(sabertooth_m_relation_in))),16));								
									
									
								END IF;
								
									
							when others => null;
						END case;
					
					ELSE
						state_s <= get_cmd_st;
					END IF;
					
					
					
				-----drive_st------------------------------------------------------------------------------------------------------------------------------------------------------------------
				when drive_st => --rueckgabe der gesamten strecke 15bit -> 3,276 meter -> 262.400 ticks  ->20 bit // regler_speed
					Encoder_New_Command_sig <= '0';
					
					IF (Encoder1_Full_Register_sig < sabertooth_m_distance_in_ticks_var or Encoder2_Full_Register_sig < sabertooth_m_distance_in_ticks_var) THEN -- sabertooth_m_distance_in				
						active_regler_sig <= '1'; --on regler

						IF (new_value_m1_in_sig = '1' or new_value_m2_in_sig = '1') THEN	-- abfrage ob ein neuer geschwindigkeitswert vorliegt
							job_m1_working_sig <= '0';													-- flag fuer neue uebertragung

						END IF;	
							
						IF job_m1_working_sig = '0' THEN --erster aufruf -> start der motoren -- weitere aufrufe -> aenderung der geschwindigkeit
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(y1_speed_in_sig))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");
							send_m1_in_sig <= address & sabertooth_m1_command_reg & y1_speed_in_sig & check_sum_m1;
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(y2_speed_in_sig))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");
							send_m2_in_sig <= address & sabertooth_m2_command_reg & y2_speed_in_sig & check_sum_m2;

							send_active_sig <= '1';
							job_m1_working_sig <= '1';							
							
						ELSE 										--alle weiteren aufrufe
							send_active_sig <= '0';

						END IF;
						
					ELSE 											--strecke erreicht motor ausschalten
						active_regler_sig <= '0';			--off regler
						
						IF send_active_sig = '0' then		--erstes mal wenn strecke erreicht ist
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");
							send_m1_in_sig <= address & sabertooth_m1_command_reg & sabertooth_m_speed_zero_var & check_sum_m1;
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");
							send_m2_in_sig <= address & sabertooth_m2_command_reg & sabertooth_m_speed_zero_var & check_sum_m2;		
							
							send_active_sig	<= '1';
							
						ELSE										--zweites mal wenn strecke erreicht ist, alle werte werden wieder auf den ausgangswert gesetzt
							send_active_sig 		<= '0';
							job_m1_working_sig	<= '0';
							sabertooth_m_distance_in_ticks_var <= (others=>'0');
							done_reg					<= '1';
							
							w1_speed_out_sig 	<= (others=>'0');
							w2_speed_out_sig 	<= (others=>'0');
							
							state_s					<= get_cmd_st; 
							
						END IF;
					END IF;
					
				
				
				-----turn_st------------------------------------------------------------------------------------------------------------------------------------------------------------------
				when turn_st =>

					IF (turn_enable_out_sig = '1' ) THEN
						active_regler_sig <= '1';			--on regler

						IF (new_value_m1_in_sig = '1' or new_value_m2_in_sig = '1') THEN	-- abfrage ob ein neuer geschwindigkeitswert vorliegt
							job_m1_working_sig <= '0';													-- flag fuer neue uebertragung
							
						END IF;	
					
						IF job_m1_working_sig = '0' THEN --erster aufruf
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(y1_speed_in_sig))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");
							send_m1_in_sig <= address & sabertooth_m1_command_reg & y1_speed_in_sig & check_sum_m1;
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(y2_speed_in_sig))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");
							send_m2_in_sig <= address & sabertooth_m2_command_reg & y2_speed_in_sig & check_sum_m2;

							send_active_sig <= '1';
							job_m1_working_sig <= '1';	
							turn_enable_in_sig <= '1';
							
						ELSE 										--alle weiteren aufrufe
							send_active_sig <= '0';
			
						END IF;
						
					ELSE 											--strecke erreicht motor ausschalten
						
						active_regler_sig <= '0'; --off regler
						
						IF send_active_sig = '0' then		--erstes mal wenn strecke erreicht ist
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");
							send_m1_in_sig <= address & sabertooth_m1_command_reg & sabertooth_m_speed_zero_var & check_sum_m1;
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");
							send_m2_in_sig <= address & sabertooth_m2_command_reg & sabertooth_m_speed_zero_var & check_sum_m2;		
							
							send_active_sig <= '1';
							
						ELSE										--zweites mal wenn strecke erreicht ist, alle werte werden wieder auf den ausgangswert gesetzt
							send_active_sig 		<= '0';
							job_m1_working_sig	<= '0';
							sabertooth_m_distance_in_ticks_var <= (others=>'0');
							turn_enable_in_sig	<= '0';
							done_reg					<= '1';
							state_s					<= get_cmd_st;
							
						END IF;
					END IF;

					
					
				-----curve_st------------------------------------------------------------------------------------------------------------------------------------------------------------------	
				when curve1_st =>
				
					Encoder_New_Command_sig <= '0';
																											
					IF (Encoder1_Full_Register_sig < circle_part_distance1_in_ticks_var and Encoder2_Full_Register_sig < circle_part_distance2_in_ticks_var) THEN -- sabertooth_m_distance_in				
						active_regler_sig <= '1'; --on regler

						IF (new_value_m1_in_sig = '1' or new_value_m2_in_sig = '1') THEN --start neuer uart uebertragung
							job_m1_working_sig <= '0';
						END IF;	
							
						IF job_m1_working_sig = '0' THEN --erster aufruf
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(y1_speed_in_sig))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");
							send_m1_in_sig <= address & sabertooth_m1_command_reg & y1_speed_in_sig & check_sum_m1;
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(y2_speed_in_sig))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");
							send_m2_in_sig <= address & sabertooth_m2_command_reg & y2_speed_in_sig & check_sum_m2;

							send_active_sig <= '1';
							job_m1_working_sig <= '1';							
							
						ELSE 										--alle weiteren aufrufe
							send_active_sig <= '0';
							


						END IF;
						
									
						
					ELSE 											--strecke erreicht motor ausschalten
					
						
						active_regler_sig <= '0'; --off regler
						curve_enable_in_sig	<= '0'; --off winkel
						
															
						IF (send_active_sig = '0' and curve_angle_sum_var >= (to_integer(unsigned(sabertooth_m_angle_in))*10-to_integer(unsigned(curve_angle_sig))) and count_var >= to_integer(unsigned(resolution_in_sig))) then		--wenn gesamte strecke erreicht worden ist
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");
							send_m1_in_sig <= address & sabertooth_m1_command_reg & sabertooth_m_speed_zero_var & check_sum_m1;
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");
							send_m2_in_sig <= address & sabertooth_m2_command_reg & sabertooth_m_speed_zero_var & check_sum_m2;		
							
							send_active_sig	<= '1';
							
						ELSIF (send_active_sig = '1' and curve_angle_sum_var >= (to_integer(unsigned(sabertooth_m_angle_in))*10-to_integer(unsigned(curve_angle_sig))) and count_var >= to_integer(unsigned(resolution_in_sig))) then											--zweites mal wenn strecke erreicht ist
							send_active_sig 		<= '0';
							job_m1_working_sig	<= '0';
							sabertooth_m_distance_in_ticks_var <= (others=>'0');
							done_reg					<= '1';
							
							
							w1_speed_out_sig 	<= (others=>'0');
							w2_speed_out_sig 	<= (others=>'0');
							
							state_s					<= get_cmd_st;
							
						ELSE
							count_var	:= count_var +1;
							
							send_active_sig 		<= '0';
							job_m1_working_sig	<= '0';
							active_regler_sig 	<= '0';
							
							curve_angle_sig <= curve_angle_out_sig; --den gefahren winkel holen
							
							curve_angle_sum_var := curve_angle_sum_var + to_integer(unsigned(curve_angle_sig));
							
							state_s		<= curve2_st;
							
						END IF;
					END IF;
								

				--neustarten des cases
			WHEN curve2_st =>
					curve_enable_in_sig	<= '1';
					Encoder1_Full_Register_Enable_sig	<= '1';
					Encoder2_Full_Register_Enable_sig	<= '1';
					Encoder_New_Command_sig					<= '1';
					done_reg										<= '0';
				
				
					w1_temp_var := to_integer(unsigned(w1_speed_out_sig));
					w2_temp_var := to_integer(unsigned(w2_speed_out_sig));
				
				
				
																					
					IF curve_lr_sig = "10" THEN 	--rechts kurve											in grad	(x*10 fuer 90 ->900)												--50--85
						IF (to_integer(unsigned(curve_angle_sig)) < (((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) -20)) THEN --links schneller und rechts langsamer
						--(((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) -20))

						
							w1_temp_var := w1_temp_var + 12;
							w2_temp_var := w2_temp_var - 12;
																					
						ELSIF (to_integer(unsigned(curve_angle_sig)) > (((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) +20)) THEN --rechts schneller und links langsamer
						--(((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) +20))

							
							w1_temp_var := w1_temp_var - 12;
							w2_temp_var := w2_temp_var + 12;
						
						END IF;
				 
					
					ELSE									--links kurve
						IF (to_integer(unsigned(curve_angle_sig)) < (((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) -20)) THEN --rechts schneller und links langsamer
						--(((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) -20))

							
							w1_temp_var := w1_temp_var - 12;
							w2_temp_var := w2_temp_var + 12;
						
							
					
						ELSIF (to_integer(unsigned(curve_angle_sig)) > (((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) +20)) THEN --lins schneller und rechts langsamer
							--(((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) +20))
							w1_temp_var := w1_temp_var + 12;
							w2_temp_var := w2_temp_var - 12;
						
						END IF;
					END IF;	
	
					IF w1_temp_var < 40 THEN
						w1_temp_var := 40;
						w2_temp_var := w2_temp_var + 12; 
					
					END IF;
			
					IF w2_temp_var < 40 THEN
						w2_temp_var := 40;
						w1_temp_var := w1_temp_var + 12; 
					
					END IF;
					
					-- falls der winkel erreicht worden ist wird langsam geradeaus gefahren
					IF (curve_angle_sum_var > ((to_integer(unsigned(sabertooth_m_angle_in))*10)-10)) THEN
						w1_temp_var:= 50;
						w2_temp_var:= 50;
					
					END IF;
					
					
					
					w1_speed_out_sig <= std_logic_vector(to_unsigned(w1_temp_var,16));
					w2_speed_out_sig <= std_logic_vector(to_unsigned(w2_temp_var,16));
					
					
					curve_angle_sum_reg	<= std_logic_vector(to_unsigned(curve_angle_sum_var,16));
					curve_angle_reg		<= curve_angle_sig;
					
					state_s		<= curve1_st;
	
					
			END case;
		END IF;
	END PROCESS;

end arch_motor_modul;
