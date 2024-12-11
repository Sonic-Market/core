import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { deployWithVerify } from '../utils'
import { Address } from 'viem'

const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, network } = hre
  const deployer = (await getNamedAccounts())['deployer'] as Address

  if (await deployments.getOrNull('BookManager')) {
    return
  }

  let bookLibraryAddress = (await deployments.getOrNull('Book'))?.address
  if (!bookLibraryAddress) {
    bookLibraryAddress = await deployWithVerify(hre, 'Book', [])
  }

  let owner: Address = deployer
  let defaultProvider: Address = '0xcc92364b6b886158e71fd4e4da5c682d33d1491e'

  await deployWithVerify(
    hre,
    'BookManager',
    [
      owner,
      defaultProvider,
      `https://sonic.market/api/nft/chains/146/orders/`,
      `https://sonic.market/api/contract/chains/146`,
      'Sonic Market Orderbook Maker Order',
      'SONIC-MARKET-ORDER',
    ],
    {
      libraries: {
        Book: bookLibraryAddress,
      },
    },
  )
}

deployFunction.tags = ['BookManager']
deployFunction.dependencies = []
export default deployFunction
