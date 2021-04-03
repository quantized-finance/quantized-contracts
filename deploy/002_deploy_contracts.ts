import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();

  const stringsLib = await deployments.get('Strings');
  const safeMathLib = await deployments.get('SafeMath');
  const quantizedLib = await deployments.get('QuantizedLib');
  const c2Deployer = await deployments.get('Create2Deployer');

  await deploy('Quantized', {
    from: deployer,
    log: true,
    libraries: {
      Strings: stringsLib.address,
      SafeMath: safeMathLib.address,
      QuantizedLib: quantizedLib.address,
      Create2Deployer: c2Deployer.address,
    },
  });

  await deploy('QuantizedGovernor', {
    from: deployer,
    log: true,
    proxy: {
      upgradeIndex: 0,
      methodName: 'initialize',
    },
  });

  await deploy('QuantizedMultiToken', {
    from: deployer,
    log: true,
  });

  await deploy('QuantizedERC20Factory', {
    from: deployer,
    log: true,
  });

  await deploy('QuantizedERC20', {
    from: deployer,
    log: true,
  });

  await deploy('QuantizedFeeTracker', {
    from: deployer,
    log: true,
  });
};

func.tags = ['QuantizedContracts'];
func.dependencies = ['QuantizedLibs'];
export default func;
