--------------------------------------------------------------------------------
--! Conrad Urban B.Eng.
--! Universitaet der Bundeswehr - Muenchen
--
--! @file dffe.vhd
--! @brief design of an D Flip Flop
--------------------------------------------------------------------------------

--! Use standart library
library IEEE;
--! Use logic elements
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;


ENTITY dflipflop IS

	GENERIC(
		BIT_DATA_POS_g	: INTEGER		:= 	8			--genauigkeit der postion in bits 
	);

	PORT(
		Q		: OUT 	STD_LOGIC_VECTOR (BIT_DATA_POS_g-1 DOWNTO 0);

		D		: IN 	STD_LOGIC_VECTOR (BIT_DATA_POS_g-1 DOWNTO 0);
		ENABLE		: IN 	STD_LOGIC;
		CLK		: IN 	STD_LOGIC;					
		RESET_n		: IN 	STD_LOGIC		
	);
	
END ENTITY;

ARCHITECTURE logic OF dflipflop IS

BEGIN

	PROCESS (CLK, RESET_n)
	BEGIN
		IF (RESET_n = '0') THEN				--asynchroner reset
			Q <= "00";
		ELSIF (CLK 'EVENT AND CLK = '0') THEN

			IF (ENABLE = '1') THEN			--synchrones enable
				Q <= D;
			END IF;

		END IF;

	END PROCESS;

END ARCHITECTURE;
