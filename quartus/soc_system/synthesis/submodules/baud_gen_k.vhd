--! @file 		baud_gen.vhd
--! @brief		Dient als Baudgenerator fuer verschiedene weitere Module zb. UART.
--! @details	In diesem Modul wird in abhaenigkeit der BAUD_g Variablen ein passendes
--! 				Signal generiert, welches fuer ein weiters Modul als Bausclock dienen kann.
--!
--! 
--! @author 	BoE. Lt. Kluge Florian
--! @version 	V1.0
--! @date    	18.04.2016
--!
--! @par History:
--! @details	- 	V0.1 	start of development 
--!				11.04.2016 Hohenberg
--!
--! @details	-	V1.0	Ueberarbeitung des Modules, Kommentierung und implementierung Aenderungen fuer Anforderungen
--!							verwendetes Projekt.
--!				18.04.2016 Kluge
--!
--! @todo		---
--!
--! @bug			---

LIBRARY IEEE;
USE ieee.std_logic_1164.all;


ENTITY baud_gen_k IS 						-- Baudrate erzeugen
GENERIC (BAUD_g : INTEGER := 2604); --128 bei 2,5MHZ fuer 19200baud// 2604 bei 50MHZ fuer 19200baud
	PORT(
		reset_n	: IN STD_LOGIC; 		--reset_n
		clk		: IN STD_LOGIC; 		--clk
		baud_en	: OUT STD_LOGIC		--zum schreiben
	);
END baud_gen_k;

ARCHITECTURE arch_baud_gen OF baud_gen_k IS
BEGIN 										-- architecture

	PROCESS(reset_n,clk)
		VARIABLE count_v	: INTEGER RANGE 1 TO BAUD_g := 1;
			BEGIN								-- Process
			
				--asynchrones Verhalten
				IF (reset_n = '0') THEN

					count_v := 1;
					baud_en <= '0';
									
				-- synchrones Verhalten
				ELSIF (clk'event and clk = '1') THEN
				
					-- Wenn die Zaehlvariable 'count_v' den Sollwert 'BAUD_g'...
					-- erreicht hat dann einen Takt lang Enable 'baud_en' auf '1' setzen...
					IF (count_v = BAUD_g) THEN -- enable_v = BAUD_g
					
						baud_en <= '1';
						count_v := 1;
						
					
					-- sonst die Zaehlvariable incrementieren
					-- und das Enablesignal auf '0' setzen.
					ELSE
					
						baud_en <= '0';
						count_v := count_v + 1;
						
					END IF;
				END IF;
	END PROCESS;							-- Ende des Processes
END arch_baud_gen;						-- Ende der Architecture