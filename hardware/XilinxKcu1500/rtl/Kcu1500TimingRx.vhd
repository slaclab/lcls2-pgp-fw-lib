-------------------------------------------------------------------------------
-- File       : Kcu1500TimingRx.vhd
-- Company    : SLAC National Accelerator Laboratory
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.TimingPkg.all;

library unisim;
use unisim.vcomponents.all;

entity Kcu1500TimingRx is
   generic (
      TPD_G             : time    := 1 ns;
      SIMULATION_G      : boolean := false;
      AXIL_CLK_FREQ_G   : real    := 156.25E+6;  -- units of Hz
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXI_BASE_ADDR_G   : slv(31 downto 0));
   port (
      -- Trigger Interface (axilClk domain)
      triggers        : out slv(3 downto 0);
      trigMasters     : out AxiStreamMasterArray(3 downto 0);
      trigSlaves      : in  AxiStreamSlaveArray(3 downto 0);
      -- Reference Clock and Reset
      userClk25       : in  sl;
      userRst25       : in  sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- GT Serial Ports
      timingRxP       : in  slv(1 downto 0);
      timingRxN       : in  slv(1 downto 0);
      timingTxP       : out slv(1 downto 0);
      timingTxN       : out slv(1 downto 0));
end Kcu1500TimingRx;

architecture mapping of Kcu1500TimingRx is

   constant NUM_AXIL_MASTERS_C : positive := 5;

   constant RX_PHY0_INDEX_C : natural := 0;
   constant RX_PHY1_INDEX_C : natural := 1;
   constant MON_INDEX_C     : natural := 2;
   constant TRIG_INDEX_C    : natural := 3;
   constant TIMING_INDEX_C  : natural := 4;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      RX_PHY0_INDEX_C => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0000_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      RX_PHY1_INDEX_C => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0001_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      MON_INDEX_C     => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0002_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      TRIG_INDEX_C    => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0003_0000"),
         addrBits     => 16,
         connectivity => x"FFFF"),
      TIMING_INDEX_C  => (
         baseAddr     => (AXI_BASE_ADDR_G+x"0008_0000"),
         addrBits     => 18,
         connectivity => x"FFFF"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal initReadMaster  : AxiLiteReadMasterType;
   signal initReadSlave   : AxiLiteReadSlaveType;
   signal initWriteMaster : AxiLiteWriteMasterType;
   signal initWriteSlave  : AxiLiteWriteSlaveType;

   signal mmcmRst      : sl;
   signal refClk       : slv(1 downto 0);
   signal refClkDiv2   : slv(1 downto 0);
   signal refRst       : slv(1 downto 0);
   signal refRstDiv2   : slv(1 downto 0);
   signal mmcmLocked   : slv(1 downto 0);
   signal timingClkSel : sl;
   signal useMiniTpg   : sl;
   signal loopback     : slv(2 downto 0);

   signal rxUserRst   : sl;
   signal gtRxClk     : slv(1 downto 0);
   signal gtRxClock   : slv(1 downto 0);
   signal rxClk       : sl;
   signal rxRst       : sl;
   signal gtRxData    : Slv16Array(1 downto 0);
   signal rxData      : slv(15 downto 0);
   signal gtRxDataK   : Slv2Array(1 downto 0);
   signal rxDataK     : slv(1 downto 0);
   signal gtRxDispErr : Slv2Array(1 downto 0);
   signal rxDispErr   : slv(1 downto 0);
   signal gtRxDecErr  : Slv2Array(1 downto 0);
   signal rxDecErr    : slv(1 downto 0);
   signal gtRxStatus  : TimingPhyStatusArray(1 downto 0);
   signal rxStatus    : TimingPhyStatusType;
   signal rxCtrl      : TimingPhyControlType;
   signal rxControl   : TimingPhyControlType;

   signal txUserRst  : sl;
   signal gtTxClk    : slv(1 downto 0);
   signal txClk      : sl;
   signal txRst      : sl;
   signal txData     : slv(15 downto 0);
   signal txDataK    : slv(1 downto 0);
   signal txStatus   : TimingPhyStatusType := TIMING_PHY_STATUS_FORCE_C;
   signal gtTxStatus : TimingPhyStatusArray(1 downto 0);

   signal timingPhy     : TimingPhyType;
   signal appTimingBus  : TimingBusType;
   signal appTimingTrig : TimingTrigType;
   signal appTimingMode : sl;

   signal appTrigMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal appTrigCtrl    : AxiStreamCtrlArray(3 downto 0);
   signal trigMon        : slv(3 downto 0);
   signal trigDrop       : slv(3 downto 0);

   signal txMasters : AxiStreamMasterArray(3 downto 0);
   signal txSlaves  : AxiStreamSlaveArray(3 downto 0);

begin

   txStatus <= TIMING_PHY_STATUS_FORCE_C;
   txRst    <= txUserRst;
   rxRst    <= rxUserRst;

   -------------------------   
   -- Reference LCLS-I Clock
   -------------------------   
   U_238MHz : entity work.ClockManagerUltraScale
      generic map(
         TPD_G              => TPD_G,
         SIMULATION_G       => SIMULATION_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 1,
         -- MMCM attributes
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 40.0,    -- 25 MHz
         DIVCLK_DIVIDE_G    => 1,       -- 25 MHz = 25MHz/1
         CLKFBOUT_MULT_F_G  => 29.750,  -- 743.75 MHz = 25 MHz x 29.75
         CLKOUT0_DIVIDE_F_G => 3.125)   -- 238 MHz = 743.75 MHz/3.125
      port map(
         -- Clock Input
         clkIn     => userClk25,
         rstIn     => mmcmRst,
         -- Clock Outputs
         clkOut(0) => refClk(0),
         -- Reset Outputs
         rstOut(0) => refRst(0),
         -- Locked Status
         locked    => mmcmLocked(0));

   -------------------------   
   -- Reference LCLS-I Clock
   -------------------------           
   U_371MHz : entity work.ClockManagerUltraScale
      generic map(
         TPD_G              => TPD_G,
         SIMULATION_G       => SIMULATION_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 1,
         -- MMCM attributes
         BANDWIDTH_G        => "HIGH",
         CLKIN_PERIOD_G     => 40.0,    -- 25 MHz
         DIVCLK_DIVIDE_G    => 1,       -- 25 MHz = 25MHz/1
         CLKFBOUT_MULT_F_G  => 52.000,  -- 1.3 GHz = 25 MHz x 52
         CLKOUT0_DIVIDE_F_G => 3.500)   -- 371.429 MHz = 1.3 GHz/3.5
      port map(
         -- Clock Input
         clkIn     => userClk25,
         rstIn     => mmcmRst,
         -- Clock Outputs
         clkOut(0) => refClk(1),
         -- Reset Outputs
         rstOut(0) => refRst(1),
         -- Locked Status
         locked    => mmcmLocked(1));

   -------------------------------------------------------
   -- Power Up Initialization of the KCU1500 Timing RX PHY
   -------------------------------------------------------
   U_TimingPhyInit : entity work.TimingPhyInit
      generic map (
         TPD_G              => TPD_G,
         SIMULATION_G       => SIMULATION_G,
         TIMING_BASE_ADDR_G => AXIL_CONFIG_C(TIMING_INDEX_C).baseAddr,
         AXIL_CLK_FREQ_G    => AXIL_CLK_FREQ_G)
      port map (
         mmcmLocked       => mmcmLocked,
         -- AXI-Lite Register Interface (sysClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
         mAxilReadMaster  => initReadMaster,
         mAxilReadSlave   => initReadSlave,
         mAxilWriteMaster => initWriteMaster,
         mAxilWriteSlave  => initWriteSlave);

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 2,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteMasters(1) => initWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiWriteSlaves(1)  => initWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadMasters(1)  => initReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         sAxiReadSlaves(1)   => initReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   -------------
   -- GTH Module
   -------------
   GEN_VEC : for i in 1 downto 0 generate

      REAL_PCIE : if (not SIMULATION_G) generate
         U_GTH : entity work.TimingGtCoreWrapper
            generic map (
               TPD_G            => TPD_G,
               EXTREF_G         => false,
               AXIL_BASE_ADDR_G => AXIL_CONFIG_C(RX_PHY0_INDEX_C+i).baseAddr,
               ADDR_BITS_G      => 12,
               GTH_DRP_OFFSET_G => x"00001000")
            port map (
               -- AXI-Lite Port
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => axilReadMasters(RX_PHY0_INDEX_C+i),
               axilReadSlave   => axilReadSlaves(RX_PHY0_INDEX_C+i),
               axilWriteMaster => axilWriteMasters(RX_PHY0_INDEX_C+i),
               axilWriteSlave  => axilWriteSlaves(RX_PHY0_INDEX_C+i),
               stableClk       => axilClk,
               stableRst       => axilRst,
               -- GTH FPGA IO
               gtRefClk        => refClk(i),
               gtRefClkDiv2    => refClkDiv2(i),
               gtRxP           => timingRxP(i),
               gtRxN           => timingRxN(i),
               gtTxP           => timingTxP(i),
               gtTxN           => timingTxN(i),
               -- Rx ports
               rxControl       => rxControl,
               rxStatus        => gtRxStatus(i),
               rxUsrClkActive  => mmcmLocked(i),
               rxUsrClk        => rxClk,
               rxData          => gtRxData(i),
               rxDataK         => gtRxDataK(i),
               rxDispErr       => gtRxDispErr(i),
               rxDecErr        => gtRxDecErr(i),
               rxOutClk        => gtRxClk(i),
               -- Tx Ports
               txControl       => timingPhy.control,
               txStatus        => gtTxStatus(i),
               txUsrClk        => txClk,
               txUsrClkActive  => mmcmLocked(i),
               txData          => timingPhy.data,
               txDataK         => timingPhy.dataK,
               txOutClk        => gtTxClk(i),
               -- Misc.
               loopback        => loopback);

         U_RXCLK : BUFGMUX
            generic map (
               CLK_SEL_TYPE => "ASYNC")  -- ASYNC, SYNC
            port map (
               O  => gtRxClock(i),       -- 1-bit output: Clock output
               I0 => gtRxClk(i),         -- 1-bit input: Clock input (S=0)
               I1 => refClkDiv2(i),      -- 1-bit input: Clock input (S=1)
               S  => useMiniTpg);        -- 1-bit input: Clock select      

      end generate;

      U_refClkDiv2 : BUFGCE_DIV
         generic map (
            BUFGCE_DIVIDE => 2)
         port map (
            I   => refClk(i),
            CE  => '1',
            CLR => '0',
            O   => refClkDiv2(i));

      U_refRstDiv2 : entity work.RstSync
         generic map (
            TPD_G => TPD_G)
         port map (
            clk      => refClkDiv2(i),
            asyncRst => refRst(i),
            syncRst  => refRstDiv2(i));

      SIM_PCIE : if (SIMULATION_G) generate

         axilReadSlaves(RX_PHY0_INDEX_C+i)  <= AXI_LITE_READ_SLAVE_EMPTY_OK_C;
         axilWriteSlaves(RX_PHY0_INDEX_C+i) <= AXI_LITE_WRITE_SLAVE_EMPTY_OK_C;

         gtRxClk(i) <= refClkDiv2(i);
         gtTxClk(i) <= refClkDiv2(i);

         gtTxStatus(i)  <= TIMING_PHY_STATUS_FORCE_C;
         gtRxStatus(i)  <= TIMING_PHY_STATUS_FORCE_C;
         gtRxData(i)    <= timingPhy.data;
         gtRxDataK(i)   <= timingPhy.dataK;
         gtRxDispErr(i) <= "00";
         gtRxDecErr(i)  <= "00";

      end generate;

   end generate GEN_VEC;

   process(gtRxData, gtRxDataK, gtRxDecErr, gtRxDispErr, gtRxStatus,
           gtTxStatus, timingClkSel, timingPhy, useMiniTpg)
   begin
      if (useMiniTpg = '1') then
         txStatus  <= TIMING_PHY_STATUS_FORCE_C;
         rxStatus  <= TIMING_PHY_STATUS_FORCE_C;
         rxData    <= timingPhy.data;
         rxDataK   <= timingPhy.dataK;
         rxDispErr <= "00";
         rxDecErr  <= "00";
      elsif (timingClkSel = '1') then
         txStatus  <= gtTxStatus(1);
         rxStatus  <= gtRxStatus(1);
         rxData    <= gtRxData(1);
         rxDataK   <= gtRxDataK(1);
         rxDispErr <= gtRxDispErr(1);
         rxDecErr  <= gtRxDecErr(1);
      else
         txStatus  <= gtTxStatus(0);
         rxStatus  <= gtRxStatus(0);
         rxData    <= gtRxData(0);
         rxDataK   <= gtRxDataK(0);
         rxDispErr <= gtRxDispErr(0);
         rxDecErr  <= gtRxDecErr(0);
      end if;
   end process;

   U_RXCLK : BUFGMUX
      generic map (
         CLK_SEL_TYPE => "ASYNC")       -- ASYNC, SYNC
      port map (
         O  => rxClk,                   -- 1-bit output: Clock output
         I0 => gtRxClock(0),            -- 1-bit input: Clock input (S=0)
         I1 => gtRxClock(1),            -- 1-bit input: Clock input (S=1)
         S  => timingClkSel);           -- 1-bit input: Clock select         

   U_TXCLK : BUFGMUX
      generic map (
         CLK_SEL_TYPE => "ASYNC")       -- ASYNC, SYNC
      port map (
         O  => txClk,                   -- 1-bit output: Clock output
         I0 => refClkDiv2(0),           -- 1-bit input: Clock input (S=0)
         I1 => refClkDiv2(1),           -- 1-bit input: Clock input (S=1)
         S  => timingClkSel);           -- 1-bit input: Clock select         

   -----------------------
   -- Insert user RX reset
   -----------------------
   rxControl.reset       <= rxCtrl.reset or rxUserRst;
   rxControl.inhibit     <= rxCtrl.inhibit;
   rxControl.polarity    <= rxCtrl.polarity;
   rxControl.bufferByRst <= rxCtrl.bufferByRst;
   rxControl.pllReset    <= rxCtrl.pllReset or rxUserRst;

   --------------
   -- Timing Core
   --------------
   U_TimingCore : entity work.TimingCore
      generic map (
         TPD_G             => TPD_G,
         DEFAULT_CLK_SEL_G => '0',  -- '0': default LCLS-I, '1': default LCLS-II
         AXIL_RINGB_G      => false,
         ASYNC_G           => true,
         AXIL_BASE_ADDR_G  => AXIL_CONFIG_C(TIMING_INDEX_C).baseAddr)
      port map (
         -- GT Interface
         gtTxUsrClk      => txClk,
         gtTxUsrRst      => txRst,
         gtRxRecClk      => rxClk,
         gtRxData        => rxData,
         gtRxDataK       => rxDataK,
         gtRxDispErr     => rxDispErr,
         gtRxDecErr      => rxDecErr,
         gtRxControl     => rxCtrl,
         gtRxStatus      => rxStatus,
         -- Decoded timing message interface
         appTimingClk    => axilClk,
         appTimingRst    => axilRst,
         appTimingMode   => appTimingMode,
         appTimingBus    => appTimingBus,
         timingPhy       => timingPhy,
         timingClkSel    => timingClkSel,
         -- AXI Lite interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(TIMING_INDEX_C),
         axilReadSlave   => axilReadSlaves(TIMING_INDEX_C),
         axilWriteMaster => axilWriteMasters(TIMING_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(TIMING_INDEX_C));

   ---------------------
   -- Timing PHY Monitor
   ---------------------
   U_Monitor : entity work.TimingPhyMonitor
      generic map (
         TPD_G           => TPD_G,
         SIMULATION_G    => SIMULATION_G,
         AXIL_CLK_FREQ_G => AXIL_CLK_FREQ_G)
      port map (
         rxUserRst       => rxUserRst,
         txUserRst       => txUserRst,
         useMiniTpg      => useMiniTpg,
         mmcmRst         => mmcmRst,
         loopback        => loopback,
         trig            => trigMon,
         trigDrop        => trigDrop,
         mmcmLocked      => mmcmLocked,
         refClk          => refClk,
         refRst          => refRst,
         txClk           => txClk,
         txRst           => txRst,
         rxClk           => rxClk,
         rxRst           => rxRst,
         -- AXI Lite interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(MON_INDEX_C),
         axilReadSlave   => axilReadSlaves(MON_INDEX_C),
         axilWriteMaster => axilWriteMasters(MON_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(MON_INDEX_C));

   ---------------------
   -- Timing PHY Monitor
   ---------------------         
   U_Trig : entity work.EvrV2CoreTriggers
      generic map (
         TPD_G           => TPD_G,
         NCHANNELS_G     => 4,
         NTRIGGERS_G     => 4,
         TRIG_DEPTH_G    => 19,         -- bitSize(125MHz/360Hz)
         TRIG_PIPE_G     => 0,
         COMMON_CLK_G    => true,
         AXIL_BASEADDR_G => AXIL_CONFIG_C(TRIG_INDEX_C).baseAddr)
      port map (
         -- AXI-Lite and IRQ Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilWriteMaster => axilWriteMasters(TRIG_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(TRIG_INDEX_C),
         axilReadMaster  => axilReadMasters(TRIG_INDEX_C),
         axilReadSlave   => axilReadSlaves(TRIG_INDEX_C),
         -- EVR Ports
         evrClk          => axilClk,
         evrRst          => axilRst,
         evrBus          => appTimingBus,
         -- Trigger and Sync Port
         trigOut         => appTimingTrig,
         evrModeSel      => appTimingMode);

   GEN_LANE : for i in 3 downto 0 generate

      -- Outputs
      triggers(i) <= trigMon(i);
      trigMon(i)  <= appTimingTrig.trigPulse(i) and not (appTrigCtrl(i).pause);
      trigDrop(i) <= appTimingTrig.trigPulse(i) and (appTrigCtrl(i).pause);

      appTrigMasters(i).tValid                <= trigMon(i);
      appTrigMasters(i).tData(63 downto 0)    <= appTimingTrig.timeStamp;
      appTrigMasters(i).tData(191 downto 64)  <= appTimingTrig.bsa;
      appTrigMasters(i).tData(383 downto 192) <= appTimingTrig.dmod;
      appTrigMasters(i).tLast                 <= '1';  -- EOF
      appTrigMasters(i).tUser(SSI_SOF_C)      <= '1';  -- SOF

      U_Trig_Info_Fifo : entity work.AxiStreamFifoV2
         generic map (
            -- General Configurations
            TPD_G               => TPD_G,
            SLAVE_READY_EN_G    => false,
            -- FIFO configurations
            BRAM_EN_G           => true,
            GEN_SYNC_FIFO_G     => true,
            FIFO_ADDR_WIDTH_G   => 4,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 12,
            -- AXI Stream Port Configurations
            SLAVE_AXI_CONFIG_G  => ssiAxiStreamConfig(48),  -- 48 bytes = 384-bits wide
            MASTER_AXI_CONFIG_G => ssiAxiStreamConfig(48))
         port map (
            -- Slave Port
            sAxisClk    => axilClk,
            sAxisRst    => axilRst,
            sAxisMaster => appTrigMasters(i),
            sAxisCtrl   => appTrigCtrl(i),
            -- Master Port
            mAxisClk    => axilClk,
            mAxisRst    => axilRst,
            mAxisMaster => txMasters(i),
            mAxisSlave  => txSlaves(i));

      ---------------------------------
      -- Resize the Outbound AXI Stream
      --------------------------------- 
      U_TxResize : entity work.AxiStreamResize
         generic map (
            -- General Configurations
            TPD_G               => TPD_G,
            READY_EN_G          => true,  -- Resizing from large to smaller is only supported in (READY_EN_G=true) mode, which is why we don't do it in the "U_Trig_Info_Fifo" module
            -- AXI Stream Port Configurations
            SLAVE_AXI_CONFIG_G  => ssiAxiStreamConfig(48),
            MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
         port map (
            -- Clock and reset
            axisClk     => axilClk,
            axisRst     => axilRst,
            -- Slave Port
            sAxisMaster => txMasters(i),
            sAxisSlave  => txSlaves(i),
            -- Master Port
            mAxisMaster => trigMasters(i),
            mAxisSlave  => trigSlaves(i));

   end generate GEN_LANE;

end mapping;
