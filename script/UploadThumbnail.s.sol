// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { OffChainArtThumbnailStorage } from "../src/OffChainArtThumbnailStorage.sol";
import { OffChainArt } from "../src/OffChainArt.sol";
import { IEphemera } from "../test/interfaces/IEphemera.sol";

contract UploadThumbnail is BaseScript {
    function run() public broadcast {
        OffChainArtThumbnailStorage thumbnail = new OffChainArtThumbnailStorage();
        bytes memory image = vm.readFileBinary("thumbnail.webp");
        bytes memory compressed = thumbnail.zip(image);
        uint256 maxChunkSize = 23 * 1024;

        if (compressed.length <= maxChunkSize) {
            bytes[] memory chunks = new bytes[](1);
            chunks[0] = compressed;

            thumbnail.setChunks(chunks);
        } else {
            // Split into multiple chunks
            uint256 numChunks = (compressed.length + maxChunkSize - 1) / maxChunkSize;
            bytes[] memory chunks = new bytes[](numChunks);

            for (uint256 j = 0; j < numChunks; j++) {
                uint256 start = j * maxChunkSize;
                uint256 end = start + maxChunkSize;
                if (end > compressed.length) {
                    end = compressed.length;
                }

                // Extract chunk
                chunks[j] = new bytes(end - start);
                for (uint256 k = 0; k < end - start; k++) {
                    chunks[j][k] = compressed[start + k];
                }
            }

            thumbnail.setChunks(chunks);
        }
    }
}
