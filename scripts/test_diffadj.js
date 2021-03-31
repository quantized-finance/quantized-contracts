import hre from 'hardhat';
import {terminal} from 'terminal-kit';
import fs from 'fs';
import 'colors/safe';

let TestTokenForge,
  senderAddress,
  diffobj,
  sender,
  depls,
  salt,
  hash,
  passed,
  nowtime = 0,
  starttime = 0,
  passcnt = 0,
  totalcnt = 0,
  // total = 0,
  lastThisPeriodAmountMinted = 0,
  lastBlockFoundPerMinute = [];

TestTokenForge = null;

const setupContracts = async () => {
  [sender] = await hre.ethers.getSigners();
  senderAddress = sender.getAddress();
  depls = await hre.deployments.all();
  TestTokenForge = await hre.ethers.getContractAt(
    'TestTokenForge',
    depls.TestTokenForge.address,
    sender
  );
  starttime = nowtime = Date.now();
};

const repaint = () => {
  if (!diffobj || !totalcnt || !TestTokenForge) {
    return;
  }

  terminal.moveTo(1, 1);
  terminal.eraseDisplayBelow();

  nowtime = Date.now();

  const elapsed = (nowtime - starttime) / 1000;
  diffobj.thisPeriodElapsed = elapsed;
  console.log(diffobj);

  const rpm = ((passcnt / elapsed) * 60).toFixed(2);
  const tpm = ((totalcnt / elapsed) * 60).toFixed(2);
  const passpct = ((passcnt / totalcnt) * 100).toFixed(2);
  console.log(
    `${hash.toHexString()} ${
      passed ? 'PASS' : '    '
    } ${passpct}% success, ${tpm} forgePerMin ${rpm} foundPerMin`
  );

  if (diffobj.thisPeriodAmountMinted < lastThisPeriodAmountMinted) {
    diffobj.time = nowtime;
    diffobj.forgesPerMinute = tpm;
    diffobj.foundPerMinute = rpm;
    lastBlockFoundPerMinute.push(JSON.parse(JSON.stringify(diffobj)));
    starttime = nowtime = new Date().getTime();
    passcnt = totalcnt = 0;
    const out = [Object.keys(lastBlockFoundPerMinute[0]).join(',')];
    lastBlockFoundPerMinute.forEach((e) =>
      out.push(Object.values(e).join(','))
    );
    fs.writeFileSync('./results.json', out.join('\n'));
  }
  lastThisPeriodAmountMinted = diffobj.thisPeriodAmountMinted;
};

const doHash = async () => {
  salt = await TestTokenForge.salt();
  hash = await TestTokenForge.hash(senderAddress, salt.hash);
  passed = await TestTokenForge.check(hash);
  if (passed) {
    passcnt++;
    await TestTokenForge.recordTokenMintEvent('3');
  }
  totalcnt++;

  //setTimeout(doHash, Math.random() * 2000);
  setTimeout(doHash, 0);
};

const doMonitor = async () => {
  const targetMint = (await TestTokenForge.getTargetMintAmount()).toString();
  const targetMintSpan = (await TestTokenForge.getTargetMintSpan()).toString();
  const lastDifficultyAdjustTime = (
    await TestTokenForge.getLastDifficultyAdjustTime()
  ).toString();
  const timespanMintAverage = (
    await TestTokenForge.getTimespanMintAverage()
  ).toString();
  const timespanMintDeviationAverage = (
    await TestTokenForge.getTimespanMintDeviationAverage()
  ).toString();
  const thisPeriodAmountMinted = (
    await TestTokenForge.getThisPeriodMinted()
  ).toString();
  const totalMinted = (await TestTokenForge.getTotalMinted()).toString();
  const difficulty = (await TestTokenForge.getDifficulty()).toHexString();
  const nextDifficulty = (
    await TestTokenForge.getNextDifficulty()
  ).toHexString();

  diffobj = {
    targetMint,
    targetMintSpan,
    lastDifficultyAdjustTime,
    timespanMintAverage,
    timespanMintDeviationAverage,
    thisPeriodAmountMinted,
    totalMinted,
    difficulty,
    nextDifficulty,
  };
};

const intervals = [];

setupContracts()
  .then(async () => {
    setTimeout(doHash, 100);
    intervals.push(setInterval(doMonitor, 1000));
    setTimeout(() => {
      intervals.push(setInterval(repaint, 100));
    }, 1000);
    setTimeout(() => {
      intervals.forEach((e) => clearInterval(e));
      repaint();
      process.exit(1);
    }, 60 * 60 * 1000);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
