import hre from 'hardhat';

module.exports = async function (callback, interval) {
  const [sender] = await hre.ethers.getSigners();
  const senderAddress = await sender.getAddress();
  const depls = await hre.deployments.all();

  const TestTokenForge = await hre.ethers.getContractAt(
    'TestTokenForge',
    depls.TestTokenForge.address,
    sender
  );
  // await TestTokenForge.setTargetMintAmount(50);
  // await TestTokenForge.setTargetMintSpan(50);

  const _start = () => {
    this._intervalTimer = setInterval(async () => {
      const targetMint = await TestTokenForge.getTargetMintAmount();
      const targetMintSpan = await TestTokenForge.getTargetMintSpan();
      const lastDifficultyAdjustTime = await TestTokenForge.getLastDifficultyAdjustTime();
      const difficulty = await TestTokenForge.getDifficulty();
      const timespanMintAverage = await TestTokenForge.getTimespanMintAverage();
      const timespanMintDeviationAverage = await TestTokenForge.getTimespanMintDeviationAverage();
      const thisPeriodAmountMinted = await TestTokenForge.getThisPeriodMinted();
      const totalMinted = await TestTokenForge.getTotalMinted();

      if (callback)
        callback({
          TestTokenForge,
          senderAddress,
          targetMint,
          targetMintSpan,
          lastDifficultyAdjustTime,
          difficulty,
          timespanMintAverage,
          timespanMintDeviationAverage,
          thisPeriodAmountMinted,
          totalMinted,
        });
    }, interval);
  };

  _start();

  this.interruptTimer = () => {
    if (this._intervalTimer) {
      clearInterval(this._intervalTimer);
      delete this._intervalTimer;
    }
  };
};
