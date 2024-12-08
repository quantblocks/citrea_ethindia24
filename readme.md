# Citrea DEX and Stablecoin Ecosystem


This project implements a decentralized finance (DeFi) ecosystem on the Citrea blockchain, integrating a Light Bitcoin Client for seamless interoperability with the Bitcoin blockchain. It facilitates Bitcoin (`BTC`) bridging into the system and enables decentralized swaps, lending, governance, and payment functionalities. It includes a variety of smart contracts that enable:

- Tokenized BTC (`cBTC`) and a stablecoin (`cUSD`) backed by `cBTC`.
- Automated Market Making (AMM) DEX for swapping between `cBTC` and `cUSD`.
- A lending pool that allows borrowing `cUSD` against `cBTC` collateral.
- Governance mechanisms using a `GovernorContract` and `TimelockController`.
- Collateral management, liquidation auctions, insurance fund.
- Price oracle aggregation.
- A `PaymentGateway` contract to facilitate merchant payments, including off-chain integration with fiat payment gateways like Razorpay.




---

## Features

1. **Light Bitcoin Client Integration:**
   - Verifies Bitcoin transactions using proof data.
   - Fetches the latest Bitcoin blockchain height.
   - Bridges Bitcoin into the ecosystem by minting equivalent `cBTC`.

2. **Tokenized BTC and Stablecoins:**
   - `cBTC`: A wrapped Bitcoin token bridged into the Citrea network.
   - `cUSD`: A stablecoin backed by `cBTC` collateral, mintable via smart contracts.

3. **Decentralized Finance Components:**
   - Automated Market Maker DEX (AMMDEX) for token swaps.
   - Lending pool for borrowing `cUSD` against `cBTC` collateral.
   - Payment gateway for merchant transactions, with potential integration with fiat payment systems like Razorpay.

4. **Governance and Stability:**
   - On-chain governance with `cGOV` tokens.
   - Price oracles and collateral managers ensure fair valuations.
   - Insurance fund to cover protocol shortfalls.

---

## Light Bitcoin Client

### Overview
The Light Bitcoin Client is implemented as an interface, **`ILightClient.sol`**, which provides:
- **Verification of Bitcoin Transactions:** Ensures Bitcoin payments are valid before bridging them into the ecosystem.
- **Blockchain Synchronization:** Retrieves the latest block height of the Bitcoin blockchain for validation purposes.

---


## Directory Structure

```text
citrea-dex/
├── contracts/
│   ├── AMMDEX.sol
│   ├── CBTC.sol
│   ├── CGOV.sol
│   ├── StableCoin.sol
│   ├── LendingPool.sol
│   ├── Governance.sol
│   ├── PriceOracle.sol
│   ├── AggregatorOracle.sol
│   ├── CollateralManager.sol
│   ├── TimelockController.sol
│   ├── GovernorContract.sol
│   ├── InsuranceFund.sol
│   ├── LiquidationAuction.sol
│   ├── RateModel.sol
│   ├── PaymentGateway.sol
│   ├── interfaces/
│   │   ├── IBridge.sol
│   │   ├── ILightClient.sol
│   │   ├── IPriceOracle.sol
│   │   ├── IStableCoin.sol
│   │   ├── ILendingPool.sol
│   │   ├── ICGOV.sol
│   │   ├── IAggregatorOracle.sol
│   │   ├── IGovernor.sol
│   │   ├── ITimelockController.sol
│   │   ├── ICollateralManager.sol
│   │   ├── ILiquidationAuction.sol
│   │   ├── IInsuranceFund.sol
│   │   ├── IRateModel.sol
│   │   └── PaymentGateway.sol 
│   └── libraries/
│       ├── MathLib.sol
│       ├── TWAPLib.sol
│       ├── StableSwapMath.sol
│       ├── VolatilityLib.sol
├── scripts/
│   ├── deploy.js
│   ├── deploy_stablecoin.js
|
├── test/
│   ├── AMMDEX.test.js
│   ├── StableCoin.test.js
│   ├── LendingPool.test.js
│   ├── Governance.test.js
│   ├── .....
├── hardhat.config.js
├── package.json
├── .prettierrc.json
└── README.md
```


## Contracts Overview

### AMMDEX.sol:
An Automated Market Maker (AMM) DEX for swapping `cBTC`↔`cUSD`. It supports:
- Adding and removing liquidity.
- Token swaps with fees.
- Flash loans for arbitrage or other purposes.
- Bridging BTC via a light client.
- Maintaining time-weighted average prices (TWAP).

---

### CBTC.sol:
An ERC20-like token representing wrapped BTC (`cBTC`). Features include:
- Minting and burning, controlled by an authorized owner.
- Acts as the primary collateral token in the ecosystem.

---

### CGOV.sol:
A governance token (`cGOV`) used for:
- Voting in on-chain governance proposals.
- Incentivizing users who participate in the ecosystem.

---

### StableCoin.sol (cUSD):
A stablecoin backed by `cBTC` collateral, offering:
- Minting by depositing `cBTC` collateral.
- Repayment of debts to unlock collateral.
- Liquidation mechanisms for undercollateralized positions.
- Stability fees that accrue over time.

---

### LendingPool.sol:
A lending module for:
- Borrowing `cUSD` against `cBTC` collateral.
- Regular health checks to ensure collateral sufficiency.
- Liquidation of undercollateralized users to protect the system.

---

### Governance.sol:
Provides administrative functions such as:
- Adjusting collateral ratios or fees.
- Ideally governed by decentralized voting via cGOV tokens.

---

### PriceOracle.sol & AggregatorOracle.sol:
- **PriceOracle.sol:** Sets token prices for use in the system.
- **AggregatorOracle.sol:** Aggregates multiple price feeds to provide a reliable median price, mitigating risks from faulty oracles.

---

### CollateralManager.sol:
Responsible for:
- Defining eligible collateral tokens.
- Managing collateral factors and liquidation penalties.
- Fetching token prices from `AggregatorOracle`.

---

### TimelockController.sol & GovernorContract.sol:
- **TimelockController.sol:** Introduces a governance delay, ensuring changes take effect only after a specified period.
- **GovernorContract.sol:** Enables proposals, voting, and execution by `cGOV` token holders, creating a transparent and predictable governance process.

---

### InsuranceFund.sol:
Holds reserve funds for:
- Covering unexpected protocol shortfalls.
- Mitigating risk during extreme market conditions.

---

### LiquidationAuction.sol:
Conducts auctions for collateral from undercollateralized users. Features:
- Allowing bidders to repay debt and claim collateral at discounted rates.
- Ensuring fair liquidation processes.

---

### RateModel.sol:
Implements an interest rate model based on utilization. Features:
- Dynamic adjustment of borrowing costs.
- Helps maintain system balance and incentivize liquidity.

---

### PaymentGateway.sol:
A contract for managing merchant payments. Features include:
- Accepting payments in `cUSD` directly.
- Converting `cBTC` payments into `cUSD` for merchants.
- Allowing merchants to withdraw their on-chain balances.

---

## Interfaces and Libraries

### Interfaces:
Define abstract APIs to enable modular and interchangeable contract components. Key interfaces include:
- **`IPriceOracle`** for price data.
- **`IStableCoin`** for stablecoin operations.
- **`ILendingPool`** for lending interactions.
- Additional interfaces for other key components like governance, oracles, and auctions.

---

### Libraries:
Reusable utilities to optimize contract logic:
- **`MathLib.sol`:** Provides mathematical utilities, such as square root calculations.
- **`TWAPLib.sol`:** Implements time-weighted average price (TWAP) calculations for DEX price tracking.
- **`StableSwapMath.sol`:** A placeholder for implementing stable AMM curves.
- **`VolatilityLib.sol`:** A stub for calculating market volatility.

---



## Setup and Usage in Remix

This section explains how to use the smart contracts in this repository with [Remix](https://remix.ethereum.org/), an online Solidity IDE.

---

### Prerequisites

- A web3-enabled browser (e.g., Chrome or Firefox) with a connected wallet like MetaMask.
- Basic knowledge of smart contracts and the Ethereum Virtual Machine (EVM).

---

### Steps to Use in Remix

1. **Open Remix:**
   - Navigate to [Remix IDE](https://remix.ethereum.org/).

2. **Import the Code:**
   - Copy the `contracts` directory from this repository into Remix:
     1. In the Remix file explorer, create a new folder named `citrea-dex`.
     2. Create subfolders for `contracts`, `interfaces`, and `libraries`.
     3. Copy the relevant `.sol` files from this repository into the appropriate folders.

3. **Install OpenZeppelin Dependencies:**
   - Contracts like `CBTC.sol` and `CGOV.sol` use OpenZeppelin libraries.
   - Install OpenZeppelin libraries in Remix:
     1. Open the **File Explorer** tab in Remix.
     2. Right-click on the workspace folder (e.g., `citrea-dex`) and select **"Enable GitHub Dependency"**.
     3. Add the dependency `@openzeppelin/contracts` in the imports dropdown.

4. **Compile the Contracts:**
   - Go to the **Solidity Compiler** tab.
   - Select the Solidity version `0.8.18` to match the contracts.
   - Click **Compile All** or compile specific contracts like `AMMDEX.sol` or `PaymentGateway.sol`.

5. **Deploy the Contracts:**
   - Switch to the **Deploy & Run Transactions** tab.
   - Select an environment:
     - **Injected Web3** (if using MetaMask with a live testnet like Goerli or Sepolia).
     - **Remix VM** (for local testing).
   - Deploy contracts in the correct order:
     1. Deploy `CBTC.sol` and `CGOV.sol` tokens.
     2. Deploy `PriceOracle.sol` and set initial token prices.
     3. Deploy `StableCoin.sol`, linking it to the deployed `CBTC` token and `PriceOracle`.
     4. Deploy `AMMDEX.sol`, linking it to `CBTC`, `StableCoin`, and other dependencies.
     5. Deploy `PaymentGateway.sol`, linking it to `StableCoin`, `CBTC`, and `AMMDEX`.

6. **Interact with Contracts:**
   - After deploying, use Remix's **Deployed Contracts** section to interact with the contracts.
   - Example actions:
     - Mint `cBTC` using the `mint` function in `CBTC.sol`.
     - Add liquidity to the DEX using `addLiquidity` in `AMMDEX.sol`.
     - Make a payment using `payMerchant` in `PaymentGateway.sol`.

7. **Testing PaymentGateway Integration:**
   - Use the `registerMerchant` function to register a merchant.
   - Call `payMerchant` to simulate a payment in `cUSD`.
   - Call `withdrawMerchantFunds` to simulate a merchant withdrawing funds.

8. **Save and Export Contracts:**
   - To save your progress, download the workspace or specific files from Remix by right-clicking on them and selecting **Download**.

---

### Example Deployment Walkthrough

- Deploy the `CBTC` token:
  - Use `CBTC.sol` and click **Deploy**.
  - After deployment, copy the `CBTC` contract address for use in other contracts.

- Deploy the `PriceOracle`:
  - Use `PriceOracle.sol` and click **Deploy**.
  - Set initial prices for tokens using the `setPrice` function.

- Deploy the `StableCoin`:
  - Deploy `StableCoin.sol`, passing the following parameters:
    1. Address of `CBTC` contract.
    2. Initial collateral ratio (e.g., `1000000000000000000` for 100%).
    3. Address of the deployed `PriceOracle`.
    4. Stability fee (e.g., `200` for 2% annual fee).
  - After deployment, note down the `StableCoin` contract address.

- Deploy the `AMMDEX`:
  - Use the `AMMDEX.sol` contract.
  - Provide addresses for `CBTC`, `StableCoin`, and other dependencies.
  - Set liquidity pool fees in basis points (e.g., 30 for 0.3%).

- Deploy the `PaymentGateway`:
  - Use the `PaymentGateway.sol` contract.
  - Provide addresses for `StableCoin`, `CBTC`, and `AMMDEX`.

---

### Troubleshooting

1. **Contract Compilation Errors:**
   - Ensure you are using the correct Solidity version (`0.8.18`).
   - Check for missing imports (e.g., OpenZeppelin contracts).

2. **Out-of-Gas Issues:**
   - Increase the gas limit in the **Deploy & Run Transactions** tab.

3. **Token Address Not Recognized:**
   - Verify the deployed addresses are correctly passed to dependent contracts during deployment.

