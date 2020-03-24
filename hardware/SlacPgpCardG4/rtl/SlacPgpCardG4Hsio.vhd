-------------------------------------------------------------------------------
-- File       : SlacPgpCardG4Hsio.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: SlacPgpCardG4Hsio File
-------------------------------------------------------------------------------
-- Fiber Mapping to SlacPgpCardG4Hsio:
--    SFP[0] = LCLS-I & LCLS-II Timing Receiver
--    QSFP[0][0] = PGP.Lane[0].VC[3:0]
--    QSFP[0][1] = PGP.Lane[1].VC[3:0]
--    QSFP[0][2] = PGP.Lane[2].VC[3:0]
--    QSFP[0][3] = PGP.Lane[3].VC[3:0]
--    QSFP[1][0] = PGP.Lane[0].VC[3:0]
--    QSFP[1][1] = PGP.Lane[1].VC[3:0]
--    QSFP[1][2] = PGP.Lane[2].VC[3:0]
--    QSFP[1][3] = PGP.Lane[3].VC[3:0]
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

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library l2si_core;
use l2si_core.L2SiPkg.all;

library lcls2_pgp_fw_lib;

library unisim;
use unisim.vcomponents.all;

entity SlacPgpCardG4Hsio is
   generic (
      TPD_G                          : time                        := 1 ns;
      ROGUE_SIM_EN_G                 : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G           : natural range 1024 to 49151 := 7000;
      DMA_AXIS_CONFIG_G              : AxiStreamConfigType;
      PGP_TYPE_G                     : string                      := "PGP2b";  -- PGP2b@3.125Gb/s, PGP3@10.3125Gb/s
      AXIL_CLK_FREQ_G                : real                        := 156.25E+6;  -- units of Hz
      AXI_BASE_ADDR_G                : slv(31 downto 0)            := x"0080_0000";
      NUM_PGP_LANES_G                : integer range 1 to 8        := 8;
      L1_CLK_IS_TIMING_TX_CLK_G      : boolean                     := false;
      TRIGGER_CLK_IS_TIMING_RX_CLK_G : boolean                     := false;
      EVENT_CLK_IS_TIMING_RX_CLK_G   : boolean                     := false);
   port (
      ------------------------      
      --  Top Level Interfaces
      ------------------------    
      -- AXI-Lite Interface
      axilClk             : in  sl;
      axilRst             : in  sl;
      axilReadMaster      : in  AxiLiteReadMasterType;
      axilReadSlave       : out AxiLiteReadSlaveType;
      axilWriteMaster     : in  AxiLiteWriteMasterType;
      axilWriteSlave      : out AxiLiteWriteSlaveType;
      -- PGP Streams (axilClk domain)
      pgpIbMasters        : in  AxiStreamMasterArray(NUM_PGP_LANES_G-1 downto 0);
      pgpIbSlaves         : out AxiStreamSlaveArray(NUM_PGP_LANES_G-1 downto 0);
      pgpObMasters        : out AxiStreamQuadMasterArray(NUM_PGP_LANES_G-1 downto 0);
      pgpObSlaves         : in  AxiStreamQuadSlaveArray(NUM_PGP_LANES_G-1 downto 0);
      -- Trigger Interface
      triggerClk          : in  sl;
      triggerRst          : in  sl;
      triggerData         : out TriggerEventDataArray(NUM_PGP_LANES_G-1 downto 0);
      -- L1 trigger feedback (optional)
      l1Clk               : in  sl                                                 := '0';
      l1Rst               : in  sl                                                 := '0';
      l1Feedbacks         : in  TriggerL1FeedbackArray(NUM_PGP_LANES_G-1 downto 0) := (others => TRIGGER_L1_FEEDBACK_INIT_C);
      l1Acks              : out slv(NUM_PGP_LANES_G-1 downto 0);
      -- Event streams
      eventClk            : in  sl;
      eventRst            : in  sl;
      eventTimingMessages : out TimingMessageArray(NUM_PGP_LANES_G-1 downto 0);
      eventAxisMasters    : out AxiStreamMasterArray(NUM_PGP_LANES_G-1 downto 0);
      eventAxisSlaves     : in  AxiStreamSlaveArray(NUM_PGP_LANES_G-1 downto 0);
      eventAxisCtrl       : in  AxiStreamCtrlArray(NUM_PGP_LANES_G-1 downto 0);
      ---------------------
      --  SlacPgpCardG4Hsio Ports
      ---------------------    
      -- SFP Ports
      sfpRefClkP          : in  slv(1 downto 0);
      sfpRefClkN          : in  slv(1 downto 0);
      sfpRxP              : in  sl;
      sfpRxN              : in  sl;
      sfpTxP              : out sl;
      sfpTxN              : out sl;
      -- QSFP[1:0] Ports
      qsfpRefClkP         : in  sl;
      qsfpRefClkN         : in  sl;
      qsfp0RxP            : in  slv(3 downto 0);
      qsfp0RxN            : in  slv(3 downto 0);
      qsfp0TxP            : out slv(3 downto 0);
      qsfp0TxN            : out slv(3 downto 0);
      qsfp1RxP            : in  slv(3 downto 0);
      qsfp1RxN            : in  slv(3 downto 0);
      qsfp1TxP            : out slv(3 downto 0);
      qsfp1TxN            : out slv(3 downto 0));
end SlacPgpCardG4Hsio;

architecture mapping of SlacPgpCardG4Hsio is

   constant NUM_AXIL_MASTERS_C : positive := 9;

   constant PGP_INDEX_C    : natural := 0;
   constant TIMING_INDEX_C : natural := 8;

   -- 22 Bits available
   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      PGP_INDEX_C+0   => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0000_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      PGP_INDEX_C+1   => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0001_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      PGP_INDEX_C+2   => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0002_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      PGP_INDEX_C+3   => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0003_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      PGP_INDEX_C+4   => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0004_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      PGP_INDEX_C+5   => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0005_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      PGP_INDEX_C+6   => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0006_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      PGP_INDEX_C+7   => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0007_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      TIMING_INDEX_C  => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0010_0000"),
         addrBits     => 20,
         connectivity => x"FFFF"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal qpllLock   : Slv2Array(7 downto 0);
   signal qpllClk    : Slv2Array(7 downto 0);
   signal qpllRefclk : Slv2Array(7 downto 0);
   signal qpllRst    : Slv2Array(7 downto 0);

   signal refClk : sl;

   signal iTriggerData       : TriggerEventDataArray(NUM_PGP_LANES_G-1 downto 0);
   signal remoteTriggersComb : slv(NUM_PGP_LANES_G-1 downto 0);
   signal remoteTriggers     : slv(NUM_PGP_LANES_G-1 downto 0);
   signal triggerCodes       : slv8Array(NUM_PGP_LANES_G-1 downto 0);

begin

   assert ((PGP_TYPE_G = "PGP2b") or (PGP_TYPE_G = "PGP3"))
      report "PGP_TYPE_G must be either PGP2b or PGP3" severity failure;

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

   ------------------------
   -- GT Clocking
   ------------------------
   U_QsfpRef : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => qsfpRefClkP,
         IB    => qsfpRefClkN,
         CEB   => '0',
         ODIV2 => open,
         O     => refClk);

   GEN_PGP3_QPLL : if (PGP_TYPE_G = "PGP3") generate
      GEN_QUAD :
      for i in 1 downto 0 generate
         U_QPLL : entity surf.Pgp3GthUsQpll
            generic map (
               TPD_G => TPD_G)
            port map (
               -- Stable Clock and Reset
               stableClk  => axilClk,
               stableRst  => axilRst,
               -- QPLL Clocking
               pgpRefClk  => refClk,
               qpllLock   => qpllLock(4*i+3 downto 4*i),
               qpllClk    => qpllClk(4*i+3 downto 4*i),
               qpllRefclk => qpllRefclk(4*i+3 downto 4*i),
               qpllRst    => qpllRst(4*i+3 downto 4*i));
      end generate GEN_QUAD;
   end generate;

   --------------
   -- PGP Modules
   --------------
   GEN_LANE :
   for i in NUM_PGP_LANES_G-1 downto 0 generate

      QUAD_A : if (i <= 3) generate

         GEN_PGP3 : if (PGP_TYPE_G = "PGP3") generate
            U_Lane : entity lcls2_pgp_fw_lib.Pgp3Lane
               generic map (
                  TPD_G                => TPD_G,
                  ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
                  ROGUE_SIM_PORT_NUM_G => (ROGUE_SIM_PORT_NUM_G + i*34),
                  DMA_AXIS_CONFIG_G    => DMA_AXIS_CONFIG_G,
                  AXIL_CLK_FREQ_G      => AXIL_CLK_FREQ_G,
                  AXI_BASE_ADDR_G      => AXIL_CONFIG_C(i).baseAddr)
               port map (
                  -- Trigger Interface
                  trigger         => remoteTriggers(i),
                  triggerCode     => triggerCodes(i),
                  -- QPLL Interface
                  qpllLock        => qpllLock(i),
                  qpllClk         => qpllClk(i),
                  qpllRefclk      => qpllRefclk(i),
                  qpllRst         => qpllRst(i),
                  -- PGP Serial Ports
                  pgpRxP          => qsfp0RxP(i),
                  pgpRxN          => qsfp0RxN(i),
                  pgpTxP          => qsfp0TxP(i),
                  pgpTxN          => qsfp0TxN(i),
                  -- Streaming Interface (axilClk domain)
                  pgpIbMaster     => pgpIbMasters(i),
                  pgpIbSlave      => pgpIbSlaves(i),
                  pgpObMasters    => pgpObMasters(i),
                  pgpObSlaves     => pgpObSlaves(i),
                  -- AXI-Lite Interface (axilClk domain)
                  axilClk         => axilClk,
                  axilRst         => axilRst,
                  axilReadMaster  => axilReadMasters(i),
                  axilReadSlave   => axilReadSlaves(i),
                  axilWriteMaster => axilWriteMasters(i),
                  axilWriteSlave  => axilWriteSlaves(i));
         end generate;

         GEN_PGP2b : if (PGP_TYPE_G = "PGP2b") generate
            U_Lane : entity lcls2_pgp_fw_lib.Pgp2bLane
               generic map (
                  TPD_G                => TPD_G,
                  ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
                  ROGUE_SIM_PORT_NUM_G => (ROGUE_SIM_PORT_NUM_G + i*34),
                  DMA_AXIS_CONFIG_G    => DMA_AXIS_CONFIG_G,
                  AXIL_CLK_FREQ_G      => AXIL_CLK_FREQ_G,
                  AXI_BASE_ADDR_G      => AXIL_CONFIG_C(i).baseAddr)
               port map (
                  -- Trigger Interface
                  trigger         => remoteTriggers(i),
                  triggerCode     => triggerCodes(i),
                  -- PGP Serial Ports
                  pgpRxP          => qsfp0RxP(i),
                  pgpRxN          => qsfp0RxN(i),
                  pgpTxP          => qsfp0TxP(i),
                  pgpTxN          => qsfp0TxN(i),
                  pgpRefClk       => refClk,
                  -- Streaming Interface (axilClk domain)
                  pgpIbMaster     => pgpIbMasters(i),
                  pgpIbSlave      => pgpIbSlaves(i),
                  pgpObMasters    => pgpObMasters(i),
                  pgpObSlaves     => pgpObSlaves(i),
                  -- AXI-Lite Interface (axilClk domain)
                  axilClk         => axilClk,
                  axilRst         => axilRst,
                  axilReadMaster  => axilReadMasters(i),
                  axilReadSlave   => axilReadSlaves(i),
                  axilWriteMaster => axilWriteMasters(i),
                  axilWriteSlave  => axilWriteSlaves(i));
         end generate;

      end generate QUAD_A;

      QUAD_B : if (i >= 4) generate

         GEN_PGP3 : if (PGP_TYPE_G = "PGP3") generate
            U_Lane : entity lcls2_pgp_fw_lib.Pgp3Lane
               generic map (
                  TPD_G                => TPD_G,
                  ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
                  ROGUE_SIM_PORT_NUM_G => (ROGUE_SIM_PORT_NUM_G + i*34),
                  DMA_AXIS_CONFIG_G    => DMA_AXIS_CONFIG_G,
                  AXIL_CLK_FREQ_G      => AXIL_CLK_FREQ_G,
                  AXI_BASE_ADDR_G      => AXIL_CONFIG_C(i).baseAddr)
               port map (
                  -- Trigger Interface
                  trigger         => remoteTriggers(i),
                  -- QPLL Interface
                  qpllLock        => qpllLock(i),
                  qpllClk         => qpllClk(i),
                  qpllRefclk      => qpllRefclk(i),
                  qpllRst         => qpllRst(i),
                  -- PGP Serial Ports
                  pgpRxP          => qsfp1RxP(i-4),
                  pgpRxN          => qsfp1RxN(i-4),
                  pgpTxP          => qsfp1TxP(i-4),
                  pgpTxN          => qsfp1TxN(i-4),
                  -- Streaming Interface (axilClk domain)
                  pgpIbMaster     => pgpIbMasters(i),
                  pgpIbSlave      => pgpIbSlaves(i),
                  pgpObMasters    => pgpObMasters(i),
                  pgpObSlaves     => pgpObSlaves(i),
                  -- AXI-Lite Interface (axilClk domain)
                  axilClk         => axilClk,
                  axilRst         => axilRst,
                  axilReadMaster  => axilReadMasters(i),
                  axilReadSlave   => axilReadSlaves(i),
                  axilWriteMaster => axilWriteMasters(i),
                  axilWriteSlave  => axilWriteSlaves(i));
         end generate;

         GEN_PGP2b : if (PGP_TYPE_G = "PGP2b") generate
            U_Lane : entity lcls2_pgp_fw_lib.Pgp2bLane
               generic map (
                  TPD_G                => TPD_G,
                  ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
                  ROGUE_SIM_PORT_NUM_G => (ROGUE_SIM_PORT_NUM_G + i*34),
                  DMA_AXIS_CONFIG_G    => DMA_AXIS_CONFIG_G,
                  AXIL_CLK_FREQ_G      => AXIL_CLK_FREQ_G,
                  AXI_BASE_ADDR_G      => AXIL_CONFIG_C(i).baseAddr)
               port map (
                  -- Trigger Interface
                  trigger         => remoteTriggers(i),
                  -- PGP Serial Ports
                  pgpRxP          => qsfp1RxP(i-4),
                  pgpRxN          => qsfp1RxN(i-4),
                  pgpTxP          => qsfp1TxP(i-4),
                  pgpTxN          => qsfp1TxN(i-4),
                  pgpRefClk       => refClk,
                  -- Streaming Interface (axilClk domain)
                  pgpIbMaster     => pgpIbMasters(i),
                  pgpIbSlave      => pgpIbSlaves(i),
                  pgpObMasters    => pgpObMasters(i),
                  pgpObSlaves     => pgpObSlaves(i),
                  -- AXI-Lite Interface (axilClk domain)
                  axilClk         => axilClk,
                  axilRst         => axilRst,
                  axilReadMaster  => axilReadMasters(i),
                  axilReadSlave   => axilReadSlaves(i),
                  axilWriteMaster => axilWriteMasters(i),
                  axilWriteSlave  => axilWriteSlaves(i));
         end generate;

      end generate QUAD_B;

   end generate GEN_LANE;

   ------------------
   -- Timing Receiver
   ------------------
   U_TimingRx : entity lcls2_pgp_fw_lib.SlacPgpCardG4TimingRx
      generic map (
         TPD_G             => TPD_G,
         SIMULATION_G      => ROGUE_SIM_EN_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         AXIL_CLK_FREQ_G   => AXIL_CLK_FREQ_G,
         AXI_BASE_ADDR_G   => AXIL_CONFIG_C(TIMING_INDEX_C).baseAddr,
         NUM_DETECTORS_G   => NUM_PGP_LANES_G)
      port map (
         -- Trigger / event interfaces
         triggerClk          => triggerClk,           -- [in]
         triggerRst          => triggerRst,           -- [in]
         triggerData         => iTriggerData,         -- [out]
         l1Clk               => l1Clk,                -- [in]
         l1Rst               => l1Rst,                -- [in]  
         l1Feedbacks         => l1Feedbacks,          -- [in]  
         l1Acks              => l1Acks,               -- [out] 
         eventClk            => eventClk,             -- [in]
         eventRst            => eventRst,             -- [in]
         eventTimingMessages => eventTimingMessages,  -- [out]
         eventAxisMasters    => eventAxisMasters,     -- [out]
         eventAxisSlaves     => eventAxisSlaves,      -- [in]
         eventAxisCtrl       => eventAxisCtrl,        -- [in]
         -- AXI-Lite Interface (axilClk domain)
         axilClk             => axilClk,
         axilRst             => axilRst,
         axilReadMaster      => axilReadMasters(TIMING_INDEX_C),
         axilReadSlave       => axilReadSlaves(TIMING_INDEX_C),
         axilWriteMaster     => axilWriteMasters(TIMING_INDEX_C),
         axilWriteSlave      => axilWriteSlaves(TIMING_INDEX_C),
         -- GT Serial Ports
         refClkP             => sfpRefClkP,
         refClkN             => sfpRefClkN,
         timingRxP           => sfpRxP,
         timingRxN           => sfpRxN,
         timingTxP           => sfpTxP,
         timingTxN           => sfpTxN);

   -- Feed triggers directly to PGP
   TRIGGER_GEN : for i in NUM_PGP_LANES_G-1 downto 0 generate
      remoteTriggersComb(i) <= iTriggerData(i).valid and iTriggerData(i).l0Accept;
      trigerCodes(i)        <= "000" & iTriggerData(i).l0Tag;
   end generate TRIGGER_GEN;
   U_RegisterVector_1 : entity surf.RegisterVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => NUM_PGP_LANES_G)
      port map (
         clk   => triggerClk,           -- [in]
         sig_i => remoteTriggersComb,   -- [in]
         reg_o => remoteTriggers);      -- [out]

   triggerData <= iTriggerData;

end mapping;
