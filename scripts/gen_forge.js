import main from '../utils/gen_tokenmint';
import {terminal} from 'terminal-kit';
import colors from 'colors/safe';

terminal.fullscreen(true);

console.log(colors.rainbow('Hello user'));

const paintScreen = (amount) => {
  // term.moveTo( 1 , 1 );
  // term.eraseDisplayBelow();
  console.log('Generated token mint event', amount);
};

const m = () => {
  main(4, 5, 1000, paintScreen).catch((error) => {
    console.error(error);
    process.exit(1);
  });
};
m();
