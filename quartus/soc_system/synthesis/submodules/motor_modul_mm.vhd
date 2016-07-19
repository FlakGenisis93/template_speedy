--! @file 	motor_modul_mm.vhd
--! @brief	Dieses Modul dient zur verarbeitung der eingehenden Befehle und zur Steuerung ueber
--!			die Regler.
--! @details	In diesem MOdul werden die Eingaenge in Registern abgelegt und alle gro�en
--! 				Operationen durchgefuehrt. Es wird vermieden mit real Zahlen zu rechnen und 
--!				stattdessen wird auf integer werte zurueckgegriffen.
--! 				Die Realisierung erfolgt ueber eine Statemachine die je nach Befehl die passenden
--!				Operationen ausfuehrt.
--! 				Es wird hier auf die Distanz und die Geschwindigkeit ueberpruft.
--!
--! 
--! @author 	BoE. Lt. Kluge Florian
--! @version 	V1.0
--! @date    	07.07.2016
--!
--! @par History:
--! @details	- V0.1 	start of development 
--!				01.04.2016 Kluge
--!
--! @details	- V0.2	Drive_st mit Motor m1 und Distanz funktioniert
--!				26.04.2016 Kluge
--!
--! @details	- V0.3	Drive_st mit m1/m2 sowie turn_st mit m1/m2 + anfaenge vom curve_st
--!				09.05.2016 Kluge
--!
--! @details	- V0.4.0	Regler fuer drive_st implementiert
--!				30.04.2016 Kluge
--!
--! @details	- V0.4.1	drive_st fertiggestellt
--!				10.05.2016 Kluge
--!
--! @details	- V0.5.0	turn_st mit Regler verbunden
--!				30.05.2016 Kluge
--!
--! @details	- V0.5.1	turn_st optimiert und fertiggestellt
--!				06.06.2016 Kluge			
--!
--! @details	- V0.6.0	curve_st fertiggestellt
--!				30.06.2016 Kluge	
--!
--! @details	- V1.0	final version mit doku
--!				07.07.2016 Kluge		
--!
--! @todo		- alternative fuer geteilt rechnung finden!
--!
--! @bug			- geteilt rechnen in VHDL funktioniert nicht richtig!


library IEEE;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;

entity motor_modul_mm is
	Generic( 
           REG1_cntBits: INTEGER := 8;
           REG2_cntBits: INTEGER := 16;
           REG3_cntBits: INTEGER := 3
           
	);

	port
	(
		
		clk								: in std_logic;											-- clock
		reset_n							: in std_logic;											-- reset

	--Gyro input 
		gyro_angle_in					: in std_logic_vector(REG2_cntBits-1 downto 0); -- gyro input von C

	--Encoder 1 und 2 input
		encoder1_register_in			: in std_logic_vector(1 downto 0);					-- encoder input von motor 
		encoder2_register_in			: in std_logic_vector(1 downto 0); 

	--Input vom interface
		sabertooth_m1_command_in	: in std_logic_vector(REG1_cntBits-1 downto 0);	-- befehl fuer motor1
		sabertooth_m2_command_in	: in std_logic_vector(REG1_cntBits-1 downto 0);	-- befehl fuer motor2
		sabertooth_m_angle_in		: in std_logic_vector(REG2_cntBits-1 downto 0);	-- winkel
		sabertooth_m_distance_in	: in std_logic_vector(REG2_cntBits-1 downto 0);	-- distanz
		sabertooth_m_relation_in	: in std_logic_vector(REG1_cntBits-1 downto 0);	-- verhaeltnis zwischen den einzelnen kreisbahnen bzw. der benoetigten geschwindigkeit
		sabertooth_m_speed_in		: in std_logic_vector(REG2_cntBits-1 downto 0);	-- geschwindigkeit
		sabertooth_m_cmd_in			: in std_logic_vector(REG3_cntBits-1 downto 0);	-- interner befehl
		sabertooth_m_start_in		: in std_logic;											-- start flag
		
		curve_m1_distance_in			: in std_logic_vector(REG2_cntBits-1 downto 0);	-- sl strecke links
		curve_m2_distance_in			: in std_logic_vector(REG2_cntBits-1 downto 0);	-- sr strecke rechts
		curve_resolution_in			: in std_logic_vector(REG2_cntBits-1 downto 0);	-- teiler fuer die kreisabschnitte

	--Output zum interface
		uart_out							: out std_logic;												-- uart_out
		LED_DriveStatus				: out std_logic_vector(1 downto 0);						-- multi LED out	
		done_reg							: out std_logic := '1';										-- zur Steuerung in Nios
		E1_reg							: out std_logic_vector(REG2_cntBits-1 downto 0);	-- zum Debuggen
		E2_reg							: out std_logic_vector(REG2_cntBits-1 downto 0);	-- zum Debuggen
		curve_angle_reg				: out std_logic_vector(REG2_cntBits-1 downto 0);	-- zum Debuggen
		curve_angle_sum_reg			: out std_logic_vector(REG2_cntBits-1 downto 0)		-- zum Debuggen
 

	);

end motor_modul_mm;

architecture arch_motor_modul_mm of motor_modul_mm is

--------component encoder_motor--------------!details siehe encoder_motor_mm.vhd!--------------------------------
	component encoder_motor_mm is
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
	end component encoder_motor_mm;

--------component baud_gen-------------------!details siehe baud_gen_mm.vhd!--------------------------------------
	component baud_gen_mm is
		port(
			reset_n	: in STD_LOGIC; 
			clk		: in STD_LOGIC; 

			baud_en	: out STD_LOGIC
		);
	end component baud_gen_mm;

--------component uart_send------------------!details siehe uart_send_mm.vhd!-------------------------------------
	component uart_send_mm is
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
	end component uart_send_mm;


--------component winkel_modul---------------!details siehe winkel_modul_mm.vhd!----------------------------------
	component winkel_modul_mm is
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
			
			curve_angle_out	: out std_logic_vector(REG2_cntBits-1 downto 0);
			
			turn_enable_out	: out std_logic				
		);
	end component winkel_modul_mm;
		
		
--------component pid_regler-----------------!details siehe pid_regler_mm.vhd!------------------------------------
	component pid_regler_mm
		generic(
			REG1_cntBits		: INTEGER := 8;
			REG2_cntBits		: INTEGER := 16;

			CNT_MAX				: INTEGER := 2_500_000 

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
	end component pid_regler_mm;


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


begin

--------instanz encoder_motor---------------------------------------------------------------------------
	inst_encoder_motor_mm : encoder_motor_mm
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
	inst_baud_gen_mm : baud_gen_mm
	port map (
		--in der instanz => in diesem level
 		reset_n	=> reset_n,
		clk		=> clk,

		baud_en	=> baud_en_sig
	);

--------instanz uart_send---------------------------------------------------------------------------
	inst_uart_send_mm : uart_send_mm
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
	inst_winkel_modul_mm : winkel_modul_mm
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
	regler_mm : pid_regler_mm
	port map (
		--in der instanz => in diesem level
 		reset_n			=> reset_n,
		clk				=> clk,

		active_in		=> active_regler_sig, 
		
		w1_soll_in		=> w1_speed_out_sig,
		x1_ist_in		=> Encoder1_Register_sig, 
		
		w2_soll_in		=> w2_speed_out_sig, 
		x2_ist_in		=> Encoder2_Register_sig,
		
		y1_out			=> y1_speed_in_sig,
		y2_out			=> y2_speed_in_sig,
		
		new_value_m1_out	=> new_value_m1_in_sig,
		new_value_m2_out	=> new_value_m2_in_sig
	);


	
	E1_reg <= Encoder1_Register_sig;	-- signal uebergabe
	E2_reg <= Encoder2_Register_sig;	-- signal uebergabe
	
	
--process:	dient zur Steuerung der Motoren. Je nach Befehl werden Regler- und Winkel-Module dazugeschaltet oder nicht.
--				Zusaetzlich werden alle benoetigten Werte ausgerechnet und uebergeben. In den einzelnen States werden jeweils 
--				die dafuer benötigten Sequenzen abgehandelt. Am Ende wird ein Done_Flag gesetzt und wieder auf einen neuen 
--				Befehl gewartet.
	PROCESS(clk, reset_n)

	variable cmd_reg_local						: std_logic_vector(2 downto 0) := (others=>'0');					-- lokale kopie des registers
	variable sabertooth_m_speed_zero_var	: std_logic_vector(REG1_cntBits-1 downto 0):= (others=>'0');	-- platzhalter fuer geschwindigkeit: 0	

	constant address      : std_logic_vector(7 downto 0) := "10000000";	-- 128 default address of the Sabertooth
	variable temp_sum_m1  : std_logic_vector(7 downto 0) := "00000000";	-- rechen variable
	variable temp_sum_m2  : std_logic_vector(7 downto 0) := "00000000";	-- rechen variable
	variable check_sum_m1 : std_logic_vector(7 downto 0) := "00000000";	-- checksum variable
	variable check_sum_m2 : std_logic_vector(7 downto 0) := "00000000";	-- checksum variable
	
	variable count_var	 : integer RANGE 1000 downto 0 := 0; 				-- zaehl variable

	variable w1_temp_var	 : integer RANGE 1000 downto 0 := 0;				-- soll geschwindigkeit variable fuer m1
	variable w2_temp_var	 : integer RANGE 1000 downto 0 := 0;				-- soll geschwindigkeit variable fuer m1
	
	variable curve_angle_sum_var	 : integer RANGE 1000000 downto 0 := 0;-- winkelsumme variable
	
	


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

				when get_cmd_st =>					-- zuruecksetzen alle signale
					send_active_sig		<= '0';	-- |
					job_m1_working_sig	<= '0';	-- |
					job_m2_working_sig	<= '0';	-- |
					job_m1_done_sig		<= '0';	-- |
					job_m2_done_sig		<= '0';	-- |
					
					done_reg 				<= '1';	-- |
					
					IF sabertooth_m_start_in = '1' THEN 								-- neuer Befehl ist eingegangen
						cmd_reg_local := sabertooth_m_cmd_in;							-- lokale kopie des Befehls

						sabertooth_m1_command_reg <= sabertooth_m1_command_in;	-- register kopieren
						sabertooth_m2_command_reg <= sabertooth_m2_command_in;	-- |
						sabertooth_m_angle_reg	  <= sabertooth_m_angle_in;		-- |
						sabertooth_m_distance_reg <= sabertooth_m_distance_in;	-- |
						sabertooth_m_relation_reg <= sabertooth_m_relation_in;	-- |
						sabertooth_m_speed_reg 	  <= sabertooth_m_speed_in;		-- |
						
						Encoder1_Full_Register_Enable_sig	<= '0';					-- encoder zuruecksetzten 
						Encoder2_Full_Register_Enable_sig	<= '0';					-- encoder zuruecksetzten 

						case cmd_reg_local is	
							when "001" => 														-- befehl: fahren!
								state_s										<= drive_st;
								Encoder1_Full_Register_Enable_sig	<= '1';			-- encoder starten
								Encoder2_Full_Register_Enable_sig	<= '1';			-- encoder starten
								Encoder_New_Command_sig					<= '1';			-- encoder starten
								done_reg										<= '0';			-- done_reg zuruecksetzten
								
								w1_speed_out_sig 	<= sabertooth_m_speed_in;			-- geschwindigkeit uebergeben
								w2_speed_out_sig 	<= sabertooth_m_speed_in;			-- geschwindigkeit uebergeben
								
								sabertooth_m_distance_in_ticks_var(17 downto 3) <= sabertooth_m_distance_in(14 downto 0); -- ein bit weniger wegen vorzeichen / umwandlung von mm in Ticks
												
							when "010" =>														-- befehl: drehen!
								state_s <= turn_st;
								turn_enable_in_sig	<= '1';								-- winkelmodul->drehen starten
								done_reg					<= '0';								-- done_reg zuruecksetzten
								
								w1_speed_out_sig 	<= sabertooth_m_speed_in;			-- geschwindigkeit uebergeben
								w2_speed_out_sig 	<= sabertooth_m_speed_in;			-- geschwindigkeit uebergeben
								
							when "011" =>														-- befehl: kurve fahren!
								state_s <= curve1_st;

								curve_enable_in_sig	<= '1';								-- winkelmodul->kurve starten
								Encoder1_Full_Register_Enable_sig	<= '1';			-- encoder starten 
								Encoder2_Full_Register_Enable_sig	<= '1';			-- encoder starten
								Encoder_New_Command_sig					<= '1';			-- encoder starten
								done_reg										<= '0';			-- done_reg zuruecksetzten
								
								curve_angle_sum_var := 0;									-- variable zuruecksetzten
								
								resolution_in_sig <= curve_resolution_in;				-- signal uebergabe

								circle_part_distance1_in_ticks_var(18 downto 3) <= curve_m1_distance_in;	-- umwandlung der strecke von mm in TIcks
								circle_part_distance2_in_ticks_var(18 downto 3) <= curve_m2_distance_in;	-- |
					
								IF sabertooth_m_angle_in(15) = '0' THEN				-- 360 grad// rechte kurve(user)  linke seite mehr strecke 
									curve_lr_sig <= "10";									-- variable zur unterscheidung rechts/links kurve
									
									w1_speed_out_sig 	<= std_logic_vector(to_unsigned((to_integer(unsigned(sabertooth_m_speed_in))*to_integer(unsigned(sabertooth_m_relation_in))),16));	-- geschwindigkeit fuer langen kreis
									w2_speed_out_sig	<= sabertooth_m_speed_in;		-- geschwindigkeit fuer kurzen kreis
									
								ELSE																-- -360 grad// links kurve
									curve_lr_sig <= "01";									-- variable zur unterscheidung rechts/links kurve
									
									w1_speed_out_sig 	<= sabertooth_m_speed_in;		-- geschwindigkeit fuer kurzen kreis
									w2_speed_out_sig	<=	std_logic_vector(to_unsigned((to_integer(unsigned(sabertooth_m_speed_in))*to_integer(unsigned(sabertooth_m_relation_in))),16));	-- geschwindigkeit fuer langen kreis							
								END IF;
									
							when others => null;
						END case;
					
					ELSE
						state_s <= get_cmd_st;												-- falls kein neuer befehl bleib in diesem state
					END IF;
					
					
					
				-----drive_st------------------------------------------------------------------------------------------------------------------------------------------------------------------
				when drive_st =>																
					Encoder_New_Command_sig <= '0';										-- encoder starten
					
					IF (Encoder1_Full_Register_sig < sabertooth_m_distance_in_ticks_var or Encoder2_Full_Register_sig < sabertooth_m_distance_in_ticks_var) THEN	-- solang die vom encoder gemessene entfernung kleiner ist als die gefoderte entfernung mache:				
						active_regler_sig <= '1';											-- regler starten

						IF (new_value_m1_in_sig = '1' or new_value_m2_in_sig = '1') THEN	-- abfrage ob ein neuer geschwindigkeitswert vom regler vorliegt
							job_m1_working_sig <= '0';													-- flag fuer neue uebertragung
						END IF;	
							
						IF job_m1_working_sig = '0' THEN 											-- erster aufruf -> start der motoren -- weitere aufrufe -> aenderung der geschwindigkeit
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(y1_speed_in_sig))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");																										-- berechnung der CS
							send_m1_in_sig <= address & sabertooth_m1_command_reg & y1_speed_in_sig & check_sum_m1;												-- erstellen des ganzen befehls
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(y2_speed_in_sig))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");																										-- berechnung der CS
							send_m2_in_sig <= address & sabertooth_m2_command_reg & y2_speed_in_sig & check_sum_m2;												-- erstellen des ganzen befehls

							send_active_sig <= '1';											-- uart uebertragung starten
							job_m1_working_sig <= '1';										-- flag setzten das befehl gesendet wurde setzen
							
						ELSE 																		-- alle weiteren aufrufe:
							send_active_sig <= '0';											-- uart uebertragung aus
						END IF;
						
					ELSE 																			-- strecke erreicht motor ausschalten
						active_regler_sig <= '0';											-- regler aus
						
						IF send_active_sig = '0' then										-- erstes mal wenn strecke erreicht ist
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");																														-- berechnung der CS
							send_m1_in_sig <= address & sabertooth_m1_command_reg & sabertooth_m_speed_zero_var & check_sum_m1;												-- erstellen des ganzen befehls
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");																														-- berechnung der CS
							send_m2_in_sig <= address & sabertooth_m2_command_reg & sabertooth_m_speed_zero_var & check_sum_m2;												-- erstellen des ganzen befehls	
							
							send_active_sig	<= '1';										-- uart uebertragung starten
							
						ELSE																		-- zweites mal wenn strecke erreicht ist, alle werte werden zurueckgesetzt
							send_active_sig 		<= '0';									-- |
							job_m1_working_sig	<= '0';									-- |
							sabertooth_m_distance_in_ticks_var <= (others=>'0');	-- |
							done_reg					<= '1';									-- |
							
							w1_speed_out_sig 	<= (others=>'0');							-- |
							w2_speed_out_sig 	<= (others=>'0');							-- |
							
							state_s					<= get_cmd_st; 						-- wechsel des states		
						END IF;
					END IF;
					
				
				
				-----turn_st------------------------------------------------------------------------------------------------------------------------------------------------------------------
				when turn_st =>

					IF (turn_enable_out_sig = '1' ) THEN								-- solange der winkel nicht erreicht ist machen:
						active_regler_sig <= '1';											-- starte regler

						IF (new_value_m1_in_sig = '1' or new_value_m2_in_sig = '1') THEN	-- abfrage ob ein neuer geschwindigkeitswert vom pid regler vorliegt
							job_m1_working_sig <= '0';													-- flag fuer neue uebertragung
						END IF;	
					
						IF job_m1_working_sig = '0' THEN									-- erster aufruf -> start der motoren -- weitere aufrufe -> aenderung der geschwindigkeit
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(y1_speed_in_sig))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");																										-- berechnung der CS
							send_m1_in_sig <= address & sabertooth_m1_command_reg & y1_speed_in_sig & check_sum_m1;												-- erstellen des ganzen befehls
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(y2_speed_in_sig))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");																										-- berechnung der CS
							send_m2_in_sig <= address & sabertooth_m2_command_reg & y2_speed_in_sig & check_sum_m2;												-- erstellen des ganzen befehls

							send_active_sig <= '1';											-- uart uebertragung starten
							job_m1_working_sig <= '1';										-- flag setzten das befehl gesendet wurde setzen
							turn_enable_in_sig <= '1';										-- drehung starten
							
						ELSE 																		-- alle weiteren aufrufe
							send_active_sig <= '0';
						END IF;
						
					ELSE 																			-- winkel erreicht motor ausschalten
						active_regler_sig <= '0';											-- regler aus
						
						IF send_active_sig = '0' then										-- erstes mal wenn strecke erreicht ist
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");																														-- berechnung der CS
							send_m1_in_sig <= address & sabertooth_m1_command_reg & sabertooth_m_speed_zero_var & check_sum_m1;												-- erstellen des ganzen befehls
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");																														-- berechnung der CS
							send_m2_in_sig <= address & sabertooth_m2_command_reg & sabertooth_m_speed_zero_var & check_sum_m2;												-- erstellen des ganzen befehls
							
							send_active_sig <= '1';
							
						ELSE																		-- zweites mal wenn strecke erreicht ist, alle werte werden zurueckgesetzt
							send_active_sig 		<= '0';									-- |
							job_m1_working_sig	<= '0';									-- |
							sabertooth_m_distance_in_ticks_var <= (others=>'0');	-- |
							turn_enable_in_sig	<= '0';									-- |
							done_reg					<= '1';									-- done flag setzen
							state_s					<= get_cmd_st; 						-- wechsel des states
						END IF;
					END IF;

					
					
				-----curve_st------------------------------------------------------------------------------------------------------------------------------------------------------------------	
				when curve1_st =>
				
					Encoder_New_Command_sig <= '0';										-- encoder starten
																											
					IF (Encoder1_Full_Register_sig < circle_part_distance1_in_ticks_var and Encoder2_Full_Register_sig < circle_part_distance2_in_ticks_var) THEN	-- solang die vom encoder gemessene entfernung kleiner ist als die gefoderte entfernung mache:				
						active_regler_sig <= '1';											-- regler start

						IF (new_value_m1_in_sig = '1' or new_value_m2_in_sig = '1') THEN	-- abfrage ob ein neuer geschwindigkeitswert vom pid regler vorliegt
							job_m1_working_sig <= '0';													-- flag fuer neue uebertragung
						END IF;	
							
						IF job_m1_working_sig = '0' THEN									-- erster aufruf -> start der motoren -- weitere aufrufe -> aenderung der geschwindigkeit
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(y1_speed_in_sig))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");																										-- berechnung der CS
							send_m1_in_sig <= address & sabertooth_m1_command_reg & y1_speed_in_sig & check_sum_m1;												-- erstellen des ganzen befehls
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(y2_speed_in_sig))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");																										-- berechnung der CS
							send_m2_in_sig <= address & sabertooth_m2_command_reg & y2_speed_in_sig & check_sum_m2;												-- erstellen des ganzen befehls

							send_active_sig <= '1';											-- uart uebertragung starten
							job_m1_working_sig <= '1';										-- flag setzten das befehl gesendet wurde setzen
							
						ELSE 																		-- alle weiteren aufrufe
							send_active_sig <= '0';
						END IF;

					ELSE 																			-- strecke erreicht motor ausschalten
						active_regler_sig <= '0';											-- regler aus
						curve_enable_in_sig	<= '0';										-- winkel_modul aus
															
						IF (send_active_sig = '0' and curve_angle_sum_var >= (to_integer(unsigned(sabertooth_m_angle_in))*10-to_integer(unsigned(curve_angle_sig))) and count_var >= to_integer(unsigned(resolution_in_sig))) then	-- wenn gesamte strecke erreicht worden ist UND alle teilabschnitte absolviert worden sind mache:
							--command for m1
							temp_sum_m1 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m1_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m1 := (temp_sum_m1 and "01111111");																														-- berechnung der CS
							send_m1_in_sig <= address & sabertooth_m1_command_reg & sabertooth_m_speed_zero_var & check_sum_m1;												-- erstellen des ganzen befehls
							
							--command for m2
							temp_sum_m2 := (std_logic_vector( unsigned (address) + unsigned (sabertooth_m2_command_reg) + unsigned(sabertooth_m_speed_zero_var))); -- additon of all 3 packages
							check_sum_m2 := (temp_sum_m2 and "01111111");																														-- berechnung der CS
							send_m2_in_sig <= address & sabertooth_m2_command_reg & sabertooth_m_speed_zero_var & check_sum_m2;												-- erstellen des ganzen befehls
							
							send_active_sig	<= '1';										-- uart uebertragung starten
							
						ELSIF (send_active_sig = '1' and curve_angle_sum_var >= (to_integer(unsigned(sabertooth_m_angle_in))*10-to_integer(unsigned(curve_angle_sig))) and count_var >= to_integer(unsigned(resolution_in_sig))) then	-- wenn gesamte strecke erreicht worden ist UND alle teilabschnitte absolviert worden sind UND das der stop befehl gesendet worden ist mache:
							send_active_sig 		<= '0';									-- alle werte zuruecksetzen
							job_m1_working_sig	<= '0';									-- |
							sabertooth_m_distance_in_ticks_var <= (others=>'0');	-- |
							done_reg					<= '1';									-- done flag setzen
							
							w1_speed_out_sig 	<= (others=>'0');							-- |
							w2_speed_out_sig 	<= (others=>'0');							-- |
							
							state_s					<= get_cmd_st;							-- wechsel des states
							
						ELSE
							count_var	:= count_var +1;									-- zaehler erhoehen
							
							send_active_sig 		<= '0';									-- alle werte zuruecksetzen 
							job_m1_working_sig	<= '0';									-- |
							active_regler_sig 	<= '0';									-- |
							
							curve_angle_sig <= curve_angle_out_sig;					-- den gefahren winkel holen
							
							curve_angle_sum_var := curve_angle_sum_var + to_integer(unsigned(curve_angle_sig));	--winkel summe bilden
							
							state_s		<= curve2_st;										-- wechsel des states zum folge_state
						END IF;
					END IF;
								
			-- folge_state: neustarten des cases
			WHEN curve2_st =>
					curve_enable_in_sig	<= '1';											-- winkelmodul->kurve starten
					Encoder1_Full_Register_Enable_sig	<= '1';						-- encoder starten
					Encoder2_Full_Register_Enable_sig	<= '1';						-- |
					Encoder_New_Command_sig					<= '1';						-- |
					done_reg										<= '0';						-- done flag zuruecksetzen
				
					w1_temp_var := to_integer(unsigned(w1_speed_out_sig));		-- lokale kopie der geschwindigkeit
					w2_temp_var := to_integer(unsigned(w2_speed_out_sig));		-- lokale kopie der geschwindigkeit
																				
					IF curve_lr_sig = "10" THEN											-- rechts kurve / in grad	(x*10 fuer 90 ->900)
						IF (to_integer(unsigned(curve_angle_sig)) < (((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) -20)) THEN	-- wenn der teil winkel nicht erreicht worden ist:

																									-- links schneller und rechts langsamer
							w1_temp_var := w1_temp_var + 12;								-- |
							w2_temp_var := w2_temp_var - 12;								-- |
																					
						ELSIF (to_integer(unsigned(curve_angle_sig)) > (((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) +20)) THEN	-- wenn der teil winkel nicht erreicht worden ist:

																									-- rechts schneller und links langsamer
							w1_temp_var := w1_temp_var - 12;								-- |
							w2_temp_var := w2_temp_var + 12;								-- |
						END IF;

					ELSE																			-- links kurve
						IF (to_integer(unsigned(curve_angle_sig)) < (((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) -20)) THEN	-- wenn der teil winkel nicht erreicht worden ist:

																									-- rechts schneller und links langsamer
							w1_temp_var := w1_temp_var - 12;								-- |
							w2_temp_var := w2_temp_var + 12;								-- |
						
							ELSIF (to_integer(unsigned(curve_angle_sig)) > (((to_integer(unsigned(sabertooth_m_angle_in))*10)/to_integer(unsigned(resolution_in_sig))) +20)) THEN	-- wenn der teil winkel nicht erreicht worden ist:
							
																									-- lins schneller und rechts langsamer
							w1_temp_var := w1_temp_var + 12;								-- |
							w2_temp_var := w2_temp_var - 12;								-- |
						END IF;
					END IF;	
	
					IF w1_temp_var < 40 THEN												-- geschwindigkeit ist kleiner als die min. geschwindigkeit
						w1_temp_var := 40;													-- setzen auf min. geschwindigkeit
						w2_temp_var := w2_temp_var + 12; 								-- andere seite nochmals erhoehen
					END IF;
			
					IF w2_temp_var < 40 THEN												-- geschwindigkeit ist kleiner als die min. geschwindigkeit
						w2_temp_var := 40;													-- setzen auf min. geschwindigkeit
						w1_temp_var := w1_temp_var + 12;  								-- andere seite nochmals erhoehen
					END IF;
					
					IF (curve_angle_sum_var > ((to_integer(unsigned(sabertooth_m_angle_in))*10)-10)) THEN	-- falls der winkel bereits erreicht worden ist:
						w1_temp_var:= 50;														-- langsam geradaus fahren
						w2_temp_var:= 50;														-- langsam geradaus fahren
					END IF;
					
					w1_speed_out_sig <= std_logic_vector(to_unsigned(w1_temp_var,16));	-- geschwindigkeit umwandeln zum signal
					w2_speed_out_sig <= std_logic_vector(to_unsigned(w2_temp_var,16));	-- |
					
					
					curve_angle_sum_reg	<= std_logic_vector(to_unsigned(curve_angle_sum_var,16)); -- winkel umwandeln zum signal
					curve_angle_reg		<= curve_angle_sig;							-- winkel wert holen
					
					state_s		<= curve1_st;												-- wechsel des states zum aufrufenden_state
			
			END case;
		END IF;
	END PROCESS;

end arch_motor_modul_mm;
