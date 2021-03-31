import hre from 'hardhat';
const [sender] = await hre.ethers.getSigners();
const depls = await hre.deployments.all();

const mine = await hre.ethers.getContractAt(
  'RadiusMine',
  depls.RadiusMine.address,
  sender
);
const ttoken = await hre.ethers.getContractAt(
  'TestToken',
  depls.TestToken.address,
  sender
);
const token = await hre.ethers.getContractAt(
  'RadiusToken',
  depls.RadiusToken.address,
  sender
);
const ore = await hre.ethers.getContractAt(
  'RadiusOreERC20',
  depls.RadiusOreERC20.address,
  sender
);
const common = await hre.ethers.getContractAt(
  'RadiusCommonERC20',
  depls.RadiusCommonERC20.address,
  sender
);
const morium = await hre.ethers.getContractAt(
  'RadiusMoriumERC20',
  depls.RadiusMoriumERC20.address,
  sender
);
const dividend = await hre.ethers.getContractAt(
  'RadiusDividendERC20',
  depls.RadiusDividendERC20.address,
  sender
);
const mdiff = await hre.ethers.getContractAt(
  'MoriumTokenForge',
  depls.MoriumTokenForge.address,
  sender
);
const ddiff = await hre.ethers.getContractAt(
  'DividendTokenForge',
  depls.DividendTokenForge.address,
  sender
);
// allow mining Fake USDT for Synth Ore
console.log('set USD token as staked token of mine');
await mine.addAllowedErc20Token(ttoken.address);

console.log('associating radius with erc20 ore');
await token.setErc20TokenAddress(0, ore.address);
console.log('associating radius with erc20 common');
await token.setErc20TokenAddress(1, common.address);
console.log('associating radius with erc20 morium');
await token.setErc20TokenAddress(2, morium.address);
console.log('associating radius with erc20 dividend');
await token.setErc20TokenAddress(3, dividend.address);

console.log('setting morium forging difficulty');
await token.setForgingDifficulty(2, mdiff.address);
console.log('setting dividend forging difficulty');
await token.setForgingDifficulty(3, ddiff.address);
