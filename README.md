# OrdinalVault 🏛️

> **Bitcoin-Native NFT Treasury & Liquidity Protocol**

A revolutionary Bitcoin-secured digital asset management platform that transforms NFTs into productive financial instruments through decentralized vaulting, fractional ownership, and automated yield generation powered by Stacks' smart contract capabilities.

[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-purple.svg)](https://stacks.co/)
[![Clarity](https://img.shields.io/badge/Smart%20Contract-Clarity-orange.svg)](https://clarity-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)]()

## 🌟 Overview

OrdinalVault bridges the gap between Bitcoin's pristine security and DeFi innovation by creating a sophisticated treasury management system for digital collectibles. Built on Stacks, every transaction inherits Bitcoin's immutable security while enabling programmable money features that traditional Bitcoin cannot provide.

### Key Features

- **🔒 Collateral-Backed NFTs**: Mint NFTs with STX collateral backing using Bitcoin-inspired security models
- **🛒 Trustless Marketplace**: Peer-to-peer trading with automated fee distribution
- **📊 Fractional Ownership**: Enhanced liquidity through innovative share tokenization
- **💰 Yield Generation**: Passive income via intelligent staking mechanisms
- **🏦 Treasury Management**: Sophisticated asset management for institutions and collectors

## 🏗️ Architecture

### System Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   NFT Minting   │    │   Marketplace    │    │ Staking System  │
│                 │    │                  │    │                 │
│ • Collateral    │◄──►│ • Listings       │◄──►│ • Yield Gen     │
│ • Validation    │    │ • Atomic Swaps   │    │ • Rewards       │
│ • Security      │    │ • Fee Collection │    │ • Time-based    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Fractional Ownership  │
                    │                         │
                    │ • Share Transfers       │
                    │ • Liquidity Enhancement │
                    │ • Multi-owner Support   │
                    └─────────────────────────┘
```

### Contract Architecture

The OrdinalVault contract is structured into several key modules:

#### Core Constants & Error Handling

```clarity
- CONTRACT-OWNER: Contract deployment authority
- Error codes: Comprehensive error handling (ERR-100 to ERR-112)
- Protocol parameters: Configurable system settings
```

#### Data Structures

```clarity
- tokens: Primary NFT registry with comprehensive metadata
- token-listings: Decentralized marketplace listings
- fractional-ownership: Multi-owner share tracking
- staking-rewards: Yield generation and distribution
```

#### Function Categories

- **🏭 Minting System**: `mint-nft`, collateral validation
- **🔄 Transfer System**: `transfer-nft`, ownership management
- **🛒 Marketplace**: `list-nft`, `purchase-nft`, atomic operations
- **📈 Staking Protocol**: `stake-nft`, `unstake-nft`, yield calculation
- **🔍 Query Interface**: Read-only functions for data access

## 💡 Data Flow

### NFT Lifecycle

```
1. Mint NFT → Lock Collateral → Register Token
2. Optional: List on Marketplace → Enable Trading
3. Optional: Stake for Yield → Earn Rewards
4. Optional: Fractionalize → Enable Shared Ownership
5. Transfer/Trade → Update Ownership Records
```

### Staking Rewards Flow

```
Stake NFT → Track Block Height → Calculate Yield → Distribute STX Rewards
    ↓              ↓                  ↓              ↓
Initialize     Time-based         Real-time      Claim/Compound
State          Tracking          Calculation     Mechanism
```

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) - JavaScript runtime
- [Git](https://git-scm.com/) - Version control

### Installation

```bash
# Clone the repository
git clone https://github.com/femi-ayo/ordinal-vault.git
cd ordinal-vault

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test
```

### Contract Deployment

```bash
# Deploy to devnet
clarinet deploy --devnet

# Deploy to testnet
clarinet deploy --testnet
```

## 📋 Usage Examples

### Minting an NFT

```clarity
;; Mint NFT with 1000 STX collateral
(contract-call? .ordinal-vault mint-nft 
  "https://example.com/metadata/1.json" 
  u1000)
```

### Listing for Sale

```clarity
;; List NFT for 500 STX
(contract-call? .ordinal-vault list-nft u1 u500)
```

### Staking for Yield

```clarity
;; Stake NFT to earn rewards
(contract-call? .ordinal-vault stake-nft u1)
```

### Fractional Share Transfer

```clarity
;; Transfer 100 shares to another user
(contract-call? .ordinal-vault transfer-shares 
  u1 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
  u100)
```

## 🔧 Configuration

### Protocol Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `min-collateral-ratio` | 150% | Minimum collateral requirement |
| `protocol-fee` | 2.5% | Marketplace transaction fee |
| `yield-rate` | 5% | Annual staking yield rate |

### Modifying Parameters (Owner Only)

```clarity
;; Update collateral ratio
(var-set min-collateral-ratio u200) ;; 200%

;; Update protocol fee
(var-set protocol-fee u30) ;; 3.0%
```

## 🧪 Testing

The contract includes comprehensive test coverage:

```bash
# Run all tests
npm test

# Run specific test file
npm test ordinal-vault.test.ts

# Check contract with Clarinet
clarinet check
```

### Test Categories

- ✅ NFT Minting & Validation
- ✅ Marketplace Operations
- ✅ Staking & Rewards
- ✅ Fractional Ownership
- ✅ Error Handling
- ✅ Security Validations

## 📊 Economics

### Collateral Model

- **Over-collateralization**: 150% minimum ratio ensures system stability
- **Bitcoin-inspired**: Conservative approach following Bitcoin's security principles
- **Dynamic backing**: Collateral locked in contract vault during NFT lifetime

### Fee Structure

- **Marketplace fee**: 2.5% on all transactions
- **Protocol treasury**: Fees collected for ongoing development and maintenance
- **Yield distribution**: STX rewards paid from staking pool

### Yield Generation

- **Base rate**: 5% annual yield for staked NFTs
- **Block-based calculation**: Rewards calculated per Stacks block
- **Compound growth**: Unclaimed rewards continue to accumulate

## 🔒 Security Features

### Built-in Protections

- **Overflow protection**: Safe arithmetic operations
- **Access control**: Owner-only functions for critical operations
- **Input validation**: Comprehensive parameter checking
- **State consistency**: Atomic operations prevent partial state updates

### Audit Considerations

- Collateral requirements prevent undercollateralized positions
- Time-locked staking prevents reward gaming
- Multi-signature ready for governance upgrades
- Emergency pause functionality for critical situations

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [Wiki](https://github.com/femi-ayo/ordinal-vault/wiki)
- **Issues**: [GitHub Issues](https://github.com/femi-ayo/ordinal-vault/issues)
- **Discussions**: [GitHub Discussions](https://github.com/femi-ayo/ordinal-vault/discussions)
- **Discord**: [Community Chat](https://discord.gg/ordinalvault)

## 🗺️ Roadmap

### Phase 1: Core Protocol ✅

- [x] NFT minting with collateral backing
- [x] Basic marketplace functionality
- [x] Staking and yield generation
- [x] Fractional ownership system

### Phase 2: Enhanced Features 🚧

- [ ] Governance token integration
- [ ] Advanced yield strategies
- [ ] Cross-chain bridge support
- [ ] Mobile app interface

### Phase 3: Ecosystem Growth 📋

- [ ] Institutional custody features
- [ ] Advanced analytics dashboard
- [ ] Third-party integrations
- [ ] Automated market makers

## 📈 Metrics

Current protocol statistics:

- **Total Value Locked (TVL)**: Dynamic based on staked collateral
- **Active NFTs**: Tracked via `total-supply`
- **Staking Participation**: Monitored through `total-staked`
- **Yield Distribution**: Real-time reward calculations

## 🏛️ Governance

OrdinalVault is designed with future governance in mind:

- **Parameter updates**: Community-driven protocol modifications
- **Upgrade proposals**: Transparent improvement processes
- **Treasury management**: Decentralized fund allocation
- **Emergency procedures**: Multi-signature emergency responses

---

*Built with ❤️ by the OrdinalVault team on Stacks blockchain*

**Perfect for institutions, collectors, and DeFi enthusiasts seeking maximum security with optimal capital efficiency.**
