----------------------------------------------------------------------------------
-- Create Date: 17.12.2024 22:50:15
-- Design Name: VGA_Timing_Generator Testbench
-- Module Name: VGA_Timing_Generator Testbench- Behavioral
-- Project Name: VGA Controller
-- Description: Testbench for generating and verifying VGA timing signals.
--
--                   ----------------------
--                  |                      |
--          CLK_i-->| VGA_Timing_Generator |--> Active_o
--          RST_i-->|                      |--> H_sync_o
--          En_i--->|                      |--> V_sync_o
--          Sync_i->|                      |
--                  |                      |
--                   ----------------------
--
-- Inputs:
-- CLK_i   : Clock input (must match the pixel clock)
-- RST_i   : Active-high reset
-- En_i    : Active-high enable signal
-- Sync_i  : Active-high sync signal (resets counters)
--
-- Outputs:
-- Active_o : High when the pixel is within the visible area
-- H_sync_o : High during horizontal sync
-- V_sync_o : High during vertical sync
--
-- Revision: 1.0 - File Created
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_timing_generator_tb IS
END vga_timing_generator_tb;

ARCHITECTURE Behavioral OF vga_timing_generator_tb IS

    -- Signals
    SIGNAL clk_s, rst_s, hsync_s, vsync_s, active_s : STD_LOGIC := '0';
    SIGNAL en_s, sync_s : STD_LOGIC := '1';

    -- Constants
    CONSTANT half_clock_period_c : TIME := 12.5 ns;
    CONSTANT clock_period_c : TIME := 2 * half_clock_period_c;

    CONSTANT h_visible_area_c : INTEGER := 800;
    CONSTANT h_frontporch_c   : INTEGER := 40;
    CONSTANT h_sync_pulse_c   : INTEGER := 128;
    CONSTANT h_back_porch_c   : INTEGER := 88;
    CONSTANT h_whole_line_c   : INTEGER := 1056;

    CONSTANT v_visible_area_c : INTEGER := 600;
    CONSTANT v_frontporch_c   : INTEGER := 1;
    CONSTANT v_sync_pulse_c   : INTEGER := 4;
    CONSTANT v_back_porch_c   : INTEGER := 23;
    CONSTANT v_whole_line_c   : INTEGER := 628;

    -- Timing calculations
    CONSTANT h_visible_area_time_c : TIME := h_visible_area_c * clock_period_c;
    CONSTANT h_frontporch_time_c   : TIME := h_frontporch_c * clock_period_c;
    CONSTANT h_sync_pulse_time_c   : TIME := h_sync_pulse_c * clock_period_c;
    CONSTANT h_back_porch_time_c   : TIME := h_back_porch_c * clock_period_c;

    -- Component Declaration
    COMPONENT vga_timing_generator IS
        GENERIC (
            h_visible_area : INTEGER := 800;
            h_frontporch   : INTEGER := 40;
            h_sync_pulse   : INTEGER := 128;
            h_back_porch   : INTEGER := 88;
            h_whole_line   : INTEGER := 1056;
            v_visible_area : INTEGER := 600;
            v_frontporch   : INTEGER := 1;
            v_sync_pulse   : INTEGER := 4;
            v_back_porch   : INTEGER := 23;
            v_whole_line   : INTEGER := 628
        );
        PORT (
            Clk_i    : IN  STD_LOGIC;
            Rst_i    : IN  STD_LOGIC;
            En_i     : IN  STD_LOGIC;
            Sync_i   : IN  STD_LOGIC;
            Active_o : OUT STD_LOGIC;
            H_sync_o : OUT STD_LOGIC;
            V_sync_o : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN
    -- Instantiate VGA Timing Generator
    uut: vga_timing_generator
        GENERIC MAP (
            h_visible_area_c, h_frontporch_c, h_sync_pulse_c, 
            h_back_porch_c, h_whole_line_c,
            v_visible_area_c, v_frontporch_c, v_sync_pulse_c, 
            v_back_porch_c, v_whole_line_c
        )
        PORT MAP (
            clk_s, rst_s, en_s, sync_s, 
            active_s, hsync_s, vsync_s
        );

    -- Clock Generation
    clk_gen: PROCESS
    BEGIN
        clk_s <= NOT clk_s;
        WAIT FOR half_clock_period_c;
    END PROCESS;

    -- Testbench Process
    der: PROCESS
        VARIABLE time_v : TIME;
    BEGIN
        -- Initialize signals
        rst_s  <= '0';
        en_s   <= '0';
        sync_s <= '0';
        WAIT FOR clock_period_c;

		rst_s <= '1';
		WAIT FOR clock_period_c;

		en_s <= '1';
		WAIT FOR 0 ns;

        -- Simulation Loop over 4 Images
		FOR L IN 0 TO 4 LOOP
			-- Visible Area Simulation
			FOR I IN 0 TO v_visible_area_c - 1 LOOP
				-- Horizontal timing checks (active fall; hsync rise and fall; active rise)
				time_v := now;
				WAIT UNTIL hsync_s = '1' OR vsync_s = '1' OR active_s = '0'; --wait for active to drop
				ASSERT now - time_v = h_visible_area_time_c REPORT "active area timing wrong low" SEVERITY failure;
				ASSERT hsync_s = '0' REPORT "hsync active at frontporch" SEVERITY failure;
				ASSERT vsync_s = '0' REPORT "vsync active at frontporch" SEVERITY failure;
				ASSERT active_s = '0' REPORT "active inactive at frontporch" SEVERITY failure;

				time_v := now;
				WAIT UNTIL hsync_s = '1' OR vsync_s = '1' OR active_s = '1'; --wait for hsync to rise
				ASSERT now - time_v = h_frontporch_time_c REPORT "frontporch timing wrong hsync" SEVERITY failure;
				ASSERT hsync_s = '1' REPORT "hsync inactive at hsync" SEVERITY failure;
				ASSERT vsync_s = '0' REPORT "vsync active at hsync" SEVERITY failure;
				ASSERT active_s = '0' REPORT "active active at hsync" SEVERITY failure;

				time_v := now;
				WAIT UNTIL hsync_s = '0' OR vsync_s = '1' OR active_s = '1'; --wait for hsync to drop
				ASSERT now - time_v = h_sync_pulse_time_c REPORT "hsync active timing wrong" SEVERITY failure;
				ASSERT hsync_s = '0' REPORT "hsync active at backporch" SEVERITY failure;
				ASSERT vsync_s = '0' REPORT "vsync active at backporch" SEVERITY failure;
				ASSERT active_s = '0' REPORT "active active at backporch" SEVERITY failure;

				IF I < v_visible_area_c - 1 THEN --last iteration does not have an active signal 
					time_v := now;
					WAIT UNTIL hsync_s = '1' OR vsync_s = '1' OR active_s = '1'; --wait for active to rise
					ASSERT now - time_v = h_back_porch_time_c REPORT "active area timing wrong high" SEVERITY failure;
					ASSERT hsync_s = '0' REPORT "hsync active at backporch" SEVERITY failure;
					ASSERT vsync_s = '0' REPORT "vsync active at backporch" SEVERITY failure;
					ASSERT active_s = '1' REPORT "active inactive at backporch" SEVERITY failure;
				END IF;
			END LOOP;

			REPORT "visible area done";

			--invisible area 
			time_v := now;
			FOR I IN 0 TO v_frontporch_c - 1 LOOP
				WAIT UNTIL hsync_s = '1' OR vsync_s = '1' OR active_s = '1'; --wait for hsync to rise
				ASSERT now - time_v = h_frontporch_time_c + h_visible_area_time_c + h_back_porch_time_c REPORT "frontporch timing wrong hsync" SEVERITY failure;
				ASSERT hsync_s = '1' REPORT "hsync inactive at hsync" SEVERITY failure;
				ASSERT vsync_s = '0' REPORT "vsync active at hsync" SEVERITY failure;
				ASSERT active_s = '0' REPORT "active active at hsync" SEVERITY failure;

				time_v := now;
				WAIT UNTIL hsync_s = '0' OR vsync_s = '1' OR active_s = '1'; --wait for hsync to drop
				ASSERT now - time_v = h_sync_pulse_time_c REPORT "hsync active timing wrong" SEVERITY failure;
				ASSERT hsync_s = '0' REPORT "hsync active at backporch" SEVERITY failure;
				ASSERT vsync_s = '0' REPORT "vsync active at backporch" SEVERITY failure;
				ASSERT active_s = '0' REPORT "active active at backporch" SEVERITY failure;
				time_v := now;
			END LOOP;

			REPORT "vsync pulse ";
			--vsync pulse
			WAIT UNTIL hsync_s = '1' OR vsync_s = '1' OR active_s = '1'; --wait for vsync to rise
			ASSERT hsync_s = '0' REPORT "hsync active at vsync" SEVERITY failure;
			ASSERT vsync_s = '1' REPORT "vsync active at vsync" SEVERITY failure;
			ASSERT active_s = '0' REPORT "active active at vsync" SEVERITY failure;

			time_v := now - h_back_porch_time_c;
			FOR I IN 0 TO v_sync_pulse_c - 1 LOOP
				WAIT UNTIL hsync_s = '1' OR vsync_s = '1' OR active_s = '1'; --wait for hsync to rise
				ASSERT now - time_v = h_frontporch_time_c + h_visible_area_time_c + h_back_porch_time_c REPORT "frontporch timing wrong hsync" SEVERITY failure;
				ASSERT hsync_s = '1' REPORT "hsync inactive at hsync" SEVERITY failure;
				ASSERT vsync_s = '1' REPORT "vsync active at hsync" SEVERITY failure;
				ASSERT active_s = '0' REPORT "active active at hsync" SEVERITY failure;

				time_v := now;
				WAIT UNTIL hsync_s = '0' OR vsync_s = '1' OR active_s = '1'; --wait for hsync to drop
				ASSERT now - time_v = h_sync_pulse_time_c REPORT "hsync active timing wrong" SEVERITY failure;
				ASSERT hsync_s = '0' REPORT "hsync active at backporch" SEVERITY failure;
				ASSERT vsync_s = '1' REPORT "vsync active at backporch" SEVERITY failure;
				ASSERT active_s = '0' REPORT "active active at backporch" SEVERITY failure;
				time_v := now;
			END LOOP;

			REPORT "vsync done ";
			WAIT UNTIL hsync_s = '1' OR vsync_s = '0' OR active_s = '1'; --wait for vsync to fall
			ASSERT hsync_s = '0' REPORT "hsync active at vsync" SEVERITY failure;
			ASSERT vsync_s = '0' REPORT "vsync inactive at vsync" SEVERITY failure;
			ASSERT active_s = '0' REPORT "active active at vsync" SEVERITY failure;

			time_v := now - h_back_porch_time_c;
			FOR I IN 0 TO v_back_porch_c - 1 LOOP
				WAIT UNTIL hsync_s = '1' OR vsync_s = '1' OR active_s = '1'; --wait for hsync to rise
				ASSERT now - time_v = h_frontporch_time_c + h_visible_area_time_c + h_back_porch_time_c REPORT "frontporch timing wrong hsync" SEVERITY failure;
				ASSERT hsync_s = '1' REPORT "hsync inactive at hsync" SEVERITY failure;
				ASSERT vsync_s = '0' REPORT "vsync active at hsync" SEVERITY failure;
				ASSERT active_s = '0' REPORT "active active at hsync" SEVERITY failure;

				time_v := now;
				WAIT UNTIL hsync_s = '0' OR vsync_s = '1' OR active_s = '1'; --wait for hsync to drop
				ASSERT now - time_v = h_sync_pulse_time_c REPORT "hsync active timing wrong" SEVERITY failure;
				ASSERT hsync_s = '0' REPORT "hsync active at backporch" SEVERITY failure;
				ASSERT vsync_s = '0' REPORT "vsync active at backporch" SEVERITY failure;
				ASSERT active_s = '0' REPORT "active active at backporch" SEVERITY failure;
				time_v := now;
			END LOOP;
			WAIT FOR h_back_porch_time_c;
			REPORT "image done ";
		END LOOP;

		ASSERT 1 = 0 REPORT "Simulation complete successfully" SEVERITY failure;
	END PROCESS;
END Behavioral;
