# 🏛️ English Auction — Solidity + Go Smart Contract

A production-ready **English Auction** smart contract built with **Solidity**, **Foundry**, and **OpenZeppelin**. Includes Go bindings via `abigen` for interacting with the contract from Go applications.

> **Learning Project** — Following along with smart contract development tutorials and building Go integration for blockchain interaction.

---

## 📦 What's Inside

```
├── src/
│   ├── EnglishAuction.sol    # Main auction contract (OpenZeppelin secured)
│   └── MyNFT.sol             # ERC721 NFT contract (for testing)
├── test/
│   └── EnglishAuction.t.sol  # 15 unit tests covering all functions
├── script/
│   └── EnglishAuction.s.sol  # Deployment script
├── pkg/
│   └── contract/
│       └── auction.go        # Auto-generated Go bindings (via abigen)
└── out/                      # Compiled artifacts (ABI, bytecode)
```

---

## 🔐 Smart Contract Features

### EnglishAuction.sol

An English auction where the **highest bidder wins an NFT**:

| Function                      | What It Does                                                      |
| ----------------------------- | ----------------------------------------------------------------- |
| `start(openingBid, duration)` | Owner starts the auction, NFT is escrowed in the contract         |
| `bid()`                       | Anyone (except owner) can bid higher than the current highest bid |
| `withdraw()`                  | Outbid bidders can withdraw their funds                           |
| `end()`                       | Owner ends the auction after duration passes, NFT goes to winner  |

### Security Measures

- ✅ **ReentrancyGuard** (OpenZeppelin) on `withdraw()` and `end()`
- ✅ **Checks-Effects-Interactions (CEI)** pattern throughout
- ✅ **`call{value:}`** instead of `transfer()` for safe ETH sends
- ✅ **Owner cannot self-bid** — prevents price manipulation
- ✅ **Zero-bid edge case** — NFT returns to owner if no one bids
- ✅ **Immutable variables** — owner, NFT address, and token ID cannot be changed

---

## 🛠️ Prerequisites

Make sure you have these installed:

| Tool           | Install                                 | Verify            |
| -------------- | --------------------------------------- | ----------------- |
| **Foundry**    | [getfoundry.sh](https://getfoundry.sh/) | `forge --version` |
| **Go** (1.21+) | [go.dev/dl](https://go.dev/dl/)         | `go version`      |
| **Git**        | [git-scm.com](https://git-scm.com/)     | `git --version`   |

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Atharva0506/go-solidity-contracts.git
cd go-solidity-contracts
```

### 2. Install Dependencies

```bash
# Install Foundry dependencies (OpenZeppelin, forge-std)
forge install
```

### 3. Build the Smart Contracts

```bash
forge build
```

This compiles all `.sol` files and outputs artifacts (ABI, bytecode) to the `out/` directory.

### 4. Run Tests

```bash
# Run all 15 tests
forge test

# Run with verbose output (see individual test results)
forge test -vvv
```

---

## 🔗 Go Bindings (Connecting Solidity ↔ Go)

This is the key part — generating Go code that can **deploy and interact** with the smart contract.

### Step 1: Extract ABI and Bytecode

```bash
# ABI = Application Binary Interface (describes the contract's functions)
forge inspect EnglishAuction abi > out/EnglishAuction.abi

# Bytecode = compiled contract code (needed for deployment)
forge inspect EnglishAuction bytecode > out/EnglishAuction.bin
```

**What is ABI?** — Think of it like an API schema. It tells Go what functions exist, what arguments they take, and what they return.

**What is Bytecode?** — The compiled EVM (Ethereum Virtual Machine) code that actually runs on the blockchain.

### Step 2: Install `abigen`

```bash
# abigen is a tool from go-ethereum that generates Go bindings
go install github.com/ethereum/go-ethereum/cmd/abigen@latest
```

### Step 3: Generate Go Bindings

```bash
# Create the output directory
mkdir -p pkg/contract

# Generate Go code from ABI + bytecode
abigen \
  --bin=out/EnglishAuction.bin \
  --abi=out/EnglishAuction.abi \
  --pkg=contract \
  --out=pkg/contract/auction.go
```

This creates `pkg/contract/auction.go` with Go functions like:

- `DeployEnglishAuction(...)` — deploy the contract
- `auction.Start(...)` — call the start function
- `auction.Bid(...)` — place a bid
- `auction.End(...)` — end the auction

### Step 4: Initialize Go Module

```bash
go mod init github.com/Atharva0506/go-solidity-contracts
go mod tidy
```

---

## 📜 Deploy to Local Testnet (Anvil)

To deploy the smart contract to a local blockchain environment, we use Foundry's `anvil` node and `forge script`.

### 1. Start Anvil (Local Blockchain)

Open a new terminal window and run:

```bash
# Start the local Ethereum node
anvil
```

Keep this terminal running. It will start a local chain at `http://127.0.0.1:8545` and provide 10 pre-funded test accounts with their private keys.

### 2. Deploy with Foundry Script

Open a **second terminal window** (in the same project directory) and run the deployment script. 

> **Where does the private key come from?**
> When you start `anvil`, it deterministically generates 10 test accounts, each loaded with 10,000 fake ETH. The private key `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` is the **well-known default private key for Account #0** in Anvil. You will see it listed in your first terminal window under "Private Keys".

```bash
# Deploy the NFT and English Auction contracts
forge script script/EnglishAuction.s.sol:EnglishAuctionScript \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

### 3. Verify Deployment

If successful, you will see output similar to this:
```text
== Logs ==
  MyNFT deployed at: 0x...
  NFT #1 minted to: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  EnglishAuction deployed at: 0x...
  Auction approved to transfer NFT #1
```

You can now interact with the deployed contracts at these addresses using `cast` commands or your generated Go bindings!

---

## 🧪 Test Coverage

| Test                                     | What It Verifies             |
| ---------------------------------------- | ---------------------------- |
| `test_ConstructorSetsOwner`              | Owner is set correctly       |
| `test_ConstructorSetsNFT`                | NFT contract is linked       |
| `test_ConstructorSetsNftId`              | Token ID is stored           |
| `test_StartAuction`                      | Auction starts, NFT escrowed |
| `test_RevertStartIfNotOwner`             | Only owner can start         |
| `test_RevertStartIfAlreadyStarted`       | Can't start twice            |
| `test_Bid`                               | Valid bid is accepted        |
| `test_RevertBidIfNotStarted`             | Can't bid before start       |
| `test_RevertBidIfTooLow`                 | Rejects low bids             |
| `test_RevertBidIfOwner`                  | Owner can't bid              |
| `test_OutbidRefundsAreSaved`             | Outbid amounts are tracked   |
| `test_Withdraw`                          | Outbid bidder gets refund    |
| `test_RevertWithdrawIfNothingToWithdraw` | No empty withdrawals         |
| `test_EndAuction`                        | NFT → winner, ETH → owner    |
| `test_EndAuctionWithNoBids`              | NFT returns to owner         |

---

## 📚 How English Auctions Work

```
1. Owner creates auction with an NFT
2. Owner calls start() → NFT is locked in the contract
3. Bidders call bid() with ETH → must beat current highest
4. Outbid bidders call withdraw() to get their ETH back
5. After duration ends, owner calls end()
   → NFT goes to highest bidder
   → ETH goes to owner
```

---

## 🧰 Useful Commands

```bash
forge build              # Compile contracts
forge test -vvv          # Run tests (verbose)
forge fmt                # Format Solidity code
forge snapshot           # Gas usage snapshot
forge inspect <Contract> abi      # View contract ABI
forge inspect <Contract> bytecode # View contract bytecode
anvil                    # Start local blockchain
cast call <addr> "functionName()" --rpc-url <url>  # Read from contract
```

---

## 📖 Resources

- [Foundry Book](https://book.getfoundry.sh/) — Foundry documentation
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/) — Security library
- [go-ethereum](https://geth.ethereum.org/) — Go Ethereum client & tools
- [Solidity by Example](https://solidity-by-example.org/) — Learn Solidity patterns

---
