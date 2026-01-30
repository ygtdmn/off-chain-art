// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

/**
 * @title IOffChainArtThumbnailStorage
 */
interface IOffChainArtThumbnailStorage {
    /**
     * @notice Retrieves the raw decompressed image data
     * @dev Returns the image as raw bytes after decompression from stored chunks
     * @return bytes The decompressed raw image data
     */
    function getRawImage() external view returns (bytes memory);

    /**
     * @notice Retrieves the image as a base64-encoded data URI
     * @dev Returns a complete data URI string suitable for web display (data:image/webp;base64,...)
     * @return string The base64-encoded data URI of the stored image
     */
    function getImageURI() external view returns (string memory);

    /**
     * @notice Checks if image chunks have been stored in the contract
     * @dev Returns true if any chunks have been set, false if storage is empty
     * @return bool True if chunks are stored, false otherwise
     */
    function isChunksSet() external view returns (bool);
}
