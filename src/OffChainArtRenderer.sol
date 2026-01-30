// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Base64 } from "solady/utils/Base64.sol";
import { OffChainArt } from "./OffChainArt.sol";
import { LibString } from "solady/utils/LibString.sol";
import { IOffChainArtThumbnailStorage } from "./interfaces/IOffChainArtThumbnailStorage.sol";

/**
 * @title OffChainArtRenderer
 * @author Yigit Duman (@yigitduman)
 */
contract OffChainArtRenderer is Ownable {
    // === Custom Errors ===
    error OnlyOwnerOrCollector();
    error InvalidImageIndex();
    error URICannotBeEmpty();
    error URIAlreadyExists();
    error NoImageURISetForImageMode();
    error NoThumbnailOrImageURIAvailable();
    /**
     * @notice Available display modes for the NFT metadata
     * @dev IMAGE mode shows a single selected image, HTML mode shows an interactive page with multiple images
     */

    enum DisplayMode {
        IMAGE,
        /// Single image display mode
        HTML
    }
    /// Interactive HTML display mode with multiple images

    // === Core Contract References ===
    /// @notice Reference to the main OffChainArt contract for accessing current owner information
    OffChainArt public offChainArt;

    /// @notice Reference to the thumbnail storage contract
    IOffChainArtThumbnailStorage public thumbnailStorage;

    // === Metadata Configuration ===
    /// @notice Base metadata JSON that will be combined with image/animation fields
    /// @dev Should contain name, description, and attributes but not image/animation_url fields
    string public metadata;

    /// @notice Expected hash of valid images for integrity verification
    /// @dev Used in HTML mode to validate that loaded images match the expected content
    string public imageHash;

    /// @notice HTML template for generating interactive displays in HTML mode
    /// @dev Contains placeholders {{IMAGE_URIS}} and {{IMAGE_HASH}} that get replaced during rendering
    string public htmlTemplate;

    /// @notice Current display mode (IMAGE or HTML)
    DisplayMode public displayMode;

    // === Image URI Management ===
    /// @notice Artist-controlled image URIs that can be displayed in both modes
    /// @dev These URIs are set by the contract owner (artist) and can be used in IMAGE mode
    string[] public imageUris;

    /// @notice Collector-controlled image URIs that can only be displayed in HTML mode
    /// @dev These URIs are added by collectors and must match the imageHash to be displayed
    string[] public customImageUris;

    /// @notice Index of the currently displayed image when in IMAGE mode
    /// @dev Points to an index in the imageUris array (not customImageUris)
    uint256 public displayedImageIndex;

    // === Events ===
    /// @notice Emitted when the display mode is changed
    event DisplayModeSet(DisplayMode mode);

    /// @notice Emitted when a custom image URI is added by a collector or artist
    event CustomImageUriAdded(string uri, address addedBy);

    /// @notice Emitted when a custom image URI is removed
    event CustomImageUriRemoved(string uri, address removedBy);

    /// @notice Emitted when the displayed image is changed
    event DisplayedImageUriSet(string uri);

    // === Access Control ===
    /**
     * @notice Restricts access to contract owner (artist) or current token holder (collector)
     * @dev Many functions can be called by either the artist or the current collector to enable collaborative control
     */
    modifier onlyOwnerOrCollector() {
        if (!(msg.sender == owner() || msg.sender == offChainArt.currentOwner())) {
            revert OnlyOwnerOrCollector();
        }
        _;
    }

    /**
     * @notice Initializes the renderer with configuration for metadata generation
     * @dev Sets up all necessary parameters for rendering both IMAGE and HTML display modes
     * @param _metadata Base JSON metadata containing name, description, attributes (without image/animation fields)
     * @param _thumbnailStorage Address of the thumbnail storage contract for HTML mode thumbnails
     * @param _imageHash Expected hash for image validation in HTML mode
     * @param _imageUris Array of initial artist-controlled image URIs
     * @param _htmlTemplate HTML template with {{IMAGE_URIS}} and {{IMAGE_HASH}} placeholders
     */
    constructor(
        string memory _metadata,
        address _thumbnailStorage,
        string memory _imageHash,
        string[] memory _imageUris,
        string memory _htmlTemplate
    ) {
        metadata = _metadata;
        thumbnailStorage = IOffChainArtThumbnailStorage(_thumbnailStorage);
        displayMode = DisplayMode.IMAGE; // Default to single image display mode
        imageHash = _imageHash;
        imageUris = _imageUris;
        htmlTemplate = _htmlTemplate;
    }

    /**
     * @notice Sets the reference to the main OffChainArt contract
     * @dev Required for accessing currentOwner() to enable collector permissions
     * @param _offChainArt Address of the OffChainArt contract
     * @custom:access Only callable by the contract owner (artist)
     * @custom:security Should be set once during initialization
     */
    function setOffChainArt(address _offChainArt) external onlyOwner {
        offChainArt = OffChainArt(_offChainArt);
    }

    /**
     * @notice Sets the reference to the thumbnail storage contract
     * @dev Updates the thumbnail storage contract used for HTML mode image display
     * @param _thumbnailStorage Address of the thumbnail storage contract
     * @custom:access Only callable by the contract owner (artist)
     */
    function setThumbnailStorage(address _thumbnailStorage) external onlyOwner {
        thumbnailStorage = IOffChainArtThumbnailStorage(_thumbnailStorage);
    }

    /**
     * @notice Returns the expected image hash for validation
     * @dev Used in HTML mode to verify that loaded images match the expected content
     * @return string The image hash used for validation
     */
    function getImageHash() public view returns (string memory) {
        return imageHash;
    }

    /**
     * @notice Updates the expected image hash for validation
     * @dev Only the artist can update this hash, affecting which images are considered valid in HTML mode
     * @param _imageHash The new image hash to use for validation
     */
    function setImageHash(string memory _imageHash) external onlyOwner {
        imageHash = _imageHash;
    }

    /**
     * @notice Returns all artist-controlled image URIs
     * @dev These URIs can be displayed in IMAGE mode and are included in HTML mode
     * @return string[] Array of artist-controlled image URIs
     */
    function getOriginalImageUris() public view returns (string[] memory) {
        return imageUris;
    }

    /**
     * @notice Updates the artist-controlled image URIs
     * @dev Replaces all existing artist URIs with the new array.
     * @param _imageUris Array of new image URIs to set
     * @custom:access Only callable by the contract owner (artist)
     */
    function setOriginalImageUris(string[] memory _imageUris) external onlyOwner {
        imageUris = _imageUris;
    }

    /**
     * @notice Changes the display mode between single image and interactive HTML
     * @dev IMAGE mode shows one selected image, HTML mode shows an interactive page with all images
     * @param mode The new display mode (IMAGE or HTML)
     * @custom:access Callable by either the artist or current collector
     */
    function setDisplayMode(DisplayMode mode) external onlyOwnerOrCollector {
        displayMode = mode;
        emit DisplayModeSet(mode);
    }

    /**
     * @notice Selects which artist image to display when in IMAGE mode
     * @dev Changes the displayedImageIndex to point to a different image in the imageUris array
     * @param index The index of the image to display (must be < imageUris.length)
     * @custom:access Callable by either the artist or current collector
     */
    function setDisplayedImageUriIndex(uint256 index) external onlyOwnerOrCollector {
        if (index >= imageUris.length) revert InvalidImageIndex();

        displayedImageIndex = index;
        emit DisplayedImageUriSet(imageUris[index]);
    }

    /**
     * @notice Adds a custom image URI that can be displayed in HTML mode
     * @dev Custom URIs are only shown in HTML mode and only if they match the expected image hash.
     *      They cannot be used in IMAGE mode, which only uses artist-controlled imageUris.
     * @param uri The image URI to add (must be non-empty and unique)
     * @custom:access Callable by either the artist or current collector
     * @custom:validation URI must be non-empty and not already exist in customImageUris
     */
    function addCustomImageUri(string memory uri) external onlyOwnerOrCollector {
        if (bytes(uri).length == 0) revert URICannotBeEmpty();

        // Prevent duplicate URIs in the custom list
        for (uint256 i = 0; i < customImageUris.length; i++) {
            if (keccak256(bytes(customImageUris[i])) == keccak256(bytes(uri))) revert URIAlreadyExists();
        }

        customImageUris.push(uri);
        emit CustomImageUriAdded(uri, msg.sender);
    }

    /**
     * @notice Removes a custom image URI from the contract
     * @dev Uses swap-and-pop for efficient removal, which changes the order of remaining elements
     * @param index The index of the custom image URI to remove
     * @custom:access Callable by either the artist or current collector
     * @custom:security Index must be valid to prevent out-of-bounds access
     */
    function removeCustomImageUri(uint256 index) external onlyOwnerOrCollector {
        if (index >= customImageUris.length) revert InvalidImageIndex();

        string memory uri = customImageUris[index];

        // Efficient removal: move last element to current position and reduce array size
        customImageUris[index] = customImageUris[customImageUris.length - 1];
        customImageUris.pop();

        emit CustomImageUriRemoved(uri, msg.sender);
    }

    // === Artist-Only Configuration Functions ===
    /**
     * @notice Updates the base metadata JSON
     * @dev Should contain name, description, and attributes but not image/animation_url fields
     * @param _metadata The new base metadata JSON string
     * @custom:access Only callable by the contract owner (artist)
     */
    function setMetadata(string memory _metadata) external onlyOwner {
        metadata = _metadata;
    }

    /**
     * @notice Updates the HTML template for HTML display mode
     * @dev Template should contain {{IMAGE_URIS}} and {{IMAGE_HASH}} placeholders for replacement
     * @param _htmlTemplate The new HTML template string
     * @custom:access Only callable by the contract owner (artist)
     */
    function setHtmlTemplate(string memory _htmlTemplate) external onlyOwner {
        htmlTemplate = _htmlTemplate;
    }

    /**
     * @notice Generates the complete metadata JSON for the token
     * @dev Combines base metadata with either an image field (IMAGE mode) or both image and animation_url fields (HTML
     * mode)
     * @return string The complete metadata JSON as a base64-encoded data URI
     */
    function renderMetadata() public view returns (string memory) {
        string memory imageField;

        if (displayMode == DisplayMode.IMAGE) {
            // IMAGE mode: Show only the selected image
            if (displayedImageIndex >= imageUris.length) revert NoImageURISetForImageMode();
            imageField = string(abi.encodePacked('"image": "', imageUris[displayedImageIndex], '"'));
        } else {
            // HTML mode: Show thumbnail from storage as image and animation_url for interactive content
            string memory htmlContent = renderHTML();
            string memory thumbnailUri = "";

            // Try to get thumbnail from storage, fallback to displayedImageIndex if not available
            if (address(thumbnailStorage) != address(0) && thumbnailStorage.isChunksSet()) {
                thumbnailUri = thumbnailStorage.getImageURI();
            } else if (displayedImageIndex < imageUris.length) {
                thumbnailUri = imageUris[displayedImageIndex];
            } else {
                revert NoThumbnailOrImageURIAvailable();
            }

            // Include both image (for thumbnail) and animation_url (for interactive HTML)
            imageField =
                string(abi.encodePacked('"image": "', thumbnailUri, '",', '"animation_url": "', htmlContent, '"'));
        }

        // Combine base metadata with the appropriate image/animation fields
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(string(abi.encodePacked("{", metadata, ",", imageField, "}"))))
            )
        );
    }

    /**
     * @notice Generates interactive HTML content for HTML display mode
     * @dev Creates an HTML page that tests all image URIs (artist + custom) and displays the first one
     *      that loads successfully and matches the expected image hash
     * @return string The complete HTML content as a base64-encoded data URI
     */
    function renderHTML() public view returns (string memory) {
        string memory uriList = "";

        // Combine artist-controlled and collector-controlled image URIs
        string[] memory combinedImageUris = new string[](imageUris.length + customImageUris.length);

        // Add artist-controlled URIs first
        for (uint256 i = 0; i < imageUris.length; i++) {
            combinedImageUris[i] = imageUris[i];
        }

        // Add collector-controlled URIs after artist URIs
        for (uint256 i = 0; i < customImageUris.length; i++) {
            combinedImageUris[imageUris.length + i] = customImageUris[i];
        }

        // Build JavaScript array string for template injection
        for (uint256 i = 0; i < combinedImageUris.length; i++) {
            if (i > 0) {
                uriList = string(abi.encodePacked(uriList, ","));
            }
            uriList = string(abi.encodePacked(uriList, '"', combinedImageUris[i], '"'));
        }

        // Replace template placeholders with actual data
        string memory htmlContent = LibString.replace(htmlTemplate, "{{IMAGE_URIS}}", uriList);
        htmlContent = LibString.replace(htmlContent, "{{IMAGE_HASH}}", imageHash);

        // Return as base64-encoded data URI for embedding in metadata
        return string(abi.encodePacked("data:text/html;base64,", Base64.encode(bytes(htmlContent))));
    }
}
