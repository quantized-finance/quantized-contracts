import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();

  const stringsLib = await deployments.get('Strings');
  const quantizedLib = await deployments.get('QuantizedLib');

  const token = await deploy('Quantized', {
    from: deployer,
    log: true,
    libraries: {
      Strings: stringsLib.address,
      QuantizedLib: quantizedLib.address,
    },
  });

  await deploy('QuantizedFactory', {
    from: deployer,
    log: true,
    args: [token.address],
  });
};

func.tags = ['QuantizedContracts'];
func.dependencies = ['QuantizedLibs'];
export default func;
