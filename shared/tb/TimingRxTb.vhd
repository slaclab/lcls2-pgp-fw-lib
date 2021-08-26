-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the TimingRxTb module
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'SLAC Firmware Standard Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library lcls2_pgp_fw_lib;

entity TimingRxTb is end TimingRxTb;

architecture testbed of TimingRxTb is

   constant CLK_PERIOD_G : time := 10 ns;
   constant TPD_G        : time := CLK_PERIOD_G/4;

   signal axilClk         : sl                     := '0';
   signal axilRst         : sl                     := '0';
   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;
   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_INIT_C;

   signal userClk25         : sl                     := '0';
   signal userRst25         : sl                     := '0';

   signal loopbackP : slv(1 downto 0);
   signal loopbackN : slv(1 downto 0);

begin

   --------------------
   -- Clocks and Resets
   --------------------
   U_axilClk : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 6.4 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => axilClk,
         rst  => axilRst);

   U_userClk25 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 40 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => userClk25,
         rst  => userRst25);

   ------------------
   -- Timing Receiver
   ------------------
   U_TimingRx : entity lcls2_pgp_fw_lib.TimingRx
      generic map (
         TPD_G               => TPD_G,
         USE_GT_REFCLK_G     => false,  -- FALSE: userClk25/userRst25
         SIMULATION_G        => true,
         BYP_GT_SIM_G        => false, -- FASLE: Using .XCI IP cores
         DMA_AXIS_CONFIG_G   => AXI_STREAM_CONFIG_INIT_C,
         AXIL_CLK_FREQ_G     => 156.25E+6,
         AXI_BASE_ADDR_G     => x"0000_0000",
         NUM_DETECTORS_G     => 1,
         EN_LCLS_I_TIMING_G  => true,
         EN_LCLS_II_TIMING_G => true)
      port map (
         -- Reference Clock and Reset
         userClk25             => userClk25,
         userRst25             => userRst25,
         -- Trigger interface
         triggerClk            => axilClk,
         triggerRst            => axilRst,
         -- L1 trigger feedback (optional)
         l1Clk                 => axilClk,
         l1Rst                 => axilRst,
         -- Event interface
         eventRst              => axilClk,
         eventClk              => axilRst,
         eventTrigMsgMasters   => open,
         eventTrigMsgSlaves    => (others => AXI_STREAM_SLAVE_FORCE_C),
         eventTrigMsgCtrl      => (others => AXI_STREAM_CTRL_UNUSED_C),
         eventTimingMsgMasters => open,
         eventTimingMsgSlaves  => (others => AXI_STREAM_SLAVE_FORCE_C),
         clearReadout          => open,
         -- AXI-Lite Interface (axilClk domain)
         axilClk               => axilClk,
         axilRst               => axilRst,
         axilReadMaster        => axilReadMaster,
         axilReadSlave         => axilReadSlave,
         axilWriteMaster       => axilWriteMaster,
         axilWriteSlave        => axilWriteSlave,
         -- GT Serial Ports
         timingRxP             => loopbackP,
         timingRxN             => loopbackN,
         timingTxP             => loopbackP,
         timingTxN             => loopbackN);

end testbed;
