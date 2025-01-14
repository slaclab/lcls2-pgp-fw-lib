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

entity TimingGtCoreWrapperTb is end TimingGtCoreWrapperTb;

architecture testbed of TimingGtCoreWrapperTb is

   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C;
   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C;

   signal axilClk : sl := '0';
   signal axilRst : sl := '1';

   signal stableClk : sl := '0';
   signal stableRst : sl := '1';

   signal refClk     : sl := '0';
   signal refClkDiv2 : sl := '1';

   signal timingP : sl := '0';
   signal timingN : sl := '1';

   signal gtRxOutClk  : sl                   := '0';
   signal gtRxControl : TimingPhyControlType := TIMING_PHY_CONTROL_INIT_C;
   signal gtRxStatus  : TimingPhyStatusType  := TIMING_PHY_STATUS_INIT_C;
   signal gtRxData    : slv(15 downto 0)     := x"BCBC";
   signal gtRxDataK   : slv(1 downto 0)      := "11";
   signal gtRxDispErr : slv(1 downto 0)      := "00";
   signal gtRxDecErr  : slv(1 downto 0)      := "00";

   signal gtTxOutClk  : sl                   := '0';
   signal gtTxControl : TimingPhyControlType := TIMING_PHY_CONTROL_INIT_C;
   signal gtTxStatus  : TimingPhyStatusType  := TIMING_PHY_STATUS_INIT_C;
   signal gtTxData    : slv(15 downto 0)     := x"BCBC";
   signal gtTxDataK   : slv(1 downto 0)      := "11";

   signal mmcmLocked : sl := '0';

begin

   U_axilClk : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 6.4 ns,   -- 156.25 MHz
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => axilClk,
         rst  => axilRst);

   U_stableClk : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => 2)
      port map (
         I   => axilClk,
         CE  => '1',
         CLR => '0',
         O   => stableClk);

   U_stableRst : entity surf.RstSync
      port map (
         clk      => stableClk,
         asyncRst => axilRst,
         syncRst  => stableRst);

   mmcmLocked <= not(stableRst);

   U_refClk : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 4 ns,     -- 250 MHz
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => refClk,
         rst  => open);

   U_refClkDiv2 : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => 2)
      port map (
         I   => refClk,
         CE  => '1',
         CLR => '0',
         O   => refClkDiv2);

   U_GTY : entity lcls_timing_core.TimingGtCoreWrapper
      generic map (
         TPD_G            => 1 ns,
         EXTREF_G         => false,
         AXI_CLK_FREQ_G   => 156.25E+6,
         AXIL_BASE_ADDR_G => x"00000000",
         GTY_DRP_OFFSET_G => x"00001000")
      port map (
         -- AXI-Lite Port
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         stableClk       => stableClk,
         stableRst       => stableRst,
         -- GTH FPGA IO
         gtRefClk        => '0',          -- Using GTGREFCLK instead
         gtRefClkDiv2    => refClkDiv2,
         gtRxP           => timingP,
         gtRxN           => timingN,
         gtTxP           => timingP,
         gtTxN           => timingN,
         -- GTGREFCLK Interface Option
         gtgRefClk       => refClk,
         cpllRefClkSel   => "111",
         -- Rx ports
         rxControl       => gtRxControl,
         rxStatus        => gtRxStatus,
         rxUsrClkActive  => mmcmLocked,
         rxUsrClk        => gtRxOutClk,
         rxData          => gtRxData,
         rxDataK         => gtRxDataK,
         rxDispErr       => gtRxDispErr,
         rxDecErr        => gtRxDecErr,
         rxOutClk        => gtRxOutClk,
         -- Tx Ports
         txControl       => gtTxControl,  --temTimingTxPhy.control,
         txStatus        => gtTxStatus,
         txUsrClk        => gtTxOutClk,
         txUsrClkActive  => mmcmLocked,
         txData          => gtTxData,
         txDataK         => gtTxDataK,
         txOutClk        => gtTxOutClk,
         -- Misc.
         loopback        => "000");

end testbed;
