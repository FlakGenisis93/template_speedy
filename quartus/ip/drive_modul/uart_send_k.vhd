--! @file 		uart_send.vhd
--! @brief		Sendemodul fuer eine UART-Kommunikation.
--! @details	In diesem Modul wird ein Vektor in 8N1 Pakete umgewandelt und 
--! 				mit einer bestimmten Baudrate gesendet.
--!				8N1: 1 Startbit, 8 Datenbits, 1 Stopbit = 10Bit
--!				Datenbits: LSB First, MSB Last
--!
--!				WICHTIG: Das Signal wird einfach auf die Leitung gegeben 
--!							ohne das der Zustand der Leitung oder des Empfaengers 
--!							ueberprueft wird.
--!
--! 
--! @author 	BoE. Lt. Kluge Florian
--! @version 	V2.0
--! @date    	27.04.2016
--!
--! @par History:
--! @details	- 	V0.1 	start of development 
--!				18.04.2016 Kluge
--!
--! @details	-	V1.0	Eingabevektor entspricht einem kompletten Befehl.
--!				26.04.2016 Kluge
--!
--! @details	-	V2.0	Hinzufuegen von einem zweiten Eingabevektor damit 
--!							beide Motoren direkt angesprochen werden koennen.
--!				27.04.2016 Kluge
--!
--! @todo		---
--!
--! @bug			---

LIBRARY IEEE;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all; 
use ieee.numeric_std.all;


ENTITY uart_send_k IS -- Sendeeinheit
	PORT(
		reset_n	: IN STD_LOGIC;
		clk	: IN STD_LOGIC;
		send_en		: IN STD_LOGIC := '0';
		send_active	: IN STD_LOGIC := '0';
		send_m1_in		: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		send_m2_in		: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		send_done	: OUT STD_LOGIC := '0';
		send_out	: OUT STD_LOGIC := '0'
	);
END uart_send_k;


ARCHITECTURE arch_uart_send OF uart_send_k IS

TYPE STATE_TYPE IS (idle_st, sending_st, done_st);

SIGNAL state_s				: STATE_TYPE := idle_st;

	BEGIN -- architecture

	PROCESS(reset_n,  clk, send_en, state_s, send_m1_in, send_m2_in) 
	
		--Variablen deklaration
		VARIABLE sendPos_v : INTEGER := 0;
		
			BEGIN-- Process
			
			IF (reset_n = '0') THEN
			
				--Verhalten bei Reset
				send_out <= '1';
				send_done <= '0';
				sendPos_v := 0;


					
				-- synchrones Verhalten
			ELSIF (clk'event and clk = '1') THEN
			
				CASE state_s IS
					WHEN idle_st =>
					
						IF (send_active = '1') THEN
						
							send_out <= '1';
							send_done <= '0';
							sendPos_v := 0;
							state_s <= sending_st;
							
						ELSE
						
							send_out <= '1';
							send_done <= '0';
							state_s <= idle_st;
							
						END IF;
						
					WHEN sending_st =>
					
						send_done <= '0';
						
						IF (send_en = '0') THEN --kommt vom baud_gen modul
							NULL;
						
						ELSE
					
							CASE sendPos_v IS
					
								--erstes Paket m1
								WHEN 0 => send_out <= '0';
								WHEN 1 => send_out <= send_m1_in(24); --LSB
								WHEN 2 => send_out <= send_m1_in(25);
								WHEN 3 => send_out <= send_m1_in(26);
								WHEN 4 => send_out <= send_m1_in(27);
								WHEN 5 => send_out <= send_m1_in(28);
								WHEN 6 => send_out <= send_m1_in(29);
								WHEN 7 => send_out <= send_m1_in(30);
								WHEN 8 => send_out <= send_m1_in(31); --MSB
								WHEN 9 => send_out <= '1';

								--zweites Paket m1
								WHEN 10 => send_out <= '0';
								WHEN 11 => send_out <= send_m1_in(16);
								WHEN 12 => send_out <= send_m1_in(17);
								WHEN 13 => send_out <= send_m1_in(18);
								WHEN 14 => send_out <= send_m1_in(19);
								WHEN 15 => send_out <= send_m1_in(20);
								WHEN 16 => send_out <= send_m1_in(21);
								WHEN 17 => send_out <= send_m1_in(22);
								WHEN 18 => send_out <= send_m1_in(23);
								WHEN 19 => send_out <= '1';

								--drittes Paket m1
								WHEN 20 => send_out <= '0';
								WHEN 21 => send_out <= send_m1_in(8);
								WHEN 22 => send_out <= send_m1_in(9);
								WHEN 23 => send_out <= send_m1_in(10);
								WHEN 24 => send_out <= send_m1_in(11);
								WHEN 25 => send_out <= send_m1_in(12);
								WHEN 26 => send_out <= send_m1_in(13);
								WHEN 27 => send_out <= send_m1_in(14);
								WHEN 28 => send_out <= send_m1_in(15);
								WHEN 29 => send_out <= '1';

								--viertes Paket m1
								WHEN 30 => send_out <= '0';
								WHEN 31 => send_out <= send_m1_in(0);
								WHEN 32 => send_out <= send_m1_in(1);
								WHEN 33 => send_out <= send_m1_in(2);
								WHEN 34 => send_out <= send_m1_in(3);
								WHEN 35 => send_out <= send_m1_in(4);
								WHEN 36 => send_out <= send_m1_in(5);
								WHEN 37 => send_out <= send_m1_in(6);
								WHEN 38 => send_out <= send_m1_in(7);
								WHEN 39 => send_out <= '1';           --200 usec
								
								
								
								--erstes Paket m2
								WHEN 40 => send_out <= '0';
								WHEN 41 => send_out <= send_m2_in(24); --LSB
								WHEN 42 => send_out <= send_m2_in(25);
								WHEN 43 => send_out <= send_m2_in(26);
								WHEN 44 => send_out <= send_m2_in(27);
								WHEN 45 => send_out <= send_m2_in(28);
								WHEN 46 => send_out <= send_m2_in(29);
								WHEN 47 => send_out <= send_m2_in(30);
								WHEN 48 => send_out <= send_m2_in(31); --MSB
								WHEN 49 => send_out <= '1';

								--zweites Paket m2
								WHEN 50 => send_out <= '0';
								WHEN 51 => send_out <= send_m2_in(16);
								WHEN 52 => send_out <= send_m2_in(17);
								WHEN 53 => send_out <= send_m2_in(18);
								WHEN 54 => send_out <= send_m2_in(19);
								WHEN 55 => send_out <= send_m2_in(20);
								WHEN 56 => send_out <= send_m2_in(21);
								WHEN 57 => send_out <= send_m2_in(22);
								WHEN 58 => send_out <= send_m2_in(23);
								WHEN 59 => send_out <= '1';

								--drittes Paket m2
								WHEN 60 => send_out <= '0';
								WHEN 61 => send_out <= send_m2_in(8);
								WHEN 62 => send_out <= send_m2_in(9);
								WHEN 63 => send_out <= send_m2_in(10);
								WHEN 64 => send_out <= send_m2_in(11);
								WHEN 65 => send_out <= send_m2_in(12);
								WHEN 66 => send_out <= send_m2_in(13);
								WHEN 67 => send_out <= send_m2_in(14);
								WHEN 68 => send_out <= send_m2_in(15);
								WHEN 69 => send_out <= '1';

								--viertes Paket m2
								WHEN 70 => send_out <= '0';
								WHEN 71 => send_out <= send_m2_in(0);
								WHEN 72 => send_out <= send_m2_in(1);
								WHEN 73 => send_out <= send_m2_in(2);
								WHEN 74 => send_out <= send_m2_in(3);
								WHEN 75 => send_out <= send_m2_in(4);
								WHEN 76 => send_out <= send_m2_in(5);
								WHEN 77 => send_out <= send_m2_in(6);
								WHEN 78 => send_out <= send_m2_in(7);
								WHEN 79 => send_out <= '1';           --400 usec

								WHEN OTHERS => send_out <= '1';
								
							END CASE;
							
							IF (sendPos_v <= 78) THEN
							
								sendPos_v := sendPos_v + 1;
							ELSE

								sendPos_v := 0;
								state_s <= done_st; 
							END IF;
						END IF;
						
					WHEN done_st =>
					
						sendPos_v := 0;
						send_done <= '1';
						state_s <= idle_st;
						
					WHEN OTHERS =>
					
						state_s <= idle_st;
						
				END CASE;
			END IF;	

			
	END PROCESS;-- Ende des Processes
END arch_uart_send;-- Ende der Architecture