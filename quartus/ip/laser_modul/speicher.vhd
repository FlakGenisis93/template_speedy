
--!!!!!! TUE DIR SELBER EIN GEFALLEN UND AENDERE HIER NICHTS !!!!!!
--! Eigene Bibliothek fuer RAM
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
PACKAGE ram_package IS
	CONSTANT ram_width : INTEGER := 8;
	CONSTANT ram_depth : INTEGER := 2048;
	
	TYPE ram IS ARRAY(0 to ram_depth-1) of character;
	SUBTYPE address_vector IS INTEGER RANGE 0 to ram_depth-1;
END ram_package;

LIBRARY IEEE;
USE ieee.std_logic_1164.all;
--Bibliothek fuer Speicher
USE work.ram_package.ALL;
ENTITY speicher IS
	PORT(
		clock_w			:	IN std_logic;
		clock_r			:	IN std_logic;
		data			:	IN CHARACTER;
		write_address	:	IN address_vector;
		read_address	:	IN address_vector;
		we				:	IN std_logic;
		q				:	OUT CHARACTER
		);
END speicher;

ARCHITECTURE rtl OF speicher IS
		SIGNAL ram_block	:	RAM;
	BEGIN
		PROCESS(clock_w)
		BEGIN			
			IF (rising_edge(clock_w)) THEN
			
				IF (we = '1') THEN
					ram_block(write_address) <= data;
				ELSE
					--q <= ram_block(read_address);
					NULL;
				END IF;	
			ELSE
				NULL;
			END IF;
		END PROCESS;
		
		
		
		PROCESS(clock_r)
		BEGIN
			IF (rising_edge(clock_r)) THEN
				q <= ram_block(read_address);
			ELSE
				NULL;
			END IF;
		END PROCESS;
END rtl;		