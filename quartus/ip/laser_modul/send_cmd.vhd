--! @file		uart_send.vhd
--! @brief		Befehlsverwaltung für den Laser
--! @details
--! Zur Verwaltung der möglichen Befehle des Lasers wird diese Komponente in das Modul 'modul_laser.vhd' Eingebunden\n\n
--!
--! <b>Wesentliche Funktionen</b>
--!		-	in Abhängigkeit der Nummer am Eingang wird ein das Senden eines bestimmten Befehls angestoßen.
--!
--! <b>Grundsätzlicher Ablauf</b>
--!		-	Organisation in einer State Machine
--!		-	An den Eingang 'command_addr' wird eine Zahl zwischen 0 und 14 gelegt.
--!		-	Hinter den Zahlen 1 bis 14 verbergen sich mögliche Befehle an den
--!			Laser und '0' bedeutet das nichts gesendet werden soll.
--!		-	Wenn der Eingang 'command_addr' verschieden von '0' ist wird der State in
--!			'buffering_st' geändert. Hierzu wird die Variable 'stringPos_v' auf '1' gesetzt
--!			und die Flags 'flag_end_of_command_s' und 'flag_start_sending' auf '0' gesetzt.
--!		-	Im 'buffering_st' wird der String mit dem Befehl übertragen. Der State wird dann
--!			verlassen wenn das zu sendende Zeichen anliegt und das Flag 'flag_start_sending' gesetzt wurde.
--!			Zusätzlich kann das Flag 'flag_end_of_command_s' gesetzt sein.
--!		-	Der State 'clearToSend_st' wird nur kurz eingenommen da hier nur unterschieden
--!			wird ob im Anschluss wieder in den 'buffering_st' übergeganger werden muss
--!			oder in den 'idle_st'.
--!
--! @note
--! <b>Hinweis zu Parametern</b>
--!		-	clr_n:
--!			#	gewöhnliches Clear Signal bei dem alle Signale auf einen definieren Zustand gesetzt werden
--!
--!		-	clk:
--!			#	gewönliches Systemclocksignal
--!
--!		-	flag_sending_done:
--!			#	Flag welches zeigt, dass ein Byte erfolgreich gesendet wurde
--!
--!		-	command_addr:
--!			#	Nummer des zu sendenden Befehls
--!
--!		-	flag_start_sending:
--!			#	Activiert die UART Sendeeinheit ("Anstoßen eines Sendevorgangs")
--!
--!		-	tx_byte_buffer:
--!			#	zu sendende Daten
--!
--! compilation : Quartus Primne Version 15.1.2 Build 192 02/01/2016 SJ Standard Edition
--! simulation : Quartus or ModelSim, V10.4b \n
--! 
--! @author  ChRHohenberg
--! @version V1.0
--! @date    08.06.2016
--!
--! \n@todo  Baud_gen so anpassen, dass eine höhere Überabtastung stattfinden kann.
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

 --! Use Standard Logic Unsigned Library
 USE IEEE.STD_LOGIC_unsigned.ALL;  -- für conv functions erforderlich

-- --! Use Standard Logic Signed Library
--USE IEEE.STD_LOGIC_signed.ALL;  -- alternativ zur unsigned-Lib...

--! Use Numeric Library
USE IEEE.NUMERIC_STD.ALL;

--LIBRARY modelsim_lib;
--use modelsim_lib.util.all;

--! @ingroup VHDL
--! @brief Sende-Komponente

ENTITY send_cmd IS -- Sendebuffer
	PORT(
		clr_n	: IN STD_LOGIC; --! System-Clock
		clk		: IN STD_LOGIC; --! System-Reset
		flag_sending_done		: IN STD_LOGIC; --! Acknowledge wird mit send_done  von uart_send verbunden
		command_addr	: IN UNSIGNED(7 DOWNTO 0); --! Nummer des Befehls der gesendet werden soll
		flag_start_sending		: OUT STD_LOGIC := '0'; --! ClearToSend wird mit send_active von uart_send verbunden
		tx_byte_buffer	: OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0) := "00000000" --! Datenbits wird mit send_in von uart_send verbunden
	);
END send_cmd;

--! @brief	Architecture Befehlsverwaltung für den Laser
ARCHITECTURE arch_laser_send_cmd OF send_cmd IS

-- Typen definieren
TYPE STRING IS ARRAY (POSITIVE RANGE <>) OF CHARACTER;--! String definieren kennt VHDL nicht
TYPE STRING_ARRAY IS ARRAY (1 TO 14) OF STRING (1 TO 16);--! Ein Array aus Strings
TYPE STATE_TYPE IS (idle_st, buffering_st, clearToSend_st);--! States

-- Signals deklarieren
SIGNAL state_s		: STATE_TYPE := idle_st;--! Statesignal für State Machine
SIGNAL flag_end_of_command_s	: std_logic := '0'; --! EndOfCommand-Signal signalisiert das Ende des Befehls
SIGNAL cmdArray		: STRING_ARRAY;--! Array aus Strings in denen die Befehle stehen

	BEGIN -- architecture

	PROCESS(clr_n, clk, state_s)
	
		CONSTANT charLF_v 		: CHARACTER	:= CHARACTER'val(10);
		--Variablen deklaration
		VARIABLE stringPos_v	: INTEGER	:= 1;
		VARIABLE cmdNumber_v	: INTEGER := 0;
		VARIABLE buffer_v	: INTEGER := 0;
		
		
		
			BEGIN-- Process

				-- Beschreiben der Befehle die der Lasersensor versteht.
				-- laser_State
				cmdArray(1)		<=	"II"	-- 	 Command Symbol	-- String Characters
									&charLF_v	-- Line Feed als Ende des Befehls
									&"0000000000000"; -- Auffüllen des Strings, da es nur statische String in VHDL gibt
								
				
				-- n_Measurements 
				cmdArray(2)		<=	"MS"	-- Command Symbol: M(4dH) D(44H) three Character Encoding
									&"0044"	-- Starting Step: 0010 jedem Byte wird 30H addiert
									&"0725"	-- End Step: 0750 jedem Byte wird 30H addiert
									&"00"	-- Cluster Count: Anzahl der benachbarten Steps die zusammengefasst werden dürfen, wobei der niedrigste Wert zurückgegeben wird.
									&"0"	-- Scan Interval: Anzahl der Messungen bevor gespeichert wird soll in Dezimalzahl gegeben werden
									&"01"	-- Number of Scans: Anzahl der durchzuführenden Messungen, soll in Dezimalzahlen gegeben werden.
									&charLF_v;	-- Line Feed als Ende des Befehls

				-- last_Values SO HAT LATZEL DEN BEFEHL GESENDET
				cmdArray(3)		<=	"GD"	-- Command Symbol
									&"0128"	-- Starting Step
									&"0640" -- End Step
									&"03"	-- Clyster Count
									&charLF_v	-- Line Feed als Ende des Befehls
									&"000";
									
				-- laser_Enable
				cmdArray(4)		<=	"BM"	-- Command Symbol
									&charLF_v	-- Line Feed als Ende des Befehls
									&"0000000000000";
									
				-- laser_Disable
				cmdArray(5)		<=	"QT"	-- Command Symbol
									&charLF_v	-- Line Feed als Ende des Befehls
									&"0000000000000";

				-- laser_Reset
				cmdArray(6)		<=	"RS"	-- Command Symbol
									&charLF_v	-- Line Feed als Ende des Befehls
									&"0000000000000";

				-- time_Adjust
				cmdArray(7)		<=	"TM"	-- Command Symbol
									&"0"	-- Control Code: kann sein 0 für Adjust-Mode an, 1 für Time-Request, 2 für Adjust-Mode off
									&charLF_v	-- Line Feed als Ende des Befehls
									&"000000000000";
									
				-- bit_Rate
				cmdArray(8)		<=	"SS"	-- Command Symbol
									&"019200"	-- Bit Rate	-- String Character
									&charLF_v	-- Line Feed als Ende des Befehls
									&"0000000";
				
				-- motor_Speed
				cmdArray(9)		<=	"CR"	-- Command Symbol
									&"00"	-- Speed Parameter: '00' Default, '01~10' 10 Geschwindigkeitslevel, '99' Reset zu Anfangswert
									&charLF_v	-- Line Feed als Ende des Befehls
									&"00000000000";
									
				-- sensity_Mode
				cmdArray(10)	<=	"HS"	-- Command Symbol
									&"0"	-- Parameter: kann sein 0 für Normal-Mode, 1 für High-Sensitivity-Mode
									&charLF_v	-- Line Feed als Ende des Befehls
									&"000000000000";

				-- laser_Malfunction
				cmdArray(11)	<=	"DB"	-- Command Symbol
									&"10"	-- Parameter: siehe Protocolspezifikation Seite 19/25
									&charLF_v	-- Line Feed als Ende des Befehls
									&"00000000000";
										
				-- laser_Details
				cmdArray(12)	<=	"VV"	-- 	 Command Symbol
									&charLF_v	-- Line Feed als Ende des Befehls
									&"0000000000000";
									
				-- laser_Spezification
				cmdArray(13)	<=	"PP"	-- 	 Command Symbol
									&charLF_v	-- Line Feed als Ende des Befehls
									&"0000000000000";
									
				cmdArray(14)	<=	"II"	-- 	 Command Symbol
									&charLF_v
									&charLF_v-- Line Feed als Ende des Befehls
									&"000000000000";
				
											
				--asynchrones Verhalten
				IF (clr_n = '0') THEN
				
					--Verhalten bei Reset
					state_s <= idle_st;
					stringPos_v := 1;
					flag_end_of_command_s <= '0';
					
				-- synchrones Verhalten
				ELSIF (clk'event and clk = '1') THEN
				
					CASE state_s IS -- Statemaschine
					
						WHEN idle_st => -- Warten auf Daten
						
							-- Es soll ein Befehl gesendet werden
							
							IF (command_addr /= "0000") THEN
							
								--! Vorbereiten der BUFFER und COUNTER
								stringPos_v := 1;--! String von vorne durchlaufen						
								flag_end_of_command_s <= '0';--! EndOfCommand zuruecksetzen
								flag_start_sending <= '0'; --! ClearToSend zuruecksetzen
								
								-- Speichern der Befehlsnummer
								cmdNumber_v := to_integer(command_addr);
								
								-- Wechseln des Status zu Daten auf Vector schreiben
								state_s <= buffering_st;
															
							-- keinen Befehl senden
							ELSE
							
								NULL;
								
							END IF;	
							
						WHEN buffering_st => -- Daten zum Senden liegen an und muessen auf den Ausgang fuer UART gelegt werden
							
							-- Pruefen ob der Character an der Stelle stringPos_v gleich "LF" ( ENDE des Befehls) ist
							IF (character'pos(cmdArray(cmdNumber_v)(stringPos_v)) /= character'pos(charLF_v)) THEN -- Character ist nicht Ende des Befehls
							
								--Belegen der Datenleitung
								
								buffer_v := character'pos(cmdArray(cmdNumber_v)(stringPos_v));
								tx_byte_buffer <= std_logic_vector(to_unsigned(buffer_v,8));
								
								-- Ende des Befehls ist noch nicht erreicht
								flag_end_of_command_s <= '0'; -- Setzen des Flags
								stringPos_v := stringPos_v + 1;
							
							ELSE -- Character ist Ende des Befehls
							
								-- Belegen der Datenleitung mit (Ende des Befehls) "LF"
								buffer_v := character'pos(charLF_v);
								tx_byte_buffer <= std_logic_vector(to_unsigned(buffer_v,8));
								
								-- Markieren des Ende des Befehls
								flag_end_of_command_s <= '1';
								stringPos_v := 1;
								
							END IF;
							
								-- Bereit zum Senden
								flag_start_sending <= '1';
								
								-- Wechseln zum Status senden
								state_s <= clearToSend_st;
								
						WHEN clearToSend_st =>
						
							-- Datenbits sind belegt und koennen gesendet werden
							flag_start_sending <= '0';
							-- Warten auf Acknowledge von UART das Daten gesendet wurden
							IF(flag_sending_done = '1') THEN -- Daten wurden ueber UART gesendet
							
								-- Pruefen ob noch weitere Befehlsdaten gesendet werden muessen
								IF(flag_end_of_command_s = '1') THEN -- Ende des Befehls erreicht
								
									flag_start_sending <= '0'; -- ClearToSend zuruecksetzen
									state_s <= idle_st; -- Warten auf neuen Befehl
									
								ELSE --	weitere Characters senden
								
									state_s <= buffering_st; -- Datenbits belegen
								
								END IF;								
							ELSE
							
								-- Daten werden noch gesendet
								NULL;
							
							END IF;
							
							
						WHEN OTHERS => -- irgendwo war ein Fehler
						
							state_s <= idle_st; -- zurueck in definierten Zustand
							
					END CASE;--! Ende State Machine	
				END IF; --! Ende synchrones Verhalten
	END PROCESS;-- Ende des Processes
END arch_laser_send_cmd;-- Ende der Architecture