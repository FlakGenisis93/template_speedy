--------------------------------------------------------------------------------
--! Conrad Urban B.Eng.
--! Universitaet der Bundeswehr - Muenchen
--
--! @file toplevel_hps_speedy.vhd
--! @brief toplevel of the design where all components are listet and connectet
--------------------------------------------------------------------------------


--! Use stnadart library
library IEEE;
--! Use logic elements
use IEEE.STD_LOGIC_1164.ALL;

--! Detaild description of toplevel_hps_speedy
--! connecting ports to pins
ENTITY toplevel_hps_speedy IS
	--! Toplevel generics
	GENERIC(
		COUNT_DFF_g			: INTEGER	:= 2
	);
	--! Toplevel ports
	PORT(
		--! Switch - pushbutton - LED PORTS
		SW						: IN	std_logic_vector (3 DOWNTO 0);
		KEY						: IN	std_logic_vector (1 DOWNTO 0);
		LED						: OUT	std_logic_vector (7 DOWNTO 0);
		TAKT						: OUT	std_logic;
		--! Memmory PORTS
		HPS_DDR3_ADDR			: OUT	std_logic_vector (14 DOWNTO 0);
        HPS_DDR3_BA				: OUT	std_logic_vector (2 DOWNTO 0);
        HPS_DDR3_CK_P			: OUT	std_logic;
        HPS_DDR3_CK_N			: OUT	std_logic;
        HPS_DDR3_CKE			: OUT	std_logic;
        HPS_DDR3_CS_N			: OUT	std_logic;
        HPS_DDR3_RAS_N			: OUT	std_logic;
        HPS_DDR3_CAS_N			: OUT	std_logic;
        HPS_DDR3_WE_N			: OUT	std_logic;
        HPS_DDR3_RESET_N		: OUT	std_logic;
        HPS_DDR3_DQ				: INOUT	std_logic_vector (31 DOWNTO 0);
        HPS_DDR3_DQS_P			: INOUT	std_logic_vector (3 DOWNTO 0);
        HPS_DDR3_DQS_N			: INOUT	std_logic_vector (3 DOWNTO 0);
        HPS_DDR3_ODT			: OUT	std_logic;
        HPS_DDR3_DM				: OUT	std_logic_vector (3 DOWNTO 0);
        HPS_DDR3_RZQ 			: IN	std_logic;
		--! EMAC PORTS
		HPS_ENET_GTX_CLK		: OUT	std_logic;
        HPS_ENET_TX_DATA		: OUT	std_logic_vector (3 DOWNTO 0);
        HPS_ENET_RX_DATA		: IN	std_logic_vector (3 DOWNTO 0);
		HPS_ENET_MDIO			: INOUT	std_logic;
        HPS_ENET_MDC			: OUT	std_logic;
        HPS_ENET_RX_DV			: IN	std_logic;
        HPS_ENET_TX_EN			: OUT	std_logic;
        HPS_ENET_RX_CLK			: IN	std_logic;
		--! SD PORTS
		HPS_SD_CMD				: INOUT	std_logic;
        HPS_SD_DATA				: INOUT	std_logic_vector (3 DOWNTO 0);
        HPS_SD_CLK				: OUT	std_logic;
		--! USB PORTS
		HPS_USB_DATA			: INOUT	std_logic_vector (7 DOWNTO 0);
        HPS_USB_CLKOUT			: IN	std_logic;
        HPS_USB_STP				: OUT	std_logic;
        HPS_USB_DIR				: IN	std_logic;
        HPS_USB_NXT				: IN	std_logic;
		--! SPIM PORTS
        HPS_SPIM_CLK			: OUT	std_logic;
        HPS_SPIM_MOSI			: OUT	std_logic;
        HPS_SPIM_MISO			: IN	std_logic;
        HPS_SPIM_SS				: INOUT	std_logic;
		--! HPS UART PORTS	
        HPS_UART_RX				: IN	std_logic;
        HPS_UART_TX				: OUT	std_logic;
		--! FPGA UART PORTS
		FPGA_UART1_RX			: IN	std_logic;
        FPGA_UART1_TX			: OUT	std_logic;
		--! HPS I2C0 PORTS
		HPS_I2C0_SDAT			: INOUT	std_logic;
        HPS_I2C0_SCLK			: INOUT	std_logic;
		--! FPGA I2C1 PORTS
		FPGA_I2C1_SDAT			: INOUT	std_logic;
        FPGA_I2C1_SCLK			: INOUT	std_logic;
		--! FPGA I2C2 PORTS
		FPGA_I2C2_SDAT			: INOUT	std_logic;
        FPGA_I2C2_SCLK			: INOUT	std_logic;
		--! HPS PORTS
        HPS_CONV_USB_N			: INOUT	std_logic;
        HPS_ENET_INT_N			: INOUT	std_logic;
        HPS_LTC_GPIO			: INOUT	std_logic;
        HPS_LED					: INOUT	std_logic;
        HPS_KEY					: INOUT	std_logic;
        HPS_GSENSOR_INT			: INOUT	std_logic;
		--! UART XBee
		FPGA_UART_XBEE_RXD		: IN	std_logic;
        FPGA_UART_XBEE_TXD		: OUT	std_logic;
		--! UART Laser
		LASER_ON_N       		: OUT	std_logic;						 		--! Laser enable_n
        UART_LASER_TXD    		: OUT	std_logic;    							
        UART_LASER_RXD			: IN	std_logic;
		--! ENCODER 
		ENCODER_A				: IN	std_logic_vector (1 DOWNTO 0);
		ENCODER_B				: IN	std_logic_vector (1 DOWNTO 0);	
		--! UART SABERTOOTH / LED Drive
		UART_SABER				: OUT	std_logic; 
		DRIVE_LED				: OUT	std_logic_vector (1 DOWNTO 0);
		--! Clock
		FPGA_CLK1_50			: IN	std_logic
		
	);

END ENTITY;


--! Architecture description of toplevel_hps_speedy
ARCHITECTURE toplevel OF toplevel_hps_speedy IS

--! Components

--! Qsys component
	COMPONENT soc_system IS
        PORT (
			--! Systemclock
            clk_clk                               : in    std_logic                     := 'X';             --! 50 MHz
			--! HPS EMAC
            hps_0_hps_io_hps_io_emac1_inst_TX_CLK : out   std_logic;                                        -- hps_io_emac1_inst_TX_CLK
            hps_0_hps_io_hps_io_emac1_inst_TXD0   : out   std_logic;                                        -- hps_io_emac1_inst_TXD0
            hps_0_hps_io_hps_io_emac1_inst_TXD1   : out   std_logic;                                        -- hps_io_emac1_inst_TXD1
            hps_0_hps_io_hps_io_emac1_inst_TXD2   : out   std_logic;                                        -- hps_io_emac1_inst_TXD2
            hps_0_hps_io_hps_io_emac1_inst_TXD3   : out   std_logic;                                        -- hps_io_emac1_inst_TXD3
            hps_0_hps_io_hps_io_emac1_inst_RXD0   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD0
            hps_0_hps_io_hps_io_emac1_inst_MDIO   : inout std_logic                     := 'X';             -- hps_io_emac1_inst_MDIO
            hps_0_hps_io_hps_io_emac1_inst_MDC    : out   std_logic;                                        -- hps_io_emac1_inst_MDC
            hps_0_hps_io_hps_io_emac1_inst_RX_CTL : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CTL
            hps_0_hps_io_hps_io_emac1_inst_TX_CTL : out   std_logic;                                        -- hps_io_emac1_inst_TX_CTL
            hps_0_hps_io_hps_io_emac1_inst_RX_CLK : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CLK
            hps_0_hps_io_hps_io_emac1_inst_RXD1   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD1
            hps_0_hps_io_hps_io_emac1_inst_RXD2   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD2
            hps_0_hps_io_hps_io_emac1_inst_RXD3   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD3
			--! HPS SDIO
            hps_0_hps_io_hps_io_sdio_inst_CMD     : inout std_logic                     := 'X';             -- hps_io_sdio_inst_CMD
            hps_0_hps_io_hps_io_sdio_inst_D0      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D0
            hps_0_hps_io_hps_io_sdio_inst_D1      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D1
            hps_0_hps_io_hps_io_sdio_inst_CLK     : out   std_logic;                                        -- hps_io_sdio_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_D2      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D2
            hps_0_hps_io_hps_io_sdio_inst_D3      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D3
			--! HPS USB 1
            hps_0_hps_io_hps_io_usb1_inst_D0      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D0
            hps_0_hps_io_hps_io_usb1_inst_D1      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D1
            hps_0_hps_io_hps_io_usb1_inst_D2      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D2
            hps_0_hps_io_hps_io_usb1_inst_D3      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D4      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D4
            hps_0_hps_io_hps_io_usb1_inst_D5      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D5
            hps_0_hps_io_hps_io_usb1_inst_D6      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D6
            hps_0_hps_io_hps_io_usb1_inst_D7      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D7
            hps_0_hps_io_hps_io_usb1_inst_CLK     : in    std_logic                     := 'X';             -- hps_io_usb1_inst_CLK
            hps_0_hps_io_hps_io_usb1_inst_STP     : out   std_logic;                                        -- hps_io_usb1_inst_STP
            hps_0_hps_io_hps_io_usb1_inst_DIR     : in    std_logic                     := 'X';             -- hps_io_usb1_inst_DIR
            hps_0_hps_io_hps_io_usb1_inst_NXT     : in    std_logic                     := 'X';             -- hps_io_usb1_inst_NXT
			--! HPS SPIM 1
            hps_0_hps_io_hps_io_spim1_inst_CLK    : out   std_logic;                                        -- hps_io_spim1_inst_CLK
            hps_0_hps_io_hps_io_spim1_inst_MOSI   : out   std_logic;                                        -- hps_io_spim1_inst_MOSI
            hps_0_hps_io_hps_io_spim1_inst_MISO   : in    std_logic                     := 'X';             -- hps_io_spim1_inst_MISO
            hps_0_hps_io_hps_io_spim1_inst_SS0    : out   std_logic;                                        -- hps_io_spim1_inst_SS0
			--! HPS UART 0 - CONSOLE
            hps_0_hps_io_hps_io_uart0_inst_RX     : in    std_logic                     := 'X';             --! hps_io_uart0_inst_RX
            hps_0_hps_io_hps_io_uart0_inst_TX     : out   std_logic;                                        --! hps_io_uart0_inst_TX
			--! HPS I2C 0 - Gsensor
            hps_0_hps_io_hps_io_i2c0_inst_SDA     : inout std_logic                     := 'X';             --! SDA Gsensor
            hps_0_hps_io_hps_io_i2c0_inst_SCL     : inout std_logic                     := 'X';             --! SCL Gsensor
			--! HPS GPIO
            hps_0_hps_io_hps_io_gpio_inst_GPIO09  : inout std_logic                     := 'X';             --! GPIO09
            hps_0_hps_io_hps_io_gpio_inst_GPIO35  : inout std_logic                     := 'X';             --! GPIO35
            hps_0_hps_io_hps_io_gpio_inst_GPIO40  : inout std_logic                     := 'X';             --! GPIO40
            hps_0_hps_io_hps_io_gpio_inst_GPIO53  : inout std_logic                     := 'X';             --! GPIO53
            hps_0_hps_io_hps_io_gpio_inst_GPIO54  : inout std_logic                     := 'X';             --! GPIO54
            hps_0_hps_io_hps_io_gpio_inst_GPIO61  : inout std_logic                     := 'X';             --! GPIO61
			--! HPS I2C 1 - FPGA - I2CA
            hps_i2c1_out_data                     : out   std_logic;                                        --! out_data
            hps_i2c1_sda                          : in    std_logic                     := 'X';             --! sda
            hps_i2c1_clk_clk                      : out   std_logic;                                        --! clk
            hps_i2c1_scl_in_clk                   : in    std_logic                     := 'X';             --! clk_in
			--! HPS I2C 2 - FPGA - I2CB
            hps_i2c2_out_data                     : out   std_logic;                                        --! out_data
            hps_i2c2_sda                          : in    std_logic                     := 'X';             --! sda
            hps_i2c2_clk_clk                      : out   std_logic;                                        --! clk
            hps_i2c2_scl_in_clk                   : in    std_logic                     := 'X';             --! clk_in
			--! HPS UART 0 - FPGA
            hps_uart1_cts                         : in    std_logic                     := 'X';             --! cts
            hps_uart1_dsr                         : in    std_logic                     := 'X';             --! dsr
            hps_uart1_dcd                         : in    std_logic                     := 'X';             --! dcd
            hps_uart1_ri                          : in    std_logic                     := 'X';             --! ri
            hps_uart1_dtr                         : out   std_logic;                                        --! dtr
            hps_uart1_rts                         : out   std_logic;                                        --! rts
            hps_uart1_out1_n                      : out   std_logic;                                        --! out1_n
            hps_uart1_out2_n                      : out   std_logic;                                        --! out2_n
            hps_uart1_rxd                         : in    std_logic                     := 'X';             --! rxd
            hps_uart1_txd                         : out   std_logic;                                        --! txd
			--! UART XBee
            fifoed_avalon_uart_xbee_rxd           : in    std_logic                     := 'X';             --! rxd
            fifoed_avalon_uart_xbee_txd           : out   std_logic;                                        --! txd
			--! UART Sabertooth
				motor_modul_encoder_encoder1_register_in        : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- encoder1_register_in
            motor_modul_encoder_encoder2_register_in        : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- encoder2_register_in
            motor_modul_led_drivestatus_led_drivestatus_out : out   std_logic_vector(1 downto 0);                     -- led_drivestatus_out
            motor_modul_uart_to_sabertooth_uart_out         : out   std_logic;                                        -- uart_out
			--! Memmory
            memory_mem_a                          : out   std_logic_vector(14 downto 0);                    --! mem_a
            memory_mem_ba                         : out   std_logic_vector(2 downto 0);                     --! mem_ba
            memory_mem_ck                         : out   std_logic;                                        --! mem_ck
            memory_mem_ck_n                       : out   std_logic;                                        --! mem_ck_n
            memory_mem_cke                        : out   std_logic;                                        --! mem_cke
            memory_mem_cs_n                       : out   std_logic;                                        --! mem_cs_n
            memory_mem_ras_n                      : out   std_logic;                                        --! mem_ras_n
            memory_mem_cas_n                      : out   std_logic;                                        --! mem_cas_n
            memory_mem_we_n                       : out   std_logic;                                        --! mem_we_n
            memory_mem_reset_n                    : out   std_logic;                                        --! mem_reset_n
            memory_mem_dq                         : inout std_logic_vector(31 downto 0) := (others => 'X'); --! mem_dq
            memory_mem_dqs                        : inout std_logic_vector(3 downto 0)  := (others => 'X'); --! mem_dqs
            memory_mem_dqs_n                      : inout std_logic_vector(3 downto 0)  := (others => 'X'); --! mem_dqs_n
            memory_mem_odt                        : out   std_logic;                                        --! mem_odt
            memory_mem_dm                         : out   std_logic_vector(3 downto 0);                     --! mem_dm
            memory_oct_rzqin                      : in    std_logic                     := 'X';             --! oct_rzqin
			--! Laser modul
            laser_external_connection_on_n        : out   std_logic;                                        --! on_n
            laser_external_connection_txd         : out   std_logic;                                        --! txd
            laser_external_connection_rxd         : in    std_logic;            --! rxd
			--! External connection
			button_pio_external_connection_export : in    std_logic_vector(3 downto 0)  := (others => 'X'); --! button pio
			dipsw_pio_external_connection_export  : in    std_logic_vector(3 downto 0)  := (others => 'X'); --! dipsw pio
			led_pio_external_connection_export    : out   std_logic_vector(7 downto 0);                     --! led pio
			--! HPS resets
            hps_0_f2h_cold_reset_req_reset_n      : in    std_logic                     := 'X';             --! cold_reset_n
            hps_0_f2h_debug_reset_req_reset_n     : in    std_logic                     := 'X';             --! debug_reset_n
            hps_0_f2h_stm_hw_events_stm_hwevents  : in    std_logic_vector(27 downto 0) := (others => 'X'); --! stm_hwevents
            hps_0_f2h_warm_reset_req_reset_n      : in    std_logic                     := 'X';             --! warm_reset_n
            hps_0_h2f_reset_reset_n               : out   std_logic;                                        --! h2f_reset_n
			reset_reset_n                         : in    std_logic              --! reset_n
        );
    END COMPONENT soc_system;
	
	--! Altera debounce
	COMPONENT debounce IS
		GENERIC (
			WIDTH_g 		: INTEGER := 32;           		-- set to be the width of the bus being debounced
			POLARITY 		: BOOLEAN := TRUE;    			-- set to be "HIGH" for active high debounce or "LOW" for active low debounce
			TIMEOUT 		: INTEGER := 50000;      		-- number of input clock cycles the input signal needs to be in the active state
			TIMEOUT_WIDTH 	: INTEGER := 16   				-- set to be ceil(log2(TIMEOUT))
		);
		
		PORT (
			clk				: IN	std_logic;
			reset_n			: IN	std_logic;
			data_in			: IN	std_logic_vector (1 DOWNTO 0);
			data_out		: OUT	std_logic_vector (1 DOWNTO 0)
		);
	END COMPONENT;
	
	--! Altera IO Buffer
	COMPONENT alt_io_buf IS
		PORT (
			datain		: IN 	std_logic_vector (1 DOWNTO 0);
			oe			: IN 	std_logic_vector (1 DOWNTO 0);
			dataio		: INOUT std_logic_vector (1 DOWNTO 0);
			dataout		: OUT 	std_logic_vector (1 DOWNTO 0)
		);
	END COMPONENT;
	
	--! HPS Reset
	COMPONENT hps_reset IS
		PORT (
			--probe		: IN	std_logic;
			source_clk	: IN	std_logic;
			source		: OUT 	std_logic_vector (2 DOWNTO 0)
		);
	END COMPONENT;
	
	--! Altera edge detector
	COMPONENT altera_edge_detector IS
		GENERIC (
			PULSE_EXT 				: INTEGER;		-- 0, 1 = edge detection generate single cycle pulse, >1 = pulse extended for specified clock cycle
			EDGE_TYPE 				: INTEGER; 		-- 0 = falling edge, 1 or else = rising edge
			IGNORE_RST_WHILE_BUSY 	: INTEGER  		-- 0 = module internal reset will be default whenever rst_n asserted, 1 = rst_n request will be ignored while generating pulse out
		); 
		
		PORT (	
			clk			: IN	std_logic;
			rst_n		: IN	std_logic;
			signal_in	: IN	std_logic;
			pulse_out	: OUT	std_logic
		);
	END COMPONENT;
	
	COMPONENT dflipflop IS

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
	END COMPONENT;	
	

--! Internal signals HPS - FPGA
SIGNAL	hps_cold_reset				: std_logic;
SIGNAL	hps_debug_reset			: std_logic;
SIGNAL 	hps_warm_reset				: std_logic;
SIGNAL	fpga_clk_50_s				: std_logic;
SIGNAL	hps_fpga_reset_n			: std_logic;
SIGNAL	led_0_s						: std_logic;
SIGNAL	signal_tap_s				: std_logic;
SIGNAL	laser_uart_dff_S 			: std_logic;
SIGNAL	UART_LASER_RXD_s			: std_logic;

SIGNAL	fpga_led_internal_s			: std_logic_vector(6 DOWNTO 0);
SIGNAL	fpga_debounced_buttons_s	: std_logic_vector(1 DOWNTO 0);
SIGNAL	hps_reset_req				: std_logic_vector(2 DOWNTO 0);
SIGNAL	stm_hw_events				: std_logic_vector(27 DOWNTO 0);

--! Internal signals I2C1
SIGNAL	FPGA_I2C1_OUT_DATA_s		: std_logic;
SIGNAL	FPGA_I2C1_SDA_s				: std_logic;
SIGNAL	FPGA_I2C1_CLK_s				: std_logic;
SIGNAL	FPGA_I2C1_CLK_IN_s			: std_logic;

--! Internal signals I2C2
SIGNAL	FPGA_I2C2_OUT_DATA_s		: std_logic;
SIGNAL	FPGA_I2C2_SDA_s				: std_logic;
SIGNAL	FPGA_I2C2_CLK_s				: std_logic;
SIGNAL	FPGA_I2C2_CLK_IN_s			: std_logic;

--! Internal signals UART1
SIGNAL	FPGA_UART1_CTS_s			: std_logic;
SIGNAL 	FPGA_UART1_DSR_s			: std_logic;
SIGNAL	FPGA_UART1_DCD_s			: std_logic;
SIGNAL	FPGA_UART1_RI_s			: std_logic;
SIGNAL	FPGA_UART1_DTR_s			: std_logic;
SIGNAL	FPGA_UART1_RTS_s			: std_logic;
SIGNAL	FPGA_UART1_OUT1_n_s		: std_logic;
SIGNAL	FPGA_UART1_OUT2_n_s		: std_logic;
SIGNAL	FPGA_UART1_RXD_s			: std_logic;
SIGNAL	FPGA_UART1_RXD_dff_s	: std_logic;

BEGIN

--! Internal wireing
LED(7 DOWNTO 1)				<=	fpga_led_internal_s;
fpga_clk_50_s				<= FPGA_CLK1_50;
stm_hw_events(27 DOWNTO 13)	<= "000000000000000";
stm_hw_events(12 DOWNTO 9)	<= SW;
stm_hw_events(8 DOWNTO 2)	<= fpga_led_internal_s;
stm_hw_events(1 DOWNTO 0)	<= fpga_debounced_buttons_s;

FPGA_UART1_CTS_s	<= '1';
FPGA_UART1_DSR_s	<= '1';
FPGA_UART1_DCD_s	<= '1';
FPGA_UART1_RI_s	<= '1';

--! I2C1
I2C1_IOB : COMPONENT alt_io_buf
			PORT MAP (
				--! I2C1 - SDA
				datain(0)	=>	'0',
				oe(0)		=>	FPGA_I2C1_OUT_DATA_s,	
				dataio(0)	=>	FPGA_I2C1_SDAT,
				dataout(0)	=>	FPGA_I2C1_SDA_s,
				--! I2C1 - SCL
				datain(1)	=>	'0',
				oe(1)		=>	FPGA_I2C1_CLK_s,
				dataio(1)	=>	FPGA_I2C1_SCLK,
				dataout(1)	=>	FPGA_I2C1_CLK_IN_s
			);

--! I2C2			
I2C2_IOB : COMPONENT alt_io_buf
			PORT MAP (
				--! I2C2 - SDA
				datain(0)	=>	'0',
				oe(0)		=>	FPGA_I2C2_OUT_DATA_s,	
				dataio(0)	=>	FPGA_I2C2_SDAT,
				dataout(0)	=>	FPGA_I2C2_SDA_s,
				--! I2C2 - SCL
				datain(1)	=>	'0',
				oe(1)		=>	FPGA_I2C2_CLK_s,
				dataio(1)	=>	FPGA_I2C2_SCLK,
				dataout(1)	=>	FPGA_I2C2_CLK_IN_s
			);

--! debounce
debounce_key : COMPONENT debounce
		GENERIC MAP(
			WIDTH_g 			=> 2,           	-- set to be the width of the bus being debounced
			POLARITY 		=> false,    		-- set to be "HIGH" for active high debounce or "LOW" for active low debounce
			TIMEOUT 			=> 50000,      	-- number of input clock cycles the input signal needs to be in the active state
			TIMEOUT_WIDTH 	=> 16   				-- set to be ceil(log2(TIMEOUT))	
		)
		
		PORT MAP(
			clk				=>	fpga_clk_50_s,
			reset_n			=>	hps_fpga_reset_n,
			data_in			=>	KEY,
			data_out		=>	fpga_debounced_buttons_s
		);
		
--! HPS Reset
hps_reset_inst : COMPONENT hps_reset
		PORT MAP(
			source_clk		=>	fpga_clk_50_s,
			source			=>	hps_reset_req
		);
		
--! pulse cold reset
pulse_cold_reset : COMPONENT altera_edge_detector
		GENERIC MAP(
			PULSE_EXT 				=>	6, 				-- 0, 1 = edge detection generate single cycle pulse, >1 = pulse extended for specified clock cycle
			EDGE_TYPE 				=>	6, 				-- 0 = falling edge, 1 or else = rising edge
			IGNORE_RST_WHILE_BUSY 	=>	1 				-- 0 = module internal reset will be default whenever rst_n asserted, 1 = rst_n request will be ignored while generating pulse out
		) 
		
		PORT MAP(	
			clk						=>	fpga_clk_50_s, 
			rst_n					=>	hps_fpga_reset_n,
			signal_in				=>	hps_reset_req(0),
			pulse_out				=>	hps_cold_reset	
		);
		
--! pulse warm reset
pulse_warm_reset : COMPONENT altera_edge_detector
		GENERIC MAP(
			PULSE_EXT 				=>	2, 				-- 0, 1 = edge detection generate single cycle pulse, >1 = pulse extended for specified clock cycle
			EDGE_TYPE 				=>	1, 				-- 0 = falling edge, 1 or else = rising edge
			IGNORE_RST_WHILE_BUSY 	=>	1  				-- 0 = module internal reset will be default whenever rst_n asserted, 1 = rst_n request will be ignored while generating pulse out
		) 
		
		PORT MAP(	
			clk						=>	fpga_clk_50_s, 
			rst_n					=>	hps_fpga_reset_n,
			signal_in				=>	hps_reset_req(1),
			pulse_out				=>	hps_warm_reset
		);
		
--! pulse debug reset
pulse_debug_reset : COMPONENT altera_edge_detector
		GENERIC MAP(
			PULSE_EXT 				=>	32, 				-- 0, 1 = edge detection generate single cycle pulse, >1 = pulse extended for specified clock cycle
			EDGE_TYPE 				=>	1, 				-- 0 = falling edge, 1 or else = rising edge
			IGNORE_RST_WHILE_BUSY 	=>	1  				-- 0 = module internal reset will be default whenever rst_n asserted, 1 = rst_n request will be ignored while generating pulse out
		) 
		
		PORT MAP(	
			clk						=>	fpga_clk_50_s, 
			rst_n					=>	hps_fpga_reset_n,
			signal_in				=>	hps_reset_req(2),
			pulse_out				=>	hps_debug_reset
		);
		
--! DFF for UART
dff_uart : COMPONENT dflipflop

	GENERIC MAP(
		BIT_DATA_POS_g	=> COUNT_DFF_g
	)
	
	PORT MAP(
		Q(0)				=>	FPGA_UART1_RXD_dff_s,
		D(0)				=>	FPGA_UART1_RX,

		Q(1)				=>	FPGA_UART1_RXD_s,
		D(1)				=>	FPGA_UART1_RXD_dff_s,
		
		ENABLE			=>	'1',
		
		CLK				=>	fpga_clk_50_s,				
		RESET_n			=>	hps_fpga_reset_n
	);	
	
--! DFF Laser

dff_laser : COMPONENT dflipflop	

	GENERIC MAP(
		BIT_DATA_POS_g	=> COUNT_DFF_g
	)
	
	PORT MAP(
		Q(0)				=>	laser_uart_dff_S,
		D(0)				=>	UART_LASER_RXD,

		Q(1)				=>	UART_LASER_RXD_s,
		D(1)				=>	laser_uart_dff_S,
		
		ENABLE			=>	'1',
		
		CLK				=>	fpga_clk_50_s,				
		RESET_n			=>	hps_fpga_reset_n
	);	
		
--! Port Mapping of components
hps : COMPONENT soc_system
		--! Port Map hps - soc_system
        PORT MAP (
            
            clk_clk                               => fpga_clk_50_s,                               		 --                            clk.clk
			
            hps_0_hps_io_hps_io_emac1_inst_TX_CLK => HPS_ENET_GTX_CLK, 									 --                   hps_0_hps_io.hps_io_emac1_inst_TX_CLK
            hps_0_hps_io_hps_io_emac1_inst_TXD0   => HPS_ENET_TX_DATA(0),   								 --                               .hps_io_emac1_inst_TXD0
            hps_0_hps_io_hps_io_emac1_inst_TXD1   => HPS_ENET_TX_DATA(1),   								 --                               .hps_io_emac1_inst_TXD1
            hps_0_hps_io_hps_io_emac1_inst_TXD2   => HPS_ENET_TX_DATA(2),   								 --                               .hps_io_emac1_inst_TXD2
            hps_0_hps_io_hps_io_emac1_inst_TXD3   => HPS_ENET_TX_DATA(3),   								 --                               .hps_io_emac1_inst_TXD3
            hps_0_hps_io_hps_io_emac1_inst_RXD0   => HPS_ENET_RX_DATA(0),   								 --                               .hps_io_emac1_inst_RXD0
            hps_0_hps_io_hps_io_emac1_inst_MDIO   => HPS_ENET_MDIO,   									 --                               .hps_io_emac1_inst_MDIO
            hps_0_hps_io_hps_io_emac1_inst_MDC    => HPS_ENET_MDC,    									 --                               .hps_io_emac1_inst_MDC
            hps_0_hps_io_hps_io_emac1_inst_RX_CTL => HPS_ENET_RX_DV, 									 --                               .hps_io_emac1_inst_RX_CTL
            hps_0_hps_io_hps_io_emac1_inst_TX_CTL => HPS_ENET_TX_EN, 									 --                               .hps_io_emac1_inst_TX_CTL
            hps_0_hps_io_hps_io_emac1_inst_RX_CLK => HPS_ENET_RX_CLK, 									 --                               .hps_io_emac1_inst_RX_CLK
            hps_0_hps_io_hps_io_emac1_inst_RXD1   => HPS_ENET_RX_DATA(1),   								 --                               .hps_io_emac1_inst_RXD1
            hps_0_hps_io_hps_io_emac1_inst_RXD2   => HPS_ENET_RX_DATA(2),   								 --                               .hps_io_emac1_inst_RXD2
            hps_0_hps_io_hps_io_emac1_inst_RXD3   => HPS_ENET_RX_DATA(3),   								 --                               .hps_io_emac1_inst_RXD3
			
            hps_0_hps_io_hps_io_sdio_inst_CMD     => HPS_SD_CMD,     									 --                               .hps_io_sdio_inst_CMD
            hps_0_hps_io_hps_io_sdio_inst_D0      => HPS_SD_DATA(0),      									 --                               .hps_io_sdio_inst_D0
            hps_0_hps_io_hps_io_sdio_inst_D1      => HPS_SD_DATA(1),      									 --                               .hps_io_sdio_inst_D1
            hps_0_hps_io_hps_io_sdio_inst_CLK     => HPS_SD_CLK,     									 --                               .hps_io_sdio_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_D2      => HPS_SD_DATA(2),      									 --                               .hps_io_sdio_inst_D2
            hps_0_hps_io_hps_io_sdio_inst_D3      => HPS_SD_DATA(3),      									 --                               .hps_io_sdio_inst_D3
			
            hps_0_hps_io_hps_io_usb1_inst_D0      => HPS_USB_DATA(0),      								 --                               .hps_io_usb1_inst_D0
            hps_0_hps_io_hps_io_usb1_inst_D1      => HPS_USB_DATA(1),      								 --                               .hps_io_usb1_inst_D1
            hps_0_hps_io_hps_io_usb1_inst_D2      => HPS_USB_DATA(2),      								 --                               .hps_io_usb1_inst_D2
            hps_0_hps_io_hps_io_usb1_inst_D3      => HPS_USB_DATA(3),      								 --                               .hps_io_usb1_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D4      => HPS_USB_DATA(4),      								 --                               .hps_io_usb1_inst_D4
            hps_0_hps_io_hps_io_usb1_inst_D5      => HPS_USB_DATA(5),      								 --                               .hps_io_usb1_inst_D5
            hps_0_hps_io_hps_io_usb1_inst_D6      => HPS_USB_DATA(6),      								 --                               .hps_io_usb1_inst_D6
            hps_0_hps_io_hps_io_usb1_inst_D7      => HPS_USB_DATA(7),      								 --                               .hps_io_usb1_inst_D7
            hps_0_hps_io_hps_io_usb1_inst_CLK     => HPS_USB_CLKOUT,     								 --                               .hps_io_usb1_inst_CLK
            hps_0_hps_io_hps_io_usb1_inst_STP     => HPS_USB_STP,     									 --                               .hps_io_usb1_inst_STP
            hps_0_hps_io_hps_io_usb1_inst_DIR     => HPS_USB_DIR,     									 --                               .hps_io_usb1_inst_DIR
            hps_0_hps_io_hps_io_usb1_inst_NXT     => HPS_USB_NXT,     									 --                               .hps_io_usb1_inst_NXT
			
            hps_0_hps_io_hps_io_spim1_inst_CLK    => HPS_SPIM_CLK,    									 --                               .hps_io_spim1_inst_CLK
            hps_0_hps_io_hps_io_spim1_inst_MOSI   => HPS_SPIM_MOSI,   									 --                               .hps_io_spim1_inst_MOSI
            hps_0_hps_io_hps_io_spim1_inst_MISO   => HPS_SPIM_MISO,   									 --                               .hps_io_spim1_inst_MISO
            hps_0_hps_io_hps_io_spim1_inst_SS0    => HPS_SPIM_SS,    									 --                               .hps_io_spim1_inst_SS0
			
            hps_0_hps_io_hps_io_uart0_inst_RX     => HPS_UART_RX,     									 --                               .hps_io_uart0_inst_RX
            hps_0_hps_io_hps_io_uart0_inst_TX     => HPS_UART_TX,     									 --                               .hps_io_uart0_inst_TX
			
            hps_0_hps_io_hps_io_i2c0_inst_SDA     => HPS_I2C0_SDAT,     								 --                               .hps_io_i2c0_inst_SDA
            hps_0_hps_io_hps_io_i2c0_inst_SCL     => HPS_I2C0_SCLK,     								 --                               .hps_io_i2c0_inst_SCL
			
            hps_0_hps_io_hps_io_gpio_inst_GPIO09  => HPS_CONV_USB_N,  									 --                               .hps_io_gpio_inst_GPIO09
            hps_0_hps_io_hps_io_gpio_inst_GPIO35  => HPS_ENET_INT_N,  									 --                               .hps_io_gpio_inst_GPIO35
            hps_0_hps_io_hps_io_gpio_inst_GPIO40  => HPS_LTC_GPIO, 										 --                               .hps_io_gpio_inst_GPIO40
            hps_0_hps_io_hps_io_gpio_inst_GPIO53  => HPS_LED,  											 --                               .hps_io_gpio_inst_GPIO53
            hps_0_hps_io_hps_io_gpio_inst_GPIO54  => HPS_KEY,  											 --                               .hps_io_gpio_inst_GPIO54
            hps_0_hps_io_hps_io_gpio_inst_GPIO61  => HPS_GSENSOR_INT,  									 --                               .hps_io_gpio_inst_GPIO61
			
            hps_i2c1_out_data                     => FPGA_I2C1_OUT_DATA_s,                     			 --                       hps_i2c1.out_data
            hps_i2c1_sda                          => FPGA_I2C1_SDA_s,                          			 --                               .sda
            hps_i2c1_clk_clk                      => FPGA_I2C1_CLK_s,                      				 --                   hps_i2c1_clk.clk
            hps_i2c1_scl_in_clk                   => FPGA_I2C1_CLK_IN_s,                   				 --                hps_i2c1_scl_in.clk
			
            hps_i2c2_out_data                     => FPGA_I2C2_OUT_DATA_s,                     			 --                       hps_i2c2.out_data
            hps_i2c2_sda                          => FPGA_I2C2_SDA_s,                          			 --                               .sda
            hps_i2c2_clk_clk                      => FPGA_I2C2_CLK_s,                      				 --                   hps_i2c2_clk.clk
            hps_i2c2_scl_in_clk                   => FPGA_I2C2_CLK_IN_s,                   				 --                hps_i2c2_scl_in.clk
			
            hps_uart1_cts                         => FPGA_UART1_CTS_s,                         			 --                      hps_uart1.cts
            hps_uart1_dsr                         => FPGA_UART1_DSR_s,                         			 --                               .dsr
            hps_uart1_dcd                         => FPGA_UART1_DCD_s,                         			 --                               .dcd
            hps_uart1_ri                          => FPGA_UART1_RI_s,                          			 --                               .ri
            hps_uart1_dtr                         => FPGA_UART1_DTR_s,                         			 --                               .dtr
            hps_uart1_rts                         => FPGA_UART1_RTS_s,                         			 --                               .rts
            hps_uart1_out1_n                      => FPGA_UART1_OUT1_n_s,                      			 --                               .out1_n
            hps_uart1_out2_n                      => FPGA_UART1_OUT2_n_s,                     			 --                               .out2_n
            hps_uart1_rxd                         => FPGA_UART1_RXD_s,                         			 --                               .rxd
            hps_uart1_txd                         => FPGA_UART1_TX,                         			 --                               .txd
			
			fifoed_avalon_uart_xbee_rxd           => FPGA_UART_XBEE_RXD,           						 --        fifoed_avalon_uart_xbee.rxd
            fifoed_avalon_uart_xbee_txd           => FPGA_UART_XBEE_TXD,           						 --                               .txd
				
				motor_modul_encoder_encoder1_register_in        => ENCODER_A,        							 --            motor_modul_encoder.encoder1_register_in
            motor_modul_encoder_encoder2_register_in        => ENCODER_B,        							 --                               .encoder2_register_in
            motor_modul_led_drivestatus_led_drivestatus_out => DRIVE_LED, 										 --    motor_modul_led_drivestatus.led_drivestatus_out
            motor_modul_uart_to_sabertooth_uart_out         => UART_SABER,         							 -- motor_modul_uart_to_sabertooth.uart_out
            
            memory_mem_a                          => HPS_DDR3_ADDR,                          			 --                         memory.mem_a
            memory_mem_ba                         => HPS_DDR3_BA,                         				 --                               .mem_ba
            memory_mem_ck                         => HPS_DDR3_CK_P,                         			 --                               .mem_ck
            memory_mem_ck_n                       => HPS_DDR3_CK_N,                       				 --                               .mem_ck_n
            memory_mem_cke                        => HPS_DDR3_CKE,                        				 --                               .mem_cke
            memory_mem_cs_n                       => HPS_DDR3_CS_N,                       				 --                               .mem_cs_n
            memory_mem_ras_n                      => HPS_DDR3_RAS_N,                      				 --                               .mem_ras_n
            memory_mem_cas_n                      => HPS_DDR3_CAS_N,                      				 --                               .mem_cas_n
            memory_mem_we_n                       => HPS_DDR3_WE_N,                       				 --                               .mem_we_n
            memory_mem_reset_n                    => HPS_DDR3_RESET_N,                    				 --                               .mem_reset_n
            memory_mem_dq                         => HPS_DDR3_DQ,                         				 --                               .mem_dq
            memory_mem_dqs                        => HPS_DDR3_DQS_P,                        			 --                               .mem_dqs
            memory_mem_dqs_n                      => HPS_DDR3_DQS_N,                      				 --                               .mem_dqs_n
            memory_mem_odt                        => HPS_DDR3_ODT,                        				 --                               .mem_odt
            memory_mem_dm                         => HPS_DDR3_DM,                         				 --                               .mem_dm
            memory_oct_rzqin                      => HPS_DDR3_RZQ,                      				 --                               .oct_rzqin
            
            laser_external_connection_on_n        => LASER_ON_N,       									 --      laser_external_connection.on_n
            laser_external_connection_txd         => UART_LASER_TXD,        							 --                               .txd
            laser_external_connection_rxd         => UART_LASER_RXD_s,         							 --                               .rxd
			
			button_pio_external_connection_export(1 DOWNTO 0) => fpga_debounced_buttons_S, 							 -- button_pio_external_connection.export
			dipsw_pio_external_connection_export  => SW,  												 --  dipsw_pio_external_connection.export
			led_pio_external_connection_export(7 DOWNTO 1) => fpga_led_internal_s,    							 --    led_pio_external_connection.export
			
            hps_0_f2h_cold_reset_req_reset_n      => NOT hps_cold_reset,      							 --       hps_0_f2h_cold_reset_req.reset_n
            hps_0_f2h_debug_reset_req_reset_n     => NOT hps_debug_reset,     							 --      hps_0_f2h_debug_reset_req.reset_n
            hps_0_f2h_stm_hw_events_stm_hwevents  => stm_hw_events, 									 --        hps_0_f2h_stm_hw_events.stm_hwevents
            hps_0_f2h_warm_reset_req_reset_n      => NOT hps_warm_reset,      							 --       hps_0_f2h_warm_reset_req.reset_n
            hps_0_h2f_reset_reset_n               => hps_fpga_reset_n,               					 --                hps_0_h2f_reset.reset_n
			
			reset_reset_n                         => hps_fpga_reset_n                          			 --                          reset.reset_n
        );

	alive : PROCESS (FPGA_CLK1_50, hps_fpga_reset_n)
	
	VARIABLE	counter	: INTEGER	:= 0;

		BEGIN
			
		IF (hps_fpga_reset_n = '0') THEN
			counter := 0;
			led_0_s <= '0';
		ELSIF ( FPGA_CLK1_50 'EVENT AND FPGA_CLK1_50 = '0' ) THEN
		
			IF ( counter = 24999999) THEN
				counter := 0;
				led_0_s <= NOT led_0_s;
			ELSE
				counter := counter + 1;
			END IF;
			
		END IF;	
		
	END PROCESS;

	LED(0)	<=	led_0_s;
	
	signal_tap : PROCESS (FPGA_CLK1_50, hps_fpga_reset_n)
	
	VARIABLE	counter	: INTEGER	:= 0;

		BEGIN
			
		IF (hps_fpga_reset_n = '0') THEN
			counter := 0;
			signal_tap_s <= '0';
		ELSIF ( FPGA_CLK1_50 'EVENT AND FPGA_CLK1_50 = '0' ) THEN
		
			IF ( counter = 499) THEN
				counter := 0;
				signal_tap_s <= NOT signal_tap_s;
			ELSE
				counter := counter + 1;
			END IF;
			
		END IF;	
		
	END PROCESS;
	
	TAKT	<=	signal_tap_s;
	

END ARCHITECTURE;