import hre from 'hardhat';

module.exports = async function (amount, interval, reps, callback) {
  const [sender] = await hre.ethers.getSigners();
  const depls = await hre.deployments.all();

  const TestTokenForge = await hre.ethers.getContractAt(
    'TestTokenForge',
    depls.TestTokenForge.address,
    sender
  );

  this._reps = reps;

  const _start = () => {
    this._intervalTimer = setInterval(async () => {
      if (this._reps === 0) {
        this.interruptTimer();
        return;
      }
      this._reps = this._reps - 1;

      await TestTokenForge.recordTokenMintEvent(amount);
      if (callback) callback(amount);
    }, interval * 1000);
  };

  _start();

  this.interruptTimer = () => {
    if (this._intervalTimer) {
      clearInterval(this._intervalTimer);
      delete this._intervalTimer;
    }
  };
};
