// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";

import { OffChainArtRenderer } from "../src/OffChainArtRenderer.sol";
import { OffChainArt } from "../src/OffChainArt.sol";
import { OffChainArtThumbnailStorage } from "../src/OffChainArtThumbnailStorage.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ICreatorExtensionTokenURI } from
    "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import { IERC1155CreatorExtensionApproveTransfer } from
    "@manifoldxyz/creator-core-solidity/contracts/extensions/ERC1155/IERC1155CreatorExtensionApproveTransfer.sol";
import { IERC1155CreatorCore } from "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import { IEphemera } from "./interfaces/IEphemera.sol";

contract OffChainArtRendererTest is Test {
    OffChainArtRenderer public renderer;
    OffChainArt public artwork;
    OffChainArtThumbnailStorage public thumbnailStorage;

    address public owner = address(0x1);
    address public collector = address(0x2);
    address public ephemera = address(0x3);

    string public constant METADATA = unicode"\"name\": \"Test Art\",\"description\": \"Test Description\"";
    string public constant IMAGE_HASH = "0x64e7494e20117fcfd5b7c5992460696c1c3114242c949a69e21a3937199f0edc";
    string public constant HTML_TEMPLATE = "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Off-Chain Art</title></head><body style='margin:0;padding:0;display:flex;justify-content:center;align-items:center;min-height:100vh;background:#000;'><div style='color:white;'id='content'>Loading...</div><div id='debug' style='position:fixed;top:10px;left:10px;color:white;font-family:monospace;font-size:12px;max-width:300px;word-break:break-all;'></div><script>async function sha256(buffer) {const data = new Uint8Array(buffer);const totalBlocks = Math.ceil((data.length + 9) / 64);let processedBlocks = 0;function rightRotate(value, amount) { return (value >>> amount) | (value << (32 - amount)); }const k = [0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2];let h = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];const len = data.length * 8;const padding = new Uint8Array(64 - ((data.length + 9) % 64));const padded = new Uint8Array(data.length + 1 + padding.length + 8);padded.set(data); padded[data.length] = 0x80;const view = new DataView(padded.buffer);view.setUint32(padded.length - 4, len, false);for (let i = 0; i < padded.length; i += 64) {processedBlocks++;if (processedBlocks % 4096 === 0) {const progress = Math.floor((processedBlocks / totalBlocks) * 100);debug.innerHTML = debug.innerHTML.split('<br>Hashing:')[0] + '<br>Hashing: ' + progress + '%';await new Promise(resolve => setTimeout(resolve, 0));}const w = new Array(64);for (let j = 0; j < 16; j++) w[j] = view.getUint32(i + j * 4, false);for (let j = 16; j < 64; j++) {const s0 = rightRotate(w[j-15], 7) ^ rightRotate(w[j-15], 18) ^ (w[j-15] >>> 3);const s1 = rightRotate(w[j-2], 17) ^ rightRotate(w[j-2], 19) ^ (w[j-2] >>> 10);w[j] = (w[j-16] + s0 + w[j-7] + s1) >>> 0;}let [a,b,c,d,e,f,g,h0] = h;for (let j = 0; j < 64; j++) {const S1 = rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25);const ch = (e & f) ^ (~e & g);const temp1 = (h0 + S1 + ch + k[j] + w[j]) >>> 0;const S0 = rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22);const maj = (a & b) ^ (a & c) ^ (b & c);const temp2 = (S0 + maj) >>> 0;h0 = g; g = f; f = e; e = (d + temp1) >>> 0; d = c; c = b; b = a; a = (temp1 + temp2) >>> 0;}h = h.map((x, i) => (x + [a,b,c,d,e,f,g,h0][i]) >>> 0);}return h.map(x => x.toString(16).padStart(8, '0')).join('');}const imageUris = [{{IMAGE_URIS}}];const expectedHash = '{{IMAGE_HASH}}';const debug = document.getElementById('debug');debug.innerHTML = 'Expected: ' + expectedHash + '<br>URIs: ' + imageUris.length + '<br>Checking available images...';async function calculateHash(arrayBuffer) {try {return await sha256(arrayBuffer);} catch (e) {debug.innerHTML += '<br>Hash error: ' + e.message;return null;}}async function loadImage() {const content = document.getElementById('content');for (let i = 0; i < imageUris.length; i++) {const uri = imageUris[i];try {debug.innerHTML += '<br>Trying: ' + uri.substring(0, 30) + '...';const response = await fetch(uri, { mode: 'cors' });debug.innerHTML += '<br>Status: ' + response.status;if (response.status === 200) {const arrayBuffer = await response.arrayBuffer();debug.innerHTML += '<br>Size: ' + arrayBuffer.byteLength;if (!expectedHash || expectedHash.length === 0) {debug.innerHTML += '<br>NO EXPECTED HASH - Cannot verify';continue;}const fileSizeMB = (arrayBuffer.byteLength / (1024 * 1024)).toFixed(1);debug.innerHTML += '<br>Hashing ' + fileSizeMB + 'MB file...';const hashHex = await calculateHash(arrayBuffer);if (!hashHex) {debug.innerHTML += '<br>Hash calculation failed';continue;}debug.innerHTML += '<br>Hash: ' + hashHex.substring(0, 16) + '...';const cleanExpected = expectedHash.replace('0x', '');if (hashHex === cleanExpected) {debug.innerHTML += '<br>HASH MATCH! Loading...';const stage = document.createElement('div');stage.style.position = 'fixed';stage.style.inset = '0';stage.style.overflow = 'hidden';stage.style.background = '#000';stage.style.touchAction = 'none';stage.style.cursor = 'grab';const panzoom = document.createElement('div');panzoom.style.transformOrigin = '0 0';panzoom.style.visibility = 'hidden';const img = document.createElement('img');img.src = uri;img.style.display = 'block';img.style.userSelect = 'none';img.draggable = false;let scale = 1, minScale = 1, x = 0, y = 0;const zoomFactors = [1, 2, 3];let zoomIndex = 0;function clampPosition() {const sw = stage.clientWidth, sh = stage.clientHeight;const iw = img.naturalWidth || 0, ih = img.naturalHeight || 0;const dw = iw * scale, dh = ih * scale;if (dw <= sw) { x = Math.round((sw - dw) / 2); } else { if (x > 0) x = 0; if (x < sw - dw) x = Math.round(sw - dw); }if (dh <= sh) { y = Math.round((sh - dh) / 2); } else { if (y > 0) y = 0; if (y < sh - dh) y = Math.round(sh - dh); }}function applyTransform() {clampPosition();panzoom.style.transform = 'translate(' + x + 'px,' + y + 'px) scale(' + scale + ')';}function setZoomAt(factor, cx, cy) {const newScale = Math.max(minScale, Math.min(10, minScale * factor));const k = newScale / scale;x = cx - (cx - x) * k;y = cy - (cy - y) * k;scale = newScale;applyTransform();}img.onload = () => {const sw = stage.clientWidth, sh = stage.clientHeight;const iw = img.naturalWidth, ih = img.naturalHeight;minScale = Math.min(sw / iw, sh / ih);scale = minScale;x = Math.round((sw - iw * scale) / 2);y = Math.round((sh - ih * scale) / 2);applyTransform();panzoom.style.visibility = 'visible';debug.style.display = 'none';};let isPanning = false, startX = 0, startY = 0, startTX = 0, startTY = 0, moved = false;stage.addEventListener('pointerdown', (e) => {isPanning = true;moved = false;startX = e.clientX; startY = e.clientY;startTX = x; startTY = y;stage.setPointerCapture(e.pointerId);stage.style.cursor = 'grabbing';});stage.addEventListener('pointermove', (e) => {if (!isPanning) return;const dx = e.clientX - startX;const dy = e.clientY - startY;if (Math.abs(dx) > 2 || Math.abs(dy) > 2) moved = true;x = startTX + dx;y = startTY + dy;applyTransform();});const endPan = (e) => {if (!isPanning) return;isPanning = false;stage.releasePointerCapture(e.pointerId);stage.style.cursor = 'grab';};stage.addEventListener('pointerup', (e) => {const rect = stage.getBoundingClientRect();const cx = e.clientX - rect.left;const cy = e.clientY - rect.top;const wasMoved = moved;endPan(e);if (!wasMoved) {zoomIndex = (zoomIndex + 1) % zoomFactors.length;setZoomAt(zoomFactors[zoomIndex], cx, cy);}});stage.addEventListener('pointercancel', endPan);stage.addEventListener('wheel', (e) => {e.preventDefault();const rect = stage.getBoundingClientRect();const cx = e.clientX - rect.left;const cy = e.clientY - rect.top;const zoom = Math.exp(-e.deltaY * 0.0015);const newScale = Math.max(minScale, Math.min(10, scale * zoom));const k = newScale / scale;x = cx - (cx - x) * k;y = cy - (cy - y) * k;scale = newScale;applyTransform();}, { passive: false });window.addEventListener('resize', () => {const sw = stage.clientWidth, sh = stage.clientHeight;const iw = img.naturalWidth, ih = img.naturalHeight;const newMin = Math.min(sw / iw, sh / ih);minScale = newMin;if (scale < minScale) {scale = minScale;}applyTransform();});content.innerHTML = '';content.appendChild(stage);stage.appendChild(panzoom);panzoom.appendChild(img);return;} else {debug.innerHTML += '<br>Hash mismatch';}}} catch (e) { debug.innerHTML += '<br>Error: ' + e.message; }}content.innerHTML = 'No image with matching hash found. All images failed hash verification.';}loadImage();</script></body></html>";
    string[] public imageUris;

    function setUp() public {
        // Setup image URIs
        imageUris = new string[](3);
        imageUris[0] = "https://example.com/image1.png";
        imageUris[1] = "https://example.com/image2.png";
        imageUris[2] = "https://example.com/image3.png";

        vm.startPrank(owner);
        thumbnailStorage = new OffChainArtThumbnailStorage();
        renderer = new OffChainArtRenderer(METADATA, address(thumbnailStorage), IMAGE_HASH, imageUris, HTML_TEMPLATE);
        artwork = new OffChainArt(address(renderer), ephemera);
        renderer.setOffChainArt(address(artwork));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function testConstructor() public view {
        // Test constructor sets initial values correctly
        assertEq(renderer.metadata(), METADATA);
        assertEq(address(renderer.thumbnailStorage()), address(thumbnailStorage));
        assertEq(renderer.getImageHash(), IMAGE_HASH);
        assertEq(uint256(renderer.displayMode()), uint256(OffChainArtRenderer.DisplayMode.IMAGE));

        string[] memory retrievedUris = renderer.getOriginalImageUris();
        assertEq(retrievedUris.length, 3);
        assertEq(retrievedUris[0], imageUris[0]);
        assertEq(retrievedUris[1], imageUris[1]);
        assertEq(retrievedUris[2], imageUris[2]);
    }

    function testConstructorWithEmptyImageUris() public {
        string[] memory emptyUris = new string[](0);

        vm.prank(owner);
        OffChainArtThumbnailStorage emptyThumbnailStorage = new OffChainArtThumbnailStorage();
        OffChainArtRenderer newRenderer = new OffChainArtRenderer(METADATA, address(emptyThumbnailStorage), IMAGE_HASH, emptyUris, HTML_TEMPLATE);

        string[] memory retrievedUris = newRenderer.getOriginalImageUris();
        assertEq(retrievedUris.length, 0);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCESS CONTROL TESTS
    //////////////////////////////////////////////////////////////*/

    function testOnlyOwnerFunctions() public {
        vm.startPrank(collector);

        // Test functions that should only be callable by owner
        vm.expectRevert("Ownable: caller is not the owner");
        renderer.setImageHash("new_hash");

        vm.expectRevert("Ownable: caller is not the owner");
        renderer.setOriginalImageUris(imageUris);

        vm.expectRevert("Ownable: caller is not the owner");
        renderer.setThumbnailStorage(address(0x123));

        vm.expectRevert("Ownable: caller is not the owner");
        renderer.setMetadata("new metadata");

        vm.expectRevert("Ownable: caller is not the owner");
        renderer.setOffChainArt(address(0x123));

        vm.stopPrank();
    }

    function testOnlyOwnerOrCollectorFunctions() public {
        // Mock the artwork to return collector as current owner
        vm.mockCall(address(artwork), abi.encodeWithSignature("currentOwner()"), abi.encode(collector));

        // Test that owner can call these functions
        vm.prank(owner);
        renderer.setDisplayMode(OffChainArtRenderer.DisplayMode.HTML);

        // Test that collector can call these functions
        vm.prank(collector);
        renderer.setDisplayMode(OffChainArtRenderer.DisplayMode.IMAGE);

        // Test that random address cannot call these functions
        vm.prank(address(0x999));
        vm.expectRevert(OffChainArtRenderer.OnlyOwnerOrCollector.selector);
        renderer.setDisplayMode(OffChainArtRenderer.DisplayMode.HTML);
    }

    /*//////////////////////////////////////////////////////////////
                            DISPLAY MODE TESTS
    //////////////////////////////////////////////////////////////*/

    function testSetDisplayMode() public {
        // Initially should be IMAGE mode
        assertEq(uint256(renderer.displayMode()), uint256(OffChainArtRenderer.DisplayMode.IMAGE));

        // Set to HTML mode
        vm.prank(owner);
        renderer.setDisplayMode(OffChainArtRenderer.DisplayMode.HTML);
        assertEq(uint256(renderer.displayMode()), uint256(OffChainArtRenderer.DisplayMode.HTML));

        // Set back to IMAGE mode
        vm.prank(owner);
        renderer.setDisplayMode(OffChainArtRenderer.DisplayMode.IMAGE);
        assertEq(uint256(renderer.displayMode()), uint256(OffChainArtRenderer.DisplayMode.IMAGE));
    }

    function testSetDisplayModeEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit OffChainArtRenderer.DisplayModeSet(OffChainArtRenderer.DisplayMode.HTML);

        vm.prank(owner);
        renderer.setDisplayMode(OffChainArtRenderer.DisplayMode.HTML);
    }

    function testSetDisplayedImageUriIndex() public {
        // Should work in IMAGE mode
        vm.prank(owner);
        renderer.setDisplayedImageUriIndex(1);
        assertEq(renderer.displayedImageIndex(), 1);

        // Should also work in HTML mode
        vm.prank(owner);
        renderer.setDisplayMode(OffChainArtRenderer.DisplayMode.HTML);

        vm.prank(owner);
        renderer.setDisplayedImageUriIndex(2);
        assertEq(renderer.displayedImageIndex(), 2);
    }

    function testSetDisplayedImageUriIndexInvalidIndex() public {
        vm.expectRevert(OffChainArtRenderer.InvalidImageIndex.selector);
        vm.prank(owner);
        renderer.setDisplayedImageUriIndex(10); // Out of bounds
    }

    function testSetDisplayedImageUriIndexEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit OffChainArtRenderer.DisplayedImageUriSet(imageUris[2]);

        vm.prank(owner);
        renderer.setDisplayedImageUriIndex(2);
    }

    /*//////////////////////////////////////////////////////////////
                            IMAGE URI MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testSetOriginalImageUris() public {
        string[] memory newUris = new string[](2);
        newUris[0] = "https://new1.com/image.png";
        newUris[1] = "https://new2.com/image.png";

        vm.prank(owner);
        renderer.setOriginalImageUris(newUris);

        string[] memory retrievedUris = renderer.getOriginalImageUris();
        assertEq(retrievedUris.length, 2);
        assertEq(retrievedUris[0], newUris[0]);
        assertEq(retrievedUris[1], newUris[1]);
    }

    function testAddCustomImageUri() public {
        string memory customUri = "https://custom.com/image.png";

        vm.expectEmit(true, true, true, true);
        emit OffChainArtRenderer.CustomImageUriAdded(customUri, owner);

        vm.prank(owner);
        renderer.addCustomImageUri(customUri);
    }

    function testAddCustomImageUriEmpty() public {
        vm.expectRevert(OffChainArtRenderer.URICannotBeEmpty.selector);
        vm.prank(owner);
        renderer.addCustomImageUri("");
    }

    function testAddCustomImageUriDuplicate() public {
        string memory customUri = "https://custom.com/image.png";

        vm.prank(owner);
        renderer.addCustomImageUri(customUri);

        vm.expectRevert(OffChainArtRenderer.URIAlreadyExists.selector);
        vm.prank(owner);
        renderer.addCustomImageUri(customUri);
    }

    function testRemoveCustomImageUri() public {
        string memory customUri1 = "https://custom1.com/image.png";
        string memory customUri2 = "https://custom2.com/image.png";

        // Add two custom URIs
        vm.startPrank(owner);
        renderer.addCustomImageUri(customUri1);
        renderer.addCustomImageUri(customUri2);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit OffChainArtRenderer.CustomImageUriRemoved(customUri1, owner);

        vm.prank(owner);
        renderer.removeCustomImageUri(0);
    }

    function testRemoveCustomImageUriInvalidIndex() public {
        vm.expectRevert(OffChainArtRenderer.InvalidImageIndex.selector);
        vm.prank(owner);
        renderer.removeCustomImageUri(0); // No custom URIs exist
    }

    /*//////////////////////////////////////////////////////////////
                            METADATA RENDERING TESTS
    //////////////////////////////////////////////////////////////*/

    function testRenderMetadataImageMode() public view {
        // Set to image mode and verify structure
        string memory metadata = renderer.renderMetadata();

        // Should be a base64 encoded data URI
        assertTrue(bytes(metadata).length > 0);
        assertTrue(_startsWith(metadata, "data:application/json;base64,"));

        // Verify it's longer than just the prefix (contains actual data)
        assertTrue(bytes(metadata).length > 29); // length of "data:application/json;base64,"
    }

    function testRenderMetadataHTMLMode() public {
        vm.prank(owner);
        renderer.setDisplayMode(OffChainArtRenderer.DisplayMode.HTML);

        string memory metadata = renderer.renderMetadata();

        // Should be a base64 encoded data URI
        assertTrue(bytes(metadata).length > 0);
        assertTrue(_startsWith(metadata, "data:application/json;base64,"));

        // HTML mode should produce longer metadata due to animation_url with HTML content
        assertTrue(bytes(metadata).length > 100);
    }

    function testRenderMetadataImageModeNoImageSet() public {
        // Create a new renderer with no images set initially
        string[] memory emptyUris = new string[](0);
        vm.prank(owner);
        OffChainArtThumbnailStorage emptyThumbnailStorage = new OffChainArtThumbnailStorage();
        OffChainArtRenderer emptyRenderer = new OffChainArtRenderer(METADATA, address(emptyThumbnailStorage), IMAGE_HASH, emptyUris, HTML_TEMPLATE);

        vm.expectRevert(OffChainArtRenderer.NoImageURISetForImageMode.selector);
        emptyRenderer.renderMetadata();
    }

    function testRenderHTML() public view {
        string memory html = renderer.renderHTML();

        // Should be a base64 encoded HTML data URI
        assertTrue(bytes(html).length > 0);
        assertTrue(_startsWith(html, "data:text/html;base64,"));

        // HTML should be quite long due to the interactive viewer code
        assertTrue(bytes(html).length > 1000);
    }

    /*//////////////////////////////////////////////////////////////
                            OFFCHAIN ART TESTS
    //////////////////////////////////////////////////////////////*/

    function testOffChainArtConstructor() public view {
        assertEq(address(artwork.metadataRenderer()), address(renderer));
        assertEq(artwork.creatorContractAddress(), ephemera);
        assertEq(artwork.tokenId(), 0); // Not minted yet
        assertEq(artwork.currentOwner(), address(0)); // No owner yet
    }

    function testOffChainArtSetters() public {
        address newRenderer = address(0x123);
        address newCreator = address(0x456);

        vm.startPrank(owner);
        artwork.setMetadataRenderer(newRenderer);
        artwork.setCreatorContractAddress(newCreator);
        vm.stopPrank();

        assertEq(address(artwork.metadataRenderer()), newRenderer);
        assertEq(artwork.creatorContractAddress(), newCreator);
    }

    function testOffChainArtSettersOnlyOwner() public {
        vm.startPrank(collector);

        vm.expectRevert("Ownable: caller is not the owner");
        artwork.setMetadataRenderer(address(0x123));

        vm.expectRevert("Ownable: caller is not the owner");
        artwork.setCreatorContractAddress(address(0x456));

        vm.stopPrank();
    }

    function testOffChainArtTokenURI() public {
        // Mock the renderer to return a specific metadata
        string memory expectedMetadata = "test-metadata-uri";
        vm.mockCall(
            address(renderer),
            abi.encodeWithSelector(OffChainArtRenderer.renderMetadata.selector),
            abi.encode(expectedMetadata)
        );

        string memory tokenUri = artwork.tokenURI(address(0), 0);
        assertEq(tokenUri, expectedMetadata);
    }

    function testOffChainArtMint() public {
        // Mock the ephemera contract to return a token ID
        uint256 expectedTokenId = 123;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = expectedTokenId;

        vm.mockCall(
            ephemera, abi.encodeWithSelector(IERC1155CreatorCore.mintExtensionNew.selector), abi.encode(tokenIds)
        );

        vm.prank(owner);
        artwork.mint();

        assertEq(artwork.tokenId(), expectedTokenId);
        assertEq(artwork.currentOwner(), owner);
    }

    function testOffChainArtMintOnlyOnce() public {
        // Mock the ephemera contract
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 123;
        vm.mockCall(
            ephemera, abi.encodeWithSelector(IERC1155CreatorCore.mintExtensionNew.selector), abi.encode(tokenIds)
        );

        vm.startPrank(owner);
        artwork.mint();

        vm.expectRevert(OffChainArt.AlreadyMinted.selector);
        artwork.mint();
        vm.stopPrank();
    }

    function testOffChainArtMintOnlyOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(collector);
        artwork.mint();
    }

    function testOffChainArtApproveTransfer() public {
        address from = address(0x111);
        address to = address(0x222);
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        // Should update current owner when transferring
        bool result = artwork.approveTransfer(address(0), from, to, ids, amounts);
        assertTrue(result);
        assertEq(artwork.currentOwner(), to);

        // Should not update when from == to
        result = artwork.approveTransfer(address(0), to, to, ids, amounts);
        assertTrue(result);
        assertEq(artwork.currentOwner(), to); // Should remain the same
    }

    function testOffChainArtSupportsInterface() public view {
        // Should support ICreatorExtensionTokenURI
        assertTrue(artwork.supportsInterface(type(ICreatorExtensionTokenURI).interfaceId));

        // Should support IERC1155CreatorExtensionApproveTransfer
        assertTrue(artwork.supportsInterface(type(IERC1155CreatorExtensionApproveTransfer).interfaceId));

        // Should support ERC165
        assertTrue(artwork.supportsInterface(type(IERC165).interfaceId));
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);

        if (strBytes.length < prefixBytes.length) {
            return false;
        }

        for (uint256 idx = 0; idx < prefixBytes.length; idx++) {
            if (strBytes[idx] != prefixBytes[idx]) {
                return false;
            }
        }

        return true;
    }

    function testFork_Example() external {
        // Silently pass this test if there is no API key.
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        if (bytes(alchemyApiKey).length == 0) {
            return;
        }

        // Otherwise, run the test against the mainnet fork.
        vm.createSelectFork({ urlOrAlias: "mainnet" });
        vm.startPrank(address(0x28996f7DECe7E058EBfC56dFa9371825fBfa515A));

        address ephemeraAddr = address(0xCb337152b6181683010D07e3f00e7508cd348BC7); // mainnet
        // address ephemeraAddr = address(0xBF6b69aF9a0f707A9004E85D2ce371Ceb665237B); // sepolia
        string memory testMetadata =
            unicode"\"name\": \"Off-Chain Art\",\"description\": \"An artwork that blends six historic paintings which were altered without the artists' intent: The Night Watch by Rembrandt, The Last Supper by Leonardo da Vinci, The Vision of Saint John by El Greco, The Last Judgement by Michelangelo, Las Meninas by Diego Velázquez, and The Death of Actaeon by Titian.\",\"attributes\": [{\"trait_type\": \"Artwork 1\", \"value\": \"The Night Watch by Rembrandt\"}, {\"trait_type\": \"Artwork 2\", \"value\": \"The Last Supper by Leonardo da Vinci\"}, {\"trait_type\": \"Artwork 3\", \"value\": \"The Vision of Saint John by El Greco\"}, {\"trait_type\": \"Artwork 4\", \"value\": \"The Last Judgement by Michelangelo\"}, {\"trait_type\": \"Artwork 5\", \"value\": \"Las Meninas by Diego Velázquez\"}, {\"trait_type\": \"Artwork 6\", \"value\": \"The Death of Actaeon by Titian\"}]";
        string memory testImageHash = "0x64e7494e20117fcfd5b7c5992460696c1c3114242c949a69e21a3937199f0edc";
        string[] memory testImageUris = new string[](6);
        testImageUris[0] = "https://raw.githubusercontent.com/ygtdmn/off-chain-art/refs/heads/main/artwork.png";
        testImageUris[1] = "https://ygtdmn.s3.us-east-1.amazonaws.com/off-chain+art.png";
        testImageUris[2] =
            "https://gateway.lighthouse.storage/ipfs/bafybeidjzgptc5unebgsbw3npoyzkpjzwuzoarw2wvkgroq2d4uzldoyp4";
        testImageUris[3] = "https://bafybeidjzgptc5unebgsbw3npoyzkpjzwuzoarw2wvkgroq2d4uzldoyp4.ipfs.w3s.link/";
        testImageUris[4] = "https://ia601007.us.archive.org/31/items/off-chain-art/off-chain%20art.png";
        testImageUris[5] =
            "https://amlljqoil6w6uh3pfyuk34uanrnznx2hf6prpovwzvkia4d673vq.arweave.net/Axa0wchfreofby4orfKAbFuW30cvnxe6ts1UgHB-_us";
        string memory testHtmlTemplate = HTML_TEMPLATE;
        OffChainArtThumbnailStorage testThumbnailStorage = new OffChainArtThumbnailStorage();
        OffChainArtRenderer testRenderer =
            new OffChainArtRenderer(testMetadata, address(testThumbnailStorage), testImageHash, testImageUris, testHtmlTemplate);
        OffChainArt testArtwork = new OffChainArt(address(testRenderer), address(ephemeraAddr));
        testRenderer.setOffChainArt(address(testArtwork));
        IEphemera(ephemeraAddr).registerExtension(address(testArtwork), "");

        testArtwork.mint();
        testRenderer.setDisplayMode(OffChainArtRenderer.DisplayMode.HTML);
        // console2.log(testArtwork.tokenURI(address(0x28996f7DECe7E058EBfC56dFa9371825fBfa515A), 7));
        console2.log(testRenderer.renderHTML());
    }
}
