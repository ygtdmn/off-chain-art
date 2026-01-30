// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { OffChainArtRenderer } from "../src/OffChainArtRenderer.sol";
import { OffChainArt } from "../src/OffChainArt.sol";
import { IEphemera } from "../test/interfaces/IEphemera.sol";

contract UpdateImageMode is BaseScript {
    function run() public broadcast {
        OffChainArtRenderer renderer = OffChainArtRenderer(0xDD66BAeE1D81c60cFb4Aa63a4FeC58eCb7BC4D76);
        renderer.setDisplayMode(OffChainArtRenderer.DisplayMode.HTML);
    }
}
