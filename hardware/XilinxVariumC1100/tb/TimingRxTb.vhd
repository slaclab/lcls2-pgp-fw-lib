-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation test bed
-------------------------------------------------------------------------------
-- This file is part of LCLS2 PGP Firmware Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of LCLS2 PGP Firmware Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library l2si_core;
use l2si_core.L2SiPkg.all;

library lcls2_pgp_fw_lib;

entity TimingRxTb is end TimingRxTb;

architecture testbed of TimingRxTb is

   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C;
   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C;

   signal axilClk : sl := '0';
   signal axilRst : sl := '1';

   signal userClk25 : sl := '0';
   signal userRst25 : sl := '1';

   signal gtP : slv(1 downto 0) := "00";
   signal gtN : slv(1 downto 0) := "11";

begin

   U_axilClk : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 6.4 ns,   -- 156.25 MHz
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => axilClk,
         rst  => axilRst);

   U_userClk25 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 40 ns,    -- 25 MHz
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 10 us)
      port map (
         clkP => userClk25,
         rst  => userRst25);

   ------------------
   -- Timing Receiver
   ------------------
   U_TimingRx : entity lcls2_pgp_fw_lib.TimingRx
      generic map (
         USE_GT_REFCLK_G     => false,  -- FALSE: userClk25/userRst25
         SIMULATION_G        => false,
         DMA_AXIS_CONFIG_G   => AXI_STREAM_CONFIG_INIT_C,
         AXIL_CLK_FREQ_G     => 156.25E+6,
         AXI_BASE_ADDR_G     => x"00000000",
         NUM_DETECTORS_G     => 1,
         EN_LCLS_I_TIMING_G  => true,
         EN_LCLS_II_TIMING_G => true)
      port map (
         -- Reference Clock and Reset
         userClk156           => axilClk,
         userClk25            => userClk25,
         userRst25            => userRst25,
         -- Trigger interface
         triggerClk           => axilClk,
         triggerRst           => axilRst,
         l1Clk                => axilClk,
         l1Rst                => axilRst,
         -- Event interface
         eventClk             => axilClk,
         eventRst             => axilRst,
         eventTrigMsgSlaves   => (others => AXI_STREAM_SLAVE_FORCE_C),
         eventTrigMsgCtrl     => (others => AXI_STREAM_CTRL_UNUSED_C),
         eventTimingMsgSlaves => (others => AXI_STREAM_SLAVE_FORCE_C),
         -- AXI-Lite Interface (axilClk domain)
         axilClk              => axilClk,
         axilRst              => axilRst,
         axilReadMaster       => axilReadMaster,
         axilReadSlave        => axilReadSlave,
         axilWriteMaster      => axilWriteMaster,
         axilWriteSlave       => axilWriteSlave,
         -- GT Serial Ports
         timingRxP            => gtP,
         timingRxN            => gtN,
         timingTxP            => gtP,
         timingTxN            => gtN);

end testbed;
