import main from '../utils/monitor_difficulty';
import {terminal} from 'terminal-kit';
import colors from 'colors/safe';

terminal.fullscreen(true);

console.log(colors.rainbow('Hello user'));

const paintScreen = (diff) => {
  delete diff.TestTokenForge;
  diff.targetMint = diff.targetMint.toString();
  diff.targetMintSpan = diff.targetMintSpan.toString();
  diff.lastDifficultyAdjustTime = diff.lastDifficultyAdjustTime.toString();
  diff.timespanMintAverage = diff.timespanMintAverage.toString();
  diff.timespanMintDeviationAverage = diff.timespanMintDeviationAverage.toString();
  diff.thisPeriodAmountMinted = diff.thisPeriodAmountMinted.toString();
  diff.totalMinted = diff.totalMinted.toString();

  terminal.moveTo(1, 1);
  terminal.eraseDisplayBelow();

  console.log('Difficulty', diff);
};

const m = () => {
  main(paintScreen, 5000).catch((error) => {
    console.error(error);
    process.exit(1);
  });
};
m();
