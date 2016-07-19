--! @file 		pid_regler_mm.vhd
--! @brief		Zwei regler fuer das Regeln der beiden Montoren des 4WD Roboters Speedy.
--! @details	Die beiden Regler und die dazugehoerigen Werte wurden fuer den Speedy12 entwickelt,
--!				bei einer anderen Verwenung MUESSEN die Reglewerte neu bestimmt werden. Dazu empfiehlt
--!				sich eine Einstellung ueber die Sprungantowrt. Diese ist zwar nicht genau (je nach Aufloesung)
--!				bietet aber schnell ein brauchbares Ergebnis.
--!			
--!				Test zur Verbesserung der Regelparameter zeigten keine positiven Ergebnisse. Weiter Verbesserung der
--! 				Parameter fuer Speedy12 nicht moeglich.
--!
--! 
--! @author 	BoE. Lt. Kluge Florian
--! @version 	V1.0
--! @date    	04.07.2016
--!
--! @par History:
--! @details	- 	V0.1 	start of development 
--!				13.05.2016 Kluge
--!
--! @details	- 	V0.2 	regler rumpf erstellt 
--!				17.05.2016 Kluge
--!
--! @details	- 	V0.3 	regler werte ermittelt und erste test 
--!				19.05.2016 Kluge
--!
--! @details	- 	V0.5 	stabiler regler fuer m1 und m2 impelemntiert 
--!				23.05.2016 Kluge
--!
--! @details	- 	V0.6 	regler synchrone in das projekt aufgenommen, keine verbesserungen der parameter mehr moeglich  
--!				30.05.2016 Kluge
--!
--! @details	- 	V1.0 	final version mit doku  
--!				04.07.2016 Kluge
--!
--!
--! @todo		---
--!
--! @bug			---



library IEEE;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;


entity pid_regler_mm is
	generic(
		REG1_cntBits	: INTEGER := 8;
		REG2_cntBits	: INTEGER := 16;

		CNT_MAX			: INTEGER := 2_500_000 --enspricht bei 50MHZ 50ms // 5_000_000 -> 100ms //100MHz System ->5_000_000 (50ms)

  	  );
 
	port(
		clk				: in std_logic;											-- clock
		reset_n			: in std_logic;											-- reset	

		active_in		: in std_logic;											-- flag
		w1_soll_in		: in std_logic_vector(REG2_cntBits-1 downto 0); -- in ticks/50ms von 
		x1_ist_in		: in std_logic_vector(REG2_cntBits-1 downto 0); -- in ticks/50ms von encoder
		
		w2_soll_in		: in std_logic_vector(REG2_cntBits-1 downto 0); -- in ticks/50ms von c 
		x2_ist_in		: in std_logic_vector(REG2_cntBits-1 downto 0); -- in ticks/50ms von encoder 
		
		y1_out			: out std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0'); -- geschwindigkeits stufen 0-127
		y2_out			: out std_logic_vector(REG1_cntBits-1 downto 0) := (others=>'0'); -- geschwindigkeits stufen 0-127
		
		new_value_m1_out	: out std_logic := '0';								-- flag fuer neuen wert
		new_value_m2_out	: out std_logic := '0'								-- flag fuer neuen wert
  	);
end pid_regler_mm;

architecture arch_pid_regler_mm of pid_regler_mm is

--w als integer um zeit zu sparen
signal w_m1_int		: INTEGER := 0;
signal w_m2_int		: INTEGER := 0;
--grenzen m1
signal w_ug_m1_int	: INTEGER := 0;
signal w_og_m1_int	: INTEGER := 0;
--grenzen m2
signal w_ug_m2_int	: INTEGER := 0;
signal w_og_m2_int	: INTEGER := 0;


begin

--process der den motor1 (links) regelt
	PROCESS(clk, reset_n)
	
	--zaehlvaraiblen
	variable cnt_var					: INTEGER RANGE 0 TO CNT_MAX := 0;	-- zaehl variable
	
	--regler constanten
		--m1															-- Erstellung: (motor1)
		constant kp_m1_con			: INTEGER := 5129;	-- 0,313055602*2^14--5129 (m1)
		constant ki_ta_m1_con		: INTEGER := 3716;	-- ki*ta =3716 (m1)
		constant kd_ta_m1_con		: INTEGER := 1230;	-- kd/ta =1230 (m1)
		
		constant ticks_stufe_con	: INTEGER := 11;		-- teilen um stufe fuer sabertrooth zu erhalten y/11 -> y*1/11 (siehe dok: Stufenvermessung m1 und m2) (m1)
		

	--regler variablen
		--m1
		variable e_m1_var				: INTEGER := 0;		-- e=w-x / w= soll_wert x= ist_wert e= differenz (motor1)
		variable e_alt_m1_var		: INTEGER := 0;		-- e bei T(-1) (m1)
		variable e_m1_sum_var		: INTEGER := 0;		-- summe aller e (m1)
		
		variable y_m1_var				: INTEGER := 0;		-- regel_wert fuer regelstrecke (m1)
		
		variable kp_m1_cal_var		: INTEGER := 0;		-- kp_anteil (m1)
		variable ki_m1_cal_var		: INTEGER := 0;		-- ki_anteil (m1)
		variable kd_m1_cal_var		: INTEGER := 0;		-- kd_anteil (m1)
		
		
	BEGIN
		IF reset_n = '0' THEN
			cnt_var := 0;
			new_value_m1_out <= '0';
			
		ELSIF clk'EVENT AND clk = '1' THEN
		
			IF active_in = '1' THEN --wenn aktiv dann 
			
				IF(cnt_var = CNT_MAX)then --wird alle 50ms ausgefuert (neuer wert vom encoder)		
					
					------m1-------------
					IF (x1_ist_in < w_ug_m1_int or x1_ist_in > w_og_m1_int) THEN
					
						e_m1_var := w_m1_int - (to_integer(unsigned(x1_ist_in(13 downto 0))));	--regeldifferenz -> vergleicher
						e_m1_sum_var := e_m1_sum_var + e_m1_var;											--summe der regeldifferenz -->integration I-teil
						
						kp_m1_cal_var := kp_m1_con*e_m1_var;												--regelgeleichung 1*2^14
						ki_m1_cal_var := ki_ta_m1_con*e_m1_sum_var;										--|					1*2^14
						kd_m1_cal_var := kd_ta_m1_con*(e_m1_var - e_alt_m1_var);						--|					1*2^14
																														--|
						y_m1_var := kp_m1_cal_var + ki_m1_cal_var + kd_m1_cal_var;					--| ergebnis in ticks 2^14+2^14+2^14 = 2^14
						
						y_m1_var := y_m1_var/ticks_stufe_con;												--umwandeln in sabertooth stufen 2^14
						
						e_alt_m1_var := e_m1_var;
						
						y1_out <= std_logic_vector(to_unsigned(y_m1_var,22))(21 downto 14);		--auf den ausgang schieben un um 14 stellen rechts schieben
						
						
						cnt_var := 0;
						new_value_m1_out <= '1';
					
					END IF;

				ELSE
					cnt_var := cnt_var +1;
					new_value_m1_out <= '0';
					
				END IF;

			ELSE 			--kein regler benoetigt alles auf anfang
				cnt_var := 0;
				new_value_m1_out <= '0';
			END IF;
		END IF;
	END PROCESS; 


	
--process der den motor2 (rechts) regelt
	PROCESS(clk, reset_n)
	
	--zaehlvaraiblen
	variable cnt_var					: INTEGER RANGE 0 TO CNT_MAX := 0;	-- zaehl variable
	
	--regler constanten
		--m2															-- Erstellung:
		constant kp_m2_con			: INTEGER := 5129;	-- 5129 (motor2)
		constant ki_ta_m2_con		: INTEGER := 3716;	-- ki*ta = 3716 (m2)
		constant kd_ta_m2_con 		: INTEGER := 1230;	-- kd/ta = 1230 (m2)
		
		constant ticks_stufe_con 	: INTEGER := 11;		-- teilen um stufe fuer sabertrooth zu erhalten y/11 -> y*1/11 (siehe dok: Stufenvermessung m1 und m2)
		

	
	--regler variablen
		--m2
		variable e_m2_var 			: INTEGER := 0;		-- e=w-x / w= soll_wert x= ist_wert e= differenz (motor2)
		variable e_alt_m2_var		: INTEGER := 0;		-- e bei T(-1) (m2)
		variable e_m2_sum_var		: INTEGER := 0;		-- summe aller e (m2)
		
		variable y_m2_var				: INTEGER := 0;		-- regel_wert fuer regelstrecke (m2)
		
		variable kp_m2_cal_var		: INTEGER := 0;		-- kp_anteil (m2)
		variable ki_m2_cal_var		: INTEGER := 0;		-- ki_anteil (m2)
		variable kd_m2_cal_var		: INTEGER := 0;		-- kd_anteil (m2)
		
		
	BEGIN
		IF reset_n = '0' THEN
			cnt_var := 0;
			
			new_value_m2_out <= '0';


		ELSIF clk'EVENT AND clk = '1' THEN
		
			IF active_in = '1' THEN -- wenn aktiv dann 
			
				IF(cnt_var = CNT_MAX)then -- wird alle 50ms ausgefuert (neuer wert vom encoder)		
					
					------m2-------------
					IF (x2_ist_in < w_ug_m2_int or x2_ist_in > w_og_m2_int) THEN
					
						e_m2_var := w_m2_int - (to_integer(unsigned(x2_ist_in(13 downto 0))));	-- regeldifferenz -> vergleicher
						e_m2_sum_var := e_m2_sum_var + e_m2_var;											-- summe der regeldifferenz -->integration I-teil
						
						kp_m2_cal_var := kp_m2_con*e_m2_var;												-- regelgeleichung 1*2^14
						ki_m2_cal_var := ki_ta_m2_con*e_m2_sum_var;										-- |					1*2^14
						kd_m2_cal_var := kd_ta_m2_con*(e_m2_var - e_alt_m2_var);						-- |					1*2^14
																														-- |
						y_m2_var := kp_m2_cal_var + ki_m2_cal_var + kd_m2_cal_var;					-- | ergebnis in ticks 2^14+2^14+2^14 = 2^14
						
						y_m2_var := y_m2_var/ticks_stufe_con;												-- umwandeln in sabertooth stufen 2^14
						
						e_alt_m2_var := e_m2_var;
						
						y2_out <= std_logic_vector(to_unsigned(y_m2_var,22))(21 downto 14);		-- auf den ausgang schieben un um 14 stellen rechts schieben
						
						cnt_var := 0;
						new_value_m2_out <= '1';
					END IF;
				
				ELSE
					cnt_var := cnt_var +1;
					new_value_m2_out <= '0';
				END IF;

			ELSE 			-- kein regler benoetigt alles auf anfang
				cnt_var := 0;
				new_value_m2_out <= '0';
			END IF;
		END IF;
	END PROCESS; 	
	
	
	
	
--process der die unteren und obere toleranzen aus der soll geschwindigkeit(in: std_logic_vector out: integer)	erstellt
	convert: PROCESS(clk, reset_n)
	
	variable convert_en		: std_logic := '0';
	variable toleranz_var	: integer := 7;--15
	
	BEGIN
		IF reset_n = '0' THEN
		
			w_m1_int		<= 0;
			w_m2_int		<= 0;
			w_ug_m1_int <= 0;
			w_og_m1_int <= 0;
			w_ug_m2_int <= 0;
			w_og_m2_int <= 0;
	
			convert_en := '0';

		ELSIF clk'EVENT AND clk = '1' THEN
			IF active_in = '1' THEN -- wenn aktiv dann
				IF convert_en = '0' THEN -- wenn noch nicht konvertiert dann
					
					w_m1_int 	<= (to_integer(unsigned(w1_soll_in)));
					w_m2_int		<= (to_integer(unsigned(w2_soll_in)));
					w_ug_m1_int <= ((to_integer(unsigned(w1_soll_in)))- toleranz_var); -- untere grenze m1
					w_og_m1_int <= ((to_integer(unsigned(w1_soll_in)))+ toleranz_var); -- obere grenze m1
					w_ug_m2_int <= ((to_integer(unsigned(w2_soll_in)))- toleranz_var); -- untere grenze m2
					w_og_m2_int <= ((to_integer(unsigned(w2_soll_in)))+ toleranz_var); -- obere grenze m2
					
					convert_en := '1';
				END IF;
				
			ELSE							-- wenn nicht aktiv dann
				w_m1_int		<= 0;
				w_m2_int		<= 0;
				w_ug_m1_int <= 0;
				w_og_m1_int <= 0;
				w_ug_m2_int <= 0;
				w_og_m2_int <= 0;
				convert_en := '0';
				
			END IF;
		END IF;			
	END PROCESS;

end arch_pid_regler_mm;