import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

import {Quantized} from '../quantized-ui/types/Quantized';
import {QuantizedFactory} from '../quantized-ui/types/QuantizedFactory';
import {Quanta} from '../quantized-ui/types/Quanta';
import {QuantizedGovernance} from '../quantized-ui/types/QuantizedGovernance';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const [sender] = await hre.ethers.getSigners();

  const {deployments} = hre;
  const getContractAt = hre.ethers.getContractAt;
  const {get} = deployments;

  const quantized: Quantized = ((await getContractAt(
    'Quantized',
    (await get('Quantized')).address,
    sender
  )) as unknown) as Quantized;

  const quantizedFactory: QuantizedFactory = ((await getContractAt(
    'QuantizedFactory',
    (await get('QuantizedFactory')).address,
    sender
  )) as unknown) as QuantizedFactory;

  const gt = await quantized.factory();
  if (gt !== quantizedFactory.address) {
    console.log('setting quantized factory');
    await quantized.setFactory(quantizedFactory.address);
  }
};
func.tags = ['QuantizedPost'];
func.dependencies = ['QuantizedLibs', 'QuantizedContracts'];
export default func;
