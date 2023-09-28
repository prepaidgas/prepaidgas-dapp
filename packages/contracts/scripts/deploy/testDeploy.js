const {
  TOTAL_TEST_ORDERS_AMOUNT,
  SYSTEM_FEE,
  PROJECT_NAME,
  PROJECT_VERSION,
  TOKEN_LINK,
} = require("../constants/index.js")
const orderHelper = require("../helpers/orderHelper.js")
const { precalculateAddress } = require("../helpers/index.js")

async function initDeploymentSetup() {
  const [admin, ...accounts] = await ethers.getSigners()
  const network = await ethers.getDefaultProvider().getNetwork()
  console.log("Network name=", network.name)
  console.log("Network chain id=", network.chainId)
  console.log("Network data", network)

  const ExecutorFactory = await ethers.getContractFactory("Executor")
  const GasOrderFactory = await ethers.getContractFactory("GasOrder")

  const GasOrderContractAddress = await precalculateAddress(admin, 1)
  const ExecutorContract = await ExecutorFactory.deploy(GasOrderContractAddress, PROJECT_NAME, PROJECT_VERSION, 1, [])
  await ExecutorContract.deploymentTransaction().wait()
  // @todo add deploy error handling
  console.log(`Executor contract deployed: ${ExecutorContract.target}`)

  const GasOrderContract = await GasOrderFactory.deploy(ExecutorContract.target, TOKEN_LINK)
  await GasOrderContract.deploymentTransaction().wait()
  console.log(`GasOrder contract deployed: ${GasOrderContract.target}`)

  const TokenFactory = await ethers.getContractFactory("MockToken")
  const TokenContract = await TokenFactory.deploy("MockUSD", "MUSD", "1000000000") // @todo use ethers function to specify token amount
  await TokenContract.deploymentTransaction().wait()

  await GasOrderContract.setFee(0, SYSTEM_FEE)
  await GasOrderContract.setFee(1, SYSTEM_FEE)
  await GasOrderContract.setFee(2, SYSTEM_FEE)

  // Create and accept order
  await TokenContract.transfer(accounts[10].address, "500000000")
  for (let i = 0; i < TOTAL_TEST_ORDERS_AMOUNT; i++) {
    let isAccepted = Math.random() < 0.5
    await orderHelper.createOrder(
      admin,
      GasOrderContract,
      TokenContract,
      isAccepted,
      isAccepted ? accounts[10] : false,
      36000,
      864000,
    )
  }
  // fruitsToGet.map(fruit => getNumFruit(fruit))
  // const numFruits = await Promise.all(promises)

  return { accounts, admin, ExecutorContract, GasOrderContract, TokenContract }
}

initDeploymentSetup().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
