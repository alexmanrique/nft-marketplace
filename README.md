# NFT Marketplace

A decentralized marketplace for buying and selling NFTs (ERC721) built with Solidity and Foundry.

## 📋 Description

This project implements a smart contract marketplace that allows users to:

- **List NFTs**: Owners can list their NFTs with a specific price
- **Buy NFTs**: Users can purchase listed NFTs by paying the set price
- **Cancel listings**: Sellers can cancel their listings before they are purchased

The marketplace charges a configurable fee percentage on each sale, which is collected by the contract owner.

## 🏗️ Architecture

The `NFTMarketplace` contract inherits from:

- **Ownable**: Access control for administrative functions
- **ReentrancyGuard**: Protection against reentrancy attacks

### Fee System

The marketplace uses a percentage-based fee system:

- **Fee Percentage**: Set during contract deployment via constructor
- **Fee Format**: `100 = 100%`, `10 = 10%`, `1 = 1%` (basis points divided by 100)
- **Fee Collection**: Fees are automatically deducted from each sale and sent to the contract owner
- **Seller Receives**: `listing price - fee`
- **Marketplace Owner Receives**: `fee`

### Data Structure

```solidity
struct Listing {
    uint256 price;        // NFT price in wei
    address seller;       // Seller address
    address nftAddress;   // NFT contract address
    uint256 tokenId;      // NFT token ID
}
```

## 🔧 Main Functions

### `listNFT(address nftAddress_, uint256 tokenId_, uint256 price)`

Lists an NFT on the marketplace.

**Requirements:**

- Price must be greater than 0
- `msg.sender` must be the owner of the NFT

**Events:**

- `NFTListed`: Emitted when an NFT is successfully listed

### `buyNFT(address nftAddress_, uint256 tokenId_) payable`

Purchases a listed NFT.

**Requirements:**

- The listing must exist
- Price must be greater than 0
- `msg.value` must equal the listing price
- Reentrancy protection with `nonReentrant`

**Process:**

1. Transfers the NFT from seller to buyer using `safeTransferFrom`
2. Calculates the marketplace fee based on the sale price
3. Sends payment to the seller (price minus fee)
4. Sends the fee to the marketplace owner
5. Deletes the listing

**Fee Calculation:**

- Fee = `(price * feePercentage) / 100`
- Seller receives: `price - fee`
- Marketplace owner receives: `fee`

**Events:**

- `NFTSold`: Emitted when an NFT is successfully sold

### `cancelListing(address nftAddress_, uint256 tokenId_)`

Cancels an existing listing.

**Requirements:**

- `msg.sender` must be the seller of the listing

**Events:**

- `NFTCancelled`: Emitted when a listing is cancelled

### Fee Management Functions

#### `getFeePercentage() view returns (uint256)`

Returns the current fee percentage configured in the marketplace.

#### `setFeePercentage(uint256 feePercentage_) onlyOwner`

Updates the marketplace fee percentage. Only callable by the contract owner.

**Requirements:**

- `msg.sender` must be the contract owner

**Example:**

```solidity
// Set fee to 2.5% (feePercentage = 2.5)
marketplace.setFeePercentage(2.5);
```

#### `calculateFee(uint256 amount) view returns (uint256)`

Calculates the marketplace fee for a given amount.

**Formula:** `(amount * feePercentage) / 100`

## 💰 Fee Examples

Assuming a fee percentage of 2% (`feePercentage = 2`):

- **NFT Price**: 1 ETH
- **Fee**: 0.02 ETH (2%)
- **Seller Receives**: 0.98 ETH
- **Marketplace Owner Receives**: 0.02 ETH

## 📦 Installation

This project uses [Foundry](https://book.getfoundry.sh/getting-started/installation).

### Prerequisites

- Rust (to install Foundry)
- Git

### Foundry Installation

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Clone and Setup Project

```shell
git clone <repository-url>
cd nft-marketplace
forge install
```

## 🚀 Usage

### Build

```shell
forge build
```

### Run Tests

```shell
forge test
```

To see detailed logs:

```shell
forge test -vvv
```

### Format Code

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Anvil (Local Network)

Start a local Ethereum network:

```shell
anvil
```

### Deploy

```shell
forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

## 🧪 Testing

The project includes comprehensive tests in `test/NFTMarkketplace.t.sol` covering:

- NFT listing
- NFT purchasing
- Listing cancellation
- Validations and edge cases

## 📚 Dependencies

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts): Secure and audited contracts
  - `Ownable`: Access control
  - `ReentrancyGuard`: Reentrancy protection
  - `IERC721`: Standard interface for NFTs

## 🔒 Security

- ✅ Reentrancy protection with `ReentrancyGuard`
- ✅ Ownership validation before listing
- ✅ Price and payment validation
- ✅ Use of `safeTransferFrom` for secure NFT transfers
- ✅ Fee calculation prevents overflow with safe arithmetic
- ✅ Owner-only access control for fee management

## 📝 Events

The contract emits the following events:

- `NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price)`
- `NFTSold(address indexed buyer, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 price)`
- `NFTCancelled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId)`

## 🤝 Contributing

Contributions are welcome. Please:

1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Useful Links

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [ERC-721 Standard](https://eips.ethereum.org/EIPS/eip-721)
