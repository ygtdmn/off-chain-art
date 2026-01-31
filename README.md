# Off-Chain Art

![Off-Chain Art](artwork.png)

Off-Chain Art is a 1/1 artwork and a framework for long-term preservation of artwork that can't fit fully on-chain.

Instead of storing artwork at a single tokenURI, it spreads the image across multiple storage solutions. If some links
break over time, others will still serve the file.

## How It Works

The token itself is an on-chain HTML page that:

1. Iterates through a list of image URLs stored in the contract
2. Fetches each URL and checks its availability
3. Computes the SHA-256 hash of the fetched image
4. Compares it against the expected hash stored in the contract
5. Displays the first image that passes hash verification

This ensures no alternate or fake image can ever be displayed, even though the images are hosted off-chain.

## Storage Locations

For this piece, the artwork is stored across 6 different locations:

- 2 different IPFS pinning services (web3.storage, Lighthouse)
- Arweave
- GitHub
- Amazon S3
- Internet Archive

Both the artist and the collector can add new URLs to the contract at any time, expanding the redundancy.

## On-Chain Components

While the artwork image lives off-chain, the following are fully on-chain:

- **Metadata** (name, description, attributes) - stored as a base64 data URI
- **HTML/Animation** - the interactive viewer page that loads and verifies images
- **Thumbnail** - a compressed WebP image stored on-chain using SSTORE2 and FastLZ compression

This scored 5/5 on [OnChainChecker](https://onchainchecker.xyz) by tokenfox.eth.

## Display Modes

The collector can toggle between two display modes:

- **IMAGE mode** - displays a single selected image directly
- **HTML mode** - displays the interactive HTML page that checks all URLs, verifies hashes, and loads the artwork with
  pan/zoom support

## Contracts

Three Solidity contracts make up the system, deployed on Ethereum Mainnet and Sepolia.

**Mainnet**

| Contract                    | Address                                                                                                                 |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| OffChainArt                 | [`0xdbbb0ab26e4220bd64797cd14269ad5fa55ff9bb`](https://etherscan.io/address/0xdbbb0ab26e4220bd64797cd14269ad5fa55ff9bb) |
| OffChainArtRenderer         | [`0xdd66baee1d81c60cfb4aa63a4fec58ecb7bc4d76`](https://etherscan.io/address/0xdd66baee1d81c60cfb4aa63a4fec58ecb7bc4d76) |
| OffChainArtThumbnailStorage | [`0x0aa880612e15d830d9b8952635f480313cd42d6e`](https://etherscan.io/address/0x0aa880612e15d830d9b8952635f480313cd42d6e) |

**Sepolia**

| Contract                    | Address                                                                                                                          |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| OffChainArt                 | [`0x8fffca14963a8136a8b426c332cd34b0f9d57eed`](https://sepolia.etherscan.io/address/0x8fffca14963a8136a8b426c332cd34b0f9d57eed)  |
| OffChainArtRenderer         | [`0x8a899abdff7bfa29dd61262e129be1ee668238ba`](https://sepolia.etherscan.io/address/0x8a899abdff7bfa29dd61262e129be1ee668238ba)  |
| OffChainArtThumbnailStorage | [`0x38e961c5c2916f28bd6f35eb918178420123e710`](https://sepolia.etherscan.io/address/0x38e961c5c2916f28bd6f35eb9 18178420123e710) |

- **OffChainArt** - the main contract, a Manifold extension that handles minting and transfer tracking (ERC1155)
- **OffChainArtRenderer** - generates token metadata, manages image URIs and display modes, and renders the HTML page
- **OffChainArtThumbnailStorage** - stores the on-chain thumbnail using SSTORE2 chunked storage with FastLZ compression

## MURI Protocol

The idea behind Off-Chain Art was later developed into **MURI Protocol** (Multi-URI Protocol), a generalized version of
the same concept as a standalone protocol.

- Website: [muri.yigitduman.com](https://muri.yigitduman.com/)
- GitHub: [github.com/ygtdmn/muri-protocol](https://github.com/ygtdmn/muri-protocol)

## License

[MIT](LICENSE.md)
