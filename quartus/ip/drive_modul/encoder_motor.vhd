--! @file 	encoder_motor.vhd
--! @brief	Encoder Modul fuer die Motoren.
--! @details	In diesem Modul werden die beiden Encoder ausgewertet und das Ergebnis
--!		in ein Register geschrieben. 
--! 		Zusaetzlich wird das Jitter abgefangen um genauer zu messen. 
--!		Eine Auswertung der Werte erfolgt hier nicht. 
--!		Rueckgabewerte sind:	- Geschwinsigkeit(pro bestimmte Zeit)
--!									- Distanz(abhaengig von der max zurueckgelegten Entfernung hier: 20bit) 
--! 		
--!
--! 
--! @author 	BoE. Lt. Kluge Florian
--! @version 	V2.1
--! @date    	14.04.2016
--!
--! @par History:
--! @details	- 	V0.1 	start of development 
--!				05.04.2015 Kluge
--!
--! @details	-	V0.5	Status LED wurde implementiert und zeigt was fuer eine Aktion gerade ausgefuehrt wird.
--!				07.04.2015 Kluge
--!
--! @details	-	V1.0	Ein Encoder wird nun vollstaendig abgetastet um Informationen zur Geschwinsigkeit und Distanz zu bekommen.
--!				Da die Befehle parallel laufen wird nur einer ausgewertet.
--!				10.05.2015 Kluge
--!
--! @details	-	V2.0	Beide Encoder werden ausgewertet fuer jeweils Geschwinsigkeit(pro bestimmter Zeitintervall) und
--!				Distanz. Distanz-Ticks werden vollstaendig erfasst (20bit), diese Zahl ist abhaenig von der im Befehl
--!				festgelegten max. Distanz. 
--!				14.04.2016 Kluge
--!
--! @details	-	V2.1	Code kommentiert, kleinere optimierungen
--!				20.06.2016 Kluge
--!
--! @todo		---
--!
--! @bug			---

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;


entity encoder_motor is
	port
	(
		reset_n 	            : in  std_logic;
		clk		            : in  std_logic;					
			
		LED_DriveStatus      : out std_logic_vector(1 downto 0);                     -- export
		
		Encoder1_DriveSystem : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
     	Encoder2_DriveSystem : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export					
		Encoder1_Register     : out std_logic_vector(15 downto 0); 						  --2/14 dir/cnt
		Encoder2_Register     : out std_logic_vector(15 downto 0);
		Encoder1_Full_Register: out std_logic_vector(19 downto 0);
		Encoder2_Full_Register: out std_logic_vector(19 downto 0);
		Encoder1_Full_Register_Enable  : in std_logic;
		Encoder2_Full_Register_Enable  : in std_logic;
		Encoder_New_Command   : in std_logic
		
	);
end encoder_motor;



architecture arch_encoder_motor of encoder_motor is

signal E1_new, E2_new, E1_old, E2_old : std_logic_vector(1 downto 0);                       -- Varaiblen zum Speichern der Zustaende
signal d1, d2 : std_logic;                                                                  -- Siganle der Encoder1/2 fuer die Richtung
signal c1  : std_logic;                                                                     -- Siganle der Encoder1/2 fuer die Erfassung des Stillstandes
signal DIR : std_logic_vector(1 downto 0);																  -- Ablegen der Richtung
signal DIR2 : std_logic_vector(1 downto 0);
signal Encoder1_DriveSystem_FF, Encoder2_DriveSystem_FF : std_logic_vector(1 downto 0);     -- FlipFlop synchrones Signal
signal CNT_value : std_logic_vector(13 downto 0);														  -- Ablegen der Counter-Ticks
signal CNT2_value : std_logic_vector(13 downto 0);
signal aktiv_wire : std_logic;																				  -- Dient zum Zuruecksetzen des Stillstandsprozess
																	  
begin



--FlipFlop zum synchronen Arbeiten

PROCESS (clk)
	BEGIN
		IF clk'EVENT AND clk = '1' THEN 	--ab hier synchron
			Encoder1_DriveSystem_FF <= Encoder1_DriveSystem;
			Encoder2_DriveSystem_FF <= Encoder2_DriveSystem;
		END IF;
		
	END PROCESS;

	
	
--Speicherung der Zustaende in "old" und "in" zum späteren Vergleichen (Encoder1)

process(Encoder1_DriveSystem_FF )
	begin
		if(clk'event and clk = '1')then		
			E1_new  <= Encoder1_DriveSystem_FF;
			if(E1_new /= Encoder1_DriveSystem_FF )then
				E1_old <= E1_new;
			end if;
		end if;
		
	end process;

	
	
--Speicherung der Zustaende in "old" und "in" zum späteren Vergleichen (Encoder2)	
	
process(Encoder2_DriveSystem_FF )
	begin
		if(clk'event and clk = '1')then		
			E2_new  <= Encoder2_DriveSystem_FF;
			if(E2_new /= Encoder2_DriveSystem_FF )then
				E2_old <= E2_new;
			end if;
		end if;
		
	end process;



	
	
-- Decodierung: 
--EXstate bestet aus 4 bit, BBAA, AA ist der alte zustand und BB der neue.
--Die Uebergaenge werden ausgewertet und in var d [1 fuer vor und 0 fuer zurueck] abgelegt.
--Die StandbyX Varaiblen dienen zum Triggern der Uebergaenge.

process(E1_old) --decodieren der Zustaender 
	variable E1state: std_logic_vector(3 downto 0);
	variable aktiv : std_logic; 
	variable standbyA, standbyB : std_logic;

	begin
		E1state := E1_new & E1_old; --erstellen der Uebergaenge
		
		case E1state is
		-- 0 zurueck / 1 vor
			when "0100" => d1 <= '0';
					aktiv := '0'; --dient zur spaeteren Evaluation des aktiv_wire signals
											
			when "1101" => d1 <= '0';
					aktiv := '0';
					standbyA := '1';
						
			when "1011" => d1 <= '0';
					aktiv := '0';
							
			when "0010" => d1 <= '0';
					if(standbyA = '1')then
						aktiv := '1';
						standbyA := '0';
						
					else
						aktiv := '0';
					end if;
					

			when "1110" => d1 <= '1';
					aktiv := '0';
						
			when "0111" => d1 <= '1';
					aktiv := '0';
					standbyB := '1';
							
			when "0001" => d1 <= '1';
					aktiv := '0';
		
			when "1000" => d1 <= '1';
					if(standbyB = '1')then
						aktiv := '1';
						standbyB := '0';
						
					else
						aktiv := '0';
					end if;		
							
			when others => aktiv := '0';		
		end case;
			
		if(aktiv = '1')then
			aktiv_wire <= '1';
			
		else
			aktiv_wire <= '0';
		end if;
		
	end process;

	
	
	
	
-- decodieren der Zustaender von Encoder2 [Speedy: rechts]
-- hier nicht so aufwendig, da es reicht wenn ein Encoder
-- die richtigen Signal gibt.
-- E2 dient somit nur noch zum erkennen von Kurven.

process(E2_old) 
	variable E2state: std_logic_vector(3 downto 0);
	
	begin
		E2state := E2_new & E2_old;  
		case E2state is
		-- 0 zurueck / 1 vor //motor aber gedreht
			when "0100" => d2 <= '0';
			when "1101" => d2 <= '0';
			when "1011" => d2 <= '0';
			when "0010" => d2 <= '0';
	 
			when "1110" => d2 <= '1';
			when "0111" => d2 <= '1';
			when "0001" => d2 <= '1';
			when "1000" => d2 <= '1';
				
			when others => null;
		end case;	
		
	end process;

	
	
	
	
--Erkennung des Stillstandes
--Reaktionszeit 0,1 sek <-- ist einstellbar ueber cnt_max_value
--wird nach 0,1 sek kein neuer Uebergang erkannt so wird der
--Stillstand angenommen und c1 auf '0' gesetzt.
--Setzt den Prozess nach einem Übergang zurueck.

process(clk) 
	variable cnt_max_value: INTEGER := 5000000;
	variable cnt_max:       INTEGER RANGE 0 TO cnt_max_value := 0; -- entspricht 0,1sek bei 50 MHz //(20x10-9)*5000000

	begin
		if(clk'event and clk = '1')then
			if(cnt_max = cnt_max_value)then 
				null;
			else
				cnt_max := cnt_max +1;
			end if;
		end if;
		
		if(aktiv_wire = '1')then
			cnt_max := 0;
		end if;
		
		if(cnt_max = cnt_max_value)then
			c1 <= '0';
		else
		   c1 <= '1';
		end if;
		
	end process;		
	

	
	
	
-- Vergleichen der beiden Variablen dX um die
-- Richtung/Stillstand zu erkennen und das
-- Signal DIR dementsprechend zu beschalten.
	
process(clk) 
	begin
		if( d1 = '0' and d2 = '1' and c1 = '1') then   -- Vor
			LED_DriveStatus <= "01"; --zur Kontrolle
			DIR <= "01";
				
		elsif(d1 = '1' and d2 = '0' and c1 = '1') then -- Zurueck
			LED_DriveStatus <= "10"; --zur Kontrolle
			DIR <= "10";
			
		elsif(d1 = '1' and d2 = '1' and c1 = '1') then -- Kurve
			LED_DriveStatus <= "11"; --zur Kontrolle
			DIR <= "11";
			
	   elsif(d1 = '0' and d2 = '0' and c1 = '1') then -- Kurve
			LED_DriveStatus <= "11"; --zur Kontrolle
			DIR <= "11";
				
		elsif(c1 = '0') then                           -- Stillstand
		   LED_DriveStatus <= "00"; --zur Kontrolle
			DIR <= "00";	
		end if;
		
	end process;
	
	
	
	
	
-- Distanzberechnung und Uebergabe Encoder1

process(clk) 
	variable timer_cnt_max:   INTEGER := 2_500_000; --2500000=0,1sek // 5000=100usek --2_500_000= 50ms
	variable timer_cnt:       INTEGER RANGE 0 TO timer_cnt_max := 0;  -- entspricht 0,1sek bei 50 MHz //(20x10-9)*5000000
	variable cnt : INTEGER RANGE 0 TO 16383 := 0; 						  -- entspricht 14 Bit fuer das Register
	variable transport_cnt : std_logic_vector (13 DOWNTO 0);

	begin
		if(clk'EVENT and clk = '1')then	
			if (timer_cnt < timer_cnt_max )then
				if(E1_new /= Encoder1_DriveSystem_FF)then
					if(cnt = 16383)then
						cnt:= 0;
						
					else 
						cnt := cnt +1;
					end if;		
				end if;
				
				timer_cnt := timer_cnt +1;
				
			else
				transport_cnt := conv_std_logic_vector(cnt, 14);		 -- umwandeln in Bit bzw. std_logic_vector
				CNT_value <= transport_cnt;
				Encoder1_Register <= DIR & CNT_value;
				timer_cnt := 0;
				cnt:= 0;
			end if;	
		end if;
				
	end process;	


-- Distanzberechnung und Uebergabe Encoder2

process(clk) 
	variable timer_cnt_max:   INTEGER := 2_500_000; --5000000=0,1sek // 5000=100usek // 2_500_000 = 50ms
	variable timer_cnt:       INTEGER RANGE 0 TO timer_cnt_max := 0;  -- entspricht 0,1sek bei 50 MHz //(20x10-9)*5000000
	variable cnt : INTEGER RANGE 0 TO 16383 := 0; 						  -- entspricht 14 Bit fuer das Register
	variable transport_cnt : std_logic_vector (13 DOWNTO 0);
	
	begin
		if(clk'EVENT and clk = '1')then
			if (timer_cnt < timer_cnt_max )then
				if(E2_new /= Encoder2_DriveSystem_FF)then
					if(cnt = 16383)then
						cnt:= 0;
						
					else 
						cnt := cnt +1;
					end if;	
				end if;
				
				timer_cnt := timer_cnt +1;
				
			else
				transport_cnt := conv_std_logic_vector(cnt, 14);		 -- umwandeln in Bit bzw. std_logic_vector
				CNT2_value <= transport_cnt;
				Encoder2_Register <= DIR2 & CNT2_value;
				timer_cnt := 0;
				cnt:= 0;
			end if;		
		end if;
				
	end process;	
                         

-- rueckgabe der gesamten strecke 15bit -> 3,276 meter -> 262.400 ticks  ->20 bit 
	process(clk) 

	variable full_cnt1 : integer RANGE 0 TO 262400 := 0;
	variable full_cnt2 : integer RANGE 0 TO 262400 := 0;
	
	begin
		if(clk'EVENT and clk = '1')then
			if Encoder1_Full_Register_Enable = '1' or Encoder2_Full_Register_Enable = '1' then
				if Encoder_New_Command = '1' then
					full_cnt1 := 0;
					full_cnt2 := 0;
					
				else
					if Encoder1_Full_Register_Enable = '1' then
						if(E1_new /= Encoder1_DriveSystem_FF)then
							full_cnt1 := full_cnt1 +1;
						end if;
					end if;
					
					if Encoder2_Full_Register_Enable = '1' then
						if(E2_new /= Encoder2_DriveSystem_FF)then
							full_cnt2 := full_cnt2 +1;
						end if;
					end if;
				end if;
			
				Encoder1_Full_Register <= conv_std_logic_vector(full_cnt1, 20); --umwandeln in std_logic und weiterleitung an aufrufendes level
				Encoder2_Full_Register <= conv_std_logic_vector(full_cnt2, 20);
			end if;		
		end if;
				
	end process;	

                                                                                                                                    
end arch_encoder_motor;