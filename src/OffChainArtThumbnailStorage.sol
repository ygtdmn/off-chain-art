// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Base64 } from "solady/utils/Base64.sol";
import { Lifebuoy } from "solady/utils/Lifebuoy.sol";
import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibZip } from "solady/utils/LibZip.sol";
import { IOffChainArtThumbnailStorage } from "./interfaces/IOffChainArtThumbnailStorage.sol";

/**
 * @title OffChainArtThumbnailStorage
 * @author Yigit Duman (@yigitduman)
 */
contract OffChainArtThumbnailStorage is Ownable, Lifebuoy, IOffChainArtThumbnailStorage {
    /// @notice Thrown when attempting to load an image that hasn't been set
    error ImageNotSet();

    /// @notice Array of SSTORE2 contract addresses storing compressed image chunks
    /// @dev Each address points to a contract deployed via SSTORE2.write() containing part of the compressed image data
    address[] public chunks;

    /**
     * @notice Initializes the contract with Ownable and Lifebuoy functionality
     * @dev Sets up the contract with access control and error handling capabilities
     */
    constructor() { }

    /**
     * @notice Replaces all existing image chunks with new compressed data
     * @dev Clears the current chunks array and stores new compressed data using SSTORE2
     * @param _chunks Array of compressed image data to store
     * @custom:access Only callable by the contract owner
     */
    function setChunks(bytes[] calldata _chunks) external onlyOwner {
        // Clear existing chunks to replace with new data
        delete chunks;

        // Store each chunk as a separate SSTORE2 contract for gas efficiency
        for (uint8 i = 0; i < _chunks.length; i++) {
            chunks.push(SSTORE2.write(_chunks[i]));
        }
    }

    /**
     * @notice Appends additional image chunks to the existing stored data
     * @dev Adds new compressed data chunks without clearing existing ones
     * @param _chunks Array of additional compressed image data to append
     * @custom:access Only callable by the contract owner
     */
    function appendChunks(bytes[] calldata _chunks) external onlyOwner {
        for (uint8 i = 0; i < _chunks.length; i++) {
            chunks.push(SSTORE2.write(_chunks[i]));
        }
    }

    /**
     * @notice Loads and decompresses the complete raw image data
     * @dev Concatenates all stored chunks from SSTORE2 contracts and decompresses using FastLZ
     * @return bytes The decompressed raw image data
     * @custom:throws ImageNotSet if no chunks have been stored
     */
    function loadRawImage() public view returns (bytes memory) {
        // Ensure image data has been set before attempting to load
        if (chunks.length == 0) {
            revert ImageNotSet();
        }

        bytes memory data;

        // Retrieve and concatenate all stored chunks from SSTORE2 contracts
        // Each chunk is stored in a separate contract for gas optimization
        for (uint8 i = 0; i < chunks.length; i++) {
            data = abi.encodePacked(data, SSTORE2.read(chunks[i]));
        }

        // Decompress the concatenated data using FastLZ algorithm
        data = LibZip.flzDecompress(data);

        return data;
    }

    /**
     * @notice Loads the image as a base64-encoded data URI
     * @dev Retrieves raw image data and encodes it as a WebP data URI for web display
     * @return string The complete data URI string (data:image/webp;base64,...)
     */
    function loadImage() public view returns (string memory) {
        return string(abi.encodePacked("data:image/webp;base64,", Base64.encode(loadRawImage())));
    }

    /**
     * @notice Interface implementation: Returns the image as a data URI
     * @dev Implements IOffChainArtThumbnailStorage.getImageURI()
     * @return string The base64-encoded data URI of the stored image
     */
    function getImageURI() external view override returns (string memory) {
        return loadImage();
    }

    /**
     * @notice Interface implementation: Returns raw image bytes
     * @dev Implements IOffChainArtThumbnailStorage.getRawImage()
     * @return bytes The decompressed raw image data
     */
    function getRawImage() external view override returns (bytes memory) {
        return loadRawImage();
    }

    /**
     * @notice Interface implementation: Checks if image chunks are stored
     * @dev Implements IOffChainArtThumbnailStorage.isChunksSet()
     * @return bool True if chunks have been stored, false otherwise
     */
    function isChunksSet() external view override returns (bool) {
        return chunks.length > 0;
    }

    /**
     * @notice Utility function to decompress FastLZ compressed data
     * @dev Pure function that can be used to test decompression of data
     * @param data The compressed data to decompress
     * @return bytes The decompressed data
     */
    function unzip(bytes memory data) external pure returns (bytes memory) {
        return abi.encodePacked(LibZip.flzDecompress(data));
    }

    /**
     * @notice Utility function to compress data using FastLZ
     * @dev Pure function that can be used to test compression of data
     * @param data The raw data to compress
     * @return bytes The compressed data
     */
    function zip(bytes memory data) external pure returns (bytes memory) {
        return abi.encodePacked(LibZip.flzCompress(data));
    }

    /**
     * @notice Returns the array of SSTORE2 contract addresses storing the image chunks
     * @dev Useful for debugging and verifying the stored chunk addresses
     * @return address[] Array of SSTORE2 contract addresses
     */
    function getChunks() external view returns (address[] memory) {
        return chunks;
    }
}
