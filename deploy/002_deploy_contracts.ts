import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();

  const stringsLib = await deployments.get('Strings');
  const safeMathLib = await deployments.get('SafeMath');
  const quantizedLib = await deployments.get('QuantizedLib');

  await deploy('Quantized', {
    from: deployer,
    log: true,
    libraries: {
      Strings: stringsLib.address,
      SafeMath: safeMathLib.address,
      QuantizedLib: quantizedLib.address,
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

  await deploy('FeeTracker', {
    from: deployer,
    log: true,
  });
};

func.tags = ['QuantizedContracts'];
func.dependencies = ['QuantizedLibs'];
export default func;
