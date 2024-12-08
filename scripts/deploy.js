const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying with account:", deployer.address);

    // System contract addresses from Citrea testnet documentation
    const LIGHT_CLIENT_ADDRESS = "0x0000000000000000000000000000000000000001";
    const BRIDGE_ADDRESS = "0x0000000000000000000000000000000000000002";

    // Deploy cBTC
    const CBTC = await ethers.getContractFactory("CBTC");
    const cBTC = await CBTC.deploy();
    await cBTC.deployed();
    console.log("cBTC deployed at:", cBTC.address);

    // Deploy PriceOracle
    const PriceOracle = await ethers.getContractFactory("PriceOracle");
    const oracle = await PriceOracle.deploy();
    await oracle.deployed();
    console.log("Oracle deployed at:", oracle.address);
    // Set initial price for cBTC = 1 cUSD
    await oracle.setPrice(cBTC.address, ethers.utils.parseEther("1"));

    // Deploy cGOV
    const CGOV = await ethers.getContractFactory("CGOV");
    const cGOV = await CGOV.deploy();
    await cGOV.deployed();
    console.log("cGOV deployed at:", cGOV.address);

    // Deploy StableCoin (cUSD)
    const StableCoin = await ethers.getContractFactory("StableCoin");
    const stableCoin = await StableCoin.deploy(
        cBTC.address,
        ethers.BigNumber.from("1000000000000000000"), // 1:1 ratio
        oracle.address,
        200 // stability fee bps
    );
    await stableCoin.deployed();
    console.log("cUSD deployed at:", stableCoin.address);

    // Deploy AMMDEX
    const AMMDEX = await ethers.getContractFactory("AMMDEX");
    const dex = await AMMDEX.deploy(
        cBTC.address,
        stableCoin.address,
        LIGHT_CLIENT_ADDRESS,
        BRIDGE_ADDRESS,
        oracle.address,
        cGOV.address,
        30,
        10,
        deployer.address
    );
    await dex.deployed();
    console.log("DEX deployed at:", dex.address);

    // Transfer cBTC ownership to DEX
    await cBTC.transferOwnership(dex.address);
    console.log("Transferred cBTC ownership to DEX");

    // Deploy AggregatorOracle
    const AggregatorOracle = await ethers.getContractFactory("AggregatorOracle");
    // The AggregatorOracle constructor expects an initialOwner; we can pass deployer.address
    const aggregator = await AggregatorOracle.deploy(deployer.address);
    await aggregator.deployed();
    console.log("AggregatorOracle deployed at:", aggregator.address);

    // Add the PriceOracle as a source for cBTC prices in the aggregator
    await aggregator.addOracle(cBTC.address, oracle.address);
    console.log("Added price oracle as a data source for cBTC in the aggregator.");

    // Deploy PaymentGateway
    // The PaymentGateway constructor is: (address _stableCoin, address _cBTC, address _aggregator, address _dex)
    const PaymentGateway = await ethers.getContractFactory("PaymentGateway");
    const paymentGateway = await PaymentGateway.deploy(
        stableCoin.address, 
        cBTC.address, 
        aggregator.address, 
        dex.address
    );
    await paymentGateway.deployed();
    console.log("PaymentGateway deployed at:", paymentGateway.address);

    // Optionally, you can register a merchant here if desired:
    const merchantId = ethers.utils.formatBytes32String("merchant123");
    await paymentGateway.registerMerchant(merchantId, deployer.address);
    console.log("Merchant registered:", merchantId, "to", deployer.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});




// const { ethers } = require("hardhat");

// async function main() {
//     const [deployer] = await ethers.getSigners();
//     console.log("Deploying with account:", deployer.address);

//     // System contract addresses from Citrea testnet documentation
//     const LIGHT_CLIENT_ADDRESS = "0x0000000000000000000000000000000000000001";
//     const BRIDGE_ADDRESS = "0x0000000000000000000000000000000000000002";

//     const CBTC = await ethers.getContractFactory("CBTC");
//     const cBTC = await CBTC.deploy();
//     await cBTC.deployed();
//     console.log("cBTC deployed at:", cBTC.address);

//     const PriceOracle = await ethers.getContractFactory("PriceOracle");
//     const oracle = await PriceOracle.deploy();
//     await oracle.deployed();
//     console.log("Oracle deployed at:", oracle.address);
//     await oracle.setPrice(cBTC.address, ethers.utils.parseEther("1"));

//     const CGOV = await ethers.getContractFactory("CGOV");
//     const cGOV = await CGOV.deploy();
//     await cGOV.deployed();
//     console.log("cGOV deployed at:", cGOV.address);

//     const StableCoin = await ethers.getContractFactory("StableCoin");
//     const stableCoin = await StableCoin.deploy(
//         cBTC.address,
//         ethers.BigNumber.from("1000000000000000000"), // 1:1 ratio
//         oracle.address,
//         200 // stability fee bps
//     );
//     await stableCoin.deployed();
//     console.log("cUSD deployed at:", stableCoin.address);

//     const AMMDEX = await ethers.getContractFactory("AMMDEX");
//     const dex = await AMMDEX.deploy(
//         cBTC.address,
//         stableCoin.address,
//         LIGHT_CLIENT_ADDRESS,
//         BRIDGE_ADDRESS,
//         oracle.address,
//         cGOV.address,
//         30,
//         10,
//         deployer.address
//     );
//     await dex.deployed();
//     console.log("DEX deployed at:", dex.address);

//     await cBTC.transferOwnership(dex.address);
//     console.log("Transferred cBTC ownership to DEX");
// }

// main().catch((error) => {
//     console.error(error);
//     process.exit(1);
// });



