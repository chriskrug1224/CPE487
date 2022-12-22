library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY synth IS
	PORT (
		clk_50MHz : IN STD_LOGIC; -- system clock (50 MHz)


		BTN0 : in STD_LOGIC;
		BTN1 : in STD_LOGIC;
		BTN2 : in STD_LOGIC;
   		 SW0 : IN STD_LOGIC;
   		 SW1 : IN STD_LOGIC;
   		 SW2 : IN STD_LOGIC;
   		 SW3 : IN STD_LOGIC;
   		 SW4 : IN STD_LOGIC;
   		 SW5 : IN STD_LOGIC;
   		 SW6 : IN STD_LOGIC;
   		 SW7 : IN STD_LOGIC;
   		 SW8 : IN STD_LOGIC;
   		 SW9 : IN STD_LOGIC;
   		 SW10 : IN STD_LOGIC;
   		 SW11 : IN STD_LOGIC;
   		 SW12 : IN STD_LOGIC;
   		 SW13 : IN STD_LOGIC;
   		 SW14 : IN STD_LOGIC;
   		 SW15 : IN STD_LOGIC;


		dac_MCLK : OUT STD_LOGIC; -- outputs to PMODI2L DAC
		dac_LRCK : OUT STD_LOGIC;
		dac_SCLK : OUT STD_LOGIC;
		dac_SDIN : OUT STD_LOGIC

		
	);
END synth;

ARCHITECTURE Behavioral OF synth IS
    CONSTANT default : UNSIGNED (13 DOWNTO 0) := to_unsigned (0, 14); -- upper limit of siren = 512 Hz
    CONSTANT note_C : UNSIGNED (13 DOWNTO 0) := to_unsigned (195, 14); -- 261.63*0.745
    CONSTANT note_E : UNSIGNED (13 DOWNTO 0) := to_unsigned (246, 14); -- 329.63*0.745
    CONSTANT note_G : UNSIGNED (13 DOWNTO 0) := to_unsigned (292, 14); -- 392.00*0.745
	CONSTANT note_B : UNSIGNED (13 DOWNTO 0) := to_unsigned (368, 14); -- 493.88*0.745
	
	CONSTANT note_C1 : UNSIGNED (13 DOWNTO 0) := to_unsigned (390, 14); -- 2*261.63*0.745
    CONSTANT note_E1 : UNSIGNED (13 DOWNTO 0) := to_unsigned (492, 14); -- 2*329.63*0.745
    CONSTANT note_G1 : UNSIGNED (13 DOWNTO 0) := to_unsigned (584, 14); -- 2*392.00*0.745
	CONSTANT note_B1 : UNSIGNED (13 DOWNTO 0) := to_unsigned (736, 14); -- 2*493.88*0.745
	
	CONSTANT note_C2 : UNSIGNED (13 DOWNTO 0) := to_unsigned (585, 14); -- 3*261.63*0.745
    CONSTANT note_E2 : UNSIGNED (13 DOWNTO 0) := to_unsigned (738, 14); -- 3*329.63*0.745
    CONSTANT note_G2 : UNSIGNED (13 DOWNTO 0) := to_unsigned (876, 14); -- 3*392.00*0.745
	CONSTANT note_B2 : UNSIGNED (13 DOWNTO 0) := to_unsigned (1104, 14); -- 3*493.88*0.745
	
	CONSTANT note_C0 : UNSIGNED (13 DOWNTO 0) := to_unsigned (98, 14); -- (261.63*0.745)/2
    CONSTANT note_E0 : UNSIGNED (13 DOWNTO 0) := to_unsigned (123, 14); -- (329.63*0.745)/2
    CONSTANT note_G0 : UNSIGNED (13 DOWNTO 0) := to_unsigned (146, 14); -- (392.00*0.745)/2
	CONSTANT note_B0 : UNSIGNED (13 DOWNTO 0) := to_unsigned (184, 14); -- (493.88*0.745)/2
	-- For reference http://www.swarthmore.edu/NatSci/ceverba1/Class/e5_2006/MusicalScales.html
	
	COMPONENT dac_if IS
		PORT (
			SCLK : IN STD_LOGIC;
			L_start : IN STD_LOGIC;
			R_start : IN STD_LOGIC;
			L_data : IN signed (15 DOWNTO 0);
			R_data : IN signed (15 DOWNTO 0);
			SDATA : OUT STD_LOGIC
		);
	END COMPONENT;
	COMPONENT tone IS
		PORT (
			clk : IN STD_LOGIC;
			pitch : IN UNSIGNED (13 DOWNTO 0);
			btn_press : IN STD_LOGIC;
			data : OUT SIGNED (15 DOWNTO 0)
		);
	END COMPONENT;
	SIGNAL tcount : unsigned (19 DOWNTO 0) := (OTHERS => '0'); -- timing counter
	SIGNAL data_L, data_R : SIGNED (15 DOWNTO 0); -- 16-bit signed audio data
	SIGNAL dac_load_L, dac_load_R : STD_LOGIC; -- timing pulses to load DAC shift reg.
	SIGNAL slo_clk, sclk, audio_CLK : STD_LOGIC;
	SIGNAL current_pitch : UNSIGNED (13 DOWNTO 0);

	-- make signals for different switches
	SIGNAL switch0 : STD_LOGIC;
	SIGNAL switch1 : STD_LOGIC;
	SIGNAL switch2 : STD_LOGIC;
	SIGNAL switch3 : STD_LOGIC;
	SIGNAL switch4 : STD_LOGIC;
	SIGNAL switch5 : STD_LOGIC;
	SIGNAL switch6 : STD_LOGIC;
	SIGNAL switch7 : STD_LOGIC;
	SIGNAL switch8 : STD_LOGIC;
	SIGNAL switch9 : STD_LOGIC;
	SIGNAL switch10 : STD_LOGIC;
	SIGNAL switch11 : STD_LOGIC;
	SIGNAL switch12 : STD_LOGIC;
	SIGNAL switch13 : STD_LOGIC;
	SIGNAL switch14 : STD_LOGIC;
	SIGNAL switch15 : STD_LOGIC;
	SIGNAL button0 : STD_LOGIC;
	--SIGNAL buttonleft : STD_LOGIC;
	--SIGNAL buttonright : STD_LOGIC;

BEGIN
	-- this process sets up a 20 bit binary counter clocked at 50MHz. This is used
	-- to generate all necessary timing signals. dac_load_L and dac_load_R are pulses
	-- sent to dac_if to load parallel data into shift register for serial clocking
	-- out to DAC
	tim_pr : PROCESS
	BEGIN
		WAIT UNTIL rising_edge(clk_50MHz);
		IF (tcount(9 DOWNTO 0) >= X"00F") AND (tcount(9 DOWNTO 0) < X"02E") THEN
			dac_load_L <= '1';
		ELSE
			dac_load_L <= '0';
		END IF;
		IF (tcount(9 DOWNTO 0) >= X"20F") AND (tcount(9 DOWNTO 0) < X"22E") THEN
			dac_load_R <= '1';
		ELSE dac_load_R <= '0';
		END IF;
		tcount <= tcount + 1;
	END PROCESS;

	switchCheck : PROCESS
	BEGIN
		WAIT UNTIL rising_edge(clk_50MHz);
		IF (switch0 = '1') THEN --tone1 switch flipped
			current_pitch <= note_C;
		--add more if's
		ELSIF (switch1 = '1') THEN --tone2 switch flipped
			current_pitch <= note_E;
		ELSIF (switch2 = '1') THEN --tone3 switch flipped
			current_pitch <= note_G;
		ELSIF (switch3 = '1') THEN --tone4 switch flipped
			current_pitch <= note_B;
		ELSIF (switch4 = '1') THEN --tone5 switch flipped
			current_pitch <= note_C1;
		ELSIF (switch5 = '1') THEN --tone6 switch flipped
			current_pitch <= note_E1;
		ELSIF (switch6 = '1') THEN --tone7 switch flipped
			current_pitch <= note_G1;
		ELSIF (switch7 = '1') THEN --tone8 switch flipped
			current_pitch <= note_B1;
		ELSIF (switch8 = '1') THEN --tone9 switch flipped
			current_pitch <= note_C2;
		ELSIF (switch9 = '1') THEN --tone10 switch flipped
			current_pitch <= note_E2;
		ELSIF (switch10 = '1') THEN --tone11 switch flipped
			current_pitch <= note_G2;
		ELSIF (switch11 = '1') THEN --tone12 switch flipped
			current_pitch <= note_B2;
		ELSIF (switch12 = '1') THEN --tone13 switch flipped
			current_pitch <= note_C0;
		ELSIF (switch13 = '1') THEN --tone14 switch flipped
			current_pitch <= note_E0;
		ELSIF (switch14 = '1') THEN --tone15 switch flipped
			current_pitch <= note_G0;
		ELSIF (switch15 = '1') THEN --tone16 switch flipped
			current_pitch <= note_B0;
		ELSE current_pitch <= default; -- default 0 Hz
		END IF;
	END PROCESS;
--	buttonCheck : PROCESS
--	BEGIN
--		WAIT UNTIL rising_edge(clk_50MHz);
--		IF (buttonleft = '1') THEN --tone1 switch flipped
--			current_pitch <= current_pitch * Multiplier_2;
--		--add more if's
--		ELSIF (buttonright = '1') THEN --tone1 switch flipped
--			current_pitch <= current_pitch/2;
--		ELSE
--		END IF;
--	END PROCESS;
	dac_MCLK <= NOT tcount(1); -- DAC master clock (12.5 MHz)
	audio_CLK <= tcount(9); -- audio sampling rate (48.8 kHz)
	dac_LRCK <= audio_CLK; -- also sent to DAC as left/right clock
	sclk <= tcount(4); -- serial data clock (1.56 MHz)
	dac_SCLK <= sclk; -- also sent to DAC as SCLK
	slo_clk <= tcount(19); -- clock to control wailing of tone (47.6 Hz)

	button0 <= BTN0;
	--buttonleft <= BTN1;
	--buttonright <= BTN2;
    switch0 <= SW0 ;
	switch1 <= SW1;
	switch2 <= SW2;
	switch3 <= SW3;
	switch4 <= SW4;
	switch5 <= SW5;
	switch6 <= SW6;
	switch7 <= SW7;
	switch8 <= SW8;
	switch9 <= SW9;
	switch10 <= SW10;
	switch11 <= SW11;
	switch12 <= SW12;
	switch13 <= SW13;
	switch14 <= SW14;
	switch15 <= SW15;

	dac : dac_if
	PORT MAP(
		SCLK => sclk, -- instantiate parallel to serial DAC interface
		L_start => dac_load_L, 
		R_start => dac_load_R, 
		L_data => data_L, 
		R_data => data_R, 
		SDATA => dac_SDIN 
		);
		tgen : tone
	PORT MAP(
	    btn_press => BTN0,
		clk => audio_clk, -- instance a tone module
		pitch => current_pitch, -- use curr-pitch to modulate tone
		data => data_L
		);
		data_R <= data_L; -- duplicate data on right channel
END Behavioral;