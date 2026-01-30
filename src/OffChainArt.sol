// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

import { IERC721CreatorCore } from "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import { IERC1155CreatorCore } from "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import { ICreatorExtensionTokenURI } from
    "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import { IERC1155CreatorExtensionApproveTransfer } from
    "@manifoldxyz/creator-core-solidity/contracts/extensions/ERC1155/IERC1155CreatorExtensionApproveTransfer.sol";
import { IERC165, ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OffChainArtRenderer } from "./OffChainArtRenderer.sol";

/**
 * @title Off-Chain Art
 * @author Yigit Duman (@yigitduman)
 */
contract OffChainArt is ICreatorExtensionTokenURI, IERC1155CreatorExtensionApproveTransfer, ERC165, Ownable {
    // === Custom Errors ===
    error AlreadyMinted();
    error CreatorMustImplementIERC1155CreatorCore();
    error CreatorMustBeTheCreatorContractAddress();

    /// @notice The metadata renderer contract that generates token metadata
    /// @dev This renderer handles both image and HTML display modes
    OffChainArtRenderer public metadataRenderer;

    /// @notice Address of the Manifold creator contract that mints the actual tokens
    /// @dev Must implement IERC1155CreatorCore for token minting functionality
    address public creatorContractAddress;

    /// @notice The token ID of the minted NFT (0 if not yet minted)
    /// @dev Only one token can be minted per contract instance
    uint256 public tokenId;

    /// @notice Current owner/holder of the minted token
    /// @dev Updated automatically when token transfers occur
    address public currentOwner;

    /**
     * @notice Initializes the off-chain art contract with renderer and creator contracts
     * @dev Sets up the contract with required external contract addresses for metadata rendering and token creation
     * @param _metadataRenderer Address of the OffChainArtRenderer contract that will generate metadata
     * @param _creatorContractAddress Address of the Manifold creator contract for minting tokens
     */
    constructor(address _metadataRenderer, address _creatorContractAddress) {
        metadataRenderer = OffChainArtRenderer(_metadataRenderer);
        creatorContractAddress = _creatorContractAddress;
    }

    /**
     * @notice Updates the metadata renderer contract address
     * @dev Only the contract owner (artist) can change the renderer to maintain artistic control
     * @param _metadataRenderer Address of the new OffChainArtRenderer contract
     */
    function setMetadataRenderer(address _metadataRenderer) public onlyOwner {
        metadataRenderer = OffChainArtRenderer(_metadataRenderer);
    }

    /**
     * @notice Updates the Manifold creator contract address
     * @dev Only the contract owner can change this address. Should be used with caution as it affects token minting.
     * @param _creatorContractAddress Address of the new Manifold creator contract
     * @custom:security Changing this after minting may cause issues with token operations
     */
    function setCreatorContractAddress(address _creatorContractAddress) public onlyOwner {
        creatorContractAddress = _creatorContractAddress;
    }

    /**
     * @notice Returns the metadata URI for any token (Manifold extension interface)
     * @dev Implements ICreatorExtensionTokenURI.tokenURI() - ignores token parameters and returns the same metadata for
     * all tokens
     * @return string The complete metadata JSON as a data URI
     */
    function tokenURI(address, uint256) external view override returns (string memory) {
        // Delegate metadata generation to the renderer contract
        return metadataRenderer.renderMetadata();
    }

    /**
     * @notice Mints the single NFT token to the contract owner
     * @dev Creates exactly one ERC1155 token via the Manifold creator contract. Can only be called once.
     *      The token is minted with quantity 1 to the contract owner (artist).
     * @custom:access Only callable by the contract owner
     * @custom:security Can only be called once - subsequent calls will revert
     */
    function mint() external onlyOwner {
        // Ensure this is the first and only mint
        if (tokenId != 0) revert AlreadyMinted();

        // Prepare minting parameters for a single token
        address[] memory dest = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        string[] memory uris = new string[](1); // Empty URIs - metadata handled by this extension

        dest[0] = msg.sender; // Mint to contract owner (artist)
        quantities[0] = 1; // Mint exactly one token

        // Mint via Manifold creator contract and store the resulting token ID
        tokenId = IERC1155CreatorCore(creatorContractAddress).mintExtensionNew(dest, quantities, uris)[0];
        currentOwner = msg.sender;
    }

    /**
     * @notice Checks if the contract supports a specific interface (ERC165)
     * @dev Returns true for supported interfaces: ICreatorExtensionTokenURI, IERC1155CreatorExtensionApproveTransfer,
     * and standard ERC165
     * @param interfaceId The 4-byte interface identifier to check
     * @return bool True if the interface is supported, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId
            || interfaceId == type(IERC1155CreatorExtensionApproveTransfer).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Enables or disables transfer approval for the creator contract
     * @dev Configures whether this extension should approve token transfers. Must be called on the correct creator
     * contract.
     * @param creator Address of the creator contract to configure
     * @param enabled True to enable transfer approval, false to disable
     * @custom:security Only works with the configured creator contract address and valid IERC1155CreatorCore
     * implementations
     */
    function setApproveTransfer(address creator, bool enabled) external override {
        // Verify the creator contract implements the required interface
        if (!ERC165Checker.supportsInterface(creator, type(IERC1155CreatorCore).interfaceId)) {
            revert CreatorMustImplementIERC1155CreatorCore();
        }
        // Ensure we're only configuring our designated creator contract
        if (creator != creatorContractAddress) revert CreatorMustBeTheCreatorContractAddress();

        // Configure transfer approval on the creator contract
        IERC1155CreatorCore(creator).setApproveTransferExtension(enabled);
    }

    /**
     * @notice Approves token transfers and tracks the current owner
     * @dev Called by the creator contract before every transfer. Updates currentOwner for collector permissions.
     *      Always approves transfers (returns true) while tracking ownership changes.
     * @param from Address transferring the token
     * @param to Address receiving the token
     *
     * @return bool Always returns true to approve all transfers
     */
    function approveTransfer(
        address, // creator contract (unused)
        address from,
        address to,
        uint256[] calldata, // token IDs (unused)
        uint256[] calldata // quantities (unused)
    )
        external
        override
        returns (bool)
    {
        // Update current owner if this is an actual transfer (not self-transfer)
        if (from != to) {
            currentOwner = to;
        }
        // Always approve transfers
        return true;
    }
}
