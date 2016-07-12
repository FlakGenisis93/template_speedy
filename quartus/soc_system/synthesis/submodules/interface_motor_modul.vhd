--! @file 	interface_motor_modul.vhd
--! @brief	Interface zwischen NIOS und dem Motormodul.
--! @details	In diesem Interface werden die Eingaenge in Registern abgelegt und kleinere
--! 		notwenidige Operationen durchgefuehrt. 
--! 		Die Realisierung erfolgt ueber eine Statemachine und im letzen State werden
--! 		die Signale an das naechste Level geschickt.
--!
--! 
--! @author 	BoE. Lt. Kluge Florian
--! @version 	V1.0
--! @date    	01.04.2016
--!
--! @par History:
--! @details	- 	V0.1 	start of development 
--!				01.04.2016 Kluge
--!
--! @details	-	V0.2	berechnung erfolgt nun mit integer Zahlen statt real zahlen, somit ist es in quartus synthetisierbar
--!				13.04.2016 Kluge
--!
--! @details	-	V0.3	hinzufuegen von einem done_flag ueber die register incl. schreib prozess
--!				12.05.2016 Kluge
--!
--! @details	-	V0.4	hinzufuegen von zwei debugg-registern fuer Encoder1 und Encorder2 incl. schreib prozess
--!				23.05.2016 Kluge
--!
--! @details	-	V1.0	hinzufuegen von zwei debugg-registern fuer die wineklpruefung im curve state incl. schreib prozess
--!				26.06.2016 Kluge
--!
--! @todo		---
--!
--! @bug			---

library IEEE;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;


-- C Befehl muss: - laut interface daten pruefen und in die richtigen register schreiben

entity interface_motor_modul is
	Generic( 
           REG1_cntBits: INTEGER := 8;
           REG2_cntBits: INTEGER := 16;
           REG3_cntBits: INTEGER := 3
           
	);

	port
	(
		
		clk						: in std_logic;
		reset_n					: in std_logic;		
			
	-- communication with nios
 		ce_n 						: in std_logic; 														-- chip enable
  		read_n 					: in std_logic; 														-- read
  		write_n					: in std_logic; 														-- write
		addr						: in std_logic_vector (3 downto 0) 	:= (others=>'0'); 	-- addr for the intern register
    	write_data				: in std_logic_vector (31 downto 0) := (others=>'0');    -- data input  
    	read_data				: out std_logic_vector (31 downto 0):= (others=>'0');		-- data output

	--Encoder 1 und 2 input
		encoder1_register_in : in std_logic_vector(1 downto 0); 
		encoder2_register_in : in std_logic_vector(1 downto 0);

		uart_out					: out std_logic;
		LED_DriveStatus      : out std_logic_vector(1 downto 0) 

	);

end interface_motor_modul;

architecture arch_interface_motor_modul of interface_motor_modul is


	component motor_modul is
		port(
			clk								: in std_logic;
			reset_n							: in std_logic;		

			gyro_angle_in   				: in std_logic_vector(15 downto 0); 				--noch nicht gepr�ft

			encoder1_register_in 		: in std_logic_vector(1 downto 0); 
			encoder2_register_in 		: in std_logic_vector(1 downto 0); 

			sabertooth_m1_command_in  	: in std_logic_vector(REG1_cntBits-1 downto 0); --:= (others=>'0');--fragen ob man vorher belegen darf/muss...
			sabertooth_m2_command_in 	: in std_logic_vector(REG1_cntBits-1 downto 0);
			sabertooth_m_angle_in	  	: in std_logic_vector(REG2_cntBits-1 downto 0);
			sabertooth_m_distance_in	: in std_logic_vector(REG2_cntBits-1 downto 0);
			sabertooth_m_relation_in	: in std_logic_vector(REG1_cntBits-1 downto 0);
			sabertooth_m_speed_in		: in std_logic_vector(REG2_cntBits-1 downto 0);
			sabertooth_m_cmd_in			: in std_logic_vector(REG3_cntBits-1 downto 0);
			sabertooth_m_start_in		: in std_logic;
			
			curve_m1_distance_in			: in std_logic_vector(REG2_cntBits-1 downto 0); --sl strecke links
			curve_m2_distance_in			: in std_logic_vector(REG2_cntBits-1 downto 0); --sr strecke rechts
			curve_resolution_in			: in std_logic_vector(REG2_cntBits-1 downto 0);

			uart_out							: out std_logic;
			LED_DriveStatus      		: out std_logic_vector(1 downto 0);
			done_reg							: out std_logic;
			
			E1_reg							: out std_logic_vector(REG2_cntBits-1 downto 0);	--zum Debuggen
			E2_reg							: out std_logic_vector(REG2_cntBits-1 downto 0);	--zum Debuggen
			curve_angle_reg				: out std_logic_vector(REG2_cntBits-1 downto 0);	--zum Debuggen
			curve_angle_sum_reg			: out std_logic_vector(REG2_cntBits-1 downto 0)		--zum Debuggen
			
			
			
		);
	end component motor_modul;




--constante
constant r_speedy_const 				: integer := 256; --der abstand zwischen speedy radm1 zu speedy radm2, d=256 r=128 (mm)

--state
type state_type is(get_cmd_st, read_cmd_st, send_to_next_level_st);
signal state_s									: state_type := get_cmd_st;

--signals
signal speed_reg 								: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- speed input from C
signal distance_reg, angle_reg			: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- distance and angle input from C !signed!
signal radius_reg								: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- distance and angle input from C 
signal relation_sig							: std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0'); 	
signal command_m1_sig, command_m2_sig	: std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0'); -- contains the command  for sabertooth
--signal speed_m1_sig, speed_m2_sig		: std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0'); -- contains the speed for sabertooth
signal cmd_reg									: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- for command
signal start_state_machine_sig 			: std_logic := '0'; 

signal curve_m1_distance_out_sig			: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- distance and angle input from C !signed!
signal curve_m2_distance_out_sig			: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');
signal curve_resolution_out_sig			: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');

--signals from or for avalon bus
signal speed_reg_ava 						: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- speed input from C
signal distance_reg_ava, angle_reg_ava	: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- distance and angle input from C !signed!
signal radius_reg_ava						: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- distance and angle input from C 
signal cmd_reg_ava							: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- for command
signal gyro_angle_in_ava					: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- for angle
signal done_reg								: std_logic := '1';														  -- done flag
signal resolution_reg_ava					: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- for resolution
signal circle_distance_part_m1_reg_ava	: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- distance for each circle part m1
signal circle_distance_part_m2_reg_ava	: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0'); -- distance for each circle part m2

--regler debug
signal E1_reg									: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');
signal E2_reg									: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');

signal curve_angle_reg						: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');
signal curve_angle_sum_reg					: std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');




--signals to next level
signal sabertooth_m1_command_out_sig  	:  std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0');
signal sabertooth_m2_command_out_sig 	:  std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0');
signal sabertooth_m_angle_out_sig  		:  std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');
signal sabertooth_m_distance_out_sig	:  std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');
signal sabertooth_m_relation_out_sig	:  std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0');
signal sabertooth_m_cmd_out_sig			:  std_logic_vector(REG3_cntBits-1 downto 0) := (others=>'0');
signal sabertooth_m_start_out_sig		:  std_logic := '0';
signal sabertooth_m_speed_out_sig		:  std_logic_vector(REG2_cntBits-1 downto 0) := (others=>'0');

	




begin

	inst_motor_modul : motor_modul
	port map (
		--in der instanz => in diesem level
 		reset_n							=> reset_n,
		clk								=> clk,
	
		gyro_angle_in					=> gyro_angle_in_ava,    
	
		encoder1_register_in			=> encoder1_register_in,
		encoder2_register_in			=> encoder2_register_in,

		sabertooth_m1_command_in	=> sabertooth_m1_command_out_sig,
		sabertooth_m2_command_in	=> sabertooth_m2_command_out_sig,
		sabertooth_m_angle_in		=> sabertooth_m_angle_out_sig,
		sabertooth_m_distance_in	=> sabertooth_m_distance_out_sig,
		sabertooth_m_relation_in	=> sabertooth_m_relation_out_sig,
		sabertooth_m_speed_in		=> sabertooth_m_speed_out_sig,
		sabertooth_m_cmd_in			=> sabertooth_m_cmd_out_sig,
		sabertooth_m_start_in		=> sabertooth_m_start_out_sig,
		
		curve_m1_distance_in			=> curve_m1_distance_out_sig,
		curve_m2_distance_in			=> curve_m2_distance_out_sig,
		curve_resolution_in			=> curve_resolution_out_sig,
		
		uart_out							=> uart_out,
		LED_DriveStatus				=> LED_DriveStatus,
		
		done_reg							=> done_reg,
		
		E1_reg							=> E1_reg,
		E2_reg							=> E2_reg,
		
		curve_angle_reg				=> curve_angle_reg,
		curve_angle_sum_reg			=> curve_angle_sum_reg
	);



	
	
--processor writes to registers
	PROCESS(clk, reset_n, write_n, ce_n, addr, write_data)
	BEGIN	
		IF reset_n = '0' then
			speed_reg_ava 		<= (others=>'0');
			distance_reg_ava	<= (others=>'0');
			angle_reg_ava		<= (others=>'0');
			radius_reg_ava		<= (others=>'0');
			cmd_reg_ava			<= (others=>'0');
			
		ELSIF clk'EVENT AND clk = '1' THEN
			IF (write_n = '0' and ce_n = '0') THEN
						case addr is
						
							when B"0000" => speed_reg_ava							<= write_data(REG2_cntBits-1 downto 0); -- ticks/50ms
							when B"0001" => distance_reg_ava 					<= write_data(REG2_cntBits-1 downto 0); -- 15bit in mm
							when B"0010" => angle_reg_ava							<= write_data(REG2_cntBits-1 downto 0); -- max 360 grad
							when B"0011" => radius_reg_ava 						<= write_data(REG2_cntBits-1 downto 0); -- 16bit in mm
							when B"0100" => cmd_reg_ava 							<= write_data(REG2_cntBits-1 downto 0);
							when B"0101" => gyro_angle_in_ava					<= write_data(REG2_cntBits-1 downto 0); --winkel
						   when B"0110" => resolution_reg_ava					<= write_data(REG2_cntBits-1 downto 0);
							when B"0111" => circle_distance_part_m1_reg_ava	<= write_data(REG2_cntBits-1 downto 0);
							when B"1000" => circle_distance_part_m2_reg_ava	<= write_data(REG2_cntBits-1 downto 0);

							when others => null ;
						end case;	
			END IF;

			IF cmd_reg_ava(15) = '1' THEN
			
				start_state_machine_sig <= '1';
				cmd_reg_ava(15) <= '0';
				
			ELSE
				start_state_machine_sig <= '0';
			END IF;	
		END IF;
	END PROCESS;
	
	
--processor liest von den registern
	process(read_n,ce_n,addr,done_reg,E1_reg,E2_reg)
	begin
		read_data <= (others=>'0');
		if (read_n = '0' and ce_n = '0') then
			case addr is
			
				when B"0000" => read_data(0) <= done_reg;
				when B"0001" => read_data(13 downto 0) <= E1_reg(13 downto 0);	-- Ticks/50 ms 13bit da 2bit fuer DIR, siehe encoder_motor.vhd
				when B"0010" => read_data(13 downto 0) <= E2_reg(13 downto 0);
				when B"0011" => read_data(REG2_cntBits-1 downto 0) <= curve_angle_reg;		--winkel fuer kreisstueck
				when B"0100" => read_data(REG2_cntBits-1 downto 0) <= curve_angle_sum_reg;	--gesamt winkel
      
       
				when others => read_data(31 downto 0)<=(others=>'0');
			end case;
		end if;
	end process;	
	
	
	
	
	
--state 
	PROCESS(clk, reset_n, start_state_machine_sig)
	--variablen
	variable rr_speedy_var		: integer RANGE 655478 downto 0 := 0; -- max wert abhaengig 16 bit *10 +128
	variable rl_speedy_var		: integer RANGE 655478 downto 0 := 0; -- max wert abhaengig 16 bit *10 +128
	
	variable sr_speedy_var		: integer RANGE 655478 downto 0 := 0; -- max wert abhaengig 16 bit *10 +128
	variable sl_speedy_var		: integer RANGE 655478 downto 0 := 0; -- max wert abhaengig 16 bit *10 +128

	variable relation_calc_var : integer RANGE 1270 downto 0 := 0; --max wert abhaengig vom maximalen verhealtnis, motor hat 127 stufen *10
	
	constant pi_con				: integer := 314; 
	constant factor_con			: integer := 377; --pi *1,2, da bei den Teilabschnitten ein +20% genauer ist

	--variable relation_speed_var : real RANGE 255.0 downto 0.0 := 0.0;
	--variable relation_speed_backup_var : real RANGE 255.0 downto 0.0 := 0.0;

	variable cmd_reg_local		: std_logic_vector(2 downto 0) := (others=>'0');

	constant address				: std_logic_vector(7 downto 0) := "10000000"; --128 default address of the Sabertooth
	variable temp_sum_m1			: std_logic_vector(7 downto 0) := (others=>'0');
	variable temp_sum_m2			: std_logic_vector(7 downto 0) := (others=>'0');
	variable check_sum_m1		: std_logic_vector(7 downto 0) := (others=>'0');
	variable check_sum_m2		: std_logic_vector(7 downto 0) := (others=>'0');

	BEGIN
		IF reset_n = '0' then
			
			command_m1_sig						<= (others=>'0');
			command_m2_sig						<= (others=>'0');

			sabertooth_m1_command_out_sig	<= (others=>'0');
			sabertooth_m2_command_out_sig	<= (others=>'0');
			sabertooth_m_angle_out_sig		<= (others=>'0'); 
			sabertooth_m_distance_out_sig	<= (others=>'0');
			sabertooth_m_relation_out_sig	<= (others=>'0');
			sabertooth_m_speed_out_sig		<= (others=>'0');
			sabertooth_m_start_out_sig		<= '0';
					
			state_s								<= get_cmd_st;

		ELSIF clk'EVENT AND clk = '1' THEN
			case state_s is

				when get_cmd_st =>

					sabertooth_m_start_out_sig <= '0';
					

					IF (start_state_machine_sig = '1') THEN
						
							 speed_reg		<= speed_reg_ava;
							 distance_reg	<= distance_reg_ava;
							 angle_reg		<= angle_reg_ava;
							 radius_reg		<= radius_reg_ava;
							 cmd_reg			<= cmd_reg_ava;
							 
							 state_s			<= read_cmd_st;
							 
							 
							 
					ELSE
							 state_s			<= get_cmd_st;
						    
						     		       
					END IF;



				when read_cmd_st =>
					cmd_reg_local := cmd_reg(2 downto 0);
					case cmd_reg_local is
						when B"001" => 									
							IF distance_reg(15) = '0' THEN			--vor fahren
								command_m1_sig <= "00000000"; 		--0000 0000 vor
								command_m2_sig <= "00000101"; 		--0000 0101 zurueck
								
								
						
							ELSIF distance_reg(15) = '1' THEN		--zurueck fahren
								command_m1_sig <= "00000001"; 		--0000 0001 zurueck
								command_m2_sig <= "00000100"; 		--0000 0100 vor
							END IF;


						when B"010" => 									--turn
							IF angle_reg(15) = '0' THEN -- 360 grad// rechts drehung
								command_m1_sig <= "00000000"; -- vor
								command_m2_sig <= "00000100"; -- zurueck


							ELSIF angle_reg(15) = '1' THEN -- -360 grad// links drehung
								command_m1_sig <= "00000001"; -- zurueck
								command_m2_sig <= "00000101"; -- vor

							END IF;
								--Mistakes will be catched by NIOS
								

						when B"011" =>									-- drive curve
							command_m1_sig <= "00000000"; 
							command_m2_sig <= "00000101";


--							IF angle_reg(15) = '0' THEN -- 360 grad// rechts drehung -->links m1 weite strecke--rechts m2 kurze strecke
--								--berechnung der verschiedenen geschwindigkeiten ueber das verhaeltnis
--								rr_speedy_var := to_integer(unsigned(radius_reg));  
--								rl_speedy_var := (to_integer(unsigned(radius_reg))+ r_speedy_const);
--
----								--berechnung der einzelnen strecken Berechnung via Winkel
----								sl_speedy_var := rl_speedy_var* (to_integer(unsigned(angle_reg(14 downto 0))));
----								sr_speedy_var := rr_speedy_var* (to_integer(unsigned(angle_reg(14 downto 0))));
--								
--
--							ELSIF angle_reg(15) = '1' THEN -- -360 grad// links drehung  --> m1 kurz--m2 lang
--								--berechnung der verschiedenen geschwindigkeiten ueber das verhaeltnis
--								rr_speedy_var := (to_integer(unsigned(radius_reg))+ r_speedy_const);
--								rl_speedy_var := to_integer(unsigned(radius_reg));
--			
----								--berechnung der einzelnen strecken Berechnung via Winkel
----								sl_speedy_var := rl_speedy_var* (to_integer(unsigned(angle_reg(14 downto 0))));
----								sr_speedy_var := rr_speedy_var* (to_integer(unsigned(angle_reg(14 downto 0))));
--							END IF;
--
								relation_calc_var := 2;--2 hat sich als guter start erwiesen, alternativ rechnerisch-> --(rl_speedy_var*10)/rr_speedy_var; -- rl_speedy_var*10 um auf eine nachkommastelle zu kommen, ergebnis ist 1/10 
--								
--								sr_speedy_var := factor_con*rr_speedy_var;
--								sr_speedy_var := sr_speedy_var/to_integer(unsigned(resolution_reg_ava));
--								
--								sl_speedy_var := factor_con*rl_speedy_var;
--								sl_speedy_var := sl_speedy_var/to_integer(unsigned(resolution_reg_ava));
							

							--Mistakes will be catched by NIOS
							

						when others => null;
						--should not happen, catched by NIOS
					end case;

--					IF cmd_reg_local = "001" THEN 
--						angle_reg 		<= (others=>'0');
--					ELSE
--						distance_reg	<= (others=>'0');
--					END IF;
--
--						
--					IF (cmd_reg_local = "010" or cmd_reg_local = "011") THEN
--						relation_sig	<= (others=>'0');
--					END IF; 

					state_s <= send_to_next_level_st;


				when send_to_next_level_st => --uebergabe der befehle

					sabertooth_m1_command_out_sig	<= command_m1_sig;

					sabertooth_m2_command_out_sig	<= command_m2_sig;

					sabertooth_m_distance_out_sig	<= distance_reg;

					sabertooth_m_speed_out_sig		<= speed_reg;
					
					sabertooth_m_angle_out_sig		<= angle_reg;

					sabertooth_m_relation_out_sig	<= std_logic_vector(to_unsigned(relation_calc_var,8)); --wichtig! wenn alternative dann ist es 1/10

					sabertooth_m_cmd_out_sig		<= cmd_reg(2 downto 0);
					
					sabertooth_m_start_out_sig		<= '1';
					
					curve_m1_distance_out_sig		<= circle_distance_part_m1_reg_ava; --"0000000100001100";--std_logic_vector(to_unsigned(sl_speedy_var,16));--"0000001010000101";--std_logic_vector(to_unsigned(sl_speedy_var,16));
					
					curve_m2_distance_out_sig		<= circle_distance_part_m2_reg_ava; --"0000000010111100";--std_logic_vector(to_unsigned(sr_speedy_var,16));--"0000000111000100";--std_logic_vector(to_unsigned(sr_speedy_var,16));
					
					curve_resolution_out_sig		<= resolution_reg_ava;

					state_s								<= get_cmd_st;
					
			END case;
		END IF;
	END PROCESS;	
			
end arch_interface_motor_modul;















