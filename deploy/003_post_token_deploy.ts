import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

import {Quantized} from '../quantized-ui/types/Quantized';
import {QuantizedMultiToken} from '../quantized-ui/types/QuantizedMultiToken';
import {QuantizedERC20Factory} from '../quantized-ui/types/QuantizedERC20Factory';
import {QuantizedFeeTracker} from '../quantized-ui/types/QuantizedFeeTracker';
import {QuantizedGovernor} from '../quantized-ui/types/QuantizedGovernor';

import {keccak256} from '@ethersproject/solidity';

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

  const governor: QuantizedGovernor = ((await getContractAt(
    'QuantizedGovernor',
    (await get('QuantizedGovernor')).address,
    sender
  )) as unknown) as QuantizedGovernor;

  const multitoken: QuantizedMultiToken = ((await getContractAt(
    'QuantizedMultiToken',
    (await get('QuantizedMultiToken')).address,
    sender
  )) as unknown) as QuantizedMultiToken;

  const factory: QuantizedERC20Factory = ((await getContractAt(
    'QuantizedERC20Factory',
    (await get('QuantizedERC20Factory')).address,
    sender
  )) as unknown) as QuantizedERC20Factory;

  const feeTracker: QuantizedFeeTracker = ((await getContractAt(
    'QuantizedFeeTracker',
    (await get('QuantizedFeeTracker')).address,
    sender
  )) as unknown) as QuantizedFeeTracker;

  console.log('initializing Quantized contract if necessary');
  await quantized.initialize(
    multitoken.address,
    governor.address,
    factory.address,
    feeTracker.address
  );

  const QuantizedERC20ABI = require('../deployments/kovan/QuantizedERC20.json');

  const COMPUTED_INIT_CODE_HASH = keccak256(
    ['bytes'],
    [`${QuantizedERC20ABI.bytecode}`]
  );

  console.log('Quantized address:' + quantized.address);
  console.log('Quantized governor address:' + governor.address);
  console.log('Quantized multitoken address:' + multitoken.address);
  console.log('Quantized factory address:' + factory.address);
  console.log('Quantized fees tracker address:' + feeTracker.address);
  console.log(
    'QuantizedERC20 contract init code hash:' + COMPUTED_INIT_CODE_HASH
  );
};

func.tags = ['QuantizedPost'];
func.dependencies = ['QuantizedLibs', 'QuantizedContracts'];
export default func;
