--! @file		uart_send.vhd
--! @brief		Sendeeinheit des UART-Moduls
--! @details
--! Um die Sendeeinheit zu benutzen muss das modul_uart eingebunden werden es kombiniert Sende- und Empfangseinheit\n\n
--!
--! <b>Wesentliche Funktionen</b>
--!		-	UART Sendemodul, welches auf einer Empfangsleitung 8 Datenbits mit jeweils einem Start und Stopbit sendet.
--!
--! <b>Grundsätzlicher Ablauf</b>
--!		-	Ablauf in einer State Machine
--!		-	Der Ruhezustand der Ausgangsleitung ist '1' dieser wird im 'idle_st' gesetzt.
--!			In diesem State bleibt die State Machine solange bis das Flag 'flag_start_sending'
--!			gesetzt wird. Dann wird in den State 'sending_st gewechselt.
--!		-	Im 'sending_st' State wird immer dann wenn vom Baudratengenerator die Baudflanke
--!			kommt ein Bit gesendet. Solange bis alle Bit gesendet wurden. Dann wird in den
--!			'done_st' gewechselt.
--!		-	Im 'done_st' werden Varibalen ('dataBitPos_v') und Flags ('flag_sending_done') zurückgesetzt
--!			danch wird er State ('idle_st') gewechselt um wieder neue Daten senden zu können.
--!
--! @note
--! <b>Hinweis zu Parametern</b>
--!		-	clr_n:
--!			#	gewöhnliches Clear Signal bei dem die Ausgangsleitungen
--!				'receive_out' und 'receive_done' auf 0 gesetzt werden
--!				Die Variable 'receivePos_v' und das Flag 'receive_flag'
--!				werden auf '0' gesetzt
--!
--!		-	clk:
--!			#	gewöhnliches Systemclocksignal
--!				Hier wichtig, dass die Clock >> Baudrate ist.
--!
--!		-	baudrate:
--!			#	Enable vom Baudratengenerator.
--!
--!		-	flag_start_sending:
--!			#	Flag zum anstoßen eines Sendevforgangs
--!
--!		-	tx_byte_buffer:
--!			#	Zu sendende Daten
--!
--!		-	flag_sending_done:
--!			#	Flag zeigt fertig mit Senden. Dann können neue Daten angelegt werden.
--!				WICHTIG: zwischen 'flag_start_sending' und 'flag_sending_done' dürfen die Daten nciht verändert werden!!!!!
--!
--!		-	uart_tx:
--!			#	serielle Datenbits
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

--! Use Standard Arithmetic Library
USE IEEE.STD_LOGIC_ARITH.ALL;     -- für conv functions erforderlich

--! Use Standard Logic Unsigned Library
--USE IEEE.STD_LOGIC_unsigned.ALL;  -- für conv functions erforderlich

--! Use Standard Logic Signed Library
-- USE IEEE.STD_LOGIC_signed.ALL;  -- alternativ zur unsigned-Lib...

--! Use Numeric Library
USE ieee.numeric_std.ALL;

--LIBRARY modelsim_lib;
--use modelsim_lib.util.all;

--! @ingroup VHDL
--! @brief		Sendeeinheit des UART-Moduls
ENTITY uart_send IS -- Sendeeinheit
	PORT(
		clr_n				: IN STD_LOGIC; --! System-Reset
		clk					: IN STD_LOGIC; --! System-Clock 50MHz
		baudrate			: IN STD_LOGIC := '0'; --! Bausdrate
		flag_start_sending	: IN STD_LOGIC := '0'; --! Flag: "LOS!"
		tx_byte_buffer		: IN STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000"; --! Datenbits welche gesendet werden sollen
		flag_sending_done	: OUT STD_LOGIC := '0'; --! Flag: "fertig mit senden"
		uart_tx				: OUT STD_LOGIC := '0' --! serielle Daten
	);
END uart_send;

--! @brief		Sendeeinheit des UART-Moduls
ARCHITECTURE arch_uart_send OF uart_send IS

--! Typendefinition
TYPE STATE_TYPE IS (idle_st, sending_st, done_st);
--! Send Signale
SIGNAL state_s				: STATE_TYPE := idle_st;

	BEGIN -- architecture

	PROCESS(clr_n, clk, baudrate, state_s, tx_byte_buffer)
	
		--Variablen deklaration
		VARIABLE dataBitPos_v : INTEGER := 0;
		
			BEGIN-- Process
			--! asynchrones Verhalten
			IF (clr_n = '0') THEN
				--Verhalten bei Reset
				uart_tx <= '1';
				flag_sending_done <= '0';--! Flag: "fertig mit senden" NICHT
				dataBitPos_v := 0;

			--! synchrones Verhalten
			ELSIF (clk'event and clk = '1') THEN
			
				--! State Machine
				CASE state_s IS
				
					--! Warten bis was gesendet werden soll
					WHEN idle_st =>
					
						--! Fang an zu senden
						IF (flag_start_sending = '1') THEN
							--! Vorbereiten des Sendens
							uart_tx <= '1'; --! Leitung in den Ruhezustand
							flag_sending_done <= '0'; --! Flag: "fertig mit senden" NICHT
							dataBitPos_v := 0; --! Vorne Anfangen
							state_s <= sending_st; --! eigentliches senden
							
						ELSE
							--! W	A	R	T	E	N
							uart_tx <= '1'; --! Leitung in den Ruhezustand
							flag_sending_done <= '0'; --! Flag: "fertig mit senden" NICHT
							state_s <= idle_st; --! weiter warten
							
						END IF;
					
					--! S	E	N	D	E	N
					WHEN sending_st =>
						--! Flag: "fertig mit senden" NICHT
						flag_sending_done <= '0';
						
						--! Bausdrate
						IF (baudrate = '0') THEN
							NULL;--! nicht Baud
						
						ELSE
					
							--! wenn Baudrate dann sende
							CASE dataBitPos_v IS --! Eigentliches Senden		
								WHEN 0 => uart_tx <=  '0'; --! Startbit
								WHEN 1 => uart_tx <= tx_byte_buffer(0); --! Datenbit 1
								WHEN 2 => uart_tx <= tx_byte_buffer(1); --! Datenbit 2
								WHEN 3 => uart_tx <= tx_byte_buffer(2); --! Datenbit 3
								WHEN 4 => uart_tx <= tx_byte_buffer(3); --! Datenbit 4
								WHEN 5 => uart_tx <= tx_byte_buffer(4); --! Datenbit 5
								WHEN 6 => uart_tx <= tx_byte_buffer(5); --! Datenbit 6
								WHEN 7 => uart_tx <= tx_byte_buffer(6); --! Datenbit 7
								WHEN 8 => uart_tx <= tx_byte_buffer(7); --! Datenbit 8
								WHEN 9 => uart_tx <= '1';
								WHEN OTHERS => uart_tx <= '1'; --! Stoppbit
							END CASE;--! ENDE eigentliches Senden
							
							--! Inkrement solange nicht alle Bits gesendet
							IF (dataBitPos_v <= 9) THEN
								dataBitPos_v := dataBitPos_v + 1;
								
							ELSE--! Es wurde alles gesendet
								dataBitPos_v := 0; --! nächstes mal wieder von vorne anfangen
								state_s <= done_st; --! State: Fertig mit senden
								
							END IF;
						END IF;
					
					--! Es wurde alles gesendet
					WHEN done_st =>
						dataBitPos_v := 0; --! Wieder vorne anfangen
						flag_sending_done <= '1'; --! Flag: "fertig mit senden"
						state_s <= idle_st; --! Warten bis wieder was gesendet werden soll
					
					--! irgendwas komisches ist passiert
					WHEN OTHERS =>
					
						state_s <= idle_st; ---! biege es wieder gerade						
				END CASE; --! Ende State Machine
			END IF;	--! Ende synchrones Verhalten

			
	END PROCESS;-- Ende des Processes
END arch_uart_send;-- Ende der Architecture