-------------------------------------------------------------------------------
-- File       : TimingPhyMonitor.vhd
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

entity TimingPhyMonitor is
   generic (
      TPD_G           : time := 1 ns;
      AXIL_CLK_FREQ_G : real := 156.25E+6);  -- units of Hz
   port (
      rxUserRst       : out sl;
      txUserRst       : out sl;
      txDiffCtrl      : out slv(3 downto 0);
      txPreCursor     : out slv(4 downto 0);
      txPostCursor    : out slv(4 downto 0);
      loopback        : out Slv3Array(1  downto 0);
      mmcmRst         : out sl;
      mmcmLocked      : in  slv(1 downto 0);
      refClk          : in  slv(1 downto 0);
      refRst          : in  slv(1 downto 0);
      txClk           : in  sl;
      txRst           : in  sl;
      rxClk           : in  sl;
      rxRst           : in  sl;
      -- AXI-Lite Register Interface (sysClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end TimingPhyMonitor;

architecture rtl of TimingPhyMonitor is

   type RegType is record
      mmcmRst        : sl;
      rxUserRst      : sl;
      txUserRst      : sl;
      txDiffCtrl     : slv(3 downto 0);
      txPreCursor    : slv(4 downto 0);
      txPostCursor   : slv(4 downto 0);
      loopback       : Slv3Array(1  downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      mmcmRst        => '0',
      rxUserRst      => '0',
      txUserRst      => '0',
      txDiffCtrl     => "1000",
      txPreCursor    => "00000",
      txPostCursor   => "00000",
      loopback       => (others=>"100"),-- 100: Far-end PMA Loopback
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal refClkFreq : Slv32Array(1 downto 0);

   signal txReset   : sl;
   signal txClkFreq : slv(31 downto 0);

   signal rxReset   : sl;
   signal rxClkFreq : slv(31 downto 0);

begin

   GEN_REFCLK_FREQ :
   for i in 1 downto 0 generate
      U_refClk : entity work.SyncClockFreq
         generic map (
            TPD_G          => TPD_G,
            REF_CLK_FREQ_G => AXIL_CLK_FREQ_G,
            REFRESH_RATE_G => 1.0,
            CNT_WIDTH_G    => 32)
         port map (
            -- Frequency Measurement (locClk domain)
            freqOut => refClkFreq(i),
            -- Clocks
            clkIn   => refClk(i),
            locClk  => axilClk,
            refClk  => axilClk);
   end generate GEN_REFCLK_FREQ;

   Sync_txRst : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,
         dataIn  => txRst,
         dataOut => txReset);

   U_txClkFreq : entity work.SyncClockFreq
      generic map (
         TPD_G          => TPD_G,
         REF_CLK_FREQ_G => AXIL_CLK_FREQ_G,
         REFRESH_RATE_G => 1.0,
         CNT_WIDTH_G    => 32)
      port map (
         -- Frequency Measurement (locClk domain)
         freqOut => txClkFreq,
         -- Clocks
         clkIn   => txClk,
         locClk  => axilClk,
         refClk  => axilClk);

   Sync_rxRst : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,
         dataIn  => rxRst,
         dataOut => rxReset);

   U_rxClkFreq : entity work.SyncClockFreq
      generic map (
         TPD_G          => TPD_G,
         REF_CLK_FREQ_G => AXIL_CLK_FREQ_G,
         REFRESH_RATE_G => 1.0,
         CNT_WIDTH_G    => 32)
      port map (
         -- Frequency Measurement (locClk domain)
         freqOut => rxClkFreq,
         -- Clocks
         clkIn   => rxClk,
         locClk  => axilClk,
         refClk  => axilClk);

   --------------------- 
   -- AXI Lite Interface
   --------------------- 
   comb : process (axilReadMaster, axilRst, axilWriteMaster, mmcmLocked, r,
                   refClkFreq, refRst, rxClkFreq, rxReset, txClkFreq, txReset) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.rxUserRst := '0';
      v.txUserRst := '0';
      v.mmcmRst   := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      axiSlaveRegister(regCon, x"00", 0, v.mmcmRst);
      axiSlaveRegisterR(regCon, x"04", 0, mmcmLocked);
      axiSlaveRegisterR(regCon, x"08", 0, refRst);

      axiSlaveRegister(regCon, x"10", 0, v.loopback(0));
      axiSlaveRegister(regCon, x"10", 4, v.loopback(1));
      axiSlaveRegister(regCon, x"14", 0, v.rxUserRst);
      axiSlaveRegister(regCon, x"18", 0, v.txUserRst);
      axiSlaveRegister(regCon, x"1C", 0, v.txDiffCtrl);

      axiSlaveRegister(regCon, x"20", 0, v.txPreCursor);
      axiSlaveRegister(regCon, x"24", 0, v.txPostCursor);

      axiSlaveRegisterR(regCon, x"40", 0, txReset);
      axiSlaveRegisterR(regCon, x"44", 0, txClkFreq);
      axiSlaveRegisterR(regCon, x"48", 0, rxReset);
      axiSlaveRegisterR(regCon, x"4C", 0, rxClkFreq);

      axiSlaveRegisterR(regCon, x"60", 0, refClkFreq(0));
      axiSlaveRegisterR(regCon, x"64", 0, refClkFreq(1));

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      loopback       <= r.loopback;
      txDiffCtrl     <= r.txDiffCtrl;
      txPreCursor    <= r.txPreCursor;
      txPostCursor   <= r.txPostCursor;

      -- Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_mmcmRst : entity work.PwrUpRst
      generic map (
         TPD_G      => TPD_G,
         DURATION_G => 156000000)
      port map (
         arst   => r.mmcmRst,
         clk    => axilClk,
         rstOut => mmcmRst);

   U_rxUserRst : entity work.PwrUpRst
      generic map (
         TPD_G      => TPD_G,
         DURATION_G => 125000000)
      port map (
         arst   => r.rxUserRst,
         clk    => axilClk,
         rstOut => rxUserRst);

   U_txUserRst : entity work.PwrUpRst
      generic map (
         TPD_G      => TPD_G,
         DURATION_G => 125000000)
      port map (
         arst   => r.txUserRst,
         clk    => axilClk,
         rstOut => txUserRst);

end rtl;
