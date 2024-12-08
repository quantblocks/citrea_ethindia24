require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy");

module.exports = {
    solidity: "0.8.18",
    networks: {
        citrea: {
            url: "https://rpc.testnet.citrea.xyz", // Replace with actual Citrea testnet RPC
            accounts: ["3fb28acf11012b8b832ac34070c43c07712987dcb307c1727dd7caf7aedabe0c"] // Replace with your testnet private key
        },
    },
};

