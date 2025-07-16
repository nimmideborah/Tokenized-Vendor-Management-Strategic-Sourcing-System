# Tokenized Vendor Management Strategic Sourcing System

## Overview

A comprehensive blockchain-based vendor management system that tokenizes strategic sourcing processes, enabling transparent and efficient supplier management, market analysis, and value optimization.

## System Architecture

The system consists of five interconnected smart contracts:

### 1. Strategic Sourcing Manager Verification (`sourcing-manager.clar`)
- Validates and manages strategic sourcing managers
- Handles manager registration and verification
- Tracks manager performance and credentials

### 2. Market Analysis Contract (`market-analysis.clar`)
- Analyzes sourcing markets and trends
- Provides market intelligence and insights
- Tracks market conditions and pricing data

### 3. Supplier Identification Contract (`supplier-identification.clar`)
- Identifies and evaluates strategic suppliers
- Manages supplier profiles and capabilities
- Handles supplier onboarding and verification

### 4. Negotiation Coordination Contract (`negotiation-coordination.clar`)
- Coordinates sourcing negotiations between parties
- Manages negotiation rounds and proposals
- Tracks negotiation outcomes and agreements

### 5. Value Optimization Contract (`value-optimization.clar`)
- Optimizes sourcing value across the supply chain
- Calculates cost savings and efficiency metrics
- Provides recommendations for value enhancement

## Key Features

- **Tokenized Management**: All vendor interactions are tokenized for transparency
- **Strategic Sourcing**: Focus on long-term supplier relationships
- **Market Intelligence**: Real-time market analysis and insights
- **Automated Negotiations**: Streamlined negotiation processes
- **Value Optimization**: Continuous improvement of sourcing outcomes
- **Decentralized Governance**: Community-driven decision making

## Data Structures

### Manager Profile
- Manager ID (uint)
- Principal address
- Verification status
- Performance metrics
- Specialization areas

### Market Data
- Market ID (uint)
- Category information
- Price trends
- Supply/demand metrics
- Risk assessments

### Supplier Profile
- Supplier ID (uint)
- Company information
- Capabilities and certifications
- Performance history
- Contract terms

### Negotiation Session
- Session ID (uint)
- Participating parties
- Terms and conditions
- Status tracking
- Final agreements

### Value Metrics
- Optimization ID (uint)
- Cost savings achieved
- Efficiency improvements
- Quality enhancements
- Risk reductions

## Error Codes

- `ERR-NOT-AUTHORIZED` (u100): Caller not authorized for action
- `ERR-INVALID-INPUT` (u101): Invalid input parameters
- `ERR-NOT-FOUND` (u102): Requested item not found
- `ERR-ALREADY-EXISTS` (u103): Item already exists
- `ERR-INSUFFICIENT-BALANCE` (u104): Insufficient token balance
- `ERR-INVALID-STATUS` (u105): Invalid status for operation
- `ERR-EXPIRED` (u106): Request or session expired
- `ERR-LIMIT-EXCEEDED` (u107): Operation limit exceeded

## Installation

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `npm test` to execute test suite

## Usage

### Deploy Contracts
\`\`\`bash
clarinet deploy --testnet
\`\`\`

### Run Tests
\`\`\`bash
npm test
\`\`\`

### Interact with Contracts
Use Clarinet console or integrate with frontend applications using Stacks.js

## Testing

The system includes comprehensive tests using Vitest:
- Unit tests for each contract function
- Integration tests for cross-contract interactions
- Edge case and error condition testing
- Performance and gas optimization tests

## Security Considerations

- All functions include proper authorization checks
- Input validation prevents malicious data
- State transitions are carefully managed
- Emergency pause functionality included
- Regular security audits recommended

## Contributing

1. Fork the repository
2. Create feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit pull request

## License

MIT License - see LICENSE file for details
