-------------------------------------------------------------------------------
-- File       : Application.vhd
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

entity ClinkDecaMode is
   generic (
      TPD_G             : time := 1 ns;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType);
   port (
      -- Clock and Reset
      axilClk    : in  sl;
      axilRst    : in  sl;
      -- Configuration
      decaMode   : in  sl;
      blowoff    : in  sl;
      -- Inbound stream
      tapMaster  : in  AxiStreamMasterType;
      tapSlave   : out AxiStreamSlaveType;
      -- Outbound stream
      dataMaster : out AxiStreamMasterType;
      dataSlave  : in  AxiStreamSlaveType);
end ClinkDecaMode;

architecture mapping of ClinkDecaMode is

   constant AXIS_80b_CONFIG_C  : AxiStreamConfigType := ssiAxiStreamConfig((80/8), TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);
   constant AXIS_128b_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig((128/8), TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);

   signal axilReset   : sl;
   signal tapSlaveTmp : AxiStreamSlaveType;

   signal rxMaster : AxiStreamMasterType;
   signal rxSlave  : AxiStreamSlaveType;

   signal txMasters : AxiStreamMasterArray(1 downto 0);
   signal txSlaves  : AxiStreamSlaveArray(1 downto 0);

   signal dataMasters : AxiStreamMasterArray(1 downto 0);
   signal dataSlaves  : AxiStreamSlaveArray(1 downto 0);

   signal muxMaster : AxiStreamMasterType;
   signal muxSlave  : AxiStreamSlaveType;

begin

   process(axilClk)
   begin
      if rising_edge(axilClk) then
         axilReset <= axilRst or blowoff after TPD_G;
      end if;
   end process;

   tapSlave.tReady <= tapSlaveTmp.tReady or axilReset;

   U_IbResize : entity surf.AxiStreamGearbox
      generic map (
         TPD_G               => TPD_G,
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => AXIS_80b_CONFIG_C,
         PIPE_STAGES_G       => 1)
      port map (
         axisClk     => axilClk,
         axisRst     => axilReset,
         sAxisMaster => tapMaster,
         sAxisSlave  => tapSlaveTmp,
         mAxisMaster => rxMaster,
         mAxisSlave  => rxSlave);

   process(decaMode, rxMaster, txSlaves)
      variable rxSlaveTmp   : AxiStreamSlaveType;
      variable txMastersTmp : AxiStreamMasterArray(1 downto 0);
   begin
      -- Init
      txMastersTmp(0) := rxMaster;
      txMastersTmp(1) := rxMaster;

      -- Add zero padding to CH=1
      for i in 0 to 7 loop
         txMastersTmp(1).tData(16*i+15 downto 16*i) := b"000000" & rxMaster.tData(10*i+9 downto 10*i);
      end loop;

      txMastersTmp(1).tKeep(1 downto 0)   := (others => rxMaster.tKeep(1));  -- smpl=1: 0x003->0x0003
      txMastersTmp(1).tKeep(3 downto 2)   := (others => rxMaster.tKeep(2));  -- smpl=2: 0x007->0x000F
      txMastersTmp(1).tKeep(5 downto 4)   := (others => rxMaster.tKeep(3));  -- smpl=3: 0x00F->0x003F
      txMastersTmp(1).tKeep(7 downto 6)   := (others => rxMaster.tKeep(4));  -- smpl=4: 0x01F->0x00FF
      txMastersTmp(1).tKeep(9 downto 8)   := (others => rxMaster.tKeep(6));  -- smpl=5: 0x07F->0x03FF
      txMastersTmp(1).tKeep(11 downto 10) := (others => rxMaster.tKeep(7));  -- smpl=6: 0x0FF->0x0FFF
      txMastersTmp(1).tKeep(13 downto 12) := (others => rxMaster.tKeep(8));  -- smpl=7: 0x1FF->0x3FFF
      txMastersTmp(1).tKeep(15 downto 14) := (others => rxMaster.tKeep(9));  -- smpl=8: 0x3FF->0xFFFF

      if decaMode = '0' then

         -- Connect CH=0 to RX
         rxSlaveTmp := txSlaves(0);

         -- Blow off CH=1
         txMastersTmp(1).tValid := '0';

      else

         -- Connect CH=1 to RX
         rxSlaveTmp := txSlaves(1);

         -- Blow off CH=0
         txMastersTmp(0).tValid := '0';

      end if;

      -- Outputs
      rxSlave   <= rxSlaveTmp;
      txMasters <= txMastersTmp;

   end process;

   U_ObResize_0 : entity surf.AxiStreamGearbox
      generic map (
         TPD_G               => TPD_G,
         SLAVE_AXI_CONFIG_G  => AXIS_80b_CONFIG_C,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G,
         PIPE_STAGES_G       => 1)
      port map (
         axisClk     => axilClk,
         axisRst     => axilReset,
         sAxisMaster => txMasters(0),
         sAxisSlave  => txSlaves(0),
         mAxisMaster => dataMasters(0),
         mAxisSlave  => dataSlaves(0));

   U_ObResize_1 : entity surf.AxiStreamGearbox
      generic map (
         TPD_G               => TPD_G,
         SLAVE_AXI_CONFIG_G  => AXIS_128b_CONFIG_C,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G,
         PIPE_STAGES_G       => 1)
      port map (
         axisClk     => axilClk,
         axisRst     => axilReset,
         sAxisMaster => txMasters(1),
         sAxisSlave  => txSlaves(1),
         mAxisMaster => dataMasters(1),
         mAxisSlave  => dataSlaves(1));

   U_Mux : entity surf.AxiStreamMux
      generic map (
         TPD_G                => TPD_G,
         NUM_SLAVES_G         => 2,
         ILEAVE_EN_G          => true,
         ILEAVE_ON_NOTVALID_G => true,
         PIPE_STAGES_G        => 1)
      port map (
         -- Clock and reset
         axisClk      => axilClk,
         axisRst      => axilReset,
         -- Inbound Ports
         sAxisMasters => dataMasters,
         sAxisSlaves  => dataSlaves,
         -- Outbound Port
         mAxisMaster  => muxMaster,
         mAxisSlave   => muxSlave);

   U_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         -- FIFO configurations
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilReset,
         sAxisMaster => muxMaster,
         sAxisSlave  => muxSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilReset,
         mAxisMaster => dataMaster,
         mAxisSlave  => dataSlave);

end mapping;
