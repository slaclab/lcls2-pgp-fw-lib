-------------------------------------------------------------------------------
-- File       : Pgp4Lane.vhd
-- Company    : SLAC National Accelerator Laboratory
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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp4Pkg.all;

library lcls2_pgp_fw_lib;

entity Pgp4Lane is
   generic (
      TPD_G                : time                        := 1 ns;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 7000;
      RATE_G               : string                      := "10.3125Gbps";  -- or "6.25Gbps" or "3.125Gbps"
      DMA_AXIS_CONFIG_G    : AxiStreamConfigType;
      AXIL_CLK_FREQ_G      : real                        := 156.25E+6;  -- units of Hz
      AXI_BASE_ADDR_G      : slv(31 downto 0)            := (others => '0'));
   port (
      -- Trigger Interface
      trigger         : in  sl;
      triggerCode     : in  slv(7 downto 0);
      -- QPLL Interface
      qpllLock        : in  slv(1 downto 0);
      qpllClk         : in  slv(1 downto 0);
      qpllRefclk      : in  slv(1 downto 0);
      qpllRst         : out slv(1 downto 0);
      -- PGP Serial Ports
      pgpTxP          : out sl;
      pgpTxN          : out sl;
      pgpRxP          : in  sl;
      pgpRxN          : in  sl;
      -- Streaming Interface (axilClk domain)
      pgpIbMaster     : in  AxiStreamMasterType;
      pgpIbSlave      : out AxiStreamSlaveType;
      pgpObMasters    : out AxiStreamQuadMasterType;
      pgpObSlaves     : in  AxiStreamQuadSlaveType;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end Pgp4Lane;

architecture mapping of Pgp4Lane is

   constant AXIS_CLK_FREQ_C : real :=
      ite(RATE_G = "10.3125Gbps", (10.3125E+9/66.0),
          ite(RATE_G = "6.25Gbps", (6.25E+9/66.0),
              (3.125E+9/66.0)));        -- RATE_G="3.125Gbps"

   constant PGP_CORE_INDEX_C   : natural := 0;
   constant RX_MON_INDEX_C     : natural := 1;
   constant TX_MON_INDEX_C     : natural := 2;
   constant NUM_AXIL_MASTERS_C : natural := 3;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_G, 16, 13);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal pgpClk : sl;
   signal pgpRst : sl;
   signal wdtRst : sl;

   signal pgpTxIn      : Pgp4TxInType := PGP4_TX_IN_INIT_C;
   signal pgpTxOut     : Pgp4TxOutType;
   signal pgpTxMasters : AxiStreamMasterArray(3 downto 0);
   signal pgpTxSlaves  : AxiStreamSlaveArray(3 downto 0);

   signal pgpRxIn      : Pgp4RxInType := PGP4_RX_IN_INIT_C;
   signal pgpRxOut     : Pgp4RxOutType;
   signal pgpRxMasters : AxiStreamMasterArray(3 downto 0);
   signal pgpRxCtrl    : AxiStreamCtrlArray(3 downto 0);
   signal pgpRxSlaves  : AxiStreamSlaveArray(3 downto 0);

begin

   U_Trig : entity surf.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => pgpClk,
         dataIn  => trigger,
         dataOut => pgpTxIn.opCodeEn);

   U_TrigCode : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 8)
      port map (
         clk     => pgpClk,
         dataIn  => triggerCode,
         dataOut => pgpTxIn.opCodeData(7 downto 0));

   U_Wtd : entity surf.WatchDogRst
      generic map(
         TPD_G      => TPD_G,
         DURATION_G => getTimeRatio(AXIL_CLK_FREQ_G, 0.2))  -- 5 s timeout
      port map (
         clk    => axilClk,
         monIn  => pgpRxOut.remRxLinkReady,
         rstOut => wdtRst);

   U_PwrUpRst : entity surf.PwrUpRst
      generic map (
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => ROGUE_SIM_EN_G,
         DURATION_G    => getTimeRatio(AXIL_CLK_FREQ_G, 10.0))  -- 100 ms reset pulse
      port map (
         clk    => axilClk,
         arst   => wdtRst,
         rstOut => pgpRxIn.resetRx);

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   -----------
   -- PGP Core
   -----------
   REAL_PGP : if (not ROGUE_SIM_EN_G) generate
      U_Pgp : entity surf.Pgp4GtyUs
         generic map (
            TPD_G              => TPD_G,
            RATE_G             => RATE_G,
            EN_PGP_MON_G       => true,
            NUM_VC_G           => 4,
            STATUS_CNT_WIDTH_G => 12,
            ERROR_CNT_WIDTH_G  => 8,
            AXIL_CLK_FREQ_G    => AXIL_CLK_FREQ_G,
            AXIL_BASE_ADDR_G   => AXIL_CONFIG_C(0).baseAddr)
         port map (
            -- Stable Clock and Reset
            stableClk       => axilClk,
            stableRst       => axilRst,
            -- QPLL Interface
            qpllLock        => qpllLock,
            qpllClk         => qpllClk,
            qpllRefclk      => qpllRefclk,
            qpllRst         => qpllRst,
            -- Gt Serial IO
            pgpGtTxP        => pgpTxP,
            pgpGtTxN        => pgpTxN,
            pgpGtRxP        => pgpRxP,
            pgpGtRxN        => pgpRxN,
            -- Clocking
            pgpClk          => pgpClk,
            pgpClkRst       => pgpRst,
            -- Non VC Rx Signals
            pgpRxIn         => pgpRxIn,
            pgpRxOut        => pgpRxOut,
            -- Non VC Tx Signals
            pgpTxIn         => pgpTxIn,
            pgpTxOut        => pgpTxOut,
            -- Frame Transmit Interface
            pgpTxMasters    => pgpTxMasters,
            pgpTxSlaves     => pgpTxSlaves,
            -- Frame Receive Interface
            pgpRxMasters    => pgpRxMasters,
            pgpRxCtrl       => pgpRxCtrl,
            -- AXI-Lite Register Interface (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(PGP_CORE_INDEX_C),
            axilReadSlave   => axilReadSlaves(PGP_CORE_INDEX_C),
            axilWriteMaster => axilWriteMasters(PGP_CORE_INDEX_C),
            axilWriteSlave  => axilWriteSlaves(PGP_CORE_INDEX_C));
   end generate REAL_PGP;

   SIM_PGP : if (ROGUE_SIM_EN_G) generate

      U_Rogue : entity surf.RoguePgp4Sim
         generic map(
            TPD_G      => TPD_G,
            PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
            NUM_VC_G   => 4)
         port map(
            -- GT Ports
            pgpRefClk       => axilClk,
            pgpGtTxP        => pgpTxP,
            pgpGtTxN        => pgpTxN,
            pgpGtRxP        => pgpRxP,
            pgpGtRxN        => pgpRxN,
            -- PGP Clock and Reset
            pgpClk          => pgpClk,
            pgpClkRst       => pgpRst,
            -- Non VC Rx Signals
            pgpRxIn         => pgpRxIn,
            pgpRxOut        => pgpRxOut,
            -- Non VC Tx Signals
            pgpTxIn         => pgpTxIn,
            pgpTxOut        => pgpTxOut,
            -- Frame Transmit Interface
            pgpTxMasters    => pgpTxMasters,
            pgpTxSlaves     => pgpTxSlaves,
            -- Frame Receive Interface
            pgpRxMasters    => pgpRxMasters,
            pgpRxSlaves     => pgpRxSlaves,
            -- AXI-Lite Register Interface (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(PGP_CORE_INDEX_C),
            axilReadSlave   => axilReadSlaves(PGP_CORE_INDEX_C),
            axilWriteMaster => axilWriteMasters(PGP_CORE_INDEX_C),
            axilWriteSlave  => axilWriteSlaves(PGP_CORE_INDEX_C));

   end generate SIM_PGP;

   -----------------------------
   -- Monitor the PGP RX streams
   -----------------------------
   U_AXIS_RX_MON : entity surf.AxiStreamMonAxiL
      generic map(
         TPD_G            => TPD_G,
         COMMON_CLK_G     => false,
         AXIS_CLK_FREQ_G  => AXIS_CLK_FREQ_C,
         AXIS_NUM_SLOTS_G => 4,
         AXIS_CONFIG_G    => PGP4_AXIS_CONFIG_C)
      port map(
         -- AXIS Stream Interface
         axisClk          => pgpClk,
         axisRst          => pgpRst,
         axisMasters      => pgpRxMasters,
         axisSlaves       => (others => AXI_STREAM_SLAVE_FORCE_C),  -- SLAVE_READY_EN_G=false
         -- AXI lite slave port for register access
         axilClk          => axilClk,
         axilRst          => axilRst,
         sAxilWriteMaster => axilWriteMasters(RX_MON_INDEX_C),
         sAxilWriteSlave  => axilWriteSlaves(RX_MON_INDEX_C),
         sAxilReadMaster  => axilReadMasters(RX_MON_INDEX_C),
         sAxilReadSlave   => axilReadSlaves(RX_MON_INDEX_C));

   -----------------------------
   -- Monitor the PGP TX streams
   -----------------------------
   U_AXIS_TX_MON : entity surf.AxiStreamMonAxiL
      generic map(
         TPD_G            => TPD_G,
         COMMON_CLK_G     => false,
         AXIS_CLK_FREQ_G  => AXIS_CLK_FREQ_C,
         AXIS_NUM_SLOTS_G => 4,
         AXIS_CONFIG_G    => PGP4_AXIS_CONFIG_C)
      port map(
         -- AXIS Stream Interface
         axisClk          => pgpClk,
         axisRst          => pgpRst,
         axisMasters      => pgpTxMasters,
         axisSlaves       => pgpTxSlaves,
         -- AXI lite slave port for register access
         axilClk          => axilClk,
         axilRst          => axilRst,
         sAxilWriteMaster => axilWriteMasters(TX_MON_INDEX_C),
         sAxilWriteSlave  => axilWriteSlaves(TX_MON_INDEX_C),
         sAxilReadMaster  => axilReadMasters(TX_MON_INDEX_C),
         sAxilReadSlave   => axilReadSlaves(TX_MON_INDEX_C));

   --------------
   -- PGP TX Path
   --------------
   U_Tx : entity lcls2_pgp_fw_lib.PgpLaneTx
      generic map (
         TPD_G            => TPD_G,
         APP_AXI_CONFIG_G => DMA_AXIS_CONFIG_G,
         PHY_AXI_CONFIG_G => PGP4_AXIS_CONFIG_C)
      port map (
         -- AXIS Interface (axisClk domain)
         axisClk      => axilClk,
         axisRst      => axilRst,
         sAxisMaster  => pgpIbMaster,
         sAxisSlave   => pgpIbSlave,
         -- PGP Interface
         pgpClk       => pgpClk,
         pgpRst       => pgpRst,
         rxlinkReady  => pgpRxOut.linkReady,
         txlinkReady  => pgpTxOut.linkReady,
         pgpTxMasters => pgpTxMasters,
         pgpTxSlaves  => pgpTxSlaves);

   --------------
   -- PGP RX Path
   --------------
   U_Rx : entity lcls2_pgp_fw_lib.PgpLaneRx
      generic map (
         TPD_G            => TPD_G,
         ROGUE_SIM_EN_G   => ROGUE_SIM_EN_G,
         APP_AXI_CONFIG_G => DMA_AXIS_CONFIG_G,
         PHY_AXI_CONFIG_G => PGP4_AXIS_CONFIG_C)
      port map (
         -- AXIS Interface (axisClk domain)
         axisClk      => axilClk,
         axisRst      => axilRst,
         mAxisMasters => pgpObMasters,
         mAxisSlaves  => pgpObSlaves,
         -- PGP RX Interface (pgpRxClk domain)
         pgpClk       => pgpClk,
         pgpRst       => pgpRst,
         rxlinkReady  => pgpRxOut.linkReady,
         pgpRxMasters => pgpRxMasters,
         pgpRxCtrl    => pgpRxCtrl,
         pgpRxSlaves  => pgpRxSlaves);

end mapping;
