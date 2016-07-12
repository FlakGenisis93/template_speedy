--! @file		uart_receive.vhd
--! @brief		Empfangseinheit des UART-Moduls
--! @details
--! Um die Empfangseinheit zu benutzen muss das modul_uart eingebunden werden es kombiniert Sende- und Empfangseinheit\n\n
--!
--! <b>Wesentliche Funktionen</b>
--!		-	UART Empfangsmodul, welches auf einer Empfangsleitung 8 Datenbits mit jeweils einem Start und Stopbit detektiert.
--!
--! <b>Grundsätzlicher Ablauf</b>
--!		-	Ablauf in einer State Machine
--!		-	Der Ruhezustand der Empfangsleitung ist '1'.
--!		-	Um ein Startbit zu detektieren muss die State Machine im Zustand 'idle_st' sein.
--!			In diesem State geht es darum ein Startbit zu detektieren. Dazu werden zwei Signale abgeprüft.
--!			Zum einen muss das 'uart_rx' Signal vom Ruhezustand '1' abweichen also '0' sein und das Signal
--!			'flag_is_receiving' muss '0' sein. Mit dem Signal 'flag_is_receiving' wird signalisiert ob ein Empfangsvorgang
--!			im Gange ist.
--!		-	Wird ein Startbit erkannt wird muss das das 'flag_is_receiving' gesetzt werden und die Variable
--!			receivePos_v wird auf '0' gesetzt um einen definierten Startpunkt zu haben.
--!			Danach kann der State gewechselt werden.
--!		-	Der eigentliche Empfangsvorgang findet im 'receiving_st' statt.
--!		-	Eigentlich soll mit dem Eingangssignal 'samplerate' der Zustand der Leitung 'uart_rx' abgetastet
--!			werden. Dies führte zu Problemen. Siehe ToDo.
--!		-	Immer dann wenn die Variable receivePos_v einen bestimmten Wert erreicht hat wird
--!			ein bestimmtes Bit des Vectors 'data_s' mit dem momentanen Zustand der Leitung 'uart_rx' belegt.
--!		-	Die Variable 'receivePos_v' wird solange inkrementiert bis die Mitte des Stoppbits erreicht wird.
--!		-	Danach enthält 'data_s' die empfangenden 8 Datenbits und wird auf das Ausgangssignal 'rx_byte_buffer' geschrieben.
--!		-	Um zu signalisieren, dass neue Daten verfügbar sind wird das Signal 'flag_data_byte_ready' gesetzt und der State wird gewechselt.
--!		-	Im State 'done_st' werden alle Signale zurückgesetzt um neue Daten detektieren zu können. Vor allem die Signale
--!		-	'flag_is_receiving' und 'flag_data_byte_ready' müssen hier in den Ausgangszustand gesetzt werden.
--!
--! @note
--! <b>Hinweis zu Parametern</b>
--!		-	clr_n:
--!			#	gewöhnliches Clear Signal bei dem die Ausgangsleitungen
--!				'rx_byte_buffer' und 'flag_data_byte_ready' auf 0 gesetzt werden
--!				Die Variable 'receivePos_v' und das Flag 'flag_is_receiving'
--!				werden auf '0' gesetzt
--!
--!		-	clk:
--!			#	gewönliches Systemclocksignal
--!				Hier wichtig, dass die Clock 50MHz beträgt
--!
--!		-	samplerate:
--!			#	mit diesem Signal soll ein geteiltes Taktsignal geliefert werden
--!				ursprünglich sollte 'receivePos_v' nur dann inkrementiert werden
--!				wenn 'samplerate' eine Flanke hat, damit der Wertebereich von
--!				'receivePos_v' kleiner ist.
--!
--!		-	uart_rx:
--!			#	UART-Empfangsleitung
--!
--!		-	flag_data_byte_ready:
--!			#	Signal das extern anzeigt, dass 8 Datenbits fertig detektiert sind
--!
--!		-	rx_byte_buffer:
--!			#	Detektierte Datenbits
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
--! @brief		Empfangseinheit des UART-Moduls
ENTITY uart_receive IS -- Empfangseinheit
	PORT(
		clr_n					: IN STD_LOGIC; --! System-Reset
		clk						: IN STD_LOGIC; --! System-Clock 50MHz
		samplerate				: IN STD_LOGIC := '0'; --! runtergeteilte Clock
		uart_rx					: IN STD_LOGIC; --! UART-Empfangsleitung
		flag_data_byte_ready	: OUT STD_LOGIC := '0'; --! Flag, welches zeigt das ein Detektiervorgang abgeschlossen ist
		rx_byte_buffer			: OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000" --! fertig detektierte Datenbits
	);
END uart_receive;

--! @brief		Empfangseinheit des UART-Moduls
ARCHITECTURE arch_uart_receive OF uart_receive IS

--! Typendefinition
TYPE STATE_TYPE IS (idle_st, receiving_st, done_st);

--! Receive Signale
SIGNAL state_s	: STATE_TYPE := idle_st; --! State Machine
SIGNAL flag_is_receiving : STD_LOGIC := '0'; --! Flag um zu zeigen, dass gerade detektiert wird
SIGNAL data_s	:	STD_LOGIC_VECTOR(7 DOWNTO 0):= "00000000"; --! Damit immer gültige Daten am Ausgang liegen wird mit diesem Signal während des Empfangends gearbeitet

	BEGIN -- architecture

	PROCESS(clr_n, clk, samplerate, state_s)
	
		--Variablen deklaration
		VARIABLE receivePos_v : INTEGER := 0;
		
			BEGIN-- Process
			--! asynchrones Verhalten
			IF (clr_n = '0') THEN
			
				--Verhalten bei Reset
				rx_byte_buffer <= "00000000";
				flag_data_byte_ready <= '0';
				receivePos_v := 0;
				flag_is_receiving <= '0';
				data_s <= "00000000";
				state_s <= idle_st;
					
			--! synchrones Verhalten
			ELSIF (rising_edge(clk)) THEN
			
				--! State Machine
				CASE state_s IS
				
					--! Warten auf Daten
					WHEN idle_st =>
					
						--! Es wird gerade nichts empfangen
						flag_data_byte_ready <= '0';
					
						--! Noch wird nichts Empfangen aber die Datenleitung ist nicht mehr im Ruhezustand
						IF (uart_rx = '0') THEN -- Detektieren Startbit
							
							--! Ab jetzt werden Daten empfangen
							receivePos_v := 0;
							state_s <= receiving_st;	-- Wechseln zum Detektieren der Daten
						ELSE
							
							--! weiter warten
							state_s <= idle_st;
							
						END IF;
					--! Detektieren von Daten
					WHEN receiving_st =>
					
						IF(samplerate = '1') THEN
						
							--! Abpassen des richtigen Zeitpunktes
							CASE receivePos_v IS
								WHEN 8		=> NULL; -- mitte Startbit
								WHEN 24		=> data_s(0) <=  uart_rx; -- mitte erstes Datenbit
								WHEN 40		=> data_s(1) <=  uart_rx; -- mitte zweites Datenbit
								WHEN 56		=> data_s(2) <=  uart_rx; -- mitte drittes Datenbit
								WHEN 72		=> data_s(3) <=  uart_rx; -- mitte viertes Datenbit
								WHEN 88		=> data_s(4) <=  uart_rx; -- mitte fuenftes Datenbit
								WHEN 104	=> data_s(5) <=  uart_rx; -- mitte sechstes Datenbit
								WHEN 120	=> data_s(6) <=  uart_rx; -- mitte siebtes Datenbit
								WHEN 136	=> data_s(7) <=  uart_rx; -- mitte achtes Datenbit
								WHEN 152	=> NULL;
								WHEN OTHERS =>	NULL;
							END CASE;
						
							--! Inkrement solange die Mitte des Stoppbits nicht erreicht ist
							IF (receivePos_v < 152) THEN
						
									receivePos_v := receivePos_v + 1;
									state_s <= receiving_st;
								
							ELSE
							
								--! Fertig mit detektieren von 8 Datenbits
								receivePos_v := 0; --! von vorne detektieren beim nächsten mal
								rx_byte_buffer <= data_s; --! fertige 8 Datenbits auf den Ausgang legen
								flag_data_byte_ready <= '1'; --! Flag zeigt: bin fertig mit detektieren, ---> ist memory_save in laser_memory.vhd
								state_s <= done_st; --! nächster Status
								
							END IF;
							
						ELSE
							state_s <= receiving_st;

						END IF;
					
					WHEN done_st =>
						
						receivePos_v := 0; --! von vorne detektieren beim nächsten mal
						flag_data_byte_ready <= '0'; --! Flag zeigt: bin nicht fertig mit detektieren
						state_s <= idle_st; --! warten auf daten
					
					--! irgendwas komisches ist passiert
					WHEN OTHERS =>
					
						state_s <= idle_st; ---! biege es wieder gerade
				END CASE; --! Ende State Machine
			END IF;--! Ende synchrones Verhalten	
							
	END PROCESS;--! Ende des Processes
END arch_uart_receive;--! Ende der Architecture