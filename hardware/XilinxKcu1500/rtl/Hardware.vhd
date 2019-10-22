-------------------------------------------------------------------------------
-- File       : Hardware.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Hardware File
-------------------------------------------------------------------------------
-- This file is part of 'Camera link gateway'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'Camera link gateway', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

-- surf
use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;

-- timing-core
use work.TimingPkg.all;

-- l2si-core
use work.L2SiPkg.all;


entity Hardware is
   generic (
      TPD_G                          : time                        := 1 ns;
      ROGUE_SIM_EN_G                 : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G           : natural range 1024 to 49151 := 7000;
      DMA_AXIS_CONFIG_G              : AxiStreamConfigType;
      PGP_TYPE_G                     : boolean                     := false;      -- False: PGPv2b@3.125Gb/s, True: PGPv3@10.3125Gb/s, 
      AXIL_CLK_FREQ_G                : real                        := 156.25E+6;  -- units of Hz
      AXI_BASE_ADDR_G                : slv(31 downto 0)            := x"0080_0000";
      NUM_PGP_LANES_G                : integer range 1 to 4        := 4;
      L1_CLK_IS_TIMING_TX_CLK_G      : boolean                     := false;
      TRIGGER_CLK_IS_TIMING_RX_CLK_G : boolean                     := false;
      EVENT_CLK_IS_TIMING_RX_CLK_G   : boolean                     := false);
   port (
      ------------------------      
      --  Top Level Interfaces
      ------------------------    
      -- Reference Clock and Reset
      userClk25           : in  sl;
      userRst25           : in  sl;
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
      l1Clk               : in  sl                                    := '0';
      l1Rst               : in  sl                                    := '0';
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
      --  Hardware Ports
      ---------------------    
      -- QSFP[0] Ports
      qsfp0RefClkP        : in  slv(1 downto 0);
      qsfp0RefClkN        : in  slv(1 downto 0);
      qsfp0RxP            : in  slv(3 downto 0);
      qsfp0RxN            : in  slv(3 downto 0);
      qsfp0TxP            : out slv(3 downto 0);
      qsfp0TxN            : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP        : in  slv(1 downto 0);
      qsfp1RefClkN        : in  slv(1 downto 0);
      qsfp1RxP            : in  slv(3 downto 0);
      qsfp1RxN            : in  slv(3 downto 0);
      qsfp1TxP            : out slv(3 downto 0);
      qsfp1TxN            : out slv(3 downto 0));
end Hardware;

architecture mapping of Hardware is

   constant NUM_AXIL_MASTERS_C : positive := 5;

   constant PGP_INDEX_C    : natural := 0;
   constant TIMING_INDEX_C : natural := 4;

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
      TIMING_INDEX_C  => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0010_0000"),
         addrBits     => 20,
         connectivity => x"FFFF"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal qpllLock   : Slv2Array(3 downto 0);
   signal qpllClk    : Slv2Array(3 downto 0);
   signal qpllRefclk : Slv2Array(3 downto 0);
   signal qpllRst    : Slv2Array(3 downto 0);

   signal refClk    : slv(3 downto 0);
   signal refClkDiv : slv(3 downto 0);

   signal iTriggerData   : TriggerEventDataArray(NUM_PGP_LANES_G-1 downto 0);
   signal remoteTriggers : slv(NUM_PGP_LANES_G-1 downto 0);

   attribute dont_touch              : string;
   attribute dont_touch of refClk    : signal is "TRUE";
   attribute dont_touch of refClkDiv : signal is "TRUE";

begin

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
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
   GEN_REFCLK :
   for i in 1 downto 0 generate

      U_QsfpRef0 : IBUFDS_GTE3
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => qsfp0RefClkP(i),
            IB    => qsfp0RefClkN(i),
            CEB   => '0',
            ODIV2 => open,
            O     => refClk((2*i)+0));

      U_QsfpRef1 : IBUFDS_GTE3
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => qsfp1RefClkP(i),
            IB    => qsfp1RefClkN(i),
            CEB   => '0',
            ODIV2 => open,
            O     => refClk((2*i)+1));

   end generate GEN_REFCLK;

   GEN_PGP3_QPLL : if (PGP_TYPE_G = true) generate
      U_QPLL : entity work.Pgp3GthUsQpll
         generic map (
            TPD_G => TPD_G)
         port map (
            -- Stable Clock and Reset
            stableClk  => axilClk,
            stableRst  => axilRst,
            -- QPLL Clocking
            pgpRefClk  => refClk(0),
            qpllLock   => qpllLock,
            qpllClk    => qpllClk,
            qpllRefclk => qpllRefclk,
            qpllRst    => qpllRst);
   end generate;

   --------------
   -- PGP Modules
   --------------
   GEN_LANE :
   for i in NUM_PGP_LANES_G-1 downto 0 generate

      GEN_PGP3 : if (PGP_TYPE_G = true) generate
         U_Lane : entity work.Kcu1500Pgp3Lane
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

      GEN_PGP2b : if (PGP_TYPE_G = false) generate
         U_Lane : entity work.Kcu1500Pgp2bLane
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
               pgpRxP          => qsfp0RxP(i),
               pgpRxN          => qsfp0RxN(i),
               pgpTxP          => qsfp0TxP(i),
               pgpTxN          => qsfp0TxN(i),
               pgpRefClk       => refClk(0),
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

   end generate GEN_LANE;

   GEN_DUMMY : if (NUM_PGP_LANES_G < 4) generate
      U_QSFP1 : entity work.Gthe3ChannelDummy
         generic map (
            TPD_G   => TPD_G,
            WIDTH_G => 4-NUM_PGP_LANES_G)
         port map (
            refClk => axilClk,
            gtRxP  => qsfp0RxP(3 downto NUM_PGP_LANES_G),
            gtRxN  => qsfp0RxN(3 downto NUM_PGP_LANES_G),
            gtTxP  => qsfp0TxP(3 downto NUM_PGP_LANES_G),
            gtTxN  => qsfp0TxN(3 downto NUM_PGP_LANES_G));
   end generate GEN_DUMMY;

   ------------------
   -- Timing Receiver
   ------------------
   U_TimingRx : entity work.Kcu1500TimingRx
      generic map (
         TPD_G             => TPD_G,
         SIMULATION_G      => ROGUE_SIM_EN_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         AXIL_CLK_FREQ_G   => AXIL_CLK_FREQ_G,
         AXI_BASE_ADDR_G   => AXIL_CONFIG_C(TIMING_INDEX_C).baseAddr,
         NUM_DETECTORS_G   => NUM_PGP_LANES_G)
      port map (
         -- Reference Clock and Reset
         userClk25           => userClk25,
         userRst25           => userRst25,
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
         timingRxP           => qsfp1RxP(1 downto 0),
         timingRxN           => qsfp1RxN(1 downto 0),
         timingTxP           => qsfp1TxP(1 downto 0),
         timingTxN           => qsfp1TxN(1 downto 0));

   -- Feed l0 triggers directly to PGP
   TRIGGER_GEN : for i in NUM_PGP_LANES_G-1 downto 0 generate
      remoteTriggers(i) <= iTriggerData(i).valid and iTriggerData(i).l0Accept;
   end generate TRIGGER_GEN;
   triggerData <= iTriggerData;

   --------------------
   -- Unused QSFP Links
   --------------------
   U_QSFP1 : entity work.Gthe3ChannelDummy
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 2)
      port map (
         refClk => axilClk,
         gtRxP  => qsfp1RxP(3 downto 2),
         gtRxN  => qsfp1RxN(3 downto 2),
         gtTxP  => qsfp1TxP(3 downto 2),
         gtTxN  => qsfp1TxN(3 downto 2));

end mapping;
