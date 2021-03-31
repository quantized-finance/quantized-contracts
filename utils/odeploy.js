import hre from 'hardhat';
import u from './utils';

module.exports = {
  deploy: async (runlist, reset) => {
    // const {deployments, ethers, getNamedAccounts} = hre;
    // const {deploy} = deployments;
    // const {deployer} = await getNamedAccounts();
    const [sender] = await hre.ethers.getSigners();
    const senderAddress = await sender.getAddress();
    var data = {
      owner: {
        instance: sender,
        address: senderAddress,
      },
      libs: {},
    };
    var configs = reset
      ? {
          owner: senderAddress,
          libs: {},
          tokens: {},
          diffcalc: {},
        }
      : u.readConfig();

    const deployLibraries = async () => {
      // deploy a new radius lib if none are deployed
      console.log('deploying radius lib');
      data.libs.token = await u.deploy('RadiusTokenLib', [], sender);
      configs.libs.token = data.libs.token.instance.address;

      console.log('deploying mine lib');
      data.libs.mine = await u.deploy('RadiusMineLib', [], sender);
      configs.libs.mine = data.libs.mine.instance.address;
    };

    const deployTokens = async () => {
      // deploy the primary erc1155 token
      console.log('deploying radius token');
      data.token = await u.linkDeployProxy(
        'RadiusToken',
        [],
        {
          libraries: {
            RadiusTokenLib: configs.libs.token,
          },
        },
        sender
      );
      configs.tokens.token = data.token.instance.address;

      // deploy radius ore token
      console.log('deploying radius ore erc20 token');
      data.ore = await u.deployProxy(
        'RadiusOreERC20',
        [0, data.token.instance.address],
        sender
      );
      configs.tokens.ore = data.ore.instance.address;

      // deploy radius common token
      console.log('deploying radius common erc20 token');
      data.common = await u.deployProxy(
        'RadiusCommonERC20',
        [1, data.token.instance.address],
        sender
      );
      configs.tokens.common = data.common.instance.address;

      // deploy radius morium token
      console.log('deploying radius morium erc20 token');
      data.morium = await u.deployProxy(
        'RadiusMoriumERC20',
        [2, data.token.instance.address],
        sender
      );
      configs.tokens.morium = {
        address: data.morium.instance.address,
      };

      // deploy radius morium difficulty calculator
      console.log('deploying radius morium difficulty calculator');
      data.moriumDiffCalc = await u.deployProxy(
        'MoriumTokenForge',
        [data.token.instance.address],
        sender
      );
      configs.tokens.morium.diffCalc = data.moriumDiffCalc.instance.address;

      // deploy radius morium difficulty calculator
      console.log('deploying radius gem difficulty calculator');
      data.gemDiffCalc = await u.deployProxy(
        'GemTokenForge',
        [data.token.instance.address],
        sender
      );
      configs.diffcalc.gem = data.gemDiffCalc.instance.address;

      // deploy radius morium difficulty calculator
      console.log('deploying radius powerup difficulty calculator');
      data.powerupDiffCalc = await u.deployProxy(
        'PowerupTokenForge',
        [data.token.instance.address],
        sender
      );
      configs.diffcalc.powerup = data.powerupDiffCalc.instance.address;

      // deploy radius morium difficulty calculator
      console.log('deploying unique difficulty calculator');
      data.uniqueDiffCalc = await u.deployProxy(
        'UniqueGemTokenForge',
        [data.token.instance.address],
        sender
      );
      configs.diffcalc.unique = data.uniqueDiffCalc.instance.address;

      // deploy radius morium difficulty calculator
      console.log('deploying test difficulty calculator');
      data.TestTokenForge = await u.deployProxy(
        'TestTokenForge',
        [senderAddress],
        sender
      );
      configs.TestTokenForge = data.TestTokenForge.instance.address;

      // deploy radius dividend token
      console.log('deploying radius dividend erc20 token');
      data.dividend = await u.deployProxy(
        'RadiusDividendERC20',
        [3, data.token.instance.address],
        sender
      );
      configs.tokens.dividend = {
        address: data.dividend.instance.address,
      };

      // deploy radius dividend difficulty calculator
      console.log('deploying radius dividend difficulty calculator');
      data.dividendDiffCalc = await u.deployProxy(
        'DividendTokenForge',
        [data.token.instance.address],
        sender
      );
      configs.tokens.dividend.diffCalc = data.dividendDiffCalc.instance.address;

      // deploy radius dividend token
      console.log('deploying test staked token');
      data.staked = await u.deployProxy('TestToken', [], sender);
      configs.tokens.staked = data.staked.instance.address;

      // associate the erc1155 with the RadiusToken tokens and
      // give the RadiusToken token ownership to mint erc20
      console.log('Account ', senderAddress);
    };

    const deployMine = async () => {
      // Deploy RadiusToken contract
      console.log('deploying mine');
      data.mine = await u.linkDeployProxy(
        'RadiusMine',
        [configs.tokens.token],
        {
          libraries: {
            RadiusMineLib: configs.libs.mine,
          },
        },
        sender
      );
      configs.mine = data.mine.instance.address;
      const radiusToken = await u.attach('RadiusToken', configs.tokens.token);
      await radiusToken.instance.addAllowedMinter(data.mine.instance.address);
    };

    const deployMain = async () => {
      // deploy radius ore token
      console.log('deploying radius contract');
      data.radius = await u.deployProxy(
        'RadiusToken',
        [configs.tokens.token, configs.mine],
        sender
      );
      configs.radius = data.radius.instance.address;
    };

    const deployPost = async () => {
      const radiusToken = (await u.attach('RadiusToken', configs.tokens.token))
        .instance;
      const radiusMine = (await u.attach('RadiusMine', configs.mine)).instance;

      // // allow mining Fake USDT for Synth Ore
      console.log('set USD token as staked token of mine');
      await radiusMine.addAllowedErc20Token(configs.tokens.staked);

      console.log('associating radius with erc20 ore');
      await radiusToken.setErc20TokenAddress(0, configs.tokens.ore);
      console.log('associating radius with erc20 common');
      await radiusToken.setErc20TokenAddress(1, configs.tokens.common);
      console.log('associating radius with erc20 morium');
      await radiusToken.setErc20TokenAddress(2, configs.tokens.morium.address);
      console.log('associating radius with erc20 dividend');
      await radiusToken.setErc20TokenAddress(
        3,
        configs.tokens.dividend.address
      );

      console.log('setting morium forging difficulty');
      await radiusToken.setForgingDifficulty(2, configs.tokens.morium.diffCalc);
      console.log('setting dividend forging difficulty');
      await radiusToken.setForgingDifficulty(
        3,
        configs.tokens.dividend.diffCalc
      );

      console.log('setting powerup forging difficulty');
      await radiusToken.setForgingDifficulty(256, configs.diffcalc.gem);
      console.log('setting powerup to 0 decimals');
      console.log('setting gem forging difficulty');
      await radiusToken.setForgingDifficulty(4096, configs.diffcalc.powerup);
      console.log('setting gem to 0 decimals');
      console.log('setting unique gem forging difficulty');
      await radiusToken.setForgingDifficulty(8192, configs.diffcalc.unique);
      console.log('setting unique gem to 0 decimals');
    };

    const rlfind = (f) => {
      return !runlist ? true : runlist.find((el) => el === f) === f;
    };
    if (rlfind('libraries')) await deployLibraries();
    if (rlfind('tokens')) await deployTokens();
    if (rlfind('mine')) await deployMine();
    if (rlfind('main')) await deployMain();
    if (rlfind('post')) await deployPost();

    // write to the config file
    u.writeConfig(configs, false);

    return data;
  },
};
