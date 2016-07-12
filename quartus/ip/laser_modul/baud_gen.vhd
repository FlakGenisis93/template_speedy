--! @file		baud_gen.vhd
--! @brief		Baudratengenerator
--! @details
--! Bestandteil des Moduls uart_modul.vhd\n\n
--!
--! <b>Wesentliche Funktionen</b>
--!		-	erzeugt Baudrate und Abtastrate
--!
--! <b>Grundsätzlicher Ablauf</b>
--!		-	Der Systemtakt wird geteilt und auf die verschiedenen Ausgänge gelegt.
--!
--! @note
--! <b>Hinweis zu Parametern</b>
--!		-	clr_n:
--!			#	gewöhnliches Clear Signal bei dem die Ausgangsleitungen
--!				auf '0' gesetzt werden.
--!
--!		-	clk:
--!			#	gewöhnliches Systemclocksignal
--!				WICHTIG:	Da der Systemclock nur geteilt wird muss der Generic
--!							entsprechend eingestellt werden.
--!					!!!!!!!	Die Baudrate ergibt sich aus Systemtakt durch Generic !!!!!!
--!
--!		-	baudrate:
--!			#	Baudrate.
--!
--!		-	samplerate:
--!			#	Abtastrate
--!
--! compilation : Quartus Primne Version 15.1.2 Build 192 02/01/2016 SJ Standard Edition
--! simulation : Quartus or ModelSim, V10.4b \n
--! 
--! @author  ChRHohenberg
--! @version V1.0
--! @date    08.06.2016
--!
--! \n@todo nichts eingetragen
--!
--! @bug  nichts eingetragen
--!
--! @brief
--! <h2><center>&copy; COPYRIGHT 2011 UniBwM ETTI WE 4</center></h2>
--!
--! @defgroup VHDL VHDL

--! Use Standard Library
LIBRARY IEEE;

--! Use Standard Logic Library
USE IEEE.STD_LOGIC_1164.ALL;

-- --! Use Standard Arithmetic Library
-- USE IEEE.STD_LOGIC_ARITH.ALL;     -- für conv functions erforderlich

-- --! Use Standard Logic Unsigned Library
-- USE IEEE.STD_LOGIC_unsigned.ALL;  -- für conv functions erforderlich

-- --! Use Standard Logic Signed Library
--USE IEEE.STD_LOGIC_signed.ALL;  -- alternativ zur unsigned-Lib...

-- --! Use Numeric Library
-- USE IEEE.NUMERIC_STD.ALL;

--LIBRARY modelsim_lib;
--use modelsim_lib.util.all;

--! @ingroup VHDL
--! @brief Baudratengenerator
ENTITY baud_gen IS -- Baudrate erzeugen
GENERIC (BAUD_g : INTEGER := 128);
	PORT(
		clr_n		: IN STD_LOGIC; --! System-Reset
		clk			: IN STD_LOGIC; --! System-Clock 50MHz
		baudrate	: OUT STD_LOGIC; --! Baudrate
		samplerate	: OUT STD_LOGIC --! Abtastrate
	);
END baud_gen;

ARCHITECTURE arch_baud_gen OF baud_gen IS
	BEGIN -- architecture

	PROCESS(clr_n,clk)
		VARIABLE count_v	: INTEGER RANGE 1 TO BAUD_g := 1;
			BEGIN-- Process
			
				--asynchrones Verhalten
				IF (clr_n = '0') THEN

					--! Verhalten bei Reset
					count_v := 1;
					baudrate <= '0';
					samplerate <= '0';
					
				-- synchrones Verhalten
				ELSIF (clk'event and clk = '1') THEN
					
					count_v := count_v + 1;
					
					CASE count_v IS
						WHEN (BAUD_g/16) => --! Abtastrate	TAKT 1/16
							samplerate <= '1';
							baudrate <= '0';
							
						WHEN (2*BAUD_g/16) => --! Abtastrate	TAKT 2/16
							samplerate <= '1';
							baudrate <= '0';	
							
						WHEN (3*BAUD_g/16) => --! Abtastrate	TAKT 3/16
							samplerate <= '1';
							baudrate <= '0';
							
						WHEN (4*BAUD_g/16) => --! Abtastrate	TAKT 4/16
							samplerate <= '1';
							baudrate <= '0';
							
						WHEN (5*BAUD_g/16) => --! Abtastrate	TAKT 5/16
							samplerate <= '1';
							baudrate <= '0';
						
						WHEN (6*BAUD_g/16) => --! Abtastrate	TAKT 6/16
							samplerate <= '1';
							baudrate <= '0';
						
						WHEN (7*BAUD_g/16) => --! Abtastrate	TAKT 7/16
							samplerate <= '1';
							baudrate <= '0';
							
						WHEN (8*BAUD_g/16) => --! Abtastrate	TAKT 8/16
							samplerate <= '1';
							baudrate <= '0';
							
						WHEN (9*BAUD_g/16) => --! Abtastrate	TAKT 9/16
							samplerate <= '1';
							baudrate <= '0';	
						
						WHEN (10*BAUD_g/16) => --! Abtastrate	TAKT 10/16
							samplerate <= '1';
							baudrate <= '0';
						
						WHEN (11*BAUD_g/16) => --! Abtastrate	TAKT 11/16
							samplerate <= '1';
							baudrate <= '0';
						
						WHEN (12*BAUD_g/16) => --! Abtastrate	TAKT 12/16
							samplerate <= '1';
							baudrate <= '0';
						
						WHEN (13*BAUD_g/16) => --! Abtastrate	TAKT 13/16
							samplerate <= '1';
							baudrate <= '0';
						
						WHEN (14*BAUD_g/16) => --! Abtastrate	TAKT 14/16
							samplerate <= '1';
							baudrate <= '0';
						
						WHEN (15*BAUD_g/16) => --! Abtastrate	TAKT 15/16
							samplerate <= '1';
							baudrate <= '0';
						
						WHEN (BAUD_g) => --! Baudrate und Abtastrate
							samplerate <= '1';
							baudrate <= '1';
							count_v := 1;
							
						WHEN OTHERS => --! Abtastrate
							baudrate <= '0';
							samplerate <= '0';
					END CASE;		
						
				END IF;
	END PROCESS;--! Ende des Processes
END arch_baud_gen;--! Ende der Architecture