
--! @file 	winkel_modul.vhd
--! @brief	Modul zur bestimmung einer Aktion durch die Winkelgeschwindigkeit.
--! @details	In diesem Modul werden die beiden Encoder ausgewertet und das Ergebnis
--!		in ein Register geschrieben. 
--! 		Zusaetzlich wird das Jitter abgefangen um genauer zu messen. 
--!		Eine Auswertung der Werte erfolgt hier nicht. 
--!		Rueckgabewerte sind:	- Geschwinsigkeit(pro bestimmte Zeit)
--!					- Distanz(abhaengig von der max zurueckgelegten Entfernung hier: 20bit) 
--! 		
--!
--! 
--! @author 	BoE. Lt. Kluge Florian
--! @version 	V0.3
--! @date    	31.05.2016
--!
--! @par History:
--! @details	- 	V0.1 	start of development 
--!				05.04.2016 Kluge
--!
--! @details	- 	V0.2 	korrekte programmierung der winkel berechnung des drive_turn partes 
--!				12.05.2016 Kluge
--!
--! @details	- 	V0.3  verbesserte programmierung der winkel berechnung des drive_turn partes 
--!				31.05.2016 Kluge
--!
--!
--! @todo		---
--!
--! @bug			---

library IEEE;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;




entity winkel_modul is
Generic( 
	MAX_COUNT				: integer := 5_000_000;	--neue werte des gyros alle 100ms -> 50MHz(system) -->5000000
	REG1_Angle_cntBits	: INTEGER := 16
	);
	port
	(
		reset_n				: in  std_logic;
		clk					: in  std_logic;

		--Process_enable in
		drive_enable_in	: in  std_logic;
		turn_enable_in		: in  std_logic;
		curve_enable_in	: in  std_logic;

		--Gyro input 
		gyro_angle_in		: in std_logic_vector(REG1_Angle_cntBits-1 downto 0) := (others=>'0'); --eigentlich 16bit fuer Zahle aber vllt. 15bit(32767) und 1bit fuer +/- // wird aber in C immer als positiver wert uebergeben

		--Aim angle input 
		aim_angle_in		: in std_logic_vector(REG1_Angle_cntBits-1 downto 0); --eigentlich 16bit fuer Zahle aber vllt. 15bit(32767) und 1bit fuer +/- // +/- wird hier aber nicht gebraucht...

--		--resolution in
--		resolution_in		: in std_logic_vector(REG1_Angle_cntBits-1 downto 0);
		
		--Out to motor_modul
		--out for curve
		curve_angle_out	: out std_logic_vector(REG1_Angle_cntBits-1 downto 0);
--		curve_enable_out	: out std_logic;
		--out for turn
		turn_enable_out	: out std_logic
		--out for drive
--		drive_enable_out	: out std_logic
			
		
	);
end winkel_modul;



architecture arch_winkel_modul of winkel_modul is

signal gyro_angle_in_FF_sig	: std_logic_vector(REG1_Angle_cntBits-1 downto 0) := (others=>'0');
signal start_turn_sig		: std_logic := '0';
signal start_curve_sig		: std_logic := '0';

begin

-------------------------------------------------------------------------------------------------------
--FlipFlop zum synchronen Arbeiten, es werden alle 100ms der neue wert des gyros aus dem register gelesen...
	process (clk, reset_n)
 
	variable count		: integer RANGE MAX_COUNT downto 0 := 0; 

	begin
		
		IF reset_n = '0' THEN
			count := 0;
			gyro_angle_in_FF_sig <= (others => '0'); 

		ELSIF clk'EVENT AND clk = '1' THEN
			IF turn_enable_in = '1' or curve_enable_in = '1' THEN
				IF count = MAX_COUNT THEN
					gyro_angle_in_FF_sig <= gyro_angle_in;
					count := 0;

				END IF;
				count := count +1;
			ELSIF  turn_enable_in = '0' or curve_enable_in = '0' THEN
				count := 0;
				gyro_angle_in_FF_sig <= (others => '0');

			END IF;
		END IF;

		
	end process;
-------------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------------------------
--process fuer turn
	process (clk, reset_n)
	
	variable actual_angle_var	: integer RANGE 3600 downto -3600 := 0;
	variable aim_angle_var		: integer RANGE 3600 downto -3600 := 0;
	
	variable count					: integer RANGE MAX_COUNT downto 0 := 0; 

	begin
		IF reset_n = '0' THEN
			count := 0;
			turn_enable_out <= '0';
			actual_angle_var := 0;
			aim_angle_var := 0;
			
		ELSIF clk'EVENT AND clk = '1' THEN
			IF turn_enable_in = '1' THEN
				IF start_turn_sig = '0' THEN
					turn_enable_out <= '1';
					actual_angle_var := 0;
						
					aim_angle_var := ((to_integer(unsigned(aim_angle_in(REG1_Angle_cntBits-2 downto 0))))*10); -- -2 da 1 bit vorzeichen
					aim_angle_var := (aim_angle_var - 185);-- -180 geht gut --abzug 18,5 hat sich als besser erwiesen...

					start_turn_sig <= '1';
					
				END IF;
				IF count >= MAX_COUNT THEN --neue werte des gyros alle 100ms -> 50MHz(system) -->5000000 
					
					actual_angle_var := (actual_angle_var + (to_integer(unsigned(gyro_angle_in_FF_sig(REG1_Angle_cntBits-1 downto 0))))); -- kommt positiv aus c
					
					IF actual_angle_var >=  aim_angle_var THEN
						turn_enable_out <= '0';
					END IF;
					
					count := 0;
				ELSE
					count := count +1;
				END IF;

			ELSIF turn_enable_in = '0' THEN
				turn_enable_out <= '0';
				count := 0;
				actual_angle_var := 0;
				start_turn_sig <= '0';
				aim_angle_var := 0;
				actual_angle_var := 0;
				
			END IF;
		END IF;
	end process;
-------------------------------------------------------------------------------------------------------


--process fuer curve
	process (clk, reset_n)
	
	variable actual_angle_var	: integer RANGE 3600 downto -3600 := 0;
	variable count					: integer RANGE MAX_COUNT downto 0 := 0; 
	
	begin
		IF reset_n = '0' THEN
			count := 0;

			actual_angle_var := 0;

			
		ELSIF clk'EVENT AND clk = '1' THEN
			IF curve_enable_in = '1' THEN
				IF start_curve_sig = '0' THEN

					actual_angle_var := 0;
					
					start_curve_sig <= '1';
					
				END IF;
				IF count >= MAX_COUNT THEN --neue werte des gyros alle 100ms -> 50MHz(system) -->5000000 
					
					actual_angle_var := (actual_angle_var + (to_integer(unsigned(gyro_angle_in_FF_sig(REG1_Angle_cntBits-1 downto 0))))); -- kommt positiv aus c
					curve_angle_out <= std_logic_vector(to_unsigned(actual_angle_var,16));


					count := 0;
				ELSE
					count := count +1;
				END IF;

			ELSIF curve_enable_in = '0' THEN

				count := 0;

				start_curve_sig <= '0';
				
			END IF;
		END IF;
	end process;
-------------------------------------------------------------------------------------------------------


----process fuer drive
--	process (clk)
--	begin
--	end process;

                                                                                                   
end arch_winkel_modul;