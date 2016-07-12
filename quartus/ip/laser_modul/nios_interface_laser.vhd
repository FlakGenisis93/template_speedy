--! @file		nios_interface_laser.vhd
--! @brief		SoC/NIOS-Interfacekomponente zur Ansteuerung des Laser Moduls HOKUYO URG 04LX
--! @details
--! Das BLDC-NIOS-Interface wird vom NIOS über einen Registersatz angesteuert und bildet die Schnittstelle zum VHDL-Laser-Modul, das die eigentliche
--! Steuerung des Lasers übernimmt. \n\n
--!
--! <b>Wesentliche Funktionen</b>
--!		-	Nachbildung der UART Schnittstelle
--!		-	Instantiierung des Lasersmoduls
--!		-	Übergabe der Laser-spezifischen Parameter von QSys-Level zum Laser-Modul
--!		-	Rückgabe von Fehlermeldungen an NIOS erfolgt über auslesen der Laser-Antwort
--!
--! <b>Grundsätzlicher Ablauf</b>
--!		-	NIOS schreibt den gewünschten Laser Befehl in den Registersatz
--!		-	NIOS liest zyklisch die entsprechenden Register aus und zeigt die Antworten des Lasers
--!
--! @note
--! <b>Hinweis zu Parametern</b>
--!		-	Die Zuordnung der Hall-Codes zur Phasenansteuerungsfolge wird über Motor-spezifische Parameter festgelegt
--!		-	Im NIOS-System werden die Parameter von QSys-Level zum BLDC-Modul durchgereicht.
--!		-	Um für das Demo-Projekt eine einfachere Auswahl des Motors zu ermöglichen wurden die entsprechenden Parameter bereits in verschiedenen QSys-Files hinterlegt.
--!	  		Auf TopLevel-Ebene muß dann die entsprechende QSys-Toplevel-Komponente einkommentiert werden.
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
--USE IEEE.STD_LOGIC_ARITH.ALL;     -- für conv functions erforderlich

--! Use Standard Logic Unsigned Library
USE IEEE.STD_LOGIC_unsigned.ALL;  -- für conv functions erforderlich

--! Use Standard Logic Signed Library
-- USE IEEE.STD_LOGIC_signed.ALL;  -- alternativ zur unsigned-Lib...

--! Use Numeric Library
USE ieee.numeric_std.ALL;

--LIBRARY modelsim_lib;
--use modelsim_lib.util.all;

--! @ingroup VHDL
--! @brief SoC-/NIOS-Komponente mit NIOS-BLDC-Interface und Parametersatz für Motor (Parameter werden auf SoC-Komponentenlevel gesetzt !!!)
ENTITY nios_interface_laser is
	GENERIC ( -- !!!!!!!!!!!alles in Integer, weil QSys keine std_logic verarbeiten kann bei der Parameterübergabe !!!!!!!!!!!!!!!!!!!!!!
				 -- !!!!!!!!!!!Parameter müssen in der QSys-Component eingestellt werden !!!!!!!!!!!!!!!!!!!!!!!!!!
				 
		BAUD_GEN_PRESCALER_g: integer := 2604;--! Vorteiler fuer Baudratengenerator um zum Richtigen Zeitpunkt zuz Sampeln und UART-Bits zu setzen
		RAM_DEPTH_g : integer := 2048
		);
	PORT(
		-- communication with nios
		ce_n		: in std_logic; --! NIOS chip enable
		read_n		: in std_logic; --! NIOS read
		write_n		: in std_logic; --! NIOS write
		reg_addr	: in std_logic_vector (2 downto 0); --! NIOS address bus for registers
		write_data	: in std_logic_vector (31 downto 0); --! NIOS write bus
		read_data	: out std_logic_vector (31 downto 0); --! NIOS read bus
		--led			: out std_logic_vector(7 downto 0);
		
		--irq:        out std_logic;									--! Interruptleitung zum NIOS (nicht verwendet, bleibt aber drin wegen QSys)

		-- user relevant signals
		rx	: IN STD_LOGIC; --! Bitstrom zum Laser
		tx	: OUT STD_LOGIC; --! Bitstrom vom Laser
		on_n	: OUT STD_LOGIC; --! Einschalt des Lasers

		CLK			: IN STD_LOGIC; --! System-Clock
		RESET_n		: IN STD_LOGIC --! System-Reset
	);
end entity nios_interface_laser;


--! @brief Architecture für nios_interface_bldc_control
architecture arch_nios_interface_laser of nios_interface_laser is

--! NIOS-SIGNALE
--! Editieren mit NIOS um den Befehl an der stelle Number aus dem Array zu senden.
SIGNAL cmd_number_reg_s	: std_logic_vector(7 downto 0);
SIGNAL line_add_reg_s	: INTEGER;
SIGNAL add_reg_s		: INTEGER;
SIGNAL memory_char_s	: CHARACTER;
SIGNAL memory_init_n_s	: STD_LOGIC := '0';


--! @brief Laser-Komponente zur Ansteuerung des Lasers
COMPONENT modul_laser IS

	--! Vorteiler fuer Baudratengenerator um zum Richtigen Zeitpunkt zu Sampeln und UART-Bits zu setzen
	GENERIC (LASER_BAUD_g		: INTEGER := 2604;
			LASER_RAM_DEPTH_g	:	INTEGER := 2048);
	
	--! Ports des Moduls Beschreibung siehe oben unter "Hinweis zu Parametern"
	PORT(
		command_addr		: IN STD_LOGIC_VECTOR (7 DOWNTO 0); -- Befehlsnummer
		rx					: IN STD_LOGIC; -- Sendebitstrom
		tx					: OUT STD_LOGIC; -- Empfangsbitstrom
		on_n				: OUT STD_LOGIC; -- Zum Einschalten des Laser
		
		--! Speicheraddressen
		memory_addr			: IN  INTEGER;
		--! Speicher in defginirten Zustand ueberfuehren
		flag_memory_init_n	: IN STD_LOGIC;
		--! Daten im Speicher an Addresse
		char_on_addr		: OUT CHARACTER;
		
		clr_n				: IN STD_LOGIC; -- Clear
		clk					: IN STD_LOGIC -- Clock
		);
END COMPONENT;




--***********************************************************************************************************************************************
--***********************************************************************************************************************************************
--***********************************************************************************************************************************************
BEGIN	--of architecture ****************************************************

--!!!!!!!!!!!!! Port Mapping einfuegen für die verwendete Komponente "modul_laser"
		inst_laser : modul_laser
		GENERIC MAP(LASER_BAUD_g => BAUD_GEN_PRESCALER_g,
					LASER_RAM_DEPTH_g => RAM_DEPTH_g)
		PORT MAP(
			command_addr		=> cmd_number_reg_s, -- Befehlsnummer
			rx					=> rx, -- Sendebitstrom
			tx					=> tx, -- Empfangsbitstrom
			on_n				=> on_n, -- Zum Einschalten des Laser
		
			--! Speicheraddressen
			memory_addr			=> add_reg_s,
			--! Speicher in defginirten Zustand ueberfuehren
			flag_memory_init_n	=> memory_init_n_s,
			--! Daten im Speicher an Addresse
			char_on_addr		=> memory_char_s,
			
			clr_n				=> RESET_n, -- Clear
			clk					=> CLK -- CLOCK
				);	
		
--! @brief NIOS-Interface SCHREIBEN und und Command-Interpretation
--! @details Wenn ein Register vom NIOS beschrieben wurde, wertet eine statemachine innerhalb des Prozesses die geänderten Bits aus und veranlasst die entsprechende Steuerung.
NIOS_Schreiben: process(RESET_n, CLK, write_n, ce_n, reg_addr, write_data, cmd_number_reg_s)

BEGIN
	if RESET_n = '0' then
	elsif CLK'EVENT and CLK = '1' then					--voller Systemclock !!!!!!
		if (write_n = '0' and ce_n = '0') then			--NIOS writes to interface registers
			case reg_addr is
				when B"000" => 								--schreiben auf das command-register
					cmd_number_reg_s <= write_data(7 DOWNTO 0);

				when B"001" => 								--schreiben der Zeilennummer an der gelesen werden soll.
					add_reg_s <= to_integer(unsigned(write_data));

				when B"010" => 								--schreiben das Speicher mit '0' beschrieben werden soll 
					memory_init_n_s <= write_data(0);

--				when B"011" => 								--
--					

--				when B"100" => 								--
--					

				when others => 
					null;
			end case;	
		end if;													--end: NIOS writes to interface registers
	end if;
end process;

--! @brief NIOS-Interface LESEN
--! @details NIOS liest zyklich die Daten-Register der BLDC-Komponente aus
NIOS_Lesen: process(read_n, ce_n, reg_addr,memory_char_s, cmd_number_reg_s, add_reg_s, memory_init_n_s)
begin
read_data <= (OTHERS => '0');
		if (read_n = '0' and ce_n = '0') then		--NIOS reads from interface registers
			case reg_addr is -- lese Adresse
				when B"000" => 
					read_data(7 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(character'pos(memory_char_s),8));
					
				when B"001" =>
					read_data(7 DOWNTO 0) <= cmd_number_reg_s;
						
				when B"010" => 
					read_data <= STD_LOGIC_VECTOR(to_unsigned(add_reg_s,32));
					
				when B"011" =>
					read_data(0) <= memory_init_n_s;
							
				-- when B"100" => 
						
				-- when B"101" => 
					
				when others => null;
			end case;
		end if;
end process;

end arch_nios_interface_laser;
