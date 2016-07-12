--! @file		modul_laser.vhd
--! @brief		Interfacekomponente für den Laser Moduls HOKUYO URG 04LX
--! @details
--! Zur Einbindung in das nios_interface_laser.vhd\n\n
--!
--! <b>Wesentliche Funktionen</b>
--!		-	Einfaches einbinden des Lasers
--!
--! <b>Grundsätzlicher Ablauf</b>
--!		-	Die Komponenten werden Automatisch eingebunden und sind direkt gemappt
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
--!		-	command_addr:
--!			#	Nummer des zu sendenen Befehls näheres siehe send_cmd.vhd
--!
--!		-	rx:
--!			#	Empfangsleitung für Laserdaten
--!
--!		-	tx:
--!			#	Sendeleitung für Lasebefehle
--!
--!		-	on_n:
--!			#	Einschalten des Lasers
--!
--!		-	memory_addr:
--!			#	Leseadresse im Speicher
--!
--!		-	flag_memory_init_n:
--!			#	Flag zum Initialisieren des Speichers
--!
--!		-	char_on_addr:
--!			#	Buchstabe im Speicher an der Stelle 'memory_addr'
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
-- USE IEEE.STD_LOGIC_unsigned.ALL;  -- für conv functions erforderlich+


-- --! Use Standard Logic Signed Library
--USE IEEE.STD_LOGIC_signed.ALL;  -- alternativ zur unsigned-Lib...

--! Use Numeric Library
USE IEEE.NUMERIC_STD.ALL;

--LIBRARY modelsim_lib;
--use modelsim_lib.util.all;

--! @ingroup VHDL
--! @brief Modul fuer die kommunikation mnit dem Laser ?!?!?! MODEL: BLABLABLA

ENTITY modul_laser IS

	--! Vorteiler fuer Baudratengenerator um zum Richtigen Zeitpunkt zu Sampeln und UART-Bits zu setzen
	GENERIC (LASER_BAUD_g : INTEGER := 2604;
			LASER_RAM_DEPTH_g	:	INTEGER := 2048);
	
	--! Ports des Moduls Beschreibung siehe oben unter "Hinweis zu Parametern"
	PORT(
		command_addr	: IN STD_LOGIC_VECTOR (7 DOWNTO 0); -- Stelle im Befehlsarray
		rx				: IN STD_LOGIC; -- Sendebitstrom
		tx				: OUT STD_LOGIC; -- Empfangsbitstrom
		on_n			: OUT STD_LOGIC; -- Zum Einschalten des Laser
		
		--! Speicher
		memory_addr		: IN  INTEGER;--! Speicheraddresse
		flag_memory_init_n	: IN STD_LOGIC; --! Flag zum initialisieren des Speichers
		--! Daten im Speicher an Addresse
		char_on_addr	: OUT CHARACTER;
		
		clr_n			: IN STD_LOGIC; -- Clear
		clk				: IN STD_LOGIC -- Clock
		);
END ENTITY;

--! @brief	Architecture Interfacekomponente zur Realisierung eines UART
ARCHITECTURE arch_modul_laser OF modul_laser IS

COMPONENT modul_uart IS -- UART MODUL

	--! Vorteiler fuer Baudratengenerator um zum Richtigen Zeitpunkt zuz Sampeln und UART-Bits zu setzen
	GENERIC(UART_BAUD_g : INTEGER :=2**7);
	
	--! Ports des Moduls Beschreibung siehe modul_uart.vhd
	PORT(
		clr_n					: IN STD_LOGIC; -- Clear
		clk						: IN STD_LOGIC; -- Clock
		flag_start_sending		: IN STD_LOGIC := '0'; -- Los senden
		tx_byte_buffer			: IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Sendedaten
		rx						: IN STD_LOGIC; -- Empfangsbitstrom
		flag_sending_done		: OUT STD_LOGIC := '0'; -- Sendevorgang fertig
		tx						: OUT STD_LOGIC := '0'; -- Sendebitstrom
		flag_data_byte_ready	: OUT STD_LOGIC := '0'; -- Fertig mit Empfangen
		rx_byte_buffer			: OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000" -- Empfangsdaten
	);
END COMPONENT;

COMPONENT send_cmd IS -- Befehlseinheit
	PORT(
		clr_n	: IN STD_LOGIC; -- Clock
		clk		: IN STD_LOGIC; -- Clear_n
		flag_sending_done		: IN STD_LOGIC; -- Acknowledge wird mit send_done  von uart_send verbunden
		command_addr	: IN UNSIGNED(7 DOWNTO 0); -- Nummer des befehls der gesendet werden soll
		flag_start_sending		: OUT STD_LOGIC; -- ClearToSend wird mit send_active von uart_send verbunden
		tx_byte_buffer	: OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0) -- Datenbits wird mit send_in von uart_send verbunden
	);
END COMPONENT;

COMPONENT laser_memory IS --! Antwort vom Sensor speichern
	generic(MEMORY_RAM_DEPTH_g: INTEGER := 2048);
	PORT(
	
		flag_data_byte_ready			: IN STD_LOGIC; --! Enable Signal zum Speichern der Daten von cmd
		rx_byte_buffer			: IN STD_LOGIC_VECTOR ( 7 DOWNTO 0); --! Datenbits die zu speichern sind.
		flag_memory_init_n		: IN STD_LOGIC; --! Signal das den Speicher in einen defginierten zustand ueberfuehren soll
		
		memory_addr			: IN INTEGER; -- Stelle im Speicher aus der gelesen werden soll
		char_on_addr			: OUT CHARACTER; -- Buchstabe der in der Zeile/Spalte steht die gelesen werden soll
		
		--! Standard Signale
		clr_n	: IN STD_LOGIC; --! Clock
		clk		: IN STD_LOGIC --! Clear_n
	);
END COMPONENT;


-- TESTSIGNALE

-- Signale vom Baudratengenerator
-- Enable zum Abtasten
SIGNAL	wire_sampleraterate	: STD_LOGIC := '0';
-- Enable zum Senden
SIGNAL	wire_baudrate	: STD_LOGIC := '0';

-- Signal an send_cmd
-- Flag Character wurde gesendet
SIGNAL	wire_flag_sending_done		: STD_LOGIC := '0';

-- Signal aus snd_cmd
-- Character des Befehls der auf den Ether soll
SIGNAL	wire_tx_byte_buffer	: STD_LOGIC_VECTOR (7 DOWNTO 0) := "00000000";
-- Flag clear to send
SIGNAL	wire_start_sending		: STD_LOGIC := '0';

-- Signal aus uart_receive
-- erkannter Character
SIGNAL wire_rx_byte_buffer			: STD_LOGIC_VECTOR (7 DOWNTO 0) := "00000000"; 
-- Flag speichern
SIGNAL wire_flag_data_byte_ready			: STD_LOGIC := '0';





	BEGIN -- ARCHITECTURE
		
		--! @brief		Interfacekomponente zur Realisierung eines UART
		inst_modul_uart : modul_uart
		GENERIC MAP(UART_BAUD_g => LASER_BAUD_g)
		PORT MAP(
			clr_n					=> clr_n, -- Clear
			clk						=> clk, -- Clock
			flag_start_sending		=> wire_start_sending, -- Los senden
			tx_byte_buffer			=> wire_tx_byte_buffer, -- Sendedaten
			rx						=> rx, -- Empfangsbitstrom
			flag_sending_done		=> wire_flag_sending_done, -- Sendevorgang fertig
			tx						=> tx, -- Sendebitstrom
			flag_data_byte_ready	=> wire_flag_data_byte_ready, -- Fertig mit Empfangen
			rx_byte_buffer			=> wire_rx_byte_buffer -- Empfangsdaten
				);

		--! @brief		Befehlsverwaltung für den Laser
		inst_send_cmd : send_cmd
		PORT MAP(
			clr_n	=> clr_n, -- Clear
			clk		=> clk, -- Clock
			flag_sending_done		=> wire_flag_sending_done, -- Sendevorgang fertig
			command_addr	=> unsigned(command_addr), -- Befehlsnummer
			flag_start_sending		=> wire_start_sending, -- Clear to Send
			tx_byte_buffer	=> wire_tx_byte_buffer -- Sendedatenbits
				);
				
		--! @brief		Daten vom Laser empfangen und speichern
		inst_laser_memory : laser_memory
		GENERIC MAP(MEMORY_RAM_DEPTH_g => LASER_RAM_DEPTH_g)
		PORT MAP(
			flag_data_byte_ready			=> wire_flag_data_byte_ready, --! Enable Signal zum Speichern der Daten von cmd
			rx_byte_buffer			=> wire_rx_byte_buffer, --! Datenbits die zu speichern sind.
			flag_memory_init_n		=> flag_memory_init_n, --! Signal das den Speicher in einen defginierten zustand ueberfuehren soll			

			memory_addr			=> memory_addr, -- Zeile aus der gelesen werden soll
			char_on_addr			=> char_on_addr, -- Buchstabe der in der Zeile/Spalte steht die gelesen werden soll
		
			--! Standard Signale
			clr_n		=> clr_n, --! Clock
			clk			=> clk --! Clear_n
				);
				
			on_n	<= '0'; -- Zum Einschalten des Laser						
END arch_modul_laser; -- ENDE ARCHITECTURE arch_laser