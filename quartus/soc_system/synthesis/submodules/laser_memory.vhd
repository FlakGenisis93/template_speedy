--! @file		laser_memory.vhd
--! @brief		Daten vom Laser empfangen und speichern
--! @details
--! Daten vom Lasersensor werden empfangen aufbereitet und in einem zweidimensionalem Array gespeichert
--!
--! <b>Wesentliche Funktionen</b>
--!		-	Der vom UART-Modul empfangende Character wird an die richtige Stelle im Speicher abgelegt.
--!		-	Initialisieren des Speichers
--!		-	Lesen des Speichers
--!
--! <b>Grundsätzlicher Ablauf</b>
--!		-	In einer State Machine wird die Organisation des Speichers für den Laser durchgeführt.
--!		-	Ursprungsstate ist der 'idle_st' in diesem wird geprüft ob gespeichert oder initialisiert werden soll.
--!		-	Soll gespeichert weden...
--!			#	...dann wird der Inhalt von 'rx_byte_buffer' erst in die Variable 'buffer_v' gespeichert
--!				um dann in das Signal 'charBuffer_s' überführt zu werden.
--!			#	Der zwischen Schritt ist notwendig, da 'rx_byte_buffer'
--!				ein STD_LOGIV_VECTOR ist und im Speicher aber ein CHARACTER gespeichert werden soll. VHDL kann aber nur
--!				Integer in Character wandeln deshalb der Zwischenschritt über die Variable 'buffer_v'.
--!			#	im Anschluss wird in den State 'save_st' gewechselt.
--!		-	Soll initialisiert werden...
--!			#	...dann wird die Laufvariable zurückgesetzt und in den State 'init_st' gewechselt
--!		-	Im 'save_st' wird der in halt des Signals 'charBuffer_s' in den Speicher geschreiben.
--!		-	Hierzu wird die Laufvariable gesetzt und als Adresse im Speicher übernommen, die
--!			Daten werden auf 'rx_byte_buffer' geschrieben und das Schreibzugriffsflag wird gesetzt.
--!			Direkt nach dem Speichern geht die State Machine wieder in den 'idle_st' State und
--!			löscht das Schreibzugriffsflag
--!		-	Um den Speicher in einen definierten Zustand zu versetzen gibt es den 'init_st'
--!			hier werden alle Positionen im Speicher mit einem definierten Wert beschreiben.
--!			Dazu wird die Adresse des Speichers gesetzt der Datenausgang belegt und das
--!			Schreibzugriffsflag 'schreibFlag_s' gesetzt.
--!			Dies geschiet solange bis der Speicher einmal durchlaufen wurde. Wenn der Speicher dann
--!			mit dem Wert befüllt ist wechselt die State Machine in den State 'idle_st'.
--!
--! @endverbatim
--!
--!
--! @note
--! <b>Hinweis zu Parametern</b>
--!		-	clr_n:
--!			#	gewöhnliches Clear Signal
--!				Alle Variablen, Signals und Ausgange werden in einen definierten Zustand versetzt.
--!
--!		-	clk:
--!			#	gewöhnliches Systemclocksignal
--!
--!		-	flag_data_byte_ready:
--!			#	Flag welches signalisiert, dass die jetzt anliegenden Daten gespeichert werden sollen.
--!
--!		-	rx_byte_buffer:
--!			#	Datenbits die gespeichert werden sollen
--!
--!		-	flag_memory_init_n:
--!			#	Flag welches signalisiert, dass der Speicher initialisiert werden soll.
--!
--!		-	memory_addr:
--!			#	Adresse im Speicher die gelesen werden soll
--!
--!		-	char_on_addr:
--!			#	Buchstabe der an der Stelle 'memory_addr' im Speicher steht
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

--! Use Standard Logic Unsigned Library
USE IEEE.STD_LOGIC_unsigned.ALL;  -- für conv functions erforderlich

-- --! Use Standard Logic Signed Library
--USE IEEE.STD_LOGIC_signed.ALL;  -- alternativ zur unsigned-Lib...

--! Use Numeric Library
USE ieee.numeric_std.ALL;

--LIBRARY modelsim_lib;
--use modelsim_lib.util.all;

USE work.ram_package.ALL;
--! @ingroup VHDL

--! @brief		Daten vom Laser empfangen und speichern
ENTITY laser_memory IS --! Antwort vom Sensor speichern
	generic(MEMORY_RAM_DEPTH_g: INTEGER := 2048);
	PORT(
	
		flag_data_byte_ready	: IN STD_LOGIC; --! Enable Signal zum Speichern der Daten von cmd
		rx_byte_buffer			: IN STD_LOGIC_VECTOR ( 7 DOWNTO 0); --! Datenbits die zu speichern sind.
		flag_memory_init_n		: IN STD_LOGIC := '1'; --! Flag zum Initialisieren des Speichers
		
		memory_addr				: IN INTEGER; -- Stelle im Speicher aus der gelesen werden soll
		char_on_addr			: OUT CHARACTER; -- Buchstabe der in der Zeile/Spalte steht die gelesen werden soll
		
		--! Standard Signale
		clr_n	: IN STD_LOGIC; --! System-Clock 50MHz
		clk		: IN STD_LOGIC --! System-Reset
	);
END laser_memory;


ARCHITECTURE arch_laser_memory OF laser_memory IS


--! Typen definieren
TYPE STATE_TYPE IS (idle_st, save_st, init_st);

--! Signals deklarieren
SIGNAL state_s		: STATE_TYPE := idle_st;--! State für State Machine
SIGNAL charBuffer_s	: CHARACTER := '0'; --! Buffer für den zu speichernden Character

--! Speicherorganisation
SIGNAL schreibFlag_s	: STD_LOGIC := '0'; -- regelt Lese- oder Schreibzugriff auf den Speicher
SIGNAL write_addr_s		: INTEGER := 0; -- Schreibadresse
SIGNAL memory_data_s 			: CHARACTER := '0';

COMPONENT speicher IS
	PORT(
		clock_w			:	IN STD_LOGIC;
		clock_r			:	IN STD_LOGIC;
		data			:	IN CHARACTER;
		write_address	:	IN address_vector;
		read_address	:	IN address_vector;
		we				:	IN STD_LOGIC;
		q				:	OUT CHARACTER
		);
END COMPONENT;

	BEGIN --! architecture
	
	inst_speicher : speicher
		PORT MAP(
			q				=> char_on_addr, 
			we				=> schreibFlag_s, 
		
			--! Speicheraddressen
			read_address	=> memory_addr,
			write_address	=> write_addr_s,
			
			data			=> memory_data_s,
			clock_r			=> clk,
			clock_w			=> clk
				);
	

	PROCESS(clr_n, clk, state_s, flag_memory_init_n, flag_data_byte_ready, rx_byte_buffer)
	
		--! Variablen deklaration
		CONSTANT charLF_c 		: CHARACTER	:= CHARACTER'val(10); --! Vergleichscharacter entspricht 'LineFeed'
		VARIABLE memPos_v		: INTEGER RANGE 0 TO MEMORY_RAM_DEPTH_g := 0; --! Laufvariable
		VARIABLE buffer_v	: INTEGER := 0; --! Buffervariable
		
		
		
		
			BEGIN --! Process
				
				 --! Beginn asynchrones Verhalten
				 IF (clr_n = '0') THEN
				
					--!Verhalten bei Reset
					charBuffer_s <= '0';
					write_addr_s <= 0;
					memory_data_s <= '0';
					memPos_v := 0;					
					schreibFlag_s <= '0';	
					state_s <= init_st;	
					
				--! Ende asynchrones Verhalten	
				--! Begin synchrones Verhalten
				ELSIF (rising_edge(clk)) THEN
					
					CASE state_s IS --! Anfang Statemaschine
					
						WHEN idle_st => --! Warten auf Daten
							
							--! Nur Lesezugriff auf Speicher
							schreibFlag_s <= '0';
							
							IF (flag_data_byte_ready = '1') THEN --! Es soll gespeichert werden	????????kommt vom UART							
								--! Daten muessen gespeichert werden
								charBuffer_s <= character'val(to_integer(unsigned(rx_byte_buffer))); --! Zwischenspeichern des Anliegenden Vectors als Integer
								--! Wechseln des States
								state_s <= save_st;
								
							ELSIF(flag_memory_init_n = '0') THEN --! Der Speicher soll initialisiert werden
								buffer_v := 48;
								memPos_v := 0; --! Speicheradresse auf erste Stelle setzen
								state_s <= init_st; --! State wechsel
								
							ELSE
								--! Daten sind noch nicht vollständig
								--!	W	A	R	T	E	N
								--state_s <= idle_st;
								NULL;
								
							END IF;
						
							
						WHEN save_st => --! Daten zum Speichern liegen an und muessen ins Array geschrieben werden

													
							memory_data_s <= charBuffer_s; --! Daten an den Eingang des Speichers legen
							write_addr_s <= memPos_v;--! Position setzen
							schreibFlag_s <= '1'; --! Schreiben aktivieren	
							
							IF (memPos_v < (MEMORY_RAM_DEPTH_g-1)) THEN --! Solange das Ende des Speichers nicht erreicht ist
								memPos_v := memPos_v + 1;
							ELSE
								memPos_v := 0; --! Ende des Speichers wurde erreicht.
							END IF;
							
							state_s <= idle_st; --! Auf neue Daten warten
							
						WHEN init_st =>
						
							write_addr_s <= memPos_v;--! Position setzen
							memory_data_s <= character'val(buffer_v); --! Daten an den Eingang des Speichers legen
							schreibFlag_s <= '1'; --! Schreiben aktivieren
							
							IF (buffer_v < 57) THEN  --! Solange das Ende des Speichers nicht erreicht ist
								buffer_v := buffer_v + 1;
							ELSE --! Ende des Specihers wurde erreicht.
								buffer_v := 48;
							END IF;
							
							IF (memPos_v < (MEMORY_RAM_DEPTH_g-1)) THEN  --! Solange das Ende des Speichers nicht erreicht ist
								memPos_v := memPos_v + 1;
							ELSE --! Ende des Specihers wurde erreicht.
								memPos_v := 0;
								state_s <= idle_st; --! State wechseln
							END IF;
							
						WHEN OTHERS => --! irgendwo war ein Fehler
							schreibFlag_s <= '0';
							state_s <= idle_st; --! zurueck in definierten Zustand
							
					END CASE; --! Ende Statemaschine
					
				END IF; --! Ende synchrones Verhalten
	END PROCESS; --! Ende des Processes
	
END arch_laser_memory; --! Ende der Architecture