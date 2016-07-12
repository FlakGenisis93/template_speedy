--! @file		modul_uart.vhd
--! @brief		Interfacekomponente zur Realisierung eines UART
--!
--! <b>Wesentliche Funktionen</b>
--!		-	Nachbildung eines UART
--!		-	Sende- und Empfangsmodul
--!		-	Senden von 8 Datenbits
--!		-	Rückgabe von 8 empfangenden Datenbits
--!
--! <b>Grundsätzlicher Ablauf</b>
--!
--!	#	Sendevorgang:
--!		-	An den "tx_byte_buffer" werden die zu sendenen Datenbits angelegt.
--!		-	Mit kurzzeitigem setzen des "flag_start_sending" wird ein Sendevorgang Initialisiert.
--!		-	Wenn des "flag_sending_done" '1' wird dann ist der Sendevorgang beendet, die Datenbits koennen
--!   		neu gesetzt werden und mit einem erneuten Puls auf "flag_start_sending" ein neuer
--!   		Sendevorgang gestartet werden.
--!
--!	#	Empfangsvorgang:
--!		-	Wenn "flag_data_byte_ready" '1' dann wurden 8 Datenbits erkannt und koennen an
--!   		"rx_byte_buffer" ausgelesen werden.
--!
--!
--! @note
--! <b>Hinweis zu Parametern</b>
--!
--!		-	clr_n:
--!			#	Externes Signal zum zuruecksetzen bei Fehlfunktion in einen definierten Zustand
--!			#	Zaehler des Baudratengenerators wird zurueckgesetzt und
--!			#	Ausgangssignale auf den Pegel '0' gesetzt.
--!			#	Die Sendeeinheit setzt den Ausgang auf '1' und das flag_sending_done auf '0',
--!			#	die Sendeposition wird auch auf 0 gesetzt.
--!			#	Die Empfangseinheit setzt den Ausgang auf "00000000", das "flag_data_byte_ready" auf '0',
--!			#	die Empfangsposition auf 0 und das interne receive_flag auf '0'. 
--!
--!		-	clk:
--!			#	Externe Clock die vom Baudgenerator runtergeteilt wird um die Baudrate einzuhalten und
--!				zum richtigen Moment zu Sampeln. Externe Clock sollte >> Baudrate sein.
--!
--!		-	flag_start_sending:
--!			#	Flag zum Aktivieren des Sendevorgangs auf '1' setzen. Das Flag sollte kürzer '1' sein
--!				als der Sendevorgang dauert, da sonst die datenbits mehrmals gesendet werden.
--!
--!		-	tx_byte_buffer:
--!			#	Hier sind die zu sendenen Datenbits anzulegen.
--!				Die Datenbits werden in der Reihenfolge LSB- First gemaess ...
--!			
--!					tx_byte_buffer(0)
--!					tx_byte_buffer(1)
--!					tx_byte_buffer(2)
--!					tx_byte_buffer(3)
--!					tx_byte_buffer(4)
--!					tx_byte_buffer(5)
--!					tx_byte_buffer(6)
--!					tx_byte_buffer(7)
--!
--!				...gesendet.
--!
--!	!!NOTE!!	Zwischen "flag_start_sending" = '1' und "flag_sending_done" = '1' darf
--!				"tx_byte_buffer" nicht verändert werden.
--!
--!		-	tx:
--!			#	Bitstrom der Datenbits von "tx_byte_buffer".
--!
--!		-	flag_sending_done:
--!			#	Das "flag_sending_done" wird '1' wenn der Sendevorgang abgeschlossen ist.
--!	!!NOTE!!	Das Flag ist nur eine Clock lang '1'!!!
--!
--!		-	rx:
--!			#	Empfangsleitung
--!
--!		-	flag_data_byte_ready:
--!			#	Wird eine Clock lang '1' wenn 8 Datenbits detektiert wurden.
--!	!!NOTE!!	Das Flag ist nur eine Clock lang '1'!!!
--!
--!		-	rx_byte_buffer:
--!			#	Nachdem das "flag_data_byte_ready"='1' war koennen die empfangenden Datenbits ausgelesen werden.
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
USE IEEE.STD_LOGIC_unsigned.ALL;  -- für conv functions erforderlich

-- --! Use Standard Logic Signed Library
--USE IEEE.STD_LOGIC_signed.ALL;  -- alternativ zur unsigned-Lib...

--! Use Numeric Library
USE IEEE.NUMERIC_STD.ALL;

--LIBRARY modelsim_lib;
--use modelsim_lib.util.all;

--! @ingroup VHDL
--! @brief		Interfacekomponente zur Realisierung eines UART
ENTITY modul_uart IS -- UART MODUL

	--! Vorteiler fuer Baudratengenerator um zum Richtigen Zeitpunkt zu Sampeln und UART-Bits zu setzen
	GENERIC(UART_BAUD_g : INTEGER :=2**7);
	
	--! Ports des Moduls Beschreibung siehe oben unter "Hinweis zu Parametern"
	PORT(
		clr_n					: IN STD_LOGIC; --! System-Reset
		clk						: IN STD_LOGIC; --! System-Clock
		flag_start_sending		: IN STD_LOGIC := '0'; --! Los senden
		tx_byte_buffer			: IN STD_LOGIC_VECTOR(7 DOWNTO 0); --! Sendedaten
		rx						: IN STD_LOGIC; --! Empfangsleitung
		flag_sending_done		: OUT STD_LOGIC := '0'; --! Sendevorgang fertig
		tx						: OUT STD_LOGIC := '0'; --! Sendeleitung
		flag_data_byte_ready	: OUT STD_LOGIC := '0'; --! Fertig mit Empfangen
		rx_byte_buffer			: OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000" -- Empfangsdaten
	);
END modul_uart;

--! @brief	Architecture Interfacekomponente zur Realisierung eines UART
ARCHITECTURE arch_modul_uart OF modul_uart IS

--! @brief		Sendeeinheit des UART-Moduls
COMPONENT uart_send IS -- Sendeeinheit
	PORT(
		clr_n				: IN STD_LOGIC; --! System-Reset
		clk					: IN STD_LOGIC; --! System-Clock 50MHz
		baudrate			: IN STD_LOGIC := '0'; --! Bausdrate
		flag_start_sending	: IN STD_LOGIC := '0'; --! Flag: "LOS!"
		tx_byte_buffer			: IN STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000"; --! Datenbits welche gesendet werden sollen
		flag_sending_done	: OUT STD_LOGIC := '0'; --! Flag: "fertig mit senden"
		uart_tx				: OUT STD_LOGIC := '0' --! serielle Daten
	);
END COMPONENT;

--! @brief		Empfangseinheit des UART-Moduls
COMPONENT uart_receive IS -- Empfangseinheit
	PORT(
		clr_n					: IN STD_LOGIC; --! System-Reset
		clk						: IN STD_LOGIC; --! System-Clock 50MHz
		samplerate				: IN STD_LOGIC := '0'; --! runtergeteilte Clock
		uart_rx					: IN STD_LOGIC; --! UART-Empfangsleitung
		flag_data_byte_ready	: OUT STD_LOGIC := '0'; --! Flag, welches zeigt das ein Detektiervorgang abgeschlossen ist
		rx_byte_buffer			: OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000" --! fertig detektierte Datenbits
	);
END COMPONENT;

--! @brief		Baudratengenerator
COMPONENT baud_gen IS -- Baudrate erzeugen
	GENERIC (BAUD_g : INTEGER := 128);
	PORT(
		clr_n		: IN STD_LOGIC; --! System-Reset
		clk			: IN STD_LOGIC; --! System-Clock 50MHz
		baudrate	: OUT STD_LOGIC; --! Baudrate
		samplerate	: OUT STD_LOGIC --! Abtastrate
	);
END COMPONENT;

SIGNAL wire_samplerate : STD_LOGIC := '0'; --! Abtastrate
SIGNAL wire_baudrate : STD_LOGIC := '0'; --! Baudrate

	BEGIN
	
		inst_baud_gen : baud_gen
		GENERIC MAP(BAUD_g => UART_BAUD_g)
		PORT MAP(
			clr_n		=> clr_n,
			clk			=> clk,
			baudrate	=> wire_baudrate,
			samplerate	=> wire_samplerate
				);
				
		inst_uart_send : uart_send
		PORT MAP(
			clr_n				=> clr_n,
			clk					=> clk,
			baudrate			=> wire_baudrate,
			flag_start_sending	=> flag_start_sending,
			tx_byte_buffer		=> tx_byte_buffer,
			flag_sending_done	=> flag_sending_done,
			uart_tx				=> tx
				);
				
		inst_uart_receive : uart_receive
		PORT MAP(
			clr_n	=> clr_n,
			clk		=> clk,
			samplerate	=> wire_samplerate,
			uart_rx		=> rx,
			flag_data_byte_ready	=> flag_data_byte_ready,
			rx_byte_buffer		=> rx_byte_buffer
				);
				
END arch_modul_uart;--! Ende der Architecture
		