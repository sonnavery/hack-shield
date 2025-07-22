# Hack-Shield: Parametric DeFi Exploit Insurance

[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-purple)](https://stacks.co/)
[![Clarity](https://img.shields.io/badge/Language-Clarity-blue)](https://clarity-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

Hack-Shield is a parametric insurance protocol built on the Stacks blockchain that provides automated coverage for DeFi exploit risks. Users can purchase insurance policies for specific protocols and receive instant payouts when verified exploits occur.

## 🎯 Overview

Traditional DeFi insurance requires manual claim assessment and lengthy payout processes. Hack-Shield revolutionizes this by using parametric insurance - claims are automatically processed based on predetermined triggers (exploit events) verified by trusted oracles.

### Key Benefits
- **Instant Payouts**: Automated claim processing when exploits are verified
- **Transparent Pricing**: Dynamic risk-based premium calculation
- **Protocol Agnostic**: Support for any DeFi protocol
- **Decentralized**: Built on Stacks blockchain with minimal trust assumptions

## 🏗️ Architecture

### Core Components

1. **Policy Management**: Create, manage, and cancel insurance policies
2. **Oracle System**: Trusted data feeds for exploit events and risk scores
3. **Premium Pool**: Collects and manages insurance premiums
4. **Claims Engine**: Automated claim verification and payout system

### Data Structures

- **Policies**: Individual insurance contracts with coverage details
- **Risk Scores**: Dynamic risk assessments for DeFi protocols (1-10 scale)
- **Exploit Events**: Verified exploit occurrences with metadata
- **User Portfolios**: Track multiple policies per user

## 🚀 Getting Started

### Prerequisites

- Stacks wallet (Hiro Wallet, Xverse, etc.)
- STX tokens for premiums and gas fees
- Basic understanding of DeFi protocols

### Installation

1. Deploy the contract to Stacks blockchain:
```bash
clarinet deploy --network mainnet
```

2. Initialize oracle address and risk scores:
```clarity
(contract-call? .hack-shield set-oracle-address 'SP1ABC...)
```

### Basic Usage

#### 1. Create an Insurance Policy

```clarity
(contract-call? .hack-shield create-policy 
  "uniswap-v3"     ;; Protocol identifier
  u10000000        ;; Coverage amount (10 STX)
  u1008)           ;; Duration (1 week in blocks)
```

#### 2. File a Claim

```clarity
(contract-call? .hack-shield file-claim u1) ;; Policy ID
```

#### 3. Cancel Policy (Pro-rated Refund)

```clarity
(contract-call? .hack-shield cancel-policy u1)
```

## 📋 API Reference

### Read-Only Functions

#### `get-policy (policy-id uint)`
Returns policy details for a given policy ID.

#### `calculate-premium (coverage-amount uint) (protocol string-ascii) (duration-blocks uint)`
Calculates premium for given parameters before policy creation.

#### `get-protocol-risk (protocol string-ascii)`
Returns current risk score and last update for a protocol.

#### `get-user-policies (user principal)`
Returns list of policy IDs owned by a user.

### Public Functions

#### `create-policy (protocol-address string-ascii) (coverage-amount uint) (duration-blocks uint)`
Creates a new insurance policy.

**Parameters:**
- `protocol-address`: DeFi protocol identifier
- `coverage-amount`: Maximum payout in microSTX
- `duration-blocks`: Policy duration in blocks

**Returns:** Policy ID

#### `file-claim (policy-id uint)`
Files a claim for exploit coverage.

**Requirements:**
- Policy must be active and not expired
- Exploit event must be verified by oracle
- Claim not already processed

#### `cancel-policy (policy-id uint)`
Cancels active policy with pro-rated refund.

**Returns:** Refund amount

### Administrative Functions

#### `update-protocol-risk (protocol string-ascii) (risk-level uint)`
Updates risk score for a protocol (Oracle only).

#### `report-exploit (protocol string-ascii) (exploit-amount uint)`
Reports verified exploit event (Oracle only).

## 💰 Premium Calculation

Premiums are calculated using the formula:

```
Premium = (Coverage × Base Rate × Risk Multiplier × Duration Multiplier) / 10000
```

Where:
- **Base Rate**: 1% (100/10000)
- **Risk Multiplier**: Protocol risk score (1-10)
- **Duration Multiplier**: Duration in weeks

### Example
- Coverage: 10 STX
- Protocol: Uniswap V3 (Risk: 3)
- Duration: 1 week
- Premium: (10 × 100 × 3 × 1) / 10000 = 0.3 STX

## 🛡️ Risk Scoring

Protocols are assigned risk scores from 1-10:

| Score | Risk Level | Description |
|-------|-----------|-------------|
| 1-2   | Very Low  | Battle-tested protocols with excellent security |
| 3-4   | Low       | Established protocols with good track record |
| 5-6   | Medium    | Newer protocols or those with moderate complexity |
| 7-8   | High      | Experimental protocols or complex mechanisms |
| 9-10  | Very High | Cutting-edge or unaudited protocols |

### Default Risk Scores
- Aave V3: 2 (Very Low)
- Uniswap V3: 3 (Low)
- Compound V3: 4 (Low)
- Curve Finance: 5 (Medium)

## 🔒 Security Features

### Access Control
- **Contract Owner**: Emergency functions and oracle management
- **Oracle**: Risk updates and exploit reporting
- **Users**: Policy management and claims

### Safety Mechanisms
- Minimum premium requirements
- Policy expiration enforcement
- Double-claim prevention
- Emergency pause functionality

### Error Codes
- `u100`: Not authorized
- `u101`: Invalid policy parameters
- `u102`: Insufficient funds
- `u103`: Policy expired
- `u104`: Policy not found
- `u105`: Claim already processed
- `u106`: Invalid oracle data
- `u107`: Below minimum premium

## 📊 Monitoring & Analytics

### Key Metrics
- Total Premium Pool
- Active Policies Count
- Claims Processed
- Protocol Risk Scores
- Average Premium Rates

### Events to Monitor
- Policy creations
- Claim filings and payouts
- Risk score updates
- Exploit event reports

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Key test scenarios:
- Policy lifecycle (create, claim, cancel)
- Premium calculations
- Oracle data updates
- Access control enforcement
- Edge cases and error conditions

## 🚨 Emergency Procedures

### For Users
1. **Exploit Detected**: File claim immediately if you have coverage
2. **Policy Issues**: Contact support or use emergency withdrawal if available
3. **Oracle Problems**: Monitor official channels for updates

### For Administrators
1. **Emergency Pause**: Use `pause-new-policies` to halt new policy creation
2. **Emergency Withdrawal**: Extract funds if critical vulnerability discovered
3. **Oracle Updates**: Ensure timely risk score and exploit reporting

## 📈 Roadmap

### Phase 1 (Current)
- ✅ Basic parametric insurance functionality
- ✅ Oracle integration
- ✅ Risk-based pricing

### Phase 2 (Planned)
- 🔄 Multi-oracle consensus mechanism
- 🔄 Liquidity provider system
- 🔄 Automated risk scoring via ML

### Phase 3 (Future)
- ⏳ Cross-chain protocol coverage
- ⏳ Governance token and DAO
- ⏳ Advanced derivatives and options

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md).

### Development Setup
1. Install Clarinet: `curl -L https://raw.githubusercontent.com/hirosystems/clarinet/main/install.sh | sh`
2. Clone repository: `git clone https://github.com/hack-shield/protocol`
3. Run tests: `clarinet test`
