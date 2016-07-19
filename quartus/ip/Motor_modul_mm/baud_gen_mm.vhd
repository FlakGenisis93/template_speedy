--! @file 		baud_gen_mm.vhd
--! @brief		Dient als Baudgenerator fuer verschiedene weitere Module zb. UART.
--! @details	In diesem Modul wird in abhaenigkeit der BAUD_g Variablen ein passendes
--! 				Signal generiert, welches fuer ein weiters Modul als Baudclock dienen kann.
--!
--! 
--! @author 	BoE. Lt. Kluge Florian
--! @version 	V1.0
--! @date    	13.07.2016
--!
--! @par History:
--! @details	- 	V0.1 	start of development 
--!				11.04.2016 Kluge
--!
--! @details	-	V0.2	Ueberarbeitung des Modules, Kommentierung und implementierung Aenderungen fuer Anforderungen
--!							verwendetes Projekt.
--!				18.04.2016 Kluge
--!
--! @details	- 	V1.0 	final version mit doku  
--!				13.07.2016 Kluge
--!
--! @todo		---
--!
--! @bug			---

LIBRARY IEEE;
USE ieee.std_logic_1164.all;


ENTITY baud_gen_mm IS										-- Baudrate erzeugen
GENERIC (BAUD_g : INTEGER := 2604);						--128 bei 2,5MHZ fuer 19200baud// 2604 bei 50MHZ fuer 19200baud
	PORT(
		reset_n	: IN STD_LOGIC;							-- reset
		clk		: IN STD_LOGIC; 							-- clk
		baud_en	: OUT STD_LOGIC							-- baudclock
	);
END baud_gen_mm;

ARCHITECTURE arch_baud_gen_mm OF baud_gen_mm IS
BEGIN 										

	PROCESS(reset_n,clk)
		VARIABLE count_v	: INTEGER RANGE 1 TO BAUD_g := 1;
			BEGIN								
			
				IF (reset_n = '0') THEN
					count_v := 1;
					baud_en <= '0';
									
				ELSIF (clk'event and clk = '1') THEN
					IF (count_v = BAUD_g) THEN				-- wenn count wert ereicht hat:
						baud_en <= '1';						-- baudclock setzen
						count_v := 1;							-- zaehler reset
						
					ELSE
						baud_en <= '0';						-- baudclock zuruecksetzen
						count_v := count_v + 1;				-- zaehler erhoehen
					END IF;
				END IF;
	END PROCESS;
END arch_baud_gen_mm;