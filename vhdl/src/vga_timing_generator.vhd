----------------------------------------------------------------------------------
-- Create Date: 17.12.2024 22:50:15
-- Design Name: VGA_Timing_Generator
-- Module Name: VGA_Timing_Generator - Behavioral
-- Project Name: VGA Controller
-- Description: A basic video timing generator designed to produce VGA timing signals.
-- 
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
-- CLK_i  : Clock input (must match the pixel clock)
-- RST_i  : Active-high reset
-- En_i   : Active-high enable signal
-- Sync_i : Active-high sync signal (resets counters)
-- Active_o : High when the current pixel is within the visible area
-- H_sync_o : High when horizontal sync is active
-- V_sync_o : High when vertical sync is active
--
-- Revision: 1.0 - File Created
-- Additional Comments:
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_timing_generator IS
	GENERIC
	(--VGA timing definitions in pixel
		h_visible_area : INTEGER := 800; -- Visible horizontal pixels
		h_frontporch   : INTEGER := 40; -- Horizontal front porch width
		h_sync_pulse   : INTEGER := 128; -- Horizontal sync pulse width
		h_back_porch   : INTEGER := 88; -- Horizontal back porch width
		h_whole_line   : INTEGER := 1056; -- Total horizontal pixels

		v_visible_area : INTEGER := 600; -- Visible vertical lines
		v_frontporch   : INTEGER := 1; -- Vertical front porch height
		v_sync_pulse   : INTEGER := 4; -- Vertical sync pulse height
		v_back_porch   : INTEGER := 23; -- Vertical back porch height
		v_whole_line   : INTEGER := 628 -- Total vertical lines
	);
	PORT
	(
		Clk_i    : IN  STD_LOGIC;
		Rst_i    : IN  STD_LOGIC;
		En_i     : IN  STD_LOGIC;
		Sync_i   : IN  STD_LOGIC;
		Active_o : OUT STD_LOGIC;
		H_sync_o : OUT STD_LOGIC;
		V_sync_o : OUT STD_LOGIC
	);
END vga_timing_generator;

ARCHITECTURE Behavioral OF vga_timing_generator IS

	--horizontal and vertical timers
	SIGNAL h_sync_int_s : INTEGER := 0;
	SIGNAL v_sync_int_s : INTEGER := 0;

	--Output signals
	SIGNAL active_l_s : STD_LOGIC := '1';
	SIGNAL h_sync_l_s : STD_LOGIC := '0';
	SIGNAL v_sync_l_s : STD_LOGIC := '0';

BEGIN

	PROCESS (CLK_i)
	BEGIN
		IF (rising_edge(clk_i)) THEN
			IF RST_i = '0' THEN
				h_sync_int_s <= 0;
				v_sync_int_s <= 0;
				active_l_s <= '0';
				h_sync_l_s <= '0';
				v_sync_l_s <= '0';
			ELSE
				IF En_i = '1' THEN
					-- Horizontal counter increment
					h_sync_int_s <= h_sync_int_s + 1;

					-- Horizontal sync generation
					IF (h_sync_int_s >= h_visible_area + h_frontporch AND h_sync_int_s < h_visible_area + h_frontporch + h_sync_pulse) THEN
						h_sync_l_s <= '1';
					ELSE
						h_sync_l_s <= '0';
					END IF;

					-- End of line handling
					IF h_sync_int_s = h_whole_line THEN
						v_sync_int_s <= v_sync_int_s + 1;
						h_sync_int_s <= 1;

						-- End of frame handling
						IF v_sync_int_s = v_whole_line - 1 THEN
							v_sync_int_s <= 0;
						END IF;
					END IF;

					IF (v_sync_int_s >= v_visible_area + v_frontporch AND v_sync_int_s < v_visible_area + v_frontporch + v_sync_pulse) THEN
						v_sync_l_s <= '1';
					ELSE
						v_sync_l_s <= '0';
					END IF;

					IF ((h_sync_int_s <= h_visible_area - 1 OR h_sync_int_s = h_whole_line)) THEN
						active_l_s <= '1';
					ELSE
						active_l_s <= '0';
					END IF;
				ELSE
					-- Disable output signals when not enabled
					active_l_s <= '0';
					v_sync_l_s <= '0';
					h_sync_l_s <= '0';
				END IF;

				-- Sync handling
				IF Sync_i = '1' THEN
					h_sync_int_s <= 0;
					v_sync_int_s <= 0;
					active_l_s <= '0';
					h_sync_l_s <= '0';
					v_sync_l_s <= '0';
				END IF;

			END IF;
		END IF;
	END PROCESS;

	Active_o <= active_l_s WHEN (v_sync_int_s < v_visible_area) ELSE '0';
	H_sync_o <= h_sync_l_s;
	V_sync_o <= '1' WHEN (v_sync_int_s >= v_visible_area + v_frontporch AND v_sync_int_s < v_visible_area + v_frontporch + v_sync_pulse) ELSE '0';

END Behavioral;
