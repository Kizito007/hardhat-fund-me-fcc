const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { network, get } = require("hardhat")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    //  when going for localhost or hardhat networks we want to use a mock
    /* what happens when we change chains 
        e.g if chanId is x use address y 
        and if chainId is z use address a
    */
    // const ethUsdPriceFeedAddress = networkConfig["chainId"]["ethUsdPriceFeed"]

    let ethUsdPriceFeedAddress
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }

    // if contract D.N.E we deploy a minimal version for our local testing
    const args = [ethUsdPriceFeedAddress]
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args, // put price feed address: constructor args
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    log(`FundMe deployed at: ${fundMe.address}, Arguements: ${args}`)
    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        // verify
        await verify(fundMe.address, args)
    }
    log("--------------------------------------------------")
}
module.exports.tags = ["all", "fundme"]
